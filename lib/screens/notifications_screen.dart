import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'location_select_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _enableNotifications(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', true);
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LocationSelectScreen()),
      );
    }
  }

  void _skip(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LocationSelectScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradient2),
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
                    Icons.notifications_active,
                    size: 64,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),
                const SizedBox(height: 40),
                Text(
                  'Разрешите отправлять\nуведомления',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h1(Colors.white),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                const SizedBox(height: 16),
                Text(
                  'Мы сообщим когда заказ готов',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall(Colors.white.withOpacity(0.8)),
                ).animate().fadeIn(delay: 400.ms),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _enableNotifications(context),
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
                          'Разрешить уведомления',
                          style: AppTextStyles.button(),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _skip(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      side: BorderSide(
                        color: AppColors.borderPrimary,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    'Пропустить',
                    style: AppTextStyles.button(),
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

