import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'providers/location_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/user_provider.dart';
import 'screens/permissions_screen.dart';
import 'services/telegram_service.dart';
import 'services/supabase_service.dart';
import 'constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
      final testUser = await SupabaseService.getOrCreateUser(
        telegramId: 'test_${DateTime.now().millisecondsSinceEpoch}',
        username: 'test_user',
      );
      if (testUser != null) {
        userProvider.setUser(testUser);
        print('✅ Test user created: ${testUser['id']}');
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
    return const PermissionsScreen();
  }
}
