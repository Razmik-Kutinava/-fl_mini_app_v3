import '../models/location.dart';
import '../models/product.dart';
import '../models/category.dart';

class ApiService {
  // Mock data for demo
  static final List<Location> _mockLocations = [
    Location(
      id: 'loc_1',
      name: 'Кофейня "Арбат"',
      address: 'ул. Арбат, 24',
      lat: 55.7522,
      lng: 37.5876,
      rating: 4.9,
      workingHours: '08:00-23:00',
      isOpen: true,
    ),
    Location(
      id: 'loc_2',
      name: 'Кофейня "Тверская"',
      address: 'Тверская ул., 15',
      lat: 55.7640,
      lng: 37.6056,
      rating: 4.8,
      workingHours: '07:00-22:00',
      isOpen: true,
    ),
    Location(
      id: 'loc_3',
      name: 'Кофейня "Патриаршие"',
      address: 'Патриаршие пруды, 5',
      lat: 55.7645,
      lng: 37.5922,
      rating: 4.7,
      workingHours: '09:00-21:00',
      isOpen: true,
    ),
  ];

  static final List<Category> _mockCategories = [
    Category(id: 'cat_1', name: 'Кофе', emoji: '☕'),
    Category(id: 'cat_2', name: 'Чай', emoji: '🍵'),
    Category(id: 'cat_3', name: 'Десерты', emoji: '🍰'),
    Category(id: 'cat_4', name: 'Выпечка', emoji: '🥐'),
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
        milk: ModifierGroup(
          required: false,
          type: 'single',
          options: [
            ModifierOption(label: 'Обычное', price: 0),
            ModifierOption(label: 'Соевое', price: 30),
            ModifierOption(label: 'Миндальное', price: 40),
            ModifierOption(label: 'Кокосовое', price: 50),
          ],
        ),
        extras: ModifierGroup(
          required: false,
          type: 'multiple',
          options: [
            ModifierOption(label: 'Сироп ванильный', price: 50),
            ModifierOption(label: 'Маршмеллоу', price: 30),
            ModifierOption(label: 'Доп. шот эспрессо', price: 50),
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
      modifiers: ModifierGroups(
        size: ModifierGroup(
          required: true,
          type: 'single',
          options: [
            ModifierOption(label: 'S', volume: '200 мл', price: 0),
            ModifierOption(label: 'M', volume: '300 мл', price: 40),
            ModifierOption(label: 'L', volume: '400 мл', price: 80),
          ],
        ),
        milk: ModifierGroup(
          required: false,
          type: 'single',
          options: [
            ModifierOption(label: 'Обычное', price: 0),
            ModifierOption(label: 'Соевое', price: 30),
            ModifierOption(label: 'Овсяное', price: 35),
          ],
        ),
      ),
    ),
    Product(
      id: 'prod_3',
      name: 'Эспрессо',
      price: 180,
      description: 'Крепкий насыщенный кофе',
      imageUrl: 'https://images.unsplash.com/photo-1510707577719-ae7c14805e3a?w=400',
      categoryId: 'cat_1',
      modifiers: ModifierGroups(
        size: ModifierGroup(
          required: true,
          type: 'single',
          options: [
            ModifierOption(label: 'Single', volume: '30 мл', price: 0),
            ModifierOption(label: 'Double', volume: '60 мл', price: 60),
          ],
        ),
      ),
    ),
    Product(
      id: 'prod_4',
      name: 'Раф',
      price: 280,
      description: 'Кофе со сливками и ванильным сахаром',
      imageUrl: 'https://images.unsplash.com/photo-1485808191679-5f86510681a2?w=400',
      categoryId: 'cat_1',
      modifiers: ModifierGroups(
        size: ModifierGroup(
          required: true,
          type: 'single',
          options: [
            ModifierOption(label: 'S', volume: '250 мл', price: 0),
            ModifierOption(label: 'M', volume: '350 мл', price: 60),
            ModifierOption(label: 'L', volume: '450 мл', price: 120),
          ],
        ),
        extras: ModifierGroup(
          required: false,
          type: 'multiple',
          options: [
            ModifierOption(label: 'Лавандовый сироп', price: 50),
            ModifierOption(label: 'Карамельный сироп', price: 50),
          ],
        ),
      ),
    ),
    Product(
      id: 'prod_5',
      name: 'Флэт Уайт',
      price: 260,
      description: 'Двойной эспрессо с бархатистым молоком',
      imageUrl: 'https://images.unsplash.com/photo-1534778101976-62847782c213?w=400',
      categoryId: 'cat_1',
      modifiers: ModifierGroups(
        size: ModifierGroup(
          required: true,
          type: 'single',
          options: [
            ModifierOption(label: 'S', volume: '180 мл', price: 0),
            ModifierOption(label: 'M', volume: '240 мл', price: 40),
          ],
        ),
        milk: ModifierGroup(
          required: false,
          type: 'single',
          options: [
            ModifierOption(label: 'Обычное', price: 0),
            ModifierOption(label: 'Безлактозное', price: 30),
          ],
        ),
      ),
    ),
    Product(
      id: 'prod_6',
      name: 'Американо',
      price: 200,
      description: 'Эспрессо разбавленный горячей водой',
      imageUrl: 'https://images.unsplash.com/photo-1521302080334-4bebac2763a6?w=400',
      categoryId: 'cat_1',
      modifiers: ModifierGroups(
        size: ModifierGroup(
          required: true,
          type: 'single',
          options: [
            ModifierOption(label: 'S', volume: '200 мл', price: 0),
            ModifierOption(label: 'M', volume: '300 мл', price: 30),
            ModifierOption(label: 'L', volume: '400 мл', price: 60),
          ],
        ),
      ),
    ),
    // Чай
    Product(
      id: 'prod_7',
      name: 'Зелёный чай',
      price: 180,
      description: 'Классический зелёный чай',
      imageUrl: 'https://images.unsplash.com/photo-1556881286-fc6915169721?w=400',
      categoryId: 'cat_2',
    ),
    Product(
      id: 'prod_8',
      name: 'Чёрный чай',
      price: 160,
      description: 'Ароматный чёрный чай',
      imageUrl: 'https://images.unsplash.com/photo-1597318181409-cf64d0b5d8a2?w=400',
      categoryId: 'cat_2',
    ),
    Product(
      id: 'prod_9',
      name: 'Матча латте',
      price: 320,
      description: 'Японский зелёный чай с молоком',
      imageUrl: 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=400',
      categoryId: 'cat_2',
      modifiers: ModifierGroups(
        milk: ModifierGroup(
          required: false,
          type: 'single',
          options: [
            ModifierOption(label: 'Обычное', price: 0),
            ModifierOption(label: 'Овсяное', price: 35),
            ModifierOption(label: 'Кокосовое', price: 50),
          ],
        ),
      ),
    ),
    // Десерты
    Product(
      id: 'prod_10',
      name: 'Чизкейк',
      price: 350,
      description: 'Нежный сливочный чизкейк',
      imageUrl: 'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=400',
      categoryId: 'cat_3',
    ),
    Product(
      id: 'prod_11',
      name: 'Тирамису',
      price: 380,
      description: 'Итальянский десерт с маскарпоне',
      imageUrl: 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400',
      categoryId: 'cat_3',
    ),
    Product(
      id: 'prod_12',
      name: 'Брауни',
      price: 280,
      description: 'Шоколадный брауни с орехами',
      imageUrl: 'https://images.unsplash.com/photo-1564355808539-22fda35bed7e?w=400',
      categoryId: 'cat_3',
    ),
    // Выпечка
    Product(
      id: 'prod_13',
      name: 'Круассан',
      price: 180,
      description: 'Свежий хрустящий круассан',
      imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400',
      categoryId: 'cat_4',
    ),
    Product(
      id: 'prod_14',
      name: 'Маффин',
      price: 200,
      description: 'Черничный маффин',
      imageUrl: 'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=400',
      categoryId: 'cat_4',
    ),
  ];

  Future<List<Location>> getLocations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockLocations;
  }

  Future<Map<String, dynamic>> getMenu(String locationId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'categories': _mockCategories,
      'products': _mockProducts,
    };
  }

  Future<Map<String, dynamic>> validatePromoCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (code.toUpperCase() == 'COFFEE20') {
      return {'valid': true, 'discountPercent': 20};
    } else if (code.toUpperCase() == 'WELCOME') {
      return {'valid': true, 'discountPercent': 10};
    }
    return {'valid': false};
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'orderId': 'order_${DateTime.now().millisecondsSinceEpoch}',
      'status': 'pending',
      'estimatedTime': 15,
    };
  }
}

