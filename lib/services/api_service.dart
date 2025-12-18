import '../models/location.dart';
import '../models/product.dart';
import '../models/category.dart';
import 'supabase_service.dart';

class ApiService {
  // ==================== LOCATIONS ====================
  
  Future<List<Location>> getLocations() async {
    try {
      final data = await SupabaseService.getLocations();
      return data.map((json) => Location(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        address: json['address'] ?? json['city'] ?? '',
        lat: _parseDouble(json['latitude']),
        lng: _parseDouble(json['longitude']),
        rating: 4.5, // No rating in schema
        workingHours: _formatWorkingHours(json),
        isOpen: json['isAcceptingOrders'] ?? true,
      )).toList();
    } catch (e) {
      print('Error loading locations: $e');
      return _mockLocations;
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String _formatWorkingHours(Map<String, dynamic> json) {
    // workingHours is JSON object in schema
    final workingHours = json['workingHours'];
    if (workingHours is Map && workingHours.isNotEmpty) {
      return '08:00-22:00'; // Parse from JSON if needed
    }
    return '08:00-22:00';
  }

  // ==================== MENU ====================
  
  Future<Map<String, dynamic>> getMenu(String locationId) async {
    try {
      final categoriesData = await SupabaseService.getCategories();
      final productsData = await SupabaseService.getProducts();
      
      final categories = categoriesData.map((json) => Category(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        emoji: json['emoji'] ?? '☕',
      )).toList();
      
      final products = await Future.wait(productsData.map((json) async {
        final modifiers = await _loadProductModifiers(json['id']);
        return Product(
          id: json['id'] ?? '',
          name: json['name'] ?? '',
          price: (json['price'] as num?)?.toDouble() ?? 0,
          description: json['description'] ?? '',
          imageUrl: json['imageUrl'] ?? '',
          categoryId: json['categoryId'] ?? '',
          modifiers: modifiers,
        );
      }));
      
      return {
        'categories': categories,
        'products': products,
      };
    } catch (e) {
      print('Error loading menu: $e');
      // Fallback to mock data
      return {
        'categories': _mockCategories,
        'products': _mockProducts,
      };
    }
  }

  Future<ModifierGroups?> _loadProductModifiers(String productId) async {
    try {
      final groups = await SupabaseService.getModifierGroups(productId);
      if (groups.isEmpty) return null;
      
      ModifierGroup? sizeGroup;
      ModifierGroup? milkGroup;
      ModifierGroup? extrasGroup;
      
      for (var group in groups) {
        final options = await SupabaseService.getModifierOptions(group['id']);
        final modifierGroup = ModifierGroup(
          required: group['isRequired'] ?? false,
          type: group['type'] == 'MULTIPLE' ? 'multiple' : 'single',
          options: options.map((opt) => ModifierOption(
            label: opt['name'] ?? '',
            volume: opt['description'],
            price: (opt['price'] as num?)?.toDouble() ?? 0,
          )).toList(),
        );
        
        final groupName = (group['name'] as String?)?.toLowerCase() ?? '';
        if (groupName.contains('размер') || groupName.contains('size')) {
          sizeGroup = modifierGroup;
        } else if (groupName.contains('молоко') || groupName.contains('milk')) {
          milkGroup = modifierGroup;
        } else {
          extrasGroup = modifierGroup;
        }
      }
      
      return ModifierGroups(
        size: sizeGroup,
        milk: milkGroup,
        extras: extrasGroup,
      );
    } catch (e) {
      print('Error loading modifiers: $e');
      return null;
    }
  }

  // ==================== PROMOCODES ====================
  
  Future<Map<String, dynamic>> validatePromoCode(String code) async {
    try {
      final promo = await SupabaseService.validatePromocode(code);
      if (promo == null) {
        return {'valid': false};
      }
      
      return {
        'valid': true,
        'id': promo['id'],
        'value': promo['value'] ?? 0,
        'type': promo['type'], // percent or fixed
        'minOrderAmount': promo['minOrderAmount'],
        'maxDiscountAmount': promo['maxDiscountAmount'],
      };
    } catch (e) {
      print('Error validating promocode: $e');
      return {'valid': false};
    }
  }

  // ==================== ORDERS ====================
  
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      final result = await SupabaseService.createOrder(
        locationId: orderData['locationId'],
        items: List<Map<String, dynamic>>.from(orderData['items']),
        total: (orderData['total'] as num).toDouble(),
        promocodeId: orderData['promocodeId'],
        discount: orderData['discount']?.toDouble(),
        telegramUserId: orderData['telegramUserId'],
      );
      
      return {
        'orderId': result['id'],
        'status': result['status'],
        'estimatedTime': 15,
      };
    } catch (e) {
      print('Error creating order: $e');
      return {
        'orderId': 'order_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'pending',
        'estimatedTime': 15,
      };
    }
  }

  // ==================== MOCK DATA (Fallback - empty, use Supabase) ====================
  
  static final List<Location> _mockLocations = [];

  static final List<Category> _mockCategories = [
    Category(id: 'cat_1', name: 'Кофе', emoji: '☕'),
    Category(id: 'cat_2', name: 'Чай', emoji: '🍵'),
    Category(id: 'cat_3', name: 'Десерты', emoji: '🍰'),
  ];

  static final List<Product> _mockProducts = [
    Product(
      id: 'prod_1',
      name: 'Латте',
      price: 250,
      description: 'Классический кофе с нежным молоком',
      imageUrl: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400',
      categoryId: 'cat_1',
      modifiers: ModifierGroups(
        size: ModifierGroup(
          required: true,
          type: 'single',
          options: [
            ModifierOption(label: 'S', volume: '250 мл', price: 0),
            ModifierOption(label: 'M', volume: '350 мл', price: 50),
            ModifierOption(label: 'L', volume: '450 мл', price: 100),
          ],
        ),
      ),
    ),
    Product(
      id: 'prod_2',
      name: 'Капучино',
      price: 220,
      description: 'Эспрессо с воздушной молочной пенкой',
      imageUrl: 'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400',
      categoryId: 'cat_1',
    ),
  ];
}
