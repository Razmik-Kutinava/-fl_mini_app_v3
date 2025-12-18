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
    return Location(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      workingHours: json['workingHours'],
      isOpen: json['isOpen'] ?? true,
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

