import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/cart_provider.dart';
import 'providers/location_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/user_provider.dart';
import 'screens/permissions_screen.dart';
import 'screens/main_screen.dart';
import 'screens/location_select_screen.dart';
import 'screens/cart_screen.dart';
import 'services/telegram_service.dart';
import 'services/supabase_service.dart';
import 'constants/app_colors.dart';
import 'models/location.dart';
import 'models/product.dart';
import 'models/cart_item.dart';
import 'dart:ui'; // Для ImageFilter.blur
import 'dart:js' as js; // Для экспорта версии в JS

// ⭐ ФЛАГ ВЕРСИИ ДЕПЛОЯ - обновляется при каждом коммите/пуше
const String DEPLOY_VERSION = '21.4';
const String DEPLOY_TIMESTAMP =
    '2025-01-27 17:20:00'; // Обновлять при каждом деплое! Версия 21.4 - билд и деплой

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
    print(
      '🔍 Loading preferredLocationId from database for telegram_id: $telegramId',
    );

    try {
      // Получаем preferredLocationId из Supabase
      preferredLocationId = await SupabaseService.getUserPreferredLocationId(
        telegramId,
      );

      if (preferredLocationId != null) {
        print('✅ Found preferredLocationId from DB: $preferredLocationId');
      } else {
        // Если нет preferredLocationId, пробуем взять из последнего заказа
        print('🔍 No preferredLocationId, checking last order...');
        preferredLocationId = await SupabaseService.getUserLastOrderLocationId(
          telegramId,
        );

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
  // ⭐ ВЫВОД ВЕРСИИ ДЕПЛОЯ - ПЕРВЫМ ДЕЛОМ!
  print('');
  print('═══════════════════════════════════════════════════════════');
  print('🚀 DEPLOY INFO - ПРОВЕРКА ОБНОВЛЕНИЙ КОДА');
  print('🚀 VERSION: $DEPLOY_VERSION');
  print('🚀 TIMESTAMP: $DEPLOY_TIMESTAMP');
  print('═══════════════════════════════════════════════════════════');
  print('');

  // Экспортируем версию в window для проверки в JS
  try {
    js.context['DEPLOY_VERSION'] = DEPLOY_VERSION;
    js.context['DEPLOY_TIMESTAMP'] = DEPLOY_TIMESTAMP;
  } catch (e) {
    print('⚠️ Could not export version to JS: $e');
  }

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
  bool _isFirstVisit = true; // ⭐ Флаг первого визита
  bool _shouldOpenCart =
      false; // ⭐ Флаг для открытия корзины (для repeat_order)
  bool _showLocationDialog =
      false; // ⭐ Показывать ли диалог подтверждения локации

  @override
  void initState() {
    super.initState();
    // ⭐ Выводим версию деплоя при каждом запуске
    print('🚀 ==========================================');
    print('🚀 DEPLOY VERSION: $DEPLOY_VERSION');
    print('🚀 DEPLOY TIMESTAMP: $DEPLOY_TIMESTAMP');
    print('🚀 ==========================================');
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
    print('🚀 VERSION: $DEPLOY_VERSION - WITH REPEAT ORDER SUPPORT!');
    print('🚀 DEPLOY TIMESTAMP: $DEPLOY_TIMESTAMP');
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
      final locationIdFromHash = TelegramService.instance
          .getLocationIdFromHash();

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
            final locations = locationsData
                .map((data) => Location.fromJson(data))
                .toList();
            locationProvider.setLocations(locations);

            // Выбираем локацию из hash или первую доступную
            Location? targetLocation;
            if (locationIdFromHash != null) {
              try {
                targetLocation = locations.firstWhere(
                  (loc) => loc.id == locationIdFromHash,
                );
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
              _locationSelected = true;
            }

            // Для каждого товара заказа загружаем Product и добавляем в корзину
            for (var orderItem in orderItems) {
              try {
                final productId = orderItem['productId'] as String?;
                if (productId == null) continue;

                // Загружаем Product
                final productData = await SupabaseService.getProductById(
                  productId,
                );
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
                    // Получаем label из modifierOption (если есть) или используем optionId как fallback
                    final modifierOption =
                        modData['modifierOption'] as Map<String, dynamic>?;
                    final optionLabel = modifierOption?['name'] as String?;

                    if (groupName != null && optionLabel != null) {
                      // Находим индекс опции в группе модификаторов продукта по label
                      if (product.modifiers != null) {
                        if (groupName.toLowerCase() == 'size' &&
                            product.modifiers!.size != null) {
                          final index = product.modifiers!.size!.options
                              .indexWhere((opt) => opt.label == optionLabel);
                          if (index >= 0) {
                            modifiers['size'] = index;
                          }
                        } else if (groupName.toLowerCase() == 'milk' &&
                            product.modifiers!.milk != null) {
                          final index = product.modifiers!.milk!.options
                              .indexWhere((opt) => opt.label == optionLabel);
                          if (index >= 0) {
                            modifiers['milk'] = index;
                          }
                        } else if (groupName.toLowerCase() == 'extras' &&
                            product.modifiers!.extras != null) {
                          final extras =
                              modifiers['extras'] as List<int>? ?? [];
                          final index = product.modifiers!.extras!.options
                              .indexWhere((opt) => opt.label == optionLabel);
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
      // Если не первый визит - покажем диалог
      if (!_isFirstVisit) {
        _showLocationDialog = true;
      }
    }

    // Также читаем telegram_user_id из hash (бот передаёт его)
    final telegramIdFromHash = TelegramService.instance
        .getTelegramUserIdFromHash();
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
        firstName: firstName ?? 'User', // Default чтобы не было NOT NULL ошибки
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
        if (_savedLocationId == null) {
          final userPreferredLocationId =
              user['preferredLocationId'] as String?;
          if (userPreferredLocationId != null &&
              userPreferredLocationId.isNotEmpty) {
            print(
              '✅ Using preferredLocationId from DB: $userPreferredLocationId',
            );
            _savedLocationId = userPreferredLocationId;
            // Если не первый визит - покажем диалог
            if (!_isFirstVisit) {
              _showLocationDialog = true;
            }
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
    print('🚀 VERSION: $DEPLOY_VERSION - WITH VISIT COUNTER!');
    print('🚀 DEPLOY TIMESTAMP: $DEPLOY_TIMESTAMP');

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
            targetLocation = locations.firstWhere(
              (loc) => loc.id == _savedLocationId,
            );
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

        // ГАРАНТИРОВАННО выбираем локацию
        _autoSelectedLocation = targetLocation;
        _savedLocationId = targetLocation.id;

        // ⭐ Если не первый визит - ВСЕГДА показываем диалог подтверждения
        if (!_isFirstVisit) {
          _showLocationDialog = true;
          print('✅ Will show location confirmation dialog (NOT first visit)');
        }

        _locationSelected = true;
        await locationProvider.selectLocation(targetLocation);
        print('🎉 ==========================================');
        print('🎉 LOCATION SELECTED: ${targetLocation.name}');
        print(
          '🎉 _isFirstVisit: $_isFirstVisit, _showLocationDialog: $_showLocationDialog',
        );
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

  /// Показывает диалог подтверждения локации при повторном входе
  void _showLocationConfirmDialog(BuildContext context) {
    print('🎯 _showLocationConfirmDialog called');
    final locationProvider = context.read<LocationProvider>();
    final location = locationProvider.selectedLocation ?? _autoSelectedLocation;
    final locationName = location?.name ?? 'кофейне';
    print('🎯 Location name: $locationName');

    showDialog(
      context: context,
      barrierDismissible: true, // Разрешаем закрытие кликом на фон
      barrierColor: Colors.transparent, // Полностью прозрачный фон
      builder: (context) => Dialog(
        alignment: Alignment.topLeft, // Позиционирование в верхнем левом углу
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.only(
          left: 16,
          top: 60,
        ), // Отступы от краев
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Размытие фона
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 280,
            ), // Ограничение ширины для компактности
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6), // Темный полупрозрачный фон
              borderRadius: BorderRadius.circular(20), // Немного меньше радиус
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(16), // Уменьшенный padding
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Иконка локации и название
                Row(
                  children: [
                    Container(
                      width: 32, // Уменьшенный размер иконки
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF2196F3,
                        ), // Синий цвет как на картинке
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.rocket_launch, // Иконка ракеты/самолетика
                        color: Colors.white,
                        size: 20, // Уменьшенный размер иконки
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locationName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14, // Уменьшенный размер шрифта
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'выбрано',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11, // Уменьшенный размер шрифта
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Уменьшенный отступ
                // Приветствие и вопрос
                const Text(
                  'Привет!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20, // Уменьшенный размер шрифта
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Закажешь здесь?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16, // Уменьшенный размер шрифта
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16), // Уменьшенный отступ
                // Ссылка "Другая кофейня"
                GestureDetector(
                  onTap: () {
                    print('❌ User wants to choose different location');
                    // НЕ устанавливаем _showLocationDialog = false, чтобы при возврате диалог показался снова
                    _autoSelectedLocation = null;
                    _savedLocationId = null;
                    Navigator.of(context).pop(); // Закрываем диалог
                    Navigator.of(context).push(
                      // Используем push вместо pushReplacement, чтобы MainScreen остался в стеке
                      MaterialPageRoute(
                        builder: (context) => const LocationSelectScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Другая кофейня',
                    style: TextStyle(
                      color: const Color(0xFF64B5F6), // Светло-синий цвет
                      fontSize: 13, // Уменьшенный размер шрифта
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Уменьшенный отступ
                // Большая кнопка с названием локации
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      print('✅ User confirmed location: $locationName');
                      _showLocationDialog = false;
                      Navigator.of(context).pop();
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3), // Синий цвет
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ), // Уменьшенный padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      locationName,
                      style: const TextStyle(
                        fontSize: 14, // Уменьшенный размер шрифта
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      // Обработка закрытия диалога при клике на фон
      print('📱 Dialog dismissed (by tapping outside or button)');
      if (_showLocationDialog) {
        _showLocationDialog = false;
        setState(() {});
      }
    });
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

    // ⭐ ПРИОРИТЕТ 1: Если НЕ первый визит и нужно показать диалог → Показываем диалог подтверждения!
    print(
      '🔍 Build check: _isFirstVisit=$_isFirstVisit, _showLocationDialog=$_showLocationDialog, _savedLocationId=$_savedLocationId',
    );
    if (!_isFirstVisit && _showLocationDialog) {
      print('✅ Showing location confirmation dialog!');
      // Восстанавливаем локацию если она ещё не установлена
      if (locationProvider.selectedLocation == null &&
          locationProvider.locations.isNotEmpty) {
        try {
          locationProvider.restoreLastLocation(_savedLocationId!);
          print('✅ Location restored: $_savedLocationId');
        } catch (e) {
          print('⚠️ Could not restore location: $e');
        }
      }

      // Показываем MainScreen первым
      const mainScreen = MainScreen();

      // Показываем диалог поверх MainScreen через postFrameCallback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('📱 Showing dialog via postFrameCallback');
        _showLocationConfirmDialog(context);
      });

      // Возвращаем MainScreen вместо Scaffold с загрузкой
      return mainScreen;
    }

    // ⭐ ПРИОРИТЕТ 2: Если НЕ первый визит и диалог закрыт → идём в MainScreen
    // НО только если инициализация завершена и локация выбрана
    if (!_isFirstVisit &&
        !_showLocationDialog &&
        _initialized &&
        _locationSelected) {
      print('✅ ==========================================');
      print('✅ NOT FIRST VISIT - going to MainScreen');
      print('✅ ==========================================');
      return const MainScreen();
    }

    // ⭐ ПРИОРИТЕТ 5: Первый визит - проверяем есть ли автоматически выбранная локация
    print('🔍 FIRST VISIT - checking location');
    final hasLocationFromProvider = locationProvider.selectedLocation != null;
    final hasLocationFromState = _autoSelectedLocation != null;
    final hasLocationsAvailable = locationProvider.locations.isNotEmpty;
    final hasLocation = hasLocationFromProvider || hasLocationFromState;

    print(
      '🔍 Build check: _isFirstVisit=$_isFirstVisit, _locationSelected=$_locationSelected, _autoSelectedLocation=${_autoSelectedLocation?.name ?? "null"}, provider.selectedLocation=${locationProvider.selectedLocation?.name ?? "null"}, hasLocation=$hasLocation, hasLocationsAvailable=$hasLocationsAvailable',
    );

    if (hasLocation) {
      // Убеждаемся что локация установлена в провайдер
      if (locationProvider.selectedLocation == null &&
          _autoSelectedLocation != null) {
        print(
          '⚠️ Location not in provider, restoring from _autoSelectedLocation...',
        );
        try {
          locationProvider.restoreLastLocation(_autoSelectedLocation!.id);
          print(
            '✅ Location restored in provider: ${_autoSelectedLocation!.name}',
          );
        } catch (e) {
          print('❌ Failed to restore location: $e');
          // Если не удалось восстановить, устанавливаем напрямую
          locationProvider.selectLocation(_autoSelectedLocation!);
        }
      }

      final locationName =
          locationProvider.selectedLocation?.name ??
          _autoSelectedLocation?.name ??
          'Unknown';
      final locationId =
          locationProvider.selectedLocation?.id ??
          _autoSelectedLocation?.id ??
          'unknown';
      print(
        '🎯 → Going to MainScreen with location: $locationName (ID: $locationId) (FIRST VISIT)',
      );
      print('✅ SUCCESS: App will show MainScreen instead of PermissionsScreen');
      return const MainScreen();
    }

    // ⭐ ФИНАЛЬНЫЙ FALLBACK для первого визита:
    // Если есть локации в provider - всё равно идём в MainScreen!
    // Это гарантирует что пользователь НЕ увидит PermissionsScreen если есть хоть одна локация
    if (hasLocationsAvailable) {
      print(
        '🆘 FINAL FALLBACK (FIRST VISIT): No selected location, but locations exist! Going to MainScreen anyway',
      );
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

    print(
      '📍 → Going to PermissionsScreen (FIRST VISIT + no locations available at all!)',
    );
    print(
      '⚠️ WARNING: No locations in database - user will see permissions screen',
    );
    return const PermissionsScreen();
  }
}
