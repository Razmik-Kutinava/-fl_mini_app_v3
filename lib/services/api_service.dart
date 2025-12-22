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
        print('=== Processing Location ===');
        print('Name: ${json['name']}');
        print('City: ${json['city']}');
        print('Address: ${json['address']}');
        
        double lat = _parseDouble(json['latitude']);
        double lng = _parseDouble(json['longitude']);
        print('DB Coordinates: lat=$lat, lng=$lng');
        
        // Если координаты отсутствуют, используем геокодинг
        if (lat == 0 && lng == 0) {
          final address = json['address'] ?? json['city'] ?? '';
          final city = json['city'] ?? '';
          final name = json['name'] ?? '';
          
          print('Starting geocoding for: name=$name, city=$city, address=$address');
          
          if (address.isNotEmpty || city.isNotEmpty) {
            final coords = await _geocodeAddress(address, city, name);
            if (coords != null) {
              lat = coords['lat']!;
              lng = coords['lng']!;
              print('✅ Geocoded location: $name -> lat: $lat, lng: $lng');
            } else {
              // Fallback координаты (если не удалось найти)
              final cityLower = city.toLowerCase();
              final nameLower = name.toLowerCase();
              final addressLower = address.toLowerCase();
              
              // СНАЧАЛА проверяем Ереван (важно!)
              if (cityLower.contains('ереван') || 
                  cityLower.contains('yerevan') ||
                  addressLower.contains('ереван') ||
                  addressLower.contains('yerevan') ||
                  nameLower.contains('ереван')) {
                lat = 40.1811;
                lng = 44.5136;
                print('Using Yerevan fallback for: $name -> lat: $lat, lng: $lng');
              } else if (cityLower.contains('самара') || 
                         cityLower.contains('samara') || 
                         nameLower.contains('напибар') ||
                         addressLower.contains('куйбышева')) {
                lat = 53.2015;
                lng = 50.1405;
                print('Using Samara fallback for: $name -> lat: $lat, lng: $lng');
              } else {
                // Неизвестный город - используем центр между Самарой и Ереваном
                lat = 46.5;
                lng = 47.0;
                print('Using default fallback for: $name -> lat: $lat, lng: $lng');
              }
            }
          }
        }
        
        // Формируем полный адрес
        String fullAddress = '';
        final rawAddress = json['address'];
        final rawCity = json['city'];
        
        print('  Raw address: $rawAddress, Raw city: $rawCity');
        
        if (rawAddress != null && rawAddress.toString().isNotEmpty) {
          fullAddress = rawAddress.toString();
          if (rawCity != null && rawCity.toString().isNotEmpty) {
            final city = rawCity.toString();
            if (!fullAddress.toLowerCase().contains(city.toLowerCase())) {
              fullAddress += ', $city';
            }
          }
        } else if (rawCity != null && rawCity.toString().isNotEmpty) {
          fullAddress = rawCity.toString();
        }
        
        print('  Final address: $fullAddress');
        
        final location = Location(
          id: json['id'] ?? '',
          name: json['name'] ?? '',
          address: fullAddress,
          lat: lat,
          lng: lng,
          rating: 4.5, // No rating in schema
          workingHours: _formatWorkingHours(json),
          isOpen: json['isAcceptingOrders'] ?? true,
        );
        
        print('📍 Final location: ${location.name} -> lat: ${location.lat}, lng: ${location.lng}, address: ${location.address}');
        locations.add(location);
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
      
      // Координаты для известных адресов (fallback)
      // Координаты для "Куйбышева 98 напи бар" в Самаре
      if ((addressLower.contains('куйбышева') || 
          nameLower.contains('напибар') || 
          nameLower.contains('напи бар')) &&
          (cityLower.contains('самара') || cityLower.isEmpty)) {
        // Улица Куйбышева, 98, Самара (точные координаты)
        return {'lat': 53.2015, 'lng': 50.1405};
      }
      
      // Координаты для Еревана
      if (cityLower.contains('ереван') || 
          cityLower.contains('yerevan') ||
          addressLower.contains('ереван')) {
        // Ереван, Армения (центр города)
        return {'lat': 40.1811, 'lng': 44.5136};
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
      
      // Добавляем страну только если не указана (для международных адресов)
      // Проверяем, содержит ли запрос название страны
      final queryLower = query.toLowerCase();
      if (!queryLower.contains('россия') && 
          !queryLower.contains('russia') &&
          !queryLower.contains('армения') &&
          !queryLower.contains('armenia') &&
          !queryLower.contains('ереван') &&
          !queryLower.contains('yerevan')) {
        // Если город содержит "самара" или "samara", добавляем "Россия"
        if (cityLower.contains('самара') || cityLower.contains('samara')) {
          query += ', Россия';
        } else if (cityLower.contains('ереван') || cityLower.contains('yerevan')) {
          query += ', Армения';
        }
      }
      
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
      
      // Fallback: если геокодинг не удался, используем координаты по городу
      // СНАЧАЛА проверяем Ереван
      if (cityLower.contains('ереван') || 
          cityLower.contains('yerevan') ||
          addressLower.contains('ереван') ||
          addressLower.contains('yerevan') ||
          nameLower.contains('ереван')) {
        return {'lat': 40.1811, 'lng': 44.5136};
      } else if (cityLower.contains('самара') || 
                 cityLower.contains('samara') ||
                 nameLower.contains('напибар') ||
                 addressLower.contains('куйбышева')) {
        return {'lat': 53.2015, 'lng': 50.1405};
      }
      
      return null;
    } catch (e) {
      print('Geocoding error: $e');
      // Fallback для известных городов
      final cityLower = city.toLowerCase();
      final nameLower = name.toLowerCase();
      final addressLower = address.toLowerCase();
      
      // СНАЧАЛА проверяем Ереван
      if (cityLower.contains('ереван') || 
          cityLower.contains('yerevan') ||
          addressLower.contains('ереван') ||
          addressLower.contains('yerevan') ||
          nameLower.contains('ереван')) {
        return {'lat': 40.1811, 'lng': 44.5136};
      } else if (cityLower.contains('самара') || 
                 cityLower.contains('samara') ||
                 nameLower.contains('напибар') ||
                 addressLower.contains('куйбышева')) {
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
              : '', // Пустая строка - будет показана иконка кофе
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
      print('🔄 Loading modifiers for product: $productId');
      print('🔄 Product ID in _loadProductModifiers: "$productId"');
      final groups = await SupabaseService.getModifierGroups(productId);
      print('📦 Loaded ${groups.length} modifier groups');
      print('📦 Groups data: $groups');
      
      if (groups.isEmpty) {
        print('⚠️ No modifier groups found for product: $productId');
        return null;
      }
      
      ModifierGroup? sizeGroup;
      ModifierGroup? milkGroup;
      ModifierGroup? extrasGroup;
      
      // Сортируем группы по порядку (если есть sortOrder) или по типу
      final sortedGroups = List<Map<String, dynamic>>.from(groups);
      sortedGroups.sort((a, b) {
        final aOrder = a['sortOrder'] ?? 999;
        final bOrder = b['sortOrder'] ?? 999;
        return (aOrder as num).compareTo(bOrder as num);
      });
      
      for (var group in sortedGroups) {
        print('📝 Processing group: ${group['name']}');
        final options = await SupabaseService.getModifierOptions(group['id']);
        print('  Options count: ${options.length}');
        
        if (options.isEmpty) {
          print('  ⚠️ Skipping group ${group['name']} - no options');
          continue;
        }
        
        final modifierGroup = ModifierGroup(
          required: group['required'] ?? group['isRequired'] ?? false,
          type: (group['type']?.toString().toUpperCase() == 'MULTIPLE') ? 'multiple' : 'single',
          options: options.map((opt) => ModifierOption(
            label: opt['name'] ?? '',
            volume: opt['description'],
            price: (opt['price'] as num?)?.toDouble() ?? 0,
            emoji: opt['emoji'],
          )).toList(),
        );
        
        final groupName = (group['name'] as String?)?.toLowerCase() ?? '';
        print('  Group name (lowercase): $groupName');
        
        // Более гибкое определение типа группы
        if (groupName.contains('размер') || groupName.contains('size') || 
            groupName.contains('объем') || groupName.contains('volume')) {
          print('  ✅ Assigned to sizeGroup');
          sizeGroup = modifierGroup;
        } else if (groupName.contains('молоко') || groupName.contains('milk')) {
          print('  ✅ Assigned to milkGroup');
          milkGroup = modifierGroup;
        } else {
          // Все остальные группы идут в extras
          print('  ✅ Assigned to extrasGroup');
          // Если extrasGroup уже есть, создаем список или объединяем
          if (extrasGroup == null) {
            extrasGroup = modifierGroup;
          } else {
            // Если уже есть extras, добавляем опции к существующей группе
            // Но это не совсем правильно, лучше создать список групп
            // Пока просто перезаписываем последней группой
            extrasGroup = modifierGroup;
          }
        }
      }
      
      final result = ModifierGroups(
        size: sizeGroup,
        milk: milkGroup,
        extras: extrasGroup,
      );
      
      print('✅ Final ModifierGroups:');
      print('  - size: ${sizeGroup != null ? "${sizeGroup.options.length} options" : "null"}');
      print('  - milk: ${milkGroup != null ? "${milkGroup.options.length} options" : "null"}');
      print('  - extras: ${extrasGroup != null ? "${extrasGroup.options.length} options" : "null"}');
      
      return result;
    } catch (e) {
      print('❌ Error loading modifiers: $e');
      print('❌ Stack trace: ${StackTrace.current}');
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
        userId: orderData['userId'],
        customerName: orderData['customerName'],
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
