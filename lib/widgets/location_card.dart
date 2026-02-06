import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/location.dart';
import 'terminal_effects.dart';

class LocationCard extends StatelessWidget {
  final Location location;
  final VoidCallback onSelect;
  final bool isHighlighted;

  const LocationCard({
    super.key,
    required this.location,
    required this.onSelect,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: NeonGlow(
        glowColor: isHighlighted ? AppColors.accent : AppColors.borderPrimary,
        blurRadius: isHighlighted ? 15 : 0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isHighlighted
                ? AppColors.cardBackground
                : AppColors.statusPanel,
            borderRadius: BorderRadius.zero, // SHARP CORNERS!
            border: Border.all(
              color: isHighlighted
                  ? AppColors.borderGlow
                  : AppColors.borderSecondary,
              width: isHighlighted ? 2 : 1,
            ),
            boxShadow: isHighlighted ? AppColors.neonGlow : null,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accentDarker,
                  borderRadius: BorderRadius.zero, // SHARP CORNERS!
                  border: Border.all(
                    color: isHighlighted
                        ? AppColors.borderGlow
                        : AppColors.borderAccent,
                    width: 1,
                  ),
                  boxShadow: isHighlighted ? AppColors.neonGlow : null,
                ),
                child: Icon(
                  Icons.coffee,
                  color: AppColors.accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      location.name.toUpperCase(), // UPPERCASE
                      style: AppTextStyles.h3(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location.address,
                      style: AppTextStyles.bodyTiny(AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.star, color: AppColors.textHighlight, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          location.rating.toString(),
                          style: AppTextStyles.bodyTiny(),
                        ),
                        const SizedBox(width: 8),
                        Text('•', style: AppTextStyles.bodyTiny(AppColors.textSecondary)),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: location.isOpen ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location.workingHours,
                          style: AppTextStyles.bodyTiny(
                            location.isOpen ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (location.distance != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentDarker,
                        borderRadius: BorderRadius.zero, // SHARP CORNERS!
                        border: Border.all(
                          color: AppColors.borderAccent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${location.distance!.toStringAsFixed(1)} KM', // UPPERCASE
                        style: AppTextStyles.bodyTiny(),
                      ),
                    ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onSelect,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.accentDarker,
                        borderRadius: BorderRadius.zero, // SHARP CORNERS!
                        border: Border.all(
                          color: isHighlighted
                              ? AppColors.borderGlow
                              : AppColors.borderAccent,
                          width: 1,
                        ),
                        boxShadow: isHighlighted ? AppColors.neonGlow : null,
                      ),
                      child: Text(
                        'SELECT', // UPPERCASE
                        style: AppTextStyles.bodySmall(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
