import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/category.dart' as models;

class MenuProvider with ChangeNotifier {
  List<models.Category> _categories = [];
  List<Product> _products = [];
  String? _selectedCategoryId;
  bool _isLoading = false;

  List<models.Category> get categories => _categories;
  List<Product> get products => _selectedCategoryId == null
      ? _products
      : _products.where((p) => p.categoryId == _selectedCategoryId).toList();
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

