import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  String? _promoCode;
  double _discount = 0;

  List<CartItem> get items => _items;
  String? get promoCode => _promoCode;
  double get discount => _discount;

  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get total => subtotal - _discount;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  void addItem(CartItem item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItem(CartItem item) {
    _items.remove(item);
    _recalculateDiscount();
    notifyListeners();
  }

  void updateQuantity(CartItem item, int quantity) {
    if (quantity <= 0) {
      removeItem(item);
      return;
    }
    item.quantity = quantity;
    item.updateTotalPrice();
    _recalculateDiscount();
    notifyListeners();
  }

  void applyPromoCode(String code, double discountAmount) {
    _promoCode = code;
    _discount = discountAmount;
    notifyListeners();
  }

  void removePromoCode() {
    _promoCode = null;
    _discount = 0;
    notifyListeners();
  }

  void _recalculateDiscount() {
    if (_promoCode != null && _discount > 0) {
      // Recalculate discount based on new subtotal (10% example)
      _discount = subtotal * 0.1;
    }
  }

  void clear() {
    _items.clear();
    _promoCode = null;
    _discount = 0;
    notifyListeners();
  }
}

