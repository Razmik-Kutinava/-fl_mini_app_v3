import 'package:flutter/material.dart';

/// 🖥️ ТЕРМИНАЛЬНАЯ ЦВЕТОВАЯ ПАЛИТРА (стиль хакерского терминала 90-х)
class AppColors {
  // Основные цвета терминала
  static const background = Color(0xFF0A0A0A); // Чёрный фон (не #000!)
  static const accent = Color(0xFF00FF00); // Неоново-зелёный
  static const accentDark = Color(0xFF00CC00); // Тёмно-зелёный
  static const accentDarker = Color(0xFF006600); // Очень тёмно-зелёный
  static const accentMedium = Color(0xFF008800); // Средне-зелёный
  
  // Текст
  static const textPrimary = Color(0xFF00FF00); // Основной текст (неоновый)
  static const textSecondary = Color(0xFF00CC00); // Второстепенный текст
  static const textTertiary = Color(0xFF006600); // Третичный текст
  static const textHighlight = Color(0xFFFFFF00); // Жёлтый для активных статусов
  
  // Границы
  static const borderPrimary = Color(0xFF004400);
  static const borderSecondary = Color(0xFF006600);
  static const borderAccent = Color(0xFF008800);
  static const borderGlow = Color(0xFF00FF00);
  
  // Карточки и поверхности
  static const cardBackground = Color(0x1A001E00); // rgba(0, 30, 0, 0.2)
  static const hoverBackground = Color(0x0D00FF00); // rgba(0, 255, 0, 0.05)
  static const statusPanel = Color(0x4D001400); // rgba(0, 20, 0, 0.3)
  
  // Статусы
  static const success = Color(0xFF00FF00);
  static const error = Color(0xFFFF0000); // Красный для ошибок
  static const warning = Color(0xFFFFFF00); // Жёлтый
  
  // Для обратной совместимости (старые названия)
  static const primary = accent;
  static const primaryDark = accentDark;
  static const accentOrange = textHighlight;
  static const surface = cardBackground;

  // Градиенты для прогресс-баров (только горизонтальные)
  static const progressGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF006600), Color(0xFF00FF00)],
  );
  
  // Для обратной совместимости
  static const gradient1 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentDarker, accent],
  );

  static const gradient2 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentMedium, accent],
  );

  static const gradientCoffee = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentDarker, accentMedium],
  );

  // Hero Banner (терминальный стиль)
  static const heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF001E00), // Тёмно-зелёный
      Color(0xFF003300), // Средне-тёмный
      Color(0xFF0A0A0A), // Чёрный фон
    ],
  );

  // Promo colors (терминальный стиль)
  static const promoCardGradient1 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF004400), Color(0xFF00FF00)],
  );

  static const promoCardGradient2 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF006600), Color(0xFF00CC00)],
  );
  
  static const promoCardGradient3 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF008800), Color(0xFF00FF00)],
  );
  
  static const promoCardGradient4 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF004400), Color(0xFF008800)],
  );
  
  static const promoCardGradientSpring = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF006600), Color(0xFF00CC00), Color(0xFF00FF00)],
  );

  // Bottom Navigation colors (терминальный стиль)
  static const bottomNavActive = accent;
  static const bottomNavInactive = accentDarker;
  static const bottomNavBackground = background;

  // Location Status colors
  static const locationStatusClosed = accentDarker;
  static const locationStatusOpen = accent;
  
  // Неоновое свечение для теней
  static List<BoxShadow> get neonGlow => [
    BoxShadow(
      color: accent.withValues(alpha: 0.2),
      blurRadius: 10,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get neonGlowStrong => [
    BoxShadow(
      color: accent.withValues(alpha: 0.4),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
}

