import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
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

  @override
  void didUpdateWidget(LocationListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Обновляем список при обновлении виджета
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final locationProvider = context.read<LocationProvider>();

    print('📋 Загрузка списка кофеен...');

    // Загружаем последние посещенные кофейни с датами
    final recentWithDates = await locationProvider
        .getRecentLocationsWithDates();
    print('📋 Найдено последних кофеен: ${recentWithDates.length}');

    // Загружаем все доступные кофейни
    final allLocations = locationProvider.locations;
    print('📋 Всего доступно кофеен: ${allLocations.length}');

    // Фильтруем: оставляем все кофейни, которых нет в списке последних
    final recentIds = recentWithDates.keys.map((loc) => loc.id).toSet();
    final otherLocations = allLocations
        .where((loc) => !recentIds.contains(loc.id))
        .toList();

    print('📋 Кофеен в секции "Все кофейни": ${otherLocations.length}');

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
      MaterialPageRoute(builder: (_) => LocationMapScreen(location: location)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
          style: AppTextStyles.h2(AppColors.accent),
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
                        style: AppTextStyles.h2(AppColors.accent),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final entry = _recentLocationsWithDates.entries.elementAt(
                        index,
                      );
                      final location = entry.key;
                      final visitDate = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: _buildLocationItem(
                          location,
                          visitDate: visitDate,
                        ),
                      );
                    }, childCount: _recentLocationsWithDates.length),
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
                    padding: EdgeInsets.fromLTRB(
                      16,
                      _recentLocationsWithDates.isEmpty ? 16 : 0,
                      16,
                      8,
                    ),
                    child: Text(
                      'Все кофейни',
                      style: AppTextStyles.h2(AppColors.accent),
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
                          style: AppTextStyles.body(AppColors.accent),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final location = _allLocations[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: _buildLocationItem(location),
                      );
                    }, childCount: _allLocations.length),
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
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location.name, style: AppTextStyles.h3(AppColors.accent)),
                const SizedBox(height: 4),
                Text(
                  location.address,
                  style: AppTextStyles.bodySmall(AppColors.accent),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      location.isOpen ? 'открыто' : 'откроемся завтра в 08:00',
                      style: AppTextStyles.bodyTiny(),
                    ),
                    if (visitDateText != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: AppTextStyles.bodyTiny(AppColors.accent),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        visitDateText,
                        style: AppTextStyles.bodyTiny(AppColors.accent),
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
