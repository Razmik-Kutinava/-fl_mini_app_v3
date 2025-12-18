import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://wntvxdgxzenehfzvorae.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndudHZ4ZGd4emVuZWhmenZvcmFlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxMTQxMDgsImV4cCI6MjA4MDY5MDEwOH0.2CGjqmX-5wwgMmBKLrft9BxlcDG0bR4XDy0pT8hYNU0';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // ==================== LOCATIONS ====================
  
  static Future<List<Map<String, dynamic>>> getLocations() async {
    try {
      final response = await client
          .from('Location')
          .select();
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
          .select();
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
          .select();
      print('Supabase Products response: $response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Supabase Products error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getProductsByCategory(String categoryId) async {
    try {
      final response = await client
          .from('Product')
          .select()
          .eq('categoryId', categoryId);
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
  
  static Future<List<Map<String, dynamic>>> getModifierGroups(String productId) async {
    // Получаем связи продукт-модификатор
    final links = await client
        .from('ProductModifierGroup')
        .select('modifierGroupId')
        .eq('productId', productId);
    
    if (links.isEmpty) return [];
    
    final groupIds = (links as List).map((e) => e['modifierGroupId']).toList();
    
    final response = await client
        .from('ModifierGroup')
        .select()
        .inFilter('id', groupIds);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getModifierOptions(String groupId) async {
    final response = await client
        .from('ModifierOption')
        .select()
        .eq('modifierGroupId', groupId)
        .order('sortOrder', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // ==================== ORDERS ====================
  
  static Future<Map<String, dynamic>> createOrder({
    required String locationId,
    required List<Map<String, dynamic>> items,
    required double total,
    String? promocodeId,
    double? discount,
    String? telegramUserId,
  }) async {
    try {
      print('=== CREATING ORDER ===');
      print('locationId: $locationId');
      print('items: $items');
      print('total: $total');
      
      // Поля для Order согласно схеме БД
      final orderData = {
        'locationId': locationId,
        'status': 'PENDING',
        'subtotal': total,
        'discountAmount': discount ?? 0,
        'promocodeId': promocodeId,
      };
      
      print('Order data to insert: $orderData');
      
      // Создаём заказ
      final orderResponse = await client
          .from('Order')
          .insert(orderData)
          .select()
          .single();

      print('Order created: $orderResponse');
      
      final orderId = orderResponse['id'];

      // Добавляем позиции заказа
      for (var item in items) {
        final itemData = {
          'orderId': orderId,
          'productId': item['productId'],
          'quantity': item['quantity'],
          'price': item['price'],
          'total': item['total'],
        };
        print('Inserting OrderItem: $itemData');
        await client.from('OrderItem').insert(itemData);
      }

      // Добавляем запись в историю статусов
      await client.from('OrderStatusHistory').insert({
        'orderId': orderId,
        'status': 'PENDING',
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

  static Future<List<Map<String, dynamic>>> getOrders({String? telegramUserId}) async {
    final response = telegramUserId != null
        ? await client
            .from('Order')
            .select('*, OrderItem(*)')
            .eq('telegramUserId', telegramUserId)
            .order('createdAt', ascending: false)
        : await client
            .from('Order')
            .select('*, OrderItem(*)')
            .order('createdAt', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ==================== PROMOCODES ====================
  
  static Future<Map<String, dynamic>?> validatePromocode(String code) async {
    final response = await client
        .from('Promocode')
        .select()
        .eq('code', code.toUpperCase())
        .eq('isActive', true)
        .maybeSingle();
    
    if (response == null) return null;
    
    // Проверяем даты действия
    final now = DateTime.now();
    if (response['startDate'] != null) {
      final startDate = DateTime.parse(response['startDate']);
      if (now.isBefore(startDate)) return null;
    }
    if (response['endDate'] != null) {
      final endDate = DateTime.parse(response['endDate']);
      if (now.isAfter(endDate)) return null;
    }
    
    // Проверяем лимит использований
    if (response['maxUsages'] != null && response['usageCount'] != null) {
      if (response['usageCount'] >= response['maxUsages']) return null;
    }
    
    return response;
  }

  static Future<void> usePromocode(String promocodeId, String orderId) async {
    // Увеличиваем счётчик использований
    await client.rpc('increment_promocode_usage', params: {'promocode_id': promocodeId});
    
    // Записываем использование
    await client.from('PromocodeUsage').insert({
      'promocodeId': promocodeId,
      'orderId': orderId,
    });
  }
}

