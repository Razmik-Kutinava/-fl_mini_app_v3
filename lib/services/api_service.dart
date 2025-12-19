import 'dart:convert';
import '../models/location.dart';
import '../models/product.dart';
import '../models/category.dart';
import 'supabase_service.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // ==================== LOCATIONS ====================
  
  Future<List<Location>> getLocations() async {
    try {
      final data = await SupabaseService.getLocations();
      final locations = <Location>[];
      
      for (var json in data) {
        double lat = _parseDouble(json['latitude']);
        double lng = _parseDouble(json['longitude']);
        
        // Если координаты отсутствуют, используем геокодинг
        if (lat == 0 && lng == 0) {
          final address = json['address'] ?? json['city'] ?? '';
          final city = json['city'] ?? '';
          final name = json['name'] ?? '';
          
          if (address.isNotEmpty || city.isNotEmpty) {
            final coords = await _geocodeAddress(address, city, name);
            if (coords != null) {
              lat = coords['lat']!;
              lng = coords['lng']!;
              print('Geocoded location: $name -> lat: $lat, lng: $lng');
            } else {
              // Fallback координаты для Самары (если не удалось найти)
              final cityLower = city.toLowerCase();
              if (cityLower.contains('самара') || cityLower.contains('samara') || 
                  name.toLowerCase().contains('напибар')) {
                lat = 53.2015;
                lng = 50.1405;
              } else {
                lat = 53.2001;
                lng = 50.1400;
              }
              print('Using fallback coordinates for: $name -> lat: $lat, lng: $lng');
            }
          }
        }
        
        // Формируем полный адрес
        String fullAddress = '';
        if (json['address'] != null && json['address'].toString().isNotEmpty) {
          fullAddress = json['address'].toString();
          if (json['city'] != null && json['city'].toString().isNotEmpty) {
            final city = json['city'].toString();
            if (!fullAddress.toLowerCase().contains(city.toLowerCase())) {
              fullAddress += ', $city';
            }
          }
        } else if (json['city'] != null && json['city'].toString().isNotEmpty) {
          fullAddress = json['city'].toString();
        }
        
        locations.add(Location(
          id: json['id'] ?? '',
          name: json['name'] ?? '',
          address: fullAddress,
          lat: lat,
          lng: lng,
          rating: 4.5, // No rating in schema
          workingHours: _formatWorkingHours(json),
          isOpen: json['isAcceptingOrders'] ?? true,
        ));
      }
      
      return locations;
    } catch (e) {
      print('Error loading locations: $e');
      return _mockLocations;
    }
  }
  
  /// Геокодинг адреса через OpenStreetMap Nominatim API
  Future<Map<String, double>?> _geocodeAddress(String address, String city, String name) async {
    try {
      // Проверяем известные адреса (fallback)
      final addressLower = address.toLowerCase();
      final cityLower = city.toLowerCase();
      final nameLower = name.toLowerCase();
      
      // Координаты для "Куйбышева 98 напи бар" в Самаре
      if (addressLower.contains('куйбышева') || 
          nameLower.contains('напибар') || 
          nameLower.contains('напи бар')) {
        // Улица Куйбышева, 98, Самара (точные координаты)
        // 53.2015, 50.1405 - более точные координаты для ул. Куйбышева, 98
        return {'lat': 53.2015, 'lng': 50.1405};
      }
      
      // Формируем поисковый запрос
      String query = '';
      if (address.isNotEmpty) {
        query = address;
        if (city.isNotEmpty && !address.toLowerCase().contains(city.toLowerCase())) {
          query += ', $city';
        }
      } else if (city.isNotEmpty) {
        query = city;
      } else if (name.isNotEmpty) {
        query = name;
      }
      
      if (query.isEmpty) return null;
      
      // Добавляем "Россия" для более точного поиска
      query += ', Россия';
      
      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=1&addressdetails=1';
      
      print('Geocoding request: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'FlutterCoffeeApp/1.0', // Требуется Nominatim
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final result = data[0];
          final lat = double.tryParse(result['lat']?.toString() ?? '') ?? 0.0;
          final lon = double.tryParse(result['lon']?.toString() ?? '') ?? 0.0;
          
          if (lat != 0 && lon != 0) {
            return {'lat': lat, 'lng': lon};
          }
        }
      }
      
      print('Geocoding failed for: $query');
      
      // Fallback: если геокодинг не удался, используем координаты Самары
      if (cityLower.contains('самара') || cityLower.contains('samara') ||
          nameLower.contains('напибар')) {
        return {'lat': 53.2015, 'lng': 50.1405};
      }
      
      return null;
    } catch (e) {
      print('Geocoding error: $e');
      // Fallback для известных городов
      final cityLower = city.toLowerCase();
      final nameLower = name.toLowerCase();
      if (cityLower.contains('самара') || cityLower.contains('samara') ||
          nameLower.contains('напибар')) {
        return {'lat': 53.2015, 'lng': 50.1405};
      }
      return null;
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
        final imageUrl = json['imageUrl'];
        final productName = json['name'] ?? 'Coffee';
        return Product(
          id: json['id'] ?? '',
          name: productName,
          price: (json['price'] as num?)?.toDouble() ?? 0,
          description: json['description'] ?? '',
          imageUrl: (imageUrl != null && imageUrl.toString().isNotEmpty)
              ? imageUrl.toString()
              : 'https://via.placeholder.com/400x400/8B4513/FFFFFF?text=${Uri.encodeComponent(productName)}',
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
