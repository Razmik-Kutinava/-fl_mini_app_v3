import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'terminal_effects.dart';

class ModifierCube extends StatelessWidget {
  final String label;
  final String? emoji;
  final double price;
  final bool isSelected;
  final VoidCallback onTap;
  final String? volume;

  const ModifierCube({
    super.key,
    required this.label,
    this.emoji,
    required this.price,
    required this.isSelected,
    required this.onTap,
    this.volume,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NeonGlow(
        glowColor: isSelected ? AppColors.accent : AppColors.borderPrimary,
        blurRadius: isSelected ? 10 : 0,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accentDarker
                : AppColors.cardBackground,
            borderRadius: BorderRadius.zero, // SHARP CORNERS!
            border: Border.all(
              color: isSelected
                  ? AppColors.borderGlow
                  : AppColors.borderSecondary,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? AppColors.neonGlow : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (emoji != null)
                Text(
                  emoji!,
                  style: const TextStyle(fontSize: 24),
                )
                    .animate(target: isSelected ? 1 : 0)
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
              if (emoji != null) const SizedBox(height: 4),
              Text(
                label.toUpperCase(), // UPPERCASE
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyTiny(
                  isSelected ? AppColors.accent : AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (volume != null) ...[
                const SizedBox(height: 2),
                Text(
                  volume!,
                  style: AppTextStyles.bodyTiny(
                    isSelected ? AppColors.textSecondary : AppColors.textTertiary,
                  ).copyWith(fontSize: 9),
                ),
              ],
              if (price > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '+${price.toStringAsFixed(0)}₽',
                  style: AppTextStyles.bodyTiny(
                    isSelected ? AppColors.textSecondary : AppColors.textTertiary,
                  ).copyWith(fontSize: 9, fontWeight: FontWeight.w600),
                ),
              ] else if (price == 0 && volume == null) ...[
                const SizedBox(height: 2),
                Text(
                  'FREE', // UPPERCASE
                  style: AppTextStyles.bodyTiny(
                    isSelected ? AppColors.textSecondary : AppColors.textTertiary,
                  ).copyWith(fontSize: 8),
                ),
              ],
            ],
          ),
        ),
      )
          .animate(target: isSelected ? 1 : 0)
          .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05))
          .then()
          .shake(duration: 100.ms),
    );
  }
}

