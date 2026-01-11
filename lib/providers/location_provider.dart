import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location.dart';
import '../services/supabase_service.dart';

class LocationProvider with ChangeNotifier {
  Location? _selectedLocation;
  List<Location> _locations = [];
  Position? _userPosition;
  bool _isLoading = false;
  String? _userId; // Добавляем userId для обновления в БД
  static const String _lastLocationKey = 'last_selected_location_id';
  static const String _recentLocationsKey = 'recent_locations_history';
  static const int _maxRecentLocations = 10;

  Location? get selectedLocation => _selectedLocation;
  List<Location> get locations => _locations;
  Position? get userPosition => _userPosition;
  bool get isLoading => _isLoading;

  /// Устанавливает userId для синхронизации с БД
  void setUserId(String? userId) {
    _userId = userId;
    print('📍 LocationProvider: userId установлен = $userId');
  }

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

    // Сохраняем выбранную локацию локально
    await _saveLastLocation(location.id);

    // НОВОЕ: Сохраняем в БД для синхронизации с ботом
    if (_userId != null) {
      print('💾 Сохраняем preferredLocationId в БД...');
      final success = await SupabaseService.updateUserPreferredLocation(
        userId: _userId!,
        locationId: location.id,
      );
      if (success) {
        print('✅ preferredLocationId сохранен в БД: ${location.id}');
      } else {
        print('⚠️ Не удалось сохранить preferredLocationId в БД');
      }
    } else {
      print('⚠️ userId не установлен, пропускаем сохранение в БД');
    }
  }

  /// Сохраняет ID последней выбранной локации в локальном хранилище
  Future<void> _saveLastLocation(String locationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastLocationKey, locationId);
      print('✅ Сохранена последняя локация в локальном хранилище: $locationId');
    } catch (e) {
      print('⚠️ Ошибка сохранения локации в локальное хранилище: $e');
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

  /// Добавляет локацию в историю посещений
  Future<void> addToRecentLocations(Location location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_recentLocationsKey) ?? [];
      
      // Удаляем дубликаты (если эта локация уже есть в истории)
      historyJson.removeWhere((json) {
        try {
          final map = jsonDecode(json) as Map<String, dynamic>;
          return map['id'] == location.id;
        } catch (e) {
          return false;
        }
      });
      
      // Добавляем новую локацию в начало
      final locationJson = jsonEncode({
        'id': location.id,
        'name': location.name,
        'address': location.address,
        'lat': location.lat,
        'lng': location.lng,
        'timestamp': DateTime.now().toIso8601String(),
      });
      historyJson.insert(0, locationJson);
      
      // Оставляем только последние N локаций
      if (historyJson.length > _maxRecentLocations) {
        historyJson.removeRange(_maxRecentLocations, historyJson.length);
      }
      
      await prefs.setStringList(_recentLocationsKey, historyJson);
      print('✅ Добавлена локация в историю: ${location.name}');
    } catch (e) {
      print('⚠️ Ошибка сохранения в историю: $e');
    }
  }

  /// Получает последние посещенные локации с датами посещений
  Future<Map<Location, DateTime>> getRecentLocationsWithDates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_recentLocationsKey) ?? [];
      
      final recentLocationsMap = <Location, DateTime>{};
      for (final jsonStr in historyJson) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          final locationId = map['id'] as String;
          final timestampStr = map['timestamp'] as String?;
          
          DateTime? visitDate;
          if (timestampStr != null) {
            try {
              visitDate = DateTime.parse(timestampStr);
            } catch (e) {
              visitDate = DateTime.now();
            }
          } else {
            visitDate = DateTime.now();
          }
          
          // Ищем локацию в текущем списке локаций
          try {
            final location = _locations.firstWhere((loc) => loc.id == locationId);
            recentLocationsMap[location] = visitDate;
          } catch (e) {
            // Если локации нет в текущем списке, создаем из сохраненных данных
            final location = Location(
              id: locationId,
              name: map['name'] ?? 'Unknown',
              address: map['address'] ?? '',
              lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
              lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
              rating: 5.0,
              workingHours: map['workingHours'] ?? '',
              isOpen: map['isOpen'] ?? true,
            );
            recentLocationsMap[location] = visitDate;
          }
        } catch (e) {
          print('⚠️ Ошибка парсинга локации из истории: $e');
        }
      }
      
      return recentLocationsMap;
    } catch (e) {
      print('⚠️ Ошибка загрузки истории: $e');
      return {};
    }
  }

  /// Получает последние посещенные локации (для обратной совместимости)
  Future<List<Location>> getRecentLocations() async {
    final map = await getRecentLocationsWithDates();
    return map.keys.toList();
  }
}

