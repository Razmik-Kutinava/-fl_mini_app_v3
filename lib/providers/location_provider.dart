import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location.dart';

class LocationProvider with ChangeNotifier {
  Location? _selectedLocation;
  List<Location> _locations = [];
  Position? _userPosition;
  bool _isLoading = false;

  Location? get selectedLocation => _selectedLocation;
  List<Location> get locations => _locations;
  Position? get userPosition => _userPosition;
  bool get isLoading => _isLoading;

  void setUserPosition(Position position) {
    _userPosition = position;
    _calculateDistances();
    notifyListeners();
  }

  void setLocations(List<Location> locations) {
    _locations = locations;
    _calculateDistances();
    notifyListeners();
  }

  void _calculateDistances() {
    if (_userPosition != null) {
      for (var loc in _locations) {
        loc.distance = Geolocator.distanceBetween(
              _userPosition!.latitude,
              _userPosition!.longitude,
              loc.lat,
              loc.lng,
            ) /
            1000;
      }
      _locations.sort((a, b) => (a.distance ?? 999).compareTo(b.distance ?? 999));
    }
  }

  void selectLocation(Location location) {
    _selectedLocation = location;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

