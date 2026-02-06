import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'terminal_effects.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NeonGlow(
        glowColor: isSelected ? AppColors.accent : AppColors.accentDarker,
        blurRadius: isSelected ? 10 : 0,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            // Прямые углы
            color: isSelected
                ? AppColors.accentDarker
                : AppColors.cardBackground,
            border: Border.all(
              color: isSelected
                  ? AppColors.borderGlow
                  : AppColors.borderSecondary,
              width: 1,
            ),
            boxShadow: isSelected ? AppColors.neonGlow : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(), // UPPERCASE для терминального стиля
                style: AppTextStyles.bodySmall(
                  isSelected ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

