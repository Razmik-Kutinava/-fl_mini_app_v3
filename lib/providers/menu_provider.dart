import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/category.dart' as models;

class MenuProvider with ChangeNotifier {
  List<models.Category> _categories = [];
  List<Product> _products = [];
  String? _selectedCategoryId;
  bool _isLoading = false;

  List<models.Category> get categories => _categories;
  List<Product> get products {
    if (_selectedCategoryId == null) {
      // Если категория не выбрана ("для тебя"), возвращаем все товары
      return _products;
    }
    // Фильтруем товары по выбранной категории
    final filtered = _products.where((p) => p.categoryId == _selectedCategoryId).toList();
    print('🔍 MenuProvider.products: selectedCategoryId=$_selectedCategoryId, filtered count=${filtered.length}, total products=${_products.length}');
    for (var product in filtered) {
      print('🔍 Filtered product: id=${product.id}, name=${product.name}, categoryId=${product.categoryId}');
    }
    return filtered;
  }
  List<Product> get allProducts => _products;
  String? get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;

  void setCategories(List<models.Category> categories) {
    _categories = categories;
    notifyListeners();
  }

  void setProducts(List<Product> products) {
    _products = products;
    notifyListeners();
  }

  void selectCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

