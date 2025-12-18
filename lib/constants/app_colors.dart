import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF667EEA);
  static const primaryDark = Color(0xFF764BA2);
  static const accent = Color(0xFFFF6B7A);
  static const accentOrange = Color(0xFFFF9D4C);
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF757575);
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFE53935);

  static const gradient1 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
  );

  static const gradient2 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B7A), Color(0xFFFF9D4C)],
  );

  static const gradientCoffee = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5A2B), Color(0xFFD2691E)],
  );
}

