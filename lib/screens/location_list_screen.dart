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
  List<Location> _recentLocations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentLocations();
  }

  Future<void> _loadRecentLocations() async {
    final locationProvider = context.read<LocationProvider>();
    final recent = await locationProvider.getRecentLocations();
    
    // Если истории нет, показываем все доступные локации
    if (recent.isEmpty) {
      setState(() {
        _recentLocations = locationProvider.locations;
        _isLoading = false;
      });
    } else {
      setState(() {
        _recentLocations = recent;
        _isLoading = false;
      });
    }
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
          : _recentLocations.isEmpty
              ? Center(
                  child: Text(
                    'Нет последних кофеен',
                    style: GoogleFonts.montserrat(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _recentLocations.length,
                  itemBuilder: (context, index) {
                    final location = _recentLocations[index];
                    return _buildLocationItem(location);
                  },
                ),
    );
  }

  Widget _buildLocationItem(Location location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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

