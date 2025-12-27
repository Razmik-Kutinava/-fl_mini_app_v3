import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  Future<void> _initializeUser() async {
    print('🚀 Starting user initialization...');
    print('🚀 VERSION: 15.0 - ULTRA SIMPLE: location_id FROM HASH FIRST!');
    final userProvider = context.read<UserProvider>();
    final locationProvider = context.read<LocationProvider>();
    userProvider.setLoading(true);

    // ⭐⭐⭐ САМЫЙ ПРОСТОЙ ПУТЬ: Бот передаёт location_id в URL hash!
    // Читаем его ПЕРВЫМ ДЕЛОМ и используем напрямую!
    print('🔍 [STEP 0] Reading location_id from URL hash (bot sends it!)...');
    final hashLocationId = TelegramService.instance.getLocationIdFromHash();
    print('🔍 Hash location_id: $hashLocationId');
    
    if (hashLocationId != null && hashLocationId.isNotEmpty) {
      print('🎉 ==========================================');
      print('🎉 GOT location_id FROM HASH: $hashLocationId');
      print('🎉 Going DIRECTLY to MainScreen!');
      print('🎉 ==========================================');
      _savedLocationId = hashLocationId;
      _hasSavedLocation = true;
    }
    
    // Также читаем telegram_user_id из hash (бот передаёт его)
    final telegramIdFromHash = TelegramService.instance.getTelegramUserIdFromHash();
    print('🔍 Hash telegram_user_id: $telegramIdFromHash');
    
    // Пробуем получить Telegram user из WebApp API (часто null!)
    final tgUser = TelegramService.instance.getUser();
    print('📱 WebApp tgUser: $tgUser');
    
    // Определяем telegramId - из hash или из WebApp API
    String? telegramId = telegramIdFromHash;
    if (telegramId == null && tgUser != null && tgUser['id'] != null) {
      telegramId = tgUser['id'].toString();
    }
    print('📱 Final telegramId: $telegramId');
    
    if (telegramId != null) {
      final firstName = tgUser?['firstName'] as String?;
      final lastName = tgUser?['lastName'] as String?;
      final username = tgUser?['username'] as String?;
      
      print('📱 User data:');
      print('  - telegramId: $telegramId');
      print('  - firstName: $firstName');
      print('  - username: $username');
      
      // Получаем пользователя из БД
      print('💾 Getting user from Supabase...');
      final user = await SupabaseService.getOrCreateUser(
        telegramId: telegramId,
        firstName: firstName ?? 'User',  // Default чтобы не было NOT NULL ошибки
        lastName: lastName,
        username: username,
      );
      
      if (user != null) {
        print('✅ User found: ${user['id']}');
        print('✅ preferredLocationId: ${user['preferredLocationId']}');
        
        userProvider.setUser(user);
        locationProvider.setUserId(user['id'] as String);

        // Если location_id уже есть из hash - используем его
        // Иначе берём preferredLocationId из БД
        if (!_hasSavedLocation) {
          final userPreferredLocationId = user['preferredLocationId'] as String?;
          if (userPreferredLocationId != null && userPreferredLocationId.isNotEmpty) {
            print('✅ Using preferredLocationId from DB: $userPreferredLocationId');
            _savedLocationId = userPreferredLocationId;
            _hasSavedLocation = true;
          }
        }
      } else {
        print('⚠️ Could not get user from DB');
      }
    } else {
      print('⚠️ No telegramId available (not from hash, not from WebApp)');
    }
    
    // =====================================================
    // ЗАГРУЖАЕМ ЛОКАЦИИ - УПРОЩЁННАЯ ЛОГИКА v16
    // =====================================================
    print('🚀 VERSION: 16.0 - GUARANTEED MAIN SCREEN!');
    
    try {
      // Загружаем все активные локации
      print('📍 Loading active locations from Supabase...');
      final locationsData = await SupabaseService.getLocations();
      final locations = locationsData
          .map((data) => Location.fromJson(data))
          .toList();
      
      print('📍 Loaded ${locations.length} active locations');
      
      if (locations.isEmpty) {
        print('❌ No active locations found!');
        _locationSelected = false;
      } else {
        locationProvider.setLocations(locations);
        
        Location? targetLocation;
        
        // Пробуем найти сохранённую локацию
        if (_savedLocationId != null) {
          print('🔍 Looking for saved location: $_savedLocationId');
          try {
            targetLocation = locations.firstWhere((loc) => loc.id == _savedLocationId);
            print('✅ Found saved location: ${targetLocation.name}');
          } catch (e) {
            print('⚠️ Saved location not found in list');
          }
        }
        
        // FALLBACK: берём ПЕРВУЮ локацию если не нашли сохранённую
        if (targetLocation == null) {
          targetLocation = locations.first;
          print('📍 Using first location as fallback: ${targetLocation.name}');
        }
        
        // ГАРАНТИРОВАННО выбираем локацию и идём в MainScreen
        _autoSelectedLocation = targetLocation;
        _savedLocationId = targetLocation.id;
        _hasSavedLocation = true;
        _locationSelected = true;
        await locationProvider.selectLocation(targetLocation);
        print('🎉 ==========================================');
        print('🎉 LOCATION SELECTED: ${targetLocation.name}');
        print('🎉 GOING TO MAIN SCREEN!');
        print('🎉 ==========================================');
      }
    } catch (e, stack) {
      print('❌ Error loading locations: $e');
      print('❌ Stack: $stack');
    }
    
    userProvider.setLoading(false);
    print('✅ User initialization complete.');
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
