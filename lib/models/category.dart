class Category {
  final String id;
  final String name;
  final String emoji;

  Category({
    required this.id,
    required this.name,
    String? emoji,
  }) : emoji = emoji ?? '☕';

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      emoji: json['emoji'],
    );
  }
}

