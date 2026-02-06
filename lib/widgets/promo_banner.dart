import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'terminal_effects.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return NeonGlow(
      blurRadius: 20,
      child: Container(
        height: 140,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.gradient2,
          borderRadius: BorderRadius.zero, // SHARP CORNERS!
          border: Border.all(
            color: AppColors.borderGlow,
            width: 1,
          ),
          boxShadow: AppColors.neonGlow,
        ),
        child: Stack(
          children: [
            // Background pattern (terminal style)
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.zero, // SHARP CORNERS!
                  color: AppColors.accent.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.zero, // SHARP CORNERS!
                  color: AppColors.accent.withOpacity(0.1),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BlinkEffect(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentDarker,
                              borderRadius: BorderRadius.zero, // SHARP CORNERS!
                              border: Border.all(
                                color: AppColors.borderGlow,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_fire_department,
                                    color: AppColors.accent, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'АКЦИЯ',
                                  style: AppTextStyles.bodySmall(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '-20%',
                          style: AppTextStyles.h1().copyWith(
                            fontSize: 36,
                            height: 1,
                          ),
                        ).animate()
                            .scale(delay: 200.ms, duration: 600.ms)
                            .then()
                            .shake(duration: 1000.ms),
                        const SizedBox(height: 4),
                        Text(
                          'НА ПЕРВЫЙ ЗАКАЗ', // UPPERCASE
                          style: AppTextStyles.bodySmall(),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.accentDarker,
                      borderRadius: BorderRadius.zero, // SHARP CORNERS!
                      border: Border.all(
                        color: AppColors.borderAccent,
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '☕',
                        style: TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

