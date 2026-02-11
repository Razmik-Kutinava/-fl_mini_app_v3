import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// 🖥️ ТЕРМИНАЛЬНЫЕ ТЕКСТОВЫЕ СТИЛИ (моноширинные шрифты)
class AppTextStyles {
  // Моноширинные шрифты (JetBrains Mono как основной)
  static TextStyle _mono({required double fontSize, required FontWeight fontWeight, Color? color}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.textPrimary,
      letterSpacing: fontSize >= 28 ? 2.0 : (fontSize >= 18 ? 1.0 : 0.5),
    );
  }
  
  // Заголовки (UPPERCASE)
  static TextStyle h1([Color? color]) => _mono(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: color,
  ).copyWith(
    shadows: [
      Shadow(
        color: AppColors.accent.withValues(alpha: 0.5),
        blurRadius: 10,
      ),
    ],
  );

  static TextStyle h2([Color? color]) => _mono(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: color,
  );

  static TextStyle h3([Color? color]) => _mono(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: color,
  );

  // Основной текст
  static TextStyle body([Color? color]) => _mono(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: color,
  );

  static TextStyle bodySmall([Color? color]) => _mono(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: color ?? AppColors.textSecondary,
  );

  static TextStyle bodyTiny([Color? color]) => _mono(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: color ?? AppColors.textTertiary,
  );

  // Цена
  static TextStyle price([Color? color]) => _mono(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: color ?? AppColors.accent,
  );

  // Кнопки
  static TextStyle button([Color? color]) => _mono(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: color ?? AppColors.textPrimary,
  );

  // Системные сообщения
  static TextStyle system([Color? color]) => _mono(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: color ?? AppColors.textSecondary,
  );

  // Статусы (с миганием)
  static TextStyle status([Color? color]) => _mono(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: color ?? AppColors.textHighlight,
  );

  // Командная строка
  static TextStyle command([Color? color]) => _mono(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: color ?? AppColors.accent,
  );
  
  // Планшетная версия - специфичные стили
  static TextStyle tabletH1([Color? color]) => _mono(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: color,
  ).copyWith(
    letterSpacing: 2.0,
    shadows: AppColors.textGlow,
  );
  
  static TextStyle tabletPrice([Color? color]) => _mono(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: color ?? AppColors.accent,
  );
  
  static TextStyle tabletButton([Color? color]) => _mono(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: color ?? AppColors.textPrimary,
  );
  
  static TextStyle tabletCategoryLabel([Color? color]) => _mono(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: color ?? AppColors.textTertiary,
  ).copyWith(letterSpacing: 2.0);
  
  static TextStyle tabletTerminal([Color? color]) => _mono(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: color ?? AppColors.textTertiary,
  );
  
  // Для обратной совместимости (старые стили)
  static TextStyle get oldH1 => h1();
  static TextStyle get oldH2 => h2();
  static TextStyle get oldH3 => h3();
  static TextStyle get oldBody => body();
  static TextStyle get oldBodySmall => bodySmall();
  static TextStyle get oldPrice => price();
  static TextStyle get oldButton => button();
}

