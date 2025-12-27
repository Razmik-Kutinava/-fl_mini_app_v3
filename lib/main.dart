import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/cart_provider.dart';
import 'providers/location_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/user_provider.dart';
import 'screens/permissions_screen.dart';
import 'screens/main_screen.dart';
import 'screens/cart_screen.dart';
import 'services/telegram_service.dart';
import 'services/supabase_service.dart';
import 'constants/app_colors.dart';
import 'models/location.dart';
import 'models/product.dart';
import 'models/cart_item.dart';

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
  bool _isFirstVisit = true; // ⭐ Флаг первого визита (из FINAL_SOLUTION.md)
  bool _shouldOpenCart = false; // ⭐ Флаг для открытия корзины (для repeat_order)

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  /// Проверяет первый ли это визит пользователя (из FINAL_SOLUTION.md)
  Future<bool> _checkIsFirstVisit() async {
    final prefs = await SharedPreferences.getInstance();
    final visitCount = prefs.getInt('app_visit_count') ?? 0;
    final isFirst = visitCount == 0;

    print('🔍 Visit count: $visitCount, isFirst: $isFirst');

    // Увеличиваем счетчик
    await prefs.setInt('app_visit_count', visitCount + 1);
    print('✅ Visit count updated to: ${visitCount + 1}');

    return isFirst;
  }

  Future<void> _initializeUser() async {
    print('🚀 Starting user initialization...');
    print('🚀 VERSION: 18.0 - WITH REPEAT ORDER SUPPORT!');
    final userProvider = context.read<UserProvider>();
    final locationProvider = context.read<LocationProvider>();
    final cartProvider = context.read<CartProvider>();
    userProvider.setLoading(true);

    // ⭐⭐⭐ ПРОВЕРКА ACTION: repeat_order
    print('🔍 [STEP 0] Checking action from hash...');
    final action = TelegramService.instance.getActionFromHash();
    print('🔍 Action from hash: $action');
    
    if (action == 'repeat_order') {
      print('🔄 REPEAT ORDER DETECTED!');
      final orderId = TelegramService.instance.getOrderIdFromHash();
      final locationIdFromHash = TelegramService.instance.getLocationIdFromHash();
      
      print('🔄 Order ID: $orderId');
      print('🔄 Location ID: $locationIdFromHash');
      
      if (orderId != null && orderId.isNotEmpty) {
        try {
          // Загружаем товары заказа
          print('🔄 Loading order items...');
          final orderItems = await SupabaseService.getOrderItems(orderId);
          print('🔄 Found ${orderItems.length} items in order');
          
          if (orderItems.isNotEmpty) {
            // Очищаем корзину
            cartProvider.clear();
            
            // Загружаем локации для выбора локации
            final locationsData = await SupabaseService.getLocations();
            final locations = locationsData.map((data) => Location.fromJson(data)).toList();
            locationProvider.setLocations(locations);
            
            // Выбираем локацию из hash или первую доступную
            Location? targetLocation;
            if (locationIdFromHash != null) {
              try {
                targetLocation = locations.firstWhere((loc) => loc.id == locationIdFromHash);
                print('✅ Using location from hash: ${targetLocation.name}');
              } catch (e) {
                print('⚠️ Location from hash not found, using first available');
                targetLocation = locations.isNotEmpty ? locations.first : null;
              }
            } else {
              targetLocation = locations.isNotEmpty ? locations.first : null;
            }
            
            if (targetLocation != null) {
              await locationProvider.selectLocation(targetLocation);
              _autoSelectedLocation = targetLocation;
              _savedLocationId = targetLocation.id;
              _hasSavedLocation = true;
              _locationSelected = true;
            }
            
            // Для каждого товара заказа загружаем Product и добавляем в корзину
            for (var orderItem in orderItems) {
              try {
                final productId = orderItem['productId'] as String?;
                if (productId == null) continue;
                
                // Загружаем Product
                final productData = await SupabaseService.getProductById(productId);
                if (productData == null) {
                  print('⚠️ Product not found: $productId');
                  continue;
                }
                
                // Создаём Product объект
                final product = Product.fromJson(productData);
                
                // Получаем модификаторы из OrderItemModifier
                final modifiers = <String, dynamic>{};
                final modifiersList = orderItem['modifiers'] as List<dynamic>?;
                
                if (modifiersList != null && modifiersList.isNotEmpty) {
                  // Группируем модификаторы по группам
                  for (var mod in modifiersList) {
                    final modData = mod as Map<String, dynamic>;
                    final groupName = modData['modifierGroupName'] as String?;
                    final optionId = modData['modifierOptionId'] as String?;
                    
                    if (groupName != null && optionId != null) {
                      // Находим индекс опции в группе модификаторов продукта
                      if (product.modifiers != null) {
                        if (groupName.toLowerCase() == 'size' && product.modifiers!.size != null) {
                          final index = product.modifiers!.size!.options.indexWhere((opt) => opt.id == optionId);
                          if (index >= 0) {
                            modifiers['size'] = index;
                          }
                        } else if (groupName.toLowerCase() == 'milk' && product.modifiers!.milk != null) {
                          final index = product.modifiers!.milk!.options.indexWhere((opt) => opt.id == optionId);
                          if (index >= 0) {
                            modifiers['milk'] = index;
                          }
                        } else if (groupName.toLowerCase() == 'extras' && product.modifiers!.extras != null) {
                          final extras = modifiers['extras'] as List<int>? ?? [];
                          final index = product.modifiers!.extras!.options.indexWhere((opt) => opt.id == optionId);
                          if (index >= 0) {
                            extras.add(index);
                            modifiers['extras'] = extras;
                          }
                        }
                      }
                    }
                  }
                }
                
                // Создаём CartItem
                final quantity = (orderItem['quantity'] as num?)?.toInt() ?? 1;
                final cartItem = CartItem(
                  product: product,
                  modifiers: modifiers,
                  quantity: quantity,
                  totalPrice: 0, // Будет пересчитано в updateTotalPrice
                );
                cartItem.updateTotalPrice();
                
                // Добавляем в корзину
                cartProvider.addItem(cartItem);
                print('✅ Added to cart: ${product.name} x$quantity');
              } catch (e, stack) {
                print('❌ Error adding item to cart: $e');
                print('❌ Stack: $stack');
              }
            }
            
            print('🔄 Cart loaded with ${cartProvider.items.length} items');
            
            // Устанавливаем флаг для открытия корзины
            _shouldOpenCart = true;
          } else {
            print('⚠️ No items found in order');
          }
        } catch (e, stack) {
          print('❌ Error loading repeat order: $e');
          print('❌ Stack: $stack');
        }
      }
    }

    // ⭐ ПРОВЕРКА ПЕРВОГО ВИЗИТА (из FINAL_SOLUTION.md)
    _isFirstVisit = await _checkIsFirstVisit();
    print('🔍 Is first visit: $_isFirstVisit');

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
    // ЗАГРУЖАЕМ ЛОКАЦИИ - УПРОЩЁННАЯ ЛОГИКА v17
    // =====================================================
    print('🚀 VERSION: 17.0 - WITH VISIT COUNTER!');
    
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

    // ⭐⭐⭐ ОТКРЫТИЕ КОРЗИНЫ для repeat_order
    if (_shouldOpenCart) {
      print('🛒 Opening cart screen for repeat order...');
      // Используем WidgetsBinding для отложенного открытия после build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const CartScreen()),
        );
      });
      // Показываем MainScreen временно, пока не откроется корзина
      return const MainScreen();
    }

    // ⭐⭐⭐ НОВАЯ ЛОГИКА (из FINAL_SOLUTION.md):
    // Если НЕ первый визит - ВСЕГДА пропускаем стартовый экран!
    if (!_isFirstVisit) {
      print('✅ ==========================================');
      print('✅ NOT FIRST VISIT - skipping permissions screen');
      print('✅ Going DIRECTLY to MainScreen!');
      print('✅ ==========================================');
      return const MainScreen();
    }

    // Если первый визит - проверяем есть ли сохранённая локация
    print('🔍 FIRST VISIT - checking location');

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

    // ⭐ Только если НЕТ сохранённой кофейни И это первый визит - проверяем другие источники
    print('🔍 FIRST VISIT + NO SAVED COFFEE SHOP - checking other sources');
    final hasLocationFromProvider = locationProvider.selectedLocation != null;
    final hasLocationFromState = _autoSelectedLocation != null;
    final hasLocationsAvailable = locationProvider.locations.isNotEmpty;
    final hasLocation = hasLocationFromProvider || hasLocationFromState;

    print('🔍 Build check: _isFirstVisit=$_isFirstVisit, _locationSelected=$_locationSelected, _autoSelectedLocation=${_autoSelectedLocation?.name ?? "null"}, provider.selectedLocation=${locationProvider.selectedLocation?.name ?? "null"}, hasLocation=$hasLocation, hasLocationsAvailable=$hasLocationsAvailable');

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
      print('🎯 → Going to MainScreen with location: $locationName (ID: $locationId) (FIRST VISIT)');
      print('✅ SUCCESS: App will show MainScreen instead of PermissionsScreen');
      return const MainScreen();
    }

    // ⭐ ФИНАЛЬНЫЙ FALLBACK для первого визита:
    // Если есть локации в provider - всё равно идём в MainScreen!
    // Это гарантирует что пользователь НЕ увидит PermissionsScreen если есть хоть одна локация
    if (hasLocationsAvailable) {
      print('🆘 FINAL FALLBACK (FIRST VISIT): No selected location, but locations exist! Going to MainScreen anyway');
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

    print('📍 → Going to PermissionsScreen (FIRST VISIT + no locations available at all!)');
    print('⚠️ WARNING: No locations in database - user will see permissions screen');
    return const PermissionsScreen();
  }
}
