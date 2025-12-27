class Location {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double rating;
  final String workingHours;
  final bool isOpen;
  double? distance;

  Location({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.workingHours,
    required this.isOpen,
    this.distance,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    // Поддержка разных имён полей (lat/latitude, lng/longitude)
    final latitude = json['lat'] ?? json['latitude'] ?? 0.0;
    final longitude = json['lng'] ?? json['longitude'] ?? 0.0;
    final rating = json['rating'] ?? 5.0;
    final workingHours = json['workingHours'];
    
    // Формируем адрес из address и city
    String address = json['address'] ?? '';
    final city = json['city'] as String?;
    if (city != null && city.isNotEmpty && !address.contains(city)) {
      address = '$address, $city';
    }
    
    return Location(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      address: address,
      lat: (latitude is num) ? latitude.toDouble() : 0.0,
      lng: (longitude is num) ? longitude.toDouble() : 0.0,
      rating: (rating is num) ? rating.toDouble() : 5.0,
      workingHours: (workingHours is String) ? workingHours : '',
      isOpen: json['isOpen'] ?? json['isAcceptingOrders'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'rating': rating,
      'workingHours': workingHours,
      'isOpen': isOpen,
    };
  }
}

