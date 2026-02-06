import 'package:flutter/material.dart';
import 'dart:ui';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/location.dart';
import '../utils/responsive.dart';
import 'terminal_effects.dart';

class LocationAppBar extends StatelessWidget {
  final Location? location;
  final VoidCallback? onLocationTap;
  final VoidCallback? onProfileTap;

  const LocationAppBar({
    super.key,
    this.location,
    this.onLocationTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    // Адаптивные размеры
    final iconSize = Responsive.responsiveSize(
      context,
      mobile: 40.0,
      tablet: 44.0,
      desktop: 48.0,
    );
    
    final iconInnerSize = Responsive.responsiveSize(
      context,
      mobile: 22.0,
      tablet: 24.0,
      desktop: 26.0,
    );
    
    final padding = Responsive.responsiveSize(
      context,
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
    );

    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: Responsive.responsiveSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
        ),
        child: TerminalBorder(
          borderColor: AppColors.borderGlow,
          borderWidth: 1,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.statusPanel,
            ),
            child: Row(
              children: [
                // Иконка локации (терминальный стиль)
                GestureDetector(
                  onTap: onLocationTap,
                  child: NeonGlow(
                    child: Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: AppColors.accentDarker,
                        border: Border.all(
                          color: AppColors.borderGlow,
                          width: 1,
                        ),
                        boxShadow: AppColors.neonGlow,
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: AppColors.accent,
                        size: iconInnerSize,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Название локации и статус (кликабельно)
                Expanded(
                  child: GestureDetector(
                    onTap: onLocationTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          location?.name.toUpperCase() ?? 'КОФЕЙНЯ',
                          style: AppTextStyles.h3(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        // Статус бейдж
                        _buildStatusBadge(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Иконка профиля
                GestureDetector(
                  onTap: onProfileTap,
                  child: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: AppColors.accentDarker,
                      border: Border.all(
                        color: AppColors.borderSecondary,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: AppColors.textSecondary,
                      size: iconInnerSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isOpen = location?.isOpen ?? false;
    String statusText;
    
    if (isOpen) {
      statusText = 'открыто';
    } else {
      // Парсим workingHours для получения времени открытия
      final workingHours = location?.workingHours ?? '';
      if (workingHours.isNotEmpty) {
        // Попытка извлечь время открытия из строки
        final timeMatch = RegExp(r'(\d{2}):(\d{2})').firstMatch(workingHours);
        if (timeMatch != null) {
          final time = timeMatch.group(0);
          statusText = 'откроемся завтра в $time';
        } else {
          statusText = 'откроемся завтра в 08:00';
        }
      } else {
        statusText = 'откроемся завтра в 08:00';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(
          color: isOpen ? AppColors.borderGlow : AppColors.borderSecondary,
          width: 1,
        ),
      ),
      child: BlinkEffect(
        child: Text(
          statusText.toUpperCase(),
          style: AppTextStyles.bodyTiny(
            isOpen ? AppColors.accent : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

