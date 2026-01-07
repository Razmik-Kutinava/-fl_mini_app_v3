import 'package:flutter/material.dart';

/// Утилиты для адаптивного дизайна
class Responsive {
  // Брейкпоинты
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  /// Проверяет, является ли экран мобильным (< 600px)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Проверяет, является ли экран планшетом (600-1024px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Проверяет, является ли экран десктопом (> 1024px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Возвращает адаптивный размер на основе размера экрана
  static double responsiveSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet ?? mobile * 1.2;
    return desktop ?? mobile * 1.5;
  }

  /// Возвращает адаптивное количество колонок для GridView
  static int responsiveCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 2; // Mobile
    if (width < tabletBreakpoint) return 3; // Tablet
    if (width < 1400) return 4; // Desktop средний
    return 5; // Desktop большой
  }

  /// Возвращает ширину экрана
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Возвращает высоту экрана
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}

