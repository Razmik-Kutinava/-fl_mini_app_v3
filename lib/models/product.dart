class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final String imageUrl;
  final String categoryId;
  final ModifierGroups? modifiers;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.categoryId,
    this.modifiers,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      categoryId: json['categoryId'],
      modifiers: json['modifiers'] != null
          ? ModifierGroups.fromJson(json['modifiers'])
          : null,
    );
  }
}

class ModifierGroups {
  final ModifierGroup? size;
  final ModifierGroup? milk;
  final ModifierGroup? extras;

  ModifierGroups({this.size, this.milk, this.extras});

  factory ModifierGroups.fromJson(Map<String, dynamic> json) {
    return ModifierGroups(
      size: json['size'] != null ? ModifierGroup.fromJson(json['size']) : null,
      milk: json['milk'] != null ? ModifierGroup.fromJson(json['milk']) : null,
      extras: json['extras'] != null ? ModifierGroup.fromJson(json['extras']) : null,
    );
  }
}

class ModifierGroup {
  final bool required;
  final String type;
  final List<ModifierOption> options;

  ModifierGroup({
    required this.required,
    required this.type,
    required this.options,
  });

  factory ModifierGroup.fromJson(Map<String, dynamic> json) {
    return ModifierGroup(
      required: json['required'] ?? false,
      type: json['type'] ?? 'single',
      options: (json['options'] as List)
          .map((e) => ModifierOption.fromJson(e))
          .toList(),
    );
  }
}

class ModifierOption {
  final String label;
  final String? volume;
  final double price;
  final String? emoji;

  ModifierOption({
    required this.label,
    this.volume,
    required this.price,
    this.emoji,
  });

  factory ModifierOption.fromJson(Map<String, dynamic> json) {
    return ModifierOption(
      label: json['label'],
      volume: json['volume'],
      price: (json['price'] as num).toDouble(),
      emoji: json['emoji'],
    );
  }
}

