import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/cart_provider.dart';
import 'providers/location_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/user_provider.dart';
import 'screens/permissions_screen.dart';
import 'screens/main_screen.dart';
import 'services/telegram_service.dart';
import 'services/supabase_service.dart';
import 'constants/app_colors.dart';
import 'models/location.dart';

/// Глобальный класс для хранения preferredLocationId из БД
class UserLocationContext {
  static String? preferredLocationId;
  static String? telegramUserId;
  
  /// Загружает preferredLocationId из Supabase по telegram_id
  /// Это основной метод для автоматического выбора локации!
  static Future<void> loadFromDatabase(String? telegramId) async {
    if (telegramId == null || telegramId.isEmpty) {
      print('⚠️ No telegram_id available for location lookup');
      return;
    }
    
    telegramUserId = telegramId;
    print('🔍 Loading preferredLocationId from database for telegram_id: $telegramId');
    
    try {
      // Получаем preferredLocationId из Supabase
      preferredLocationId = await SupabaseService.getUserPreferredLocationId(telegramId);
      
      if (preferredLocationId != null) {
        print('✅ Found preferredLocationId from DB: $preferredLocationId');
      } else {
        // Если нет preferredLocationId, пробуем взять из последнего заказа
        print('🔍 No preferredLocationId, checking last order...');
        preferredLocationId = await SupabaseService.getUserLastOrderLocationId(telegramId);
        
        if (preferredLocationId != null) {
          print('✅ Found locationId from last order: $preferredLocationId');
        } else {
          print('⚠️ No location found for user');
        }
      }
    } catch (e) {
      print('❌ Error loading location from database: $e');
    }
  }
  
  /// Проверяет есть ли сохранённая локация
  static bool get hasPreferredLocation => 
      preferredLocationId != null && preferredLocationId!.isNotEmpty;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase FIRST
  await SupabaseService.initialize();
  
  // Initialize Telegram WebApp
  TelegramService.instance.init();
  
  runApp(const CoffeeApp());
}

class CoffeeApp extends StatelessWidget {
  const CoffeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
      ],
      child: MaterialApp(
        title: 'Coffee Mini App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: AppColors.background,
        ),
        home: const AppInitializer(),
      ),
    );
  }
}

// Новый виджет для инициализации пользователя
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;
  bool _locationSelected = false; // Флаг успешного выбора локации
  Location? _autoSelectedLocation; // Сохраняем выбранную локацию напрямую
  String? _savedLocationId; // ⭐ ID сохранённой кофейни (из БД или localStorage)
  bool _hasSavedLocation = false; // ⭐ Есть ли сохранённая кофейня

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  /// ⭐ БЫСТРАЯ проверка localStorage (может не работать в Telegram WebView!)
  Future<String?> _checkLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLocationId = prefs.getString('last_selected_location_id');
      print('🔍 [localStorage] last_selected_location_id: $lastLocationId');
      return lastLocationId;
    } catch (e) {
      print('❌ [localStorage] Error: $e');
      return null;
    }
  }

  /// ⭐ КЛЮЧЕВОЕ: Проверка preferredLocationId в БД (ОСНОВНОЙ ИСТОЧНИК!)
  /// Telegram WebView может НЕ сохранять localStorage между сессиями!
  /// Поэтому ВСЕГДА проверяем БД как основной источник!
  Future<String?> _checkDatabaseLocation(String telegramId) async {
    try {
      print('🔍 [DATABASE] Checking preferredLocationId for telegramId: $telegramId');
      
      // Используем существующий метод из SupabaseService
      final preferredLocationId = await SupabaseService.getUserPreferredLocationId(telegramId);
      
      if (preferredLocationId != null && preferredLocationId.isNotEmpty) {
        print('✅ [DATABASE] Found preferredLocationId: $preferredLocationId');
        return preferredLocationId;
      }
      
      // Если нет preferredLocationId, проверяем последний заказ
      print('🔍 [DATABASE] No preferredLocationId, checking last order...');
      final lastOrderLocationId = await SupabaseService.getUserLastOrderLocationId(telegramId);
      
      if (lastOrderLocationId != null && lastOrderLocationId.isNotEmpty) {
        print('✅ [DATABASE] Found locationId from last order: $lastOrderLocationId');
        return lastOrderLocationId;
      }
      
      print('ℹ️ [DATABASE] No saved location found for user');
      return null;
    } catch (e) {
      print('❌ [DATABASE] Error checking location: $e');
      return null;
    }
  }

  Future<void> _initializeUser() async {
    print('🚀 Starting user initialization...');
    print('🚀 VERSION: 9.0 - Retry mechanism for Telegram user data + DB as primary source!');
    print('🚀 localStorage may NOT persist in Telegram WebView between sessions!');
    final userProvider = context.read<UserProvider>();
    final locationProvider = context.read<LocationProvider>();
    userProvider.setLoading(true);

    // ⭐ ШАГ 0: Быстрая проверка localStorage (может не работать в TG WebView!)
    final localStorageLocationId = await _checkLocalStorage();
    print('🔍 [STEP 0] localStorage location: $localStorageLocationId');

    // ИСПРАВЛЕНИЕ: Retry механизм для получения Telegram user data
    // Telegram WebApp может инициализироваться с задержкой!
    print('📱 Getting Telegram user data with retry...');
    Map<String, dynamic>? tgUser;
    
    for (int attempt = 0; attempt < 5; attempt++) {
      if (attempt > 0) {
        print('⏳ Retry attempt $attempt/5 for Telegram user data...');
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      }
      
      tgUser = TelegramService.instance.getUser();
      
      if (tgUser != null && tgUser['id'] != null) {
        print('✅ Got Telegram user on attempt ${attempt + 1}');
        break;
      }
      
      print('⚠️ Attempt ${attempt + 1}: tgUser is null or has no id');
    }
    
    print('📱 Final tgUser result: $tgUser');
    
    if (tgUser != null && tgUser['id'] != null) {
      final telegramId = tgUser['id'].toString();
      final firstName = tgUser['firstName'] as String?;
      final lastName = tgUser['lastName'] as String?;
      final username = tgUser['username'] as String?;
      
      print('📱 Telegram user data:');
      print('  - ID: $telegramId');
      print('  - Username: $username');
      print('  - First Name: $firstName');
      print('  - Last Name: $lastName');
      
      // ⭐ КЛЮЧЕВОЕ: СРАЗУ проверяем БД на наличие сохранённой кофейни!
      // Это ОСНОВНОЙ источник, т.к. localStorage может не работать в TG WebView!
      print('🔍 ==========================================');
      print('🔍 [STEP 1] CHECKING DATABASE FOR SAVED LOCATION');
      print('🔍 ==========================================');
      final dbLocationId = await _checkDatabaseLocation(telegramId);
      
      if (dbLocationId != null && dbLocationId.isNotEmpty) {
        _savedLocationId = dbLocationId;
        _hasSavedLocation = true;
        print('✅ ==========================================');
        print('✅ FOUND SAVED COFFEE SHOP IN DATABASE!');
        print('✅ Location ID: $dbLocationId');
        print('✅ User should go DIRECTLY to MainScreen!');
        print('✅ ==========================================');
      } else if (localStorageLocationId != null && localStorageLocationId.isNotEmpty) {
        // Fallback на localStorage если БД не дала результат
        _savedLocationId = localStorageLocationId;
        _hasSavedLocation = true;
        print('✅ Using localStorage as fallback: $localStorageLocationId');
      } else {
        print('ℹ️ No saved location in DB or localStorage - first visit');
        _hasSavedLocation = false;
      }
      
      // Создаем или получаем пользователя
      print('💾 Creating/getting user in Supabase...');
      final user = await SupabaseService.getOrCreateUser(
        telegramId: telegramId,
        firstName: firstName,
        lastName: lastName,
        username: username,
      );
      
      if (user != null) {
        print('✅ User data from Supabase: $user');
        userProvider.setUser(user);
        print('✅ UserProvider updated with user data');
        print('✅ User initialized: ${user['id']}');
        print('✅ UserName will be: ${userProvider.userName}');

        // НОВОЕ: Устанавливаем userId в LocationProvider для синхронизации с БД
        locationProvider.setUserId(user['id'] as String);

        // Логируем активность
        await SupabaseService.logUserActivity(
          userId: user['id'] as String,
          activityType: 'app_opened',
          activityData: {'telegramId': telegramId},
        );
      } else {
        print('⚠️ Failed to create/get user');
      }
    } else {
      print('⚠️ No Telegram user data available');
      print('⚠️ This is normal if app is opened in browser, not in Telegram');
      
      // ⭐ КРИТИЧНО: Даже без Telegram данных - проверяем localStorage!
      // Это поможет при повторном заходе
      if (localStorageLocationId != null && localStorageLocationId.isNotEmpty) {
        _savedLocationId = localStorageLocationId;
        _hasSavedLocation = true;
        print('✅ Using localStorage location (no TG data): $localStorageLocationId');
      }
      
      // Для тестирования создаем тестового пользователя
      print('🧪 Creating test user for development...');
      try {
        final testUser = await SupabaseService.getOrCreateUser(
          telegramId: 'test_${DateTime.now().millisecondsSinceEpoch}',
          username: 'test_user',
        );
        if (testUser != null) {
          print('✅ Test user created: ${testUser['id']}');
          print('✅ Test user data: $testUser');
          userProvider.setUser(testUser);
          print('✅ UserProvider.setUser called with test user');
          print('✅ UserProvider.userName after setUser: ${userProvider.userName}');

          // НОВОЕ: Устанавливаем userId в LocationProvider для тестового пользователя
          locationProvider.setUserId(testUser['id'] as String);
        } else {
          print('❌ Failed to create test user');
        }
      } catch (e) {
        print('❌ Error creating test user: $e');
      }
    }
    
    // =====================================================
    // ЗАГРУЖАЕМ ЛОКАЦИИ И АВТОВЫБОР
    // =====================================================
    print('🚀 VERSION: 9.0 - Retry TG user + DATABASE as primary source!');
    
    try {
      // СНАЧАЛА загружаем все активные локации
      print('📍 Loading active locations from Supabase...');
      final locationsData = await SupabaseService.getLocations();
      final locations = locationsData
          .map((data) => Location.fromJson(data))
          .toList();
      
      print('📍 Loaded ${locations.length} active locations:');
      for (var loc in locations) {
        print('   - ${loc.name} (${loc.id})');
      }
      
      if (locations.isEmpty) {
        print('❌ No active locations found!');
        _locationSelected = false;
      } else {
        locationProvider.setLocations(locations);
        
        // Пытаемся найти preferredLocationId
        String? telegramIdForLocation;
        if (tgUser != null && tgUser['id'] != null) {
          telegramIdForLocation = tgUser['id'].toString();
          print('📱 Telegram user ID: $telegramIdForLocation');
        } else {
          print('⚠️ No Telegram user ID available');
        }
        
        Location? targetLocation;

        // ПРИОРИТЕТ 0: location_id из hash параметров URL (от бота) с retry механизмом
        print('🔍 PRIORITY 0: Checking hash parameters for location_id with retry...');
        print('   Current URL: ${Uri.base.toString()}');
        print('   Current hash (immediate check): ${Uri.base.fragment}');
        print('   Telegram WebApp initialized, starting hash read retry...');

        // Используем retry механизм, так как Telegram может устанавливать hash асинхронно
        // Увеличиваем количество попыток и задержку для большей надёжности
        final hashLocationId = await TelegramService.instance.getLocationIdFromHashWithRetry(
          maxAttempts: 6, // Увеличено с 5 до 6
          initialDelay: const Duration(milliseconds: 400), // Увеличено с 300 до 400
        );

        if (hashLocationId != null && hashLocationId.isNotEmpty) {
          print('✅ Found location_id in hash: $hashLocationId');
          try {
            targetLocation = locations.firstWhere(
              (loc) => loc.id == hashLocationId,
            );
            print('✅ SUCCESS! Location from hash matched: ${targetLocation.name} (${targetLocation.id})');
          } catch (e) {
            print('⚠️ Hash location_id "$hashLocationId" not found in active locations list');
            print('   Available location IDs: ${locations.map((l) => l.id).join(", ")}');
          }
        } else {
          print('ℹ️ No location_id found in hash after retries, will use other priorities');
        }

        // ПРИОРИТЕТ 1: preferredLocationId из БД или последний заказ (синхронизировано с ботом)
        if (targetLocation == null && telegramIdForLocation != null) {
          print('🔍 PRIORITY 1: Looking up preferredLocationId in database or last order...');
          print('   Telegram ID: $telegramIdForLocation');
          
          // ИСПРАВЛЕНИЕ: Запускаем БД запрос и локальное хранилище параллельно
          // Это ускоряет восстановление при втором заходе
          final dbFuture = UserLocationContext.loadFromDatabase(telegramIdForLocation);
          final localStorageFuture = locationProvider.getLastLocationId();
          
          // Ждём оба запроса параллельно
          final results = await Future.wait([dbFuture, localStorageFuture]);
          final lastLocationId = results[1] as String?;
          
          // Сначала проверяем БД результат
          if (UserLocationContext.hasPreferredLocation) {
            print('✅ Found preferredLocationId: ${UserLocationContext.preferredLocationId}');
            try {
              targetLocation = locations.firstWhere(
                (loc) => loc.id == UserLocationContext.preferredLocationId,
              );
              print('✅ Location matched from DB: ${targetLocation.name} (${targetLocation.id})');
            } catch (e) {
              print('⚠️ preferredLocationId "${UserLocationContext.preferredLocationId}" not in active locations list');
              print('   Available location IDs: ${locations.map((l) => l.id).join(", ")}');
            }
          } else {
            print('⚠️ No preferredLocationId found in database and no last order location');
          }
          
          // Если БД не дала результат, но локальное хранилище уже загружено - используем его
          if (targetLocation == null && lastLocationId != null && lastLocationId.isNotEmpty) {
            print('✅ Using location from local storage (fast path): $lastLocationId');
            try {
              targetLocation = locations.firstWhere(
                (loc) => loc.id == lastLocationId,
              );
              print('✅ Location restored from local storage: ${targetLocation.name}');
            } catch (e) {
              print('⚠️ Last location "$lastLocationId" not found in active locations');
            }
          }
        } else if (targetLocation == null) {
          print('⚠️ Cannot use PRIORITY 1: telegramIdForLocation is null');
        }
        
        // ПРИОРИТЕТ 2: Используем уже прочитанный _savedLocationId (быстрый путь!)
        // Мы уже прочитали его в начале _initializeUser(), используем напрямую
        if (targetLocation == null && _savedLocationId != null && _savedLocationId!.isNotEmpty) {
          print('🔍 PRIORITY 2: Using already loaded _savedLocationId: $_savedLocationId');
          try {
            targetLocation = locations.firstWhere(
              (loc) => loc.id == _savedLocationId,
            );
            print('✅ Location restored from saved ID: ${targetLocation.name} (${targetLocation.id})');
          } catch (e) {
            print('⚠️ Saved location "$_savedLocationId" not found in active locations list');
            print('   Available location IDs: ${locations.map((l) => l.id).join(", ")}');
          }
        }
        
        // ПРИОРИТЕТ 2.5: Fallback - повторное чтение из local storage (на всякий случай)
        if (targetLocation == null) {
          print('🔍 PRIORITY 2.5: Fallback - re-reading from local storage...');
          final lastLocationId = await locationProvider.getLastLocationId();
          
          if (lastLocationId != null && lastLocationId.isNotEmpty) {
            print('✅ Found last location in local storage: $lastLocationId');
            try {
              targetLocation = locations.firstWhere(
                (loc) => loc.id == lastLocationId,
              );
              print('✅ Location restored from local storage: ${targetLocation.name} (${targetLocation.id})');
            } catch (e) {
              print('⚠️ Last location "$lastLocationId" not found in active locations list');
              print('   Available location IDs: ${locations.map((l) => l.id).join(", ")}');
            }
          } else {
            print('ℹ️ No location found in local storage');
          }
        }
        
        // ПРИОРИТЕТ 3: Если ничего не нашли - берём первую локацию
        if (targetLocation == null && locations.isNotEmpty) {
          print('📍 PRIORITY 3: No location from hash, DB, or local storage, using first available location');
          targetLocation = locations.first;
          print('📍 Default location: ${targetLocation.name}');
        }
        
        // Выбираем локацию (если нашли на любом этапе)
        if (targetLocation != null) {
          print('🎯 AUTO-SELECTING: ${targetLocation.name} (${targetLocation.id})');

          // КРИТИЧНО: Сохраняем локацию напрямую в состояние
          _autoSelectedLocation = targetLocation;

          // Устанавливаем в провайдер (это автоматически сохранит в БД и локальное хранилище)
          await locationProvider.selectLocation(targetLocation);

          // Проверяем что локация установлена
          if (locationProvider.selectedLocation != null) {
            print('✅ Location confirmed selected in provider: ${locationProvider.selectedLocation!.name}');
            _locationSelected = true;
          } else {
            print('⚠️ Location not set in provider, but we have direct reference');
            // Используем прямую ссылку - локация всё равно будет работать
            _locationSelected = true;
          }
          print('✅ Location selection complete: _locationSelected=$_locationSelected, location=${targetLocation.name}');
          print('💾 Location automatically saved to DB via LocationProvider.selectLocation()');
        } else {
          // Если даже после всех попыток не нашли локацию
          print('❌ CRITICAL: No target location found after all priorities');
          print('   Locations available: ${locations.length}');
          if (locations.isEmpty) {
            print('   ⚠️ No locations in database - will show permissions screen');
          }
          _locationSelected = false;
          _autoSelectedLocation = null;
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error in location auto-selection: $e');
      print('❌ Stack trace: $stackTrace');
      _locationSelected = false;
      _autoSelectedLocation = null;
      
      // Последняя попытка - если есть локации, выбираем первую
      if (mounted) {
        try {
          final locationProvider = context.read<LocationProvider>();
          if (locationProvider.locations.isNotEmpty) {
            print('🆘 EMERGENCY FALLBACK: Selecting first location after error');
            final firstLoc = locationProvider.locations.first;
            _autoSelectedLocation = firstLoc;
            await locationProvider.selectLocation(firstLoc);
            _locationSelected = true;
          }
        } catch (e2) {
          print('❌ Emergency fallback also failed: $e2');
        }
      }
    }
    
    userProvider.setLoading(false);
    print('✅ User initialization complete. _locationSelected=$_locationSelected');
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final locationProvider = context.watch<LocationProvider>();

    // ⭐ КЛЮЧЕВОЕ: Если есть СОХРАНЁННАЯ КОФЕЙНЯ → СРАЗУ в главное меню!
    // Это исправляет проблему когда пользователь видит стартовую страницу
    // вместо главного меню при повторном заходе
    if (_hasSavedLocation) {
      print('✅ ==========================================');
      print('✅ HAS SAVED COFFEE SHOP - going to MainScreen!');
      print('✅ Saved location ID: $_savedLocationId');
      print('✅ ==========================================');

      // Проверяем и логируем текущую локацию
      final hasLocation = locationProvider.selectedLocation != null || _autoSelectedLocation != null;
      if (hasLocation) {
        final locationName = locationProvider.selectedLocation?.name ?? _autoSelectedLocation?.name ?? 'Unknown';
        print('✅ Current location: $locationName');
      } else {
        print('⚠️ Location will be restored from saved ID: $_savedLocationId');
        // Восстанавливаем локацию из сохранённого ID если она ещё не установлена
        if (_savedLocationId != null && locationProvider.locations.isNotEmpty) {
          try {
            locationProvider.restoreLastLocation(_savedLocationId!);
            print('✅ Location restored from saved ID');
          } catch (e) {
            print('⚠️ Could not restore location: $e - but still going to MainScreen');
          }
        }
      }

      return const MainScreen();
    }

    // ⭐ Только если НЕТ сохранённой кофейни - проверяем другие источники
    print('🔍 NO SAVED COFFEE SHOP - checking other sources');
    final hasLocationFromProvider = locationProvider.selectedLocation != null;
    final hasLocationFromState = _autoSelectedLocation != null;
    final hasLocationsAvailable = locationProvider.locations.isNotEmpty;
    final hasLocation = hasLocationFromProvider || hasLocationFromState;

    print('🔍 Build check: _locationSelected=$_locationSelected, _autoSelectedLocation=${_autoSelectedLocation?.name ?? "null"}, provider.selectedLocation=${locationProvider.selectedLocation?.name ?? "null"}, hasLocation=$hasLocation, hasLocationsAvailable=$hasLocationsAvailable');

    if (hasLocation) {
      // Убеждаемся что локация установлена в провайдер
      if (locationProvider.selectedLocation == null && _autoSelectedLocation != null) {
        print('⚠️ Location not in provider, restoring from _autoSelectedLocation...');
        try {
          locationProvider.restoreLastLocation(_autoSelectedLocation!.id);
          print('✅ Location restored in provider: ${_autoSelectedLocation!.name}');
        } catch (e) {
          print('❌ Failed to restore location: $e');
          // Если не удалось восстановить, устанавливаем напрямую
          locationProvider.selectLocation(_autoSelectedLocation!);
        }
      }
      
      final locationName = locationProvider.selectedLocation?.name ?? _autoSelectedLocation?.name ?? 'Unknown';
      final locationId = locationProvider.selectedLocation?.id ?? _autoSelectedLocation?.id ?? 'unknown';
      print('🎯 → Going to MainScreen with location: $locationName (ID: $locationId)');
      print('✅ SUCCESS: App will show MainScreen instead of PermissionsScreen');
      return const MainScreen();
    }
    
    // ⭐ ФИНАЛЬНЫЙ FALLBACK: Если есть локации в provider - всё равно идём в MainScreen!
    // Это гарантирует что пользователь НЕ увидит PermissionsScreen если есть хоть одна локация
    if (hasLocationsAvailable) {
      print('🆘 FINAL FALLBACK: No selected location, but locations exist! Going to MainScreen anyway');
      print('🆘 Selecting first available location...');
      try {
        final firstLocation = locationProvider.locations.first;
        locationProvider.selectLocation(firstLocation);
        print('✅ First location selected: ${firstLocation.name}');
      } catch (e) {
        print('⚠️ Could not select first location: $e');
      }
      return const MainScreen();
    }
    
    print('📍 → Going to PermissionsScreen (no locations available at all!)');
    print('⚠️ WARNING: No locations in database - user will see permissions screen');
    return const PermissionsScreen();
  }
}
