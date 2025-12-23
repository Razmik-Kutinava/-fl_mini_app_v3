import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location.dart';

class LocationProvider with ChangeNotifier {
  Location? _selectedLocation;
  List<Location> _locations = [];
  Position? _userPosition;
  bool _isLoading = false;
  static const String _lastLocationKey = 'last_selected_location_id';

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

  Future<void> selectLocation(Location location) async {
    _selectedLocation = location;
    notifyListeners();
    
    // Сохраняем выбранную локацию
    await _saveLastLocation(location.id);
  }
  
  /// Сохраняет ID последней выбранной локации
  Future<void> _saveLastLocation(String locationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastLocationKey, locationId);
      print('✅ Сохранена последняя локация: $locationId');
    } catch (e) {
      print('⚠️ Ошибка сохранения локации: $e');
    }
  }
  
  /// Загружает последнюю выбранную локацию
  Future<String?> getLastLocationId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationId = prefs.getString(_lastLocationKey);
      print('📍 Загружена последняя локация: $locationId');
      return locationId;
    } catch (e) {
      print('⚠️ Ошибка загрузки локации: $e');
      return null;
    }
  }
  
  /// Восстанавливает последнюю выбранную локацию из списка
  void restoreLastLocation(String locationId) {
    final location = _locations.firstWhere(
      (loc) => loc.id == locationId,
      orElse: () => _locations.isNotEmpty ? _locations.first : throw StateError('No locations available'),
    );
    _selectedLocation = location;
    notifyListeners();
    print('✅ Восстановлена локация: ${location.name}');
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

