import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    print('🚀 Starting user initialization...');
    final userProvider = context.read<UserProvider>();
    final locationProvider = context.read<LocationProvider>();
    userProvider.setLoading(true);
    
    // Небольшая задержка для инициализации Telegram WebApp
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Получаем данные из Telegram
    print('📱 Getting Telegram user data...');
    final tgUser = TelegramService.instance.getUser();
    print('📱 tgUser result: $tgUser');
    
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
        } else {
          print('❌ Failed to create test user');
        }
      } catch (e) {
        print('❌ Error creating test user: $e');
      }
    }
    
    // =====================================================
    // ПРИОРИТЕТ 1: Загружаем preferredLocationId из Supabase!
    // Telegram НЕ передаёт URL параметры - используем БД
    // =====================================================
    String? telegramIdForLocation;
    if (tgUser != null && tgUser['id'] != null) {
      telegramIdForLocation = tgUser['id'].toString();
    }
    
    print('🔗 Loading user location from Supabase...');
    await UserLocationContext.loadFromDatabase(telegramIdForLocation);
    
    if (UserLocationContext.hasPreferredLocation) {
      print('✅ Found preferredLocationId from DB: ${UserLocationContext.preferredLocationId}');
      
      // Загружаем локации и выбираем нужную
      try {
        final locationsData = await SupabaseService.getLocations();
        final locations = locationsData
            .map((data) => Location.fromJson(data))
            .toList();
        locationProvider.setLocations(locations);
        
        print('📍 Available locations: ${locations.map((l) => "${l.name} (${l.id})").join(", ")}');
        
        // Ищем локацию по preferredLocationId
        final targetLocation = locations.firstWhere(
          (loc) => loc.id == UserLocationContext.preferredLocationId,
          orElse: () {
            print('⚠️ preferredLocationId not found in active locations, using first available');
            return locations.isNotEmpty ? locations.first : throw StateError('No locations');
          },
        );
        
        print('✅ Auto-selecting location: ${targetLocation.name}');
        await locationProvider.selectLocation(targetLocation);
        print('✅ Location selected from database, skipping location selection screen!');
      } catch (e) {
        print('⚠️ Error loading location from database: $e');
      }
    } else {
      // =====================================================
      // ПРИОРИТЕТ 2: Проверяем локально сохраненную локацию
      // =====================================================
      print('📍 No preferredLocationId in DB, checking local storage...');
      final lastLocationId = await locationProvider.getLastLocationId();
      if (lastLocationId != null) {
        print('📍 Found saved location locally: $lastLocationId');
        // Загружаем локации
        try {
          final locationsData = await SupabaseService.getLocations();
          final locations = locationsData
              .map((data) => Location.fromJson(data))
              .toList();
          locationProvider.setLocations(locations);
          
          // Восстанавливаем последнюю выбранную локацию
          locationProvider.restoreLastLocation(lastLocationId);
          print('✅ Location restored from local storage');
        } catch (e) {
          print('⚠️ Error loading locations: $e');
        }
      } else {
        print('📍 No saved location found anywhere');
      }
    }
    
    userProvider.setLoading(false);
    print('✅ User initialization complete');
    if (mounted) {
      setState(() => _initialized = true);
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
    
    // Если есть сохраненная локация, сразу переходим на главное меню
    final locationProvider = context.watch<LocationProvider>();
    if (locationProvider.selectedLocation != null) {
      print('🎯 Location already selected, going to main screen');
      return const MainScreen();
    }
    
    // Иначе запрашиваем разрешения
    return const PermissionsScreen();
  }
}
