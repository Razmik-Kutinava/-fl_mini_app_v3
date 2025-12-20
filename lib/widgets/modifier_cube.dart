import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';

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
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: isSelected
              ? AppColors.gradient1
              : null,
          color: isSelected ? null : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
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
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (volume != null) ...[
              const SizedBox(height: 2),
              Text(
                volume!,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: isSelected ? Colors.white70 : Colors.grey[600]!,
                ),
              ),
            ],
            if (price > 0) ...[
              const SizedBox(height: 2),
              Text(
                '+${price.toStringAsFixed(0)}₽',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white70 : Colors.grey[700]!,
                ),
              ),
            ] else if (price == 0 && volume == null) ...[
              const SizedBox(height: 2),
              Text(
                'Бесплатно',
                style: GoogleFonts.inter(
                  fontSize: 8,
                  color: isSelected ? Colors.white70 : Colors.grey[600]!,
                ),
              ),
            ],
          ],
        ),
      )
          .animate(target: isSelected ? 1 : 0)
          .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05))
          .then()
          .shake(duration: 100.ms),
    );
  }
}

