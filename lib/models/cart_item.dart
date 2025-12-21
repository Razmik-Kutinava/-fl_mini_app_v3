import 'product.dart';

class CartItem {
  final Product product;
  final Map<String, dynamic> modifiers;
  int quantity;
  double totalPrice;

  CartItem({
    required this.product,
    required this.modifiers,
    required this.quantity,
    required this.totalPrice,
  });

  String get sizeLabel {
    if (modifiers['size'] != null && product.modifiers?.size != null) {
      final idx = modifiers['size'] as int;
      if (idx < product.modifiers!.size!.options.length) {
        return product.modifiers!.size!.options[idx].label;
      }
    }
    return '';
  }

  List<String> get modifiersList {
    List<String> list = [];
    
    if (modifiers['milk'] != null && product.modifiers?.milk != null) {
      final idx = modifiers['milk'] as int;
      if (idx < product.modifiers!.milk!.options.length && idx > 0) {
        list.add('+ ${product.modifiers!.milk!.options[idx].label}');
      }
    }
    
    if (modifiers['extras'] != null && product.modifiers?.extras != null) {
      final extras = modifiers['extras'];
      if (extras is List) {
        for (var idx in extras) {
          if (idx is int && idx < product.modifiers!.extras!.options.length) {
            list.add('+ ${product.modifiers!.extras!.options[idx].label}');
          }
        }
      } else if (extras is int) {
        if (extras < product.modifiers!.extras!.options.length) {
          list.add('+ ${product.modifiers!.extras!.options[extras].label}');
        }
      }
    }
    
    return list;
  }

  void updateTotalPrice() {
    double total = product.price;

    if (modifiers['size'] != null && product.modifiers?.size != null) {
      final idx = modifiers['size'] as int;
      if (idx < product.modifiers!.size!.options.length) {
        total += product.modifiers!.size!.options[idx].price;
      }
    }

    if (modifiers['milk'] != null && product.modifiers?.milk != null) {
      final idx = modifiers['milk'] as int;
      if (idx < product.modifiers!.milk!.options.length) {
        total += product.modifiers!.milk!.options[idx].price;
      }
    }

    if (modifiers['extras'] != null && product.modifiers?.extras != null) {
      final extras = modifiers['extras'];
      if (extras is List) {
        for (var idx in extras) {
          if (idx is int && idx < product.modifiers!.extras!.options.length) {
            total += product.modifiers!.extras!.options[idx].price;
          }
        }
      } else if (extras is int) {
        if (extras < product.modifiers!.extras!.options.length) {
          total += product.modifiers!.extras!.options[extras].price;
        }
      }
    }

    totalPrice = total * quantity;
  }
}

