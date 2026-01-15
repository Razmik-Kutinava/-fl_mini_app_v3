import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://wntvxdgxzenehfzvorae.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndudHZ4ZGd4emVuZWhmenZvcmFlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxMTQxMDgsImV4cCI6MjA4MDY5MDEwOH0.2CGjqmX-5wwgMmBKLrft9BxlcDG0bR4XDy0pT8hYNU0';

  static SupabaseClient get client => Supabase.instance.client;

  static String _generateUuid() {
    final random = Random();
    const hexDigits = '0123456789abcdef';
    final uuid = List.generate(36, (i) {
      if (i == 8 || i == 13 || i == 18 || i == 23) return '-';
      if (i == 14) return '4';
      if (i == 19) return hexDigits[(random.nextInt(4) + 8)];
      return hexDigits[random.nextInt(16)];
    }).join();
    return uuid;
  }

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  // ==================== LOCATIONS ====================

  static Future<List<Map<String, dynamic>>> getLocations() async {
    try {
      final response = await client
          .from('Location')
          .select()
          .eq('status', 'active')
          .eq('isAcceptingOrders', true);
      print('Supabase Locations response: $response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Supabase Locations error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getLocationById(String id) async {
    final response = await client
        .from('Location')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response;
  }

  // ==================== CATEGORIES ====================

  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await client
          .from('Category')
          .select()
          .eq('isActive', true)
          .order('sortOrder', ascending: true);
      print('Supabase Categories response: $response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Supabase Categories error: $e');
      return [];
    }
  }

  // ==================== PRODUCTS ====================

  static Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final response = await client
          .from('Product')
          .select()
          .eq('status', 'active');
      print('Supabase Products response: $response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Supabase Products error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getProductsByCategory(
    String categoryId,
  ) async {
    try {
      final response = await client
          .from('Product')
          .select()
          .eq('categoryId', categoryId)
          .eq('status', 'active');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Supabase Products by category error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getProductById(String id) async {
    final response = await client
        .from('Product')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response;
  }

  // ==================== MODIFIERS ====================

  static Future<List<Map<String, dynamic>>> getModifierGroups(
    String productId,
  ) async {
    try {
      print('🔍 Getting modifier groups for product: $productId');
      print('🔍 Product ID type: ${productId.runtimeType}');
      print('🔍 Product ID value: "$productId"');

      // Получаем связи продукт-модификатор
      print('📋 Querying ProductModifierGroup table...');
      print('📋 Product ID for query: "$productId"');

      // Пробуем разные варианты запроса
      List<dynamic> links = [];
      try {
        links =
            await client
                    .from('ProductModifierGroup')
                    .select('modifierGroupId')
                    .eq('productId', productId)
                as List<dynamic>;
        print('✅ Query successful');
      } catch (e) {
        print('❌ Query failed: $e');
        // Пробуем без фильтра
        try {
          final allLinks =
              await client.from('ProductModifierGroup').select('*')
                  as List<dynamic>;
          print('📋 All links without filter: $allLinks');
          // Фильтруем вручную
          links = allLinks
              .where((link) => link['productId'] == productId)
              .toList();
          print('📋 Filtered links: $links');
        } catch (e2) {
          print('❌ Fallback query also failed: $e2');
        }
      }

      print('📋 ProductModifierGroup links: $links');
      print('📋 Links type: ${links.runtimeType}');
      print('📋 Links count: ${links.length}');

      if (links.isEmpty) {
        print('⚠️ No ProductModifierGroup links found for product: $productId');
        print(
          '🔄 FALLBACK: Loading ALL modifier groups (if ProductModifierGroup is empty)',
        );

        // Проверяем, есть ли вообще записи в ProductModifierGroup
        try {
          final allLinks =
              await client.from('ProductModifierGroup').select('*').limit(1)
                  as List<dynamic>;

          if (allLinks.isEmpty) {
            print('📋 ProductModifierGroup table is completely empty');
            print('🔄 Loading ALL modifier groups as fallback...');

            // Загружаем все группы модификаторов
            final allGroups =
                await client.from('ModifierGroup').select() as List<dynamic>;

            print(
              '✅ Loaded ${allGroups.length} modifier groups (fallback mode)',
            );
            print(
              '⚠️ WARNING: Using fallback mode - all groups will be shown for all products',
            );

            return List<Map<String, dynamic>>.from(allGroups);
          } else {
            print(
              '📋 ProductModifierGroup has ${allLinks.length} records, but none match productId',
            );
          }
        } catch (e) {
          print('❌ Error checking ProductModifierGroup: $e');
          // Если даже проверка не работает, пробуем загрузить все группы
          try {
            print('🔄 Last resort: Loading ALL modifier groups...');
            final allGroups =
                await client.from('ModifierGroup').select() as List<dynamic>;
            print('✅ Loaded ${allGroups.length} modifier groups (last resort)');
            return List<Map<String, dynamic>>.from(allGroups);
          } catch (e2) {
            print('❌ Failed to load modifier groups: $e2');
          }
        }

        return [];
      }

      final groupIds = links.map((e) => e['modifierGroupId']).toList();

      print('📋 Group IDs to fetch: $groupIds');
      print('📋 Group IDs count: ${groupIds.length}');

      if (groupIds.isEmpty) {
        print('⚠️ No modifier group IDs found for product: $productId');
        return [];
      }

      print('📋 Querying ModifierGroup table with IDs: $groupIds');
      final response = await client
          .from('ModifierGroup')
          .select()
          .inFilter('id', groupIds);

      print('✅ ModifierGroups response: $response');
      print('✅ ModifierGroups type: ${response.runtimeType}');
      print('✅ ModifierGroups count: ${(response as List).length}');

      for (var group in response) {
        print(
          '  - Group: ${group['name']}, type: ${group['type']}, required: ${group['required']}',
        );
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Supabase ModifierGroups error: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e is Exception) {
        print('❌ Error message: ${e.toString()}');
      }
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getModifierOptions(
    String groupId,
  ) async {
    try {
      print('🔍 Getting modifier options for group: $groupId');
      final response = await client
          .from('ModifierOption')
          .select()
          .eq('groupId', groupId)
          .eq('isActive', true)
          .order('sortOrder', ascending: true);

      print(
        '✅ ModifierOptions for group $groupId: ${(response as List).length} options',
      );
      for (var opt in response) {
        print(
          '  - Option: ${opt['name']}, price: ${opt['price']}, emoji: ${opt['emoji']}',
        );
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Supabase ModifierOptions error: $e');
      return [];
    }
  }

  // ==================== ORDERS ====================

  static Future<Map<String, dynamic>> createOrder({
    required String locationId,
    required List<Map<String, dynamic>> items,
    required double total,
    String? promocodeId,
    double? discount,
    String? telegramUserId,
    String? userId,
    String? customerName,
    String? customerPhone,
    String? comment,
  }) async {
    try {
      print('=== CREATING ORDER ===');
      print('locationId: $locationId');
      print('items: $items');
      print('total: $total');
      print('telegramUserId: $telegramUserId');
      print('userId: $userId');
      print('customerName: $customerName');

      // Генерируем UUID для id
      final orderId = _generateUuid();
      final now = DateTime.now().toUtc().toIso8601String();

      // Все обязательные поля согласно схеме Order
      final orderData = {
        'id': orderId,
        'locationId': locationId,
        'userId': userId,
        'status': 'paid',
        'subtotal': total + (discount ?? 0),
        'discountAmount': discount ?? 0,
        'totalAmount': total,
        'promocodeId': promocodeId,
        'paymentStatus': 'pending',
        'customerName': customerName,
        'customerPhone': customerPhone,
        'comment': comment,
        'createdAt': now,
        'updatedAt': now,
      };

      print('Order data to insert: $orderData');

      // Создаём заказ
      final orderResponse = await client
          .from('Order')
          .insert(orderData)
          .select()
          .single();

      print('Order created: $orderResponse');

      // Добавляем позиции заказа
      for (var item in items) {
        final itemData = {
          'id': _generateUuid(),
          'orderId': orderId,
          'productId': item['productId'],
          'productName': item['productName'] ?? '',
          'quantity': item['quantity'] ?? 1,
          'unitPrice': item['price'] ?? 0,
          'basePrice': item['price'] ?? 0,
          'modifiersPrice': 0,
          'totalPrice': item['total'] ?? item['price'] ?? 0,
          'createdAt': now,
        };
        print('Inserting OrderItem: $itemData');
        await client.from('OrderItem').insert(itemData);
      }

      // Добавляем запись в историю статусов
      await client.from('OrderStatusHistory').insert({
        'id': _generateUuid(),
        'orderId': orderId,
        'newStatus': 'paid',
        'createdAt': now,
      });

      print('Order completed successfully!');
      return orderResponse;
    } catch (e, stack) {
      print('=== ORDER ERROR ===');
      print('Error: $e');
      print('Stack: $stack');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getOrders({
    String? visitorId,
  }) async {
    try {
      final response = await client
          .from('Order')
          .select('*, OrderItem(*)')
          .order('createdAt', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Supabase Orders error: $e');
      return [];
    }
  }

  // ==================== PROMOCODES ====================

  static Future<Map<String, dynamic>?> validatePromocode(String code) async {
    try {
      final response = await client
          .from('Promocode')
          .select()
          .eq('code', code.toUpperCase())
          .eq('isActive', true)
          .maybeSingle();

      if (response == null) return null;

      // Проверяем даты действия
      final now = DateTime.now();
      if (response['startsAt'] != null) {
        final startDate = DateTime.parse(response['startsAt']);
        if (now.isBefore(startDate)) return null;
      }
      if (response['endsAt'] != null) {
        final endDate = DateTime.parse(response['endsAt']);
        if (now.isAfter(endDate)) return null;
      }

      // Проверяем лимит использований
      if (response['usageLimit'] != null && response['usedCount'] != null) {
        if (response['usedCount'] >= response['usageLimit']) return null;
      }

      return response;
    } catch (e) {
      print('Supabase Promocode error: $e');
      return null;
    }
  }

  // ==================== USER ====================

  static Future<Map<String, dynamic>?> getOrCreateUser({
    required String telegramId,
    String? firstName,
    String? lastName,
    String? username,
  }) async {
    try {
      print(
        '🔍 [getOrCreateUser] Looking for user with telegramId: $telegramId',
      );

      // ⭐ КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Сначала ищем по telegramId (INT) - как делает БОТ!
      // Бот сохраняет telegramId как INT, поэтому нужно искать по INT
      final telegramIdInt = int.tryParse(telegramId);
      Map<String, dynamic>? existing;

      if (telegramIdInt != null) {
        print(
          '🔍 [getOrCreateUser] Searching by telegramId (int): $telegramIdInt',
        );
        existing = await client
            .from('User')
            .select()
            .eq('telegramId', telegramIdInt)
            .maybeSingle();

        if (existing != null) {
          print('✅ [getOrCreateUser] User found by telegramId (int)!');
          print('✅ [getOrCreateUser] User ID: ${existing['id']}');
          print(
            '✅ [getOrCreateUser] preferredLocationId: ${existing['preferredLocationId']}',
          );
        }
      }

      // Fallback: ищем по telegram_user_id (string) если не нашли по int
      if (existing == null) {
        print(
          '🔍 [getOrCreateUser] Searching by telegram_user_id (string): $telegramId',
        );
        existing = await client
            .from('User')
            .select()
            .eq('telegram_user_id', telegramId)
            .maybeSingle();

        if (existing != null) {
          print('✅ [getOrCreateUser] User found by telegram_user_id (string)!');
        }
      }

      final now = DateTime.now().toIso8601String();

      if (existing != null) {
        print('✅ [getOrCreateUser] User found, updating...');
        // Обновляем данные пользователя по id (не по telegram полям)
        final updated = await client
            .from('User')
            .update({
              'username': username,
              'first_name': firstName,
              'telegramFirstName': firstName,
              'telegramUsername': username,
              'lastSeenAt': now,
              'updatedAt': now,
            })
            .eq('id', existing['id'])
            .select()
            .single();

        print('✅ [getOrCreateUser] User updated: ${updated['id']}');
        print(
          '✅ [getOrCreateUser] preferredLocationId: ${updated['preferredLocationId']}',
        );
        return updated;
      } else {
        print('🆕 [getOrCreateUser] Creating new user...');
        print('🔍 [getOrCreateUser] telegram_user_id (string): $telegramId');
        print('🔍 [getOrCreateUser] telegramId (int): $telegramIdInt');

        // first_name обязательное поле в БД!
        final nameToUse = firstName ?? username ?? 'User';

        final newUser = await client
            .from('User')
            .insert({
              'id': _generateUuid(),
              'telegram_user_id': telegramId,
              'telegramId': telegramIdInt,
              'username': username ?? 'user_$telegramId',
              'first_name': nameToUse, // NOT NULL в БД!
              'telegramFirstName': nameToUse,
              'telegramUsername': username,
              'status': 'active',
              'acceptsMarketing': false,
              'createdAt': now,
              'updatedAt': now,
              'lastSeenAt': now,
            })
            .select()
            .single();

        print('✅ [getOrCreateUser] New user created: ${newUser['id']}');
        return newUser;
      }
    } catch (e) {
      print('❌ [getOrCreateUser] Error: $e');
      return null;
    }
  }

  static Future<void> logUserActivity({
    required String userId,
    required String activityType,
    Map<String, dynamic>? activityData,
  }) async {
    try {
      await client.from('UserActivity').insert({
        'id': _generateUuid(),
        'userId': userId,
        'activityType': activityType,
        'activityData': activityData,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Activity logged: $activityType');
    } catch (e) {
      print('❌ Log activity error: $e');
    }
  }

  /// Получает preferredLocationId пользователя по telegram_id
  /// Это ключевой метод для автоматического выбора локации при открытии из бота
  static Future<String?> getUserPreferredLocationId(String telegramId) async {
    try {
      print('🔍 [getUserPreferredLocationId] Starting lookup for: $telegramId');
      print('🔍 [getUserPreferredLocationId] Type: ${telegramId.runtimeType}');

      // Сначала ищем по telegramId (BigInt в Prisma схеме)
      final telegramIdInt = int.tryParse(telegramId);
      print('🔍 [getUserPreferredLocationId] Parsed as int: $telegramIdInt');

      var response;
      if (telegramIdInt != null) {
        print(
          '🔍 [getUserPreferredLocationId] Searching by telegramId (int)...',
        );
        response = await client
            .from('User')
            .select('preferredLocationId, telegramId, telegram_user_id')
            .eq('telegramId', telegramIdInt)
            .maybeSingle();

        print(
          '🔍 [getUserPreferredLocationId] Response by telegramId: $response',
        );

        if (response != null && response['preferredLocationId'] != null) {
          final locationId = response['preferredLocationId'] as String;
          print(
            '✅ [getUserPreferredLocationId] Found by telegramId: $locationId',
          );
          return locationId;
        }
      }

      // Если не нашли, пробуем по telegram_user_id (string)
      print(
        '🔍 [getUserPreferredLocationId] Searching by telegram_user_id (string)...',
      );
      response = await client
          .from('User')
          .select('preferredLocationId, telegramId, telegram_user_id')
          .eq('telegram_user_id', telegramId)
          .maybeSingle();

      print(
        '🔍 [getUserPreferredLocationId] Response by telegram_user_id: $response',
      );

      if (response != null && response['preferredLocationId'] != null) {
        final locationId = response['preferredLocationId'] as String;
        print(
          '✅ [getUserPreferredLocationId] Found by telegram_user_id: $locationId',
        );
        return locationId;
      }

      print(
        '⚠️ [getUserPreferredLocationId] No preferredLocationId found for user',
      );
      return null;
    } catch (e, stackTrace) {
      print('❌ [getUserPreferredLocationId] Error: $e');
      print('❌ [getUserPreferredLocationId] Stack: $stackTrace');
      return null;
    }
  }

  /// Обновляет preferredLocationId пользователя в БД
  /// Это ключевой метод для синхронизации выбранной локации с ботом
  static Future<bool> updateUserPreferredLocation({
    required String userId,
    required String locationId,
  }) async {
    try {
      print(
        '🔄 [updateUserPreferredLocation] Updating preferredLocationId for user: $userId',
      );
      print('🔄 [updateUserPreferredLocation] New locationId: $locationId');

      await client
          .from('User')
          .update({
            'preferredLocationId': locationId,
            'updatedAt': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      print(
        '✅ [updateUserPreferredLocation] Successfully updated preferredLocationId',
      );
      return true;
    } catch (e, stackTrace) {
      print('❌ [updateUserPreferredLocation] Error: $e');
      print('❌ [updateUserPreferredLocation] Stack: $stackTrace');
      return false;
    }
  }

  /// Получает последнюю локацию из заказов пользователя
  /// СИНХРОНИЗИРОВАНО С БОТОМ: ищет оплаченные заказы сначала, потом любой последний
  static Future<String?> getUserLastOrderLocationId(String visitorId) async {
    try {
      print(
        '🔍 [getUserLastOrderLocationId] Getting last order location for user: $visitorId',
      );

      // Сначала находим UUID пользователя
      var userResponse = await client
          .from('User')
          .select('id')
          .eq('telegramId', int.tryParse(visitorId) ?? 0)
          .maybeSingle();

      if (userResponse == null) {
        print(
          '🔍 [getUserLastOrderLocationId] User not found by telegramId, trying telegram_user_id...',
        );
        userResponse = await client
            .from('User')
            .select('id')
            .eq('telegram_user_id', visitorId)
            .maybeSingle();
      }

      if (userResponse == null) {
        print('⚠️ [getUserLastOrderLocationId] User not found');
        return null;
      }

      final userId = userResponse['id'] as String;
      print('✅ [getUserLastOrderLocationId] Found user UUID: $userId');

      // СИНХРОНИЗАЦИЯ С БОТОМ: Сначала ищем оплаченные заказы (paymentStatus)
      // Бот использует: ["succeeded", "paid", "PAID", "SUCCEEDED"]
      final paymentStatuses = ["succeeded", "paid", "PAID", "SUCCEEDED"];
      String? locationId;

      for (final status in paymentStatuses) {
        try {
          print(
            '🔍 [getUserLastOrderLocationId] Searching order with paymentStatus=$status...',
          );
          final orderResponse = await client
              .from('Order')
              .select('locationId, createdAt')
              .eq('userId', userId)
              .eq('paymentStatus', status)
              .order('createdAt', ascending: false)
              .limit(1)
              .maybeSingle();

          if (orderResponse != null && orderResponse['locationId'] != null) {
            locationId = orderResponse['locationId'] as String;
            print(
              '✅ [getUserLastOrderLocationId] Found paid order with paymentStatus=$status, locationId: $locationId',
            );
            return locationId;
          }
        } catch (e) {
          print(
            '⚠️ [getUserLastOrderLocationId] Error searching by paymentStatus=$status: $e',
          );
        }
      }

      // Если не нашли по paymentStatus, пробуем по status
      // Бот использует: ["paid", "completed", "ready", "PAID", "COMPLETED", "READY"]
      final orderStatuses = [
        "paid",
        "completed",
        "ready",
        "PAID",
        "COMPLETED",
        "READY",
      ];
      for (final status in orderStatuses) {
        try {
          print(
            '🔍 [getUserLastOrderLocationId] Searching order with status=$status...',
          );
          final orderResponse = await client
              .from('Order')
              .select('locationId, createdAt')
              .eq('userId', userId)
              .eq('status', status)
              .order('createdAt', ascending: false)
              .limit(1)
              .maybeSingle();

          if (orderResponse != null && orderResponse['locationId'] != null) {
            locationId = orderResponse['locationId'] as String;
            print(
              '✅ [getUserLastOrderLocationId] Found order with status=$status, locationId: $locationId',
            );
            return locationId;
          }
        } catch (e) {
          print(
            '⚠️ [getUserLastOrderLocationId] Error searching by status=$status: $e',
          );
        }
      }

      // Если так и не нашли оплаченные - берем просто последний заказ (как в боте)
      print(
        '🔍 [getUserLastOrderLocationId] No paid orders found, searching any last order...',
      );
      try {
        final orderResponse = await client
            .from('Order')
            .select('locationId, createdAt')
            .eq('userId', userId)
            .order('createdAt', ascending: false)
            .limit(1)
            .maybeSingle();

        if (orderResponse != null && orderResponse['locationId'] != null) {
          locationId = orderResponse['locationId'] as String;
          print(
            '✅ [getUserLastOrderLocationId] Found last order (any status), locationId: $locationId',
          );
          return locationId;
        }
      } catch (e) {
        print('⚠️ [getUserLastOrderLocationId] Error searching last order: $e');
      }

      print('⚠️ [getUserLastOrderLocationId] No orders found for user');
      return null;
    } catch (e, stackTrace) {
      print('❌ [getUserLastOrderLocationId] Error: $e');
      print('❌ [getUserLastOrderLocationId] Stack: $stackTrace');
      return null;
    }
  }

  // ==================== LAST DRINKS ====================

  /// Получает последние напитки пользователя из заказов
  static Future<List<Map<String, dynamic>>> getUserLastDrinks(String userId, {int limit = 2}) async {
    try {
      print('🔍 [getUserLastDrinks] Getting last drinks for user: $userId');
      
      // Получаем последние заказы пользователя
      final orders = await client
          .from('Order')
          .select('id, createdAt, OrderItem(productId, productName)')
          .eq('userId', userId)
          .inFilter('paymentStatus', ['succeeded', 'paid', 'PAID', 'SUCCEEDED'])
          .order('createdAt', ascending: false)
          .limit(10);
      
      print('🔍 [getUserLastDrinks] Found ${orders.length} orders');
      
      // Собираем уникальные напитки (по productId) в порядке последнего заказа
      final seenProductIds = <String>{};
      final lastDrinks = <Map<String, dynamic>>[];
      
      for (final order in orders) {
        final orderItems = order['OrderItem'] as List?;
        if (orderItems == null) continue;
        
        for (final item in orderItems) {
          final productId = item['productId'] as String?;
          if (productId == null || seenProductIds.contains(productId)) continue;
          
          seenProductIds.add(productId);
          lastDrinks.add({
            'productId': productId,
            'productName': item['productName'] ?? '',
            'orderDate': order['createdAt'],
          });
          
          if (lastDrinks.length >= limit) break;
        }
        
        if (lastDrinks.length >= limit) break;
      }
      
      print('✅ [getUserLastDrinks] Found ${lastDrinks.length} unique drinks');
      return lastDrinks;
    } catch (e, stackTrace) {
      print('❌ [getUserLastDrinks] Error: $e');
      print('❌ [getUserLastDrinks] Stack: $stackTrace');
      return [];
    }
  }

  // ==================== REPEAT ORDER ====================

  /// Получает товары заказа для повторного заказа
  static Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    try {
      print('🔄 [getOrderItems] Loading order items for order: $orderId');
      
      // Получаем OrderItem для этого заказа
      final itemsResponse = await client
          .from('OrderItem')
          .select('*, product:Product(*)')
          .eq('orderId', orderId);
      
      final items = List<Map<String, dynamic>>.from(itemsResponse);
      print('🔄 [getOrderItems] Found ${items.length} items');
      
      // Для каждого товара получаем модификаторы
      for (var item in items) {
        final itemId = item['id'] as String;
        
        // Получаем модификаторы
        final modifiersResponse = await client
            .from('OrderItemModifier')
            .select('*, modifierOption:ModifierOption(*)')
            .eq('orderItemId', itemId);
        
        final modifiers = List<Map<String, dynamic>>.from(modifiersResponse);
        item['modifiers'] = modifiers;
        
        print('🔄 [getOrderItems] Item ${item['productName']}: ${modifiers.length} modifiers');
      }
      
      return items;
    } catch (e, stackTrace) {
      print('❌ [getOrderItems] Error: $e');
      print('❌ [getOrderItems] Stack: $stackTrace');
      return [];
    }
  }
}
