import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_colors.dart';
import '../models/location.dart';
import '../providers/location_provider.dart';
import '../services/api_service.dart';
import '../widgets/location_card.dart';
import 'main_screen.dart';

class LocationSelectScreen extends StatefulWidget {
  const LocationSelectScreen({super.key});

  @override
  State<LocationSelectScreen> createState() => _LocationSelectScreenState();
}

class _LocationSelectScreenState extends State<LocationSelectScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();
  bool _isLoading = true;
  Location? _selectedLocationOnMap;

  @override
  void initState() {
    super.initState();
    _requestUserLocation();
    _loadLocations();
  }

  /// Запрос геолокации пользователя
  Future<void> _requestUserLocation() async {
    try {
      final locationProvider = context.read<LocationProvider>();
      // Если геолокация уже есть, не запрашиваем снова
      if (locationProvider.userPosition != null) return;
      
      // Проверяем разрешение
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      
      // Получаем текущую позицию
      if (await Geolocator.isLocationServiceEnabled()) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        if (mounted) {
          locationProvider.setUserPosition(position);
        }
      }
    } catch (e) {
      print('Error getting user location: $e');
    }
  }

  Future<void> _loadLocations() async {
    final locations = await _apiService.getLocations();
    if (mounted) {
      context.read<LocationProvider>().setLocations(locations);
      setState(() => _isLoading = false);
      
      // Показываем все точки на карте
      final validLocations = locations.where((loc) => loc.lat != 0 && loc.lng != 0).toList();
      if (validLocations.isNotEmpty) {
        // Используем fitBounds для показа всех точек
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitBounds(validLocations);
        });
      }
    }
  }

  /// Вычисляет границы всех точек и устанавливает карту так, чтобы все были видны
  void _fitBounds(List<Location> locations) {
    if (locations.isEmpty) {
      print('⚠️ No valid locations to fit bounds');
      return;
    }
    
    print('🗺️ Fitting bounds for ${locations.length} locations');
    for (var loc in locations) {
      print('  - ${loc.name}: lat=${loc.lat}, lng=${loc.lng}');
    }
    
    final userPos = context.read<LocationProvider>().userPosition;
    final allPoints = <LatLng>[];
    
    // Добавляем все точки локаций
    for (var loc in locations) {
      if (loc.lat != 0 && loc.lng != 0) {
        allPoints.add(LatLng(loc.lat, loc.lng));
        print('  ✅ Added point: ${loc.name} at (${loc.lat}, ${loc.lng})');
      } else {
        print('  ❌ Skipped point: ${loc.name} - invalid coordinates');
      }
    }
    
    // Добавляем позицию пользователя, если есть
    if (userPos != null) {
      allPoints.add(LatLng(userPos.latitude, userPos.longitude));
      print('  ✅ Added user position: (${userPos.latitude}, ${userPos.longitude})');
    }
    
    if (allPoints.isEmpty) {
      print('⚠️ No valid points to display');
      return;
    }
    
    // Вычисляем границы
    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;
    
    for (var point in allPoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }
    
    // Вычисляем центр
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    
    // Вычисляем оптимальный зум на основе разницы координат
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    
    // Вычисляем зум
    double zoom;
    if (maxDiff > 50) {
      zoom = 2.0; // Весь мир
    } else if (maxDiff > 20) {
      zoom = 3.0; // Континент
    } else if (maxDiff > 10) {
      zoom = 4.0; // Большая страна
    } else if (maxDiff > 5) {
      zoom = 5.0; // Страна
    } else if (maxDiff > 2) {
      zoom = 6.0; // Регион
    } else if (maxDiff > 1) {
      zoom = 7.0; // Область
    } else if (maxDiff > 0.5) {
      zoom = 9.0; // Город
    } else if (maxDiff > 0.1) {
      zoom = 11.0; // Район
    } else {
      zoom = 13.0; // Несколько точек рядом
    }
    
    // Добавляем padding (немного уменьшаем зум для лучшего отображения)
    zoom = zoom - 0.5;
    if (zoom < 1.0) zoom = 1.0;
    
    // Устанавливаем карту
    print('🗺️ Setting map center: ($centerLat, $centerLng) with zoom: $zoom');
    print('🗺️ Bounds: lat=[$minLat, $maxLat], lng=[$minLng, $maxLng], diff=$maxDiff');
    
    _mapController.move(
      LatLng(centerLat, centerLng),
      zoom,
    );
    
    print('✅ Map updated successfully');
  }

  void _selectLocation(Location location) {
    context.read<LocationProvider>().selectLocation(location);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  LatLng _getCenterPoint(List<Location> locations) {
    final validLocations = locations.where((loc) => loc.lat != 0 && loc.lng != 0).toList();
    
    if (validLocations.isEmpty) {
      final userPos = context.read<LocationProvider>().userPosition;
      if (userPos != null) {
        return LatLng(userPos.latitude, userPos.longitude);
      }
      // Fallback: центр мира
      return const LatLng(40.0, 50.0);
    }
    
    // Вычисляем центр всех точек
    double sumLat = 0, sumLng = 0;
    int count = 0;
    for (var loc in validLocations) {
      sumLat += loc.lat;
      sumLng += loc.lng;
      count++;
    }
    
    if (count > 0) {
      return LatLng(sumLat / count, sumLng / count);
    }
    
    return const LatLng(40.0, 50.0);
  }

  double _getInitialZoom(List<Location> locations) {
    final validLocations = locations.where((loc) => loc.lat != 0 && loc.lng != 0).toList();
    
    if (validLocations.length <= 1) {
      return 13.0; // Одна точка - показываем крупно
    }
    
    // Вычисляем разброс точек
    double minLat = validLocations.first.lat;
    double maxLat = validLocations.first.lat;
    double minLng = validLocations.first.lng;
    double maxLng = validLocations.first.lng;
    
    for (var loc in validLocations) {
      if (loc.lat < minLat) minLat = loc.lat;
      if (loc.lat > maxLat) maxLat = loc.lat;
      if (loc.lng < minLng) minLng = loc.lng;
      if (loc.lng > maxLng) maxLng = loc.lng;
    }
    
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    
    // Определяем зум на основе разброса
    if (maxDiff > 50) return 2.0; // Весь мир
    if (maxDiff > 20) return 3.0; // Континент
    if (maxDiff > 10) return 4.0; // Большая страна
    if (maxDiff > 5) return 5.0; // Страна
    if (maxDiff > 2) return 6.0; // Регион
    if (maxDiff > 1) return 7.0; // Область
    if (maxDiff > 0.5) return 9.0; // Город
    if (maxDiff > 0.1) return 11.0; // Район
    return 13.0; // Несколько точек рядом
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final locations = locationProvider.locations;
    final centerPoint = _getCenterPoint(locations);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerPoint,
              initialZoom: _getInitialZoom(locations),
              minZoom: 1.0, // Минимальный зум для показа всего мира
              maxZoom: 18.0,
              onTap: (tapPosition, point) {
                setState(() => _selectedLocationOnMap = null);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.fl_mini_app_v3',
                maxZoom: 19,
              ),
              // Markers
              MarkerLayer(
                markers: locations
                    .where((loc) => loc.lat != 0 && loc.lng != 0)
                    .map((location) {
                  final isSelected = _selectedLocationOnMap?.id == location.id;
                  return Marker(
                    point: LatLng(location.lat, location.lng),
                    width: isSelected ? 60 : 50,
                    height: isSelected ? 60 : 50,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedLocationOnMap = location);
                        _mapController.move(
                          LatLng(location.lat, location.lng),
                          15.0,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent : AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: (isSelected ? AppColors.accent : AppColors.primary)
                                  .withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.coffee,
                            color: Colors.white,
                            size: isSelected ? 28 : 24,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              // User location marker
              if (locationProvider.userPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        locationProvider.userPosition!.latitude,
                        locationProvider.userPosition!.longitude,
                      ),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Top gradient overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background,
                    AppColors.background.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // App Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GlassmorphicContainer(
                width: double.infinity,
                height: 60,
                borderRadius: 20,
                blur: 20,
                alignment: Alignment.center,
                border: 2,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.5),
                    Colors.white.withOpacity(0.2),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        'Выбор кофейни',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ).animate().fadeIn().slideY(begin: -0.3),
          ),
          // Search bar
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: GlassmorphicContainer(
              width: double.infinity,
              height: 56,
              borderRadius: 16,
              blur: 20,
              alignment: Alignment.center,
              border: 2,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.7),
                ],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.8),
                  Colors.white.withOpacity(0.5),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Поиск по адресу',
                  hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2),
          ),
          // Bottom sheet with locations
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            'Кофейни рядом',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: AppColors.gradient1,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${locations.length}',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Locations list
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: locations.length,
                              itemBuilder: (context, index) {
                                final location = locations[index];
                                final isSelected = _selectedLocationOnMap?.id == location.id;
                                return LocationCard(
                                  location: location,
                                  onSelect: () => _selectLocation(location),
                                  isHighlighted: isSelected,
                                ).animate(delay: Duration(milliseconds: 100 * index))
                                    .fadeIn()
                                    .slideX(begin: 0.2);
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
