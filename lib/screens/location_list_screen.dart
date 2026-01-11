import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/location.dart';
import '../providers/location_provider.dart';
import 'location_map_screen.dart';

class LocationListScreen extends StatefulWidget {
  const LocationListScreen({super.key});

  @override
  State<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  Map<Location, DateTime> _recentLocationsWithDates = {};
  List<Location> _allLocations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final locationProvider = context.read<LocationProvider>();
    
    // Загружаем последние посещенные кофейни с датами
    final recentWithDates = await locationProvider.getRecentLocationsWithDates();
    
    // Загружаем все доступные кофейни
    final allLocations = locationProvider.locations;
    
    // Фильтруем: оставляем все кофейни, которых нет в списке последних
    final recentIds = recentWithDates.keys.map((loc) => loc.id).toSet();
    final otherLocations = allLocations
        .where((loc) => !recentIds.contains(loc.id))
        .toList();
    
    setState(() {
      _recentLocationsWithDates = recentWithDates;
      _allLocations = otherLocations;
      _isLoading = false;
    });
  }

  void _navigateToMainMenu() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openLocationMap(Location location) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LocationMapScreen(location: location),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: _navigateToMainMenu,
          ),
        ),
        title: Text(
          'Последние кофейни',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Секция последних кофеен
                if (_recentLocationsWithDates.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Последние кофейни',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = _recentLocationsWithDates.entries.elementAt(index);
                        final location = entry.key;
                        final visitDate = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: _buildLocationItem(location, visitDate: visitDate),
                        );
                      },
                      childCount: _recentLocationsWithDates.length,
                    ),
                  ),
                  // Разделитель между секциями
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      height: 1,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
                // Секция всех работающих кофеен
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, _recentLocationsWithDates.isEmpty ? 16 : 0, 16, 8),
                    child: Text(
                      'Все кофейни',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (_allLocations.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Нет доступных кофеен',
                          style: GoogleFonts.montserrat(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final location = _allLocations[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: _buildLocationItem(location),
                        );
                      },
                      childCount: _allLocations.length,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildLocationItem(Location location, {DateTime? visitDate}) {
    // Форматируем дату посещения
    String? visitDateText;
    if (visitDate != null) {
      final now = DateTime.now();
      final difference = now.difference(visitDate);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          visitDateText = '${difference.inMinutes} мин назад';
        } else {
          visitDateText = '${difference.inHours} ч назад';
        }
      } else if (difference.inDays == 1) {
        visitDateText = 'Вчера';
      } else if (difference.inDays < 7) {
        visitDateText = '${difference.inDays} дн назад';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        visitDateText = '$weeks нед назад';
      } else {
        final months = (difference.inDays / 30).floor();
        visitDateText = '$months мес назад';
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location.address,
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      location.isOpen
                          ? 'открыто'
                          : 'откроемся завтра в 08:00',
                      style: GoogleFonts.montserrat(
                        color: location.isOpen
                            ? AppColors.locationStatusOpen
                            : AppColors.locationStatusClosed,
                        fontSize: 12,
                      ),
                    ),
                    if (visitDateText != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: GoogleFonts.montserrat(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        visitDateText,
                        style: GoogleFonts.montserrat(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Кнопка с иконкой карты
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.bottomNavActive,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.map, color: Colors.white, size: 24),
              onPressed: () => _openLocationMap(location),
            ),
          ),
        ],
      ),
    );
  }
}

