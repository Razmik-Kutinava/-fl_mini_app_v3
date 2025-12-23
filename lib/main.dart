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

/// Глобальные параметры из URL (для передачи из бота)
class UrlParams {
  static String? locationId;
  static String? latitude;
  static String? longitude;
  static String? action;
  
  /// Читает параметры из URL при запуске в браузере
  static void parseFromUrl() {
    if (!kIsWeb) return;
    
    try {
      final uri = Uri.base;
      print('🔗 URL Parameters Parser:');
      print('  Full URL: ${uri.toString()}');
      print('  Query: ${uri.query}');
      print('  Fragment: ${uri.fragment}');
      
      // Читаем из query string (?param=value)
      if (uri.queryParameters.isNotEmpty) {
        locationId = uri.queryParameters['location_id'];
        latitude = uri.queryParameters['latitude'];
        longitude = uri.queryParameters['longitude'];
        action = uri.queryParameters['action'];
        print('  📍 Parsed from query: locationId=$locationId, action=$action');
      }
      
      // Если нет в query, пробуем из hash (#param=value)
      if (locationId == null && uri.fragment.isNotEmpty) {
        final hashParams = Uri.splitQueryString(uri.fragment);
        locationId = hashParams['location_id'];
        latitude = hashParams['latitude'];
        longitude = hashParams['longitude'];
        action = hashParams['action'];
        print('  📍 Parsed from hash: locationId=$locationId, action=$action');
      }
      
      if (locationId != null) {
        print('✅ URL contains location_id: $locationId - will skip location selection!');
      }
    } catch (e) {
      print('⚠️ Error parsing URL parameters: $e');
    }
  }
  
  /// Проверяет есть ли location_id в URL
  static bool get hasLocationFromUrl => locationId != null && locationId!.isNotEmpty;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Парсим URL параметры ПЕРВЫМ ДЕЛОМ
  UrlParams.parseFromUrl();
  
  // Initialize Supabase
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
    // ПРИОРИТЕТ 1: Проверяем URL параметры от бота!
    // =====================================================
    print('🔗 Checking URL parameters from bot...');
    if (UrlParams.hasLocationFromUrl) {
      print('✅ Found location_id from URL: ${UrlParams.locationId}');
      print('   Action: ${UrlParams.action}');
      print('   Latitude: ${UrlParams.latitude}');
      print('   Longitude: ${UrlParams.longitude}');
      
      // Загружаем локации и выбираем нужную
      try {
        final locationsData = await SupabaseService.getLocations();
        final locations = locationsData
            .map((data) => Location.fromJson(data))
            .toList();
        locationProvider.setLocations(locations);
        
        // Ищем локацию по ID из URL
        final targetLocation = locations.firstWhere(
          (loc) => loc.id == UrlParams.locationId,
          orElse: () => locations.isNotEmpty ? locations.first : throw StateError('No locations'),
        );
        
        print('✅ Found location from URL: ${targetLocation.name}');
        await locationProvider.selectLocation(targetLocation);
        print('✅ Location selected from URL, skipping location selection screen!');
      } catch (e) {
        print('⚠️ Error loading location from URL: $e');
      }
    } else {
      // =====================================================
      // ПРИОРИТЕТ 2: Проверяем сохраненную локацию
      // =====================================================
      print('📍 Checking for saved location...');
      final lastLocationId = await locationProvider.getLastLocationId();
      if (lastLocationId != null) {
        print('📍 Found saved location: $lastLocationId');
        // Загружаем локации
        try {
          final locationsData = await SupabaseService.getLocations();
          final locations = locationsData
              .map((data) => Location.fromJson(data))
              .toList();
          locationProvider.setLocations(locations);
          
          // Восстанавливаем последнюю выбранную локацию
          locationProvider.restoreLastLocation(lastLocationId);
          print('✅ Location restored, will skip location selection');
        } catch (e) {
          print('⚠️ Error loading locations: $e');
        }
      } else {
        print('📍 No saved location found');
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
