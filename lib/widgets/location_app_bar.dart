import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/location.dart';
import '../utils/responsive.dart';

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
    
    final fontSize = Responsive.responsiveSize(
      context,
      mobile: 16.0,
      tablet: 18.0,
      desktop: 20.0,
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Иконка локации (синяя круглая)
                  GestureDetector(
                    onTap: onLocationTap,
                    child: Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: AppColors.bottomNavActive, // Синий цвет
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.bottomNavActive.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: iconInnerSize,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Название локации и статус
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          location?.name ?? 'Кофейня',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        // Статус бейдж
                        _buildStatusBadge(),
                      ],
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
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: AppColors.textPrimary,
                        size: iconInnerSize,
                      ),
                    ),
                  ),
                ],
              ),
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
        color: isOpen
            ? AppColors.locationStatusOpen.withOpacity(0.1)
            : AppColors.locationStatusClosed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isOpen
              ? AppColors.locationStatusOpen
              : AppColors.locationStatusClosed,
        ),
      ),
    );
  }
}

