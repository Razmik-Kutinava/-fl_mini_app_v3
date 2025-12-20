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
      // Получаем связи продукт-модификатор
      final links = await client
          .from('ProductModifierGroup')
          .select('modifierGroupId')
          .eq('productId', productId);

      if (links.isEmpty) return [];

      final groupIds = (links as List)
          .map((e) => e['modifierGroupId'])
          .toList();

      if (groupIds.isEmpty) {
        print('No modifier group IDs found for product: $productId');
        return [];
      }

      final response = await client
          .from('ModifierGroup')
          .select()
          .inFilter('id', groupIds);

      print('ModifierGroups response: $response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Supabase ModifierGroups error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getModifierOptions(
    String groupId,
  ) async {
    try {
      final response = await client
          .from('ModifierOption')
          .select()
          .eq('groupId', groupId)
          .eq('isActive', true)
          .order('sortOrder', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Supabase ModifierOptions error: $e');
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
    String? customerName,
    String? customerPhone,
    String? comment,
  }) async {
    try {
      print('=== CREATING ORDER ===');
      print('locationId: $locationId');
      print('items: $items');
      print('total: $total');

      // Генерируем UUID для id
      final orderId = _generateUuid();
      final now = DateTime.now().toUtc().toIso8601String();

      // Все обязательные поля согласно схеме Order
      final orderData = {
        'id': orderId,
        'locationId': locationId,
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
}
