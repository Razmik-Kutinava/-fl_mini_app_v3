import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/location_provider.dart';
import 'notifications_screen.dart';
import 'location_select_screen.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  Future<void> _requestLocation(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сервис геолокации отключён')),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Разрешение отклонено')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Разрешение навсегда отклонено')),
        );
      }
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    if (context.mounted) {
      context.read<LocationProvider>().setUserPosition(position);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradient1),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 64,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),
                const SizedBox(height: 40),
                Text(
                  'Разрешите доступ\nк геолокации',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h1(Colors.white),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                const SizedBox(height: 16),
                Text(
                  'Чтобы показать ближайшие кофейни',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall(Colors.white.withOpacity(0.8)),
                ).animate().fadeIn(delay: 400.ms),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _requestLocation(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentDarker,
                      foregroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide(
                          color: AppColors.borderGlow,
                          width: 1,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, size: 24, color: AppColors.accent),
                        const SizedBox(width: 12),
                        Text(
                          'Разрешить доступ',
                          style: AppTextStyles.button(),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LocationSelectScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Выбрать вручную',
                    style: AppTextStyles.button(AppColors.accent).copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.accent,
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

