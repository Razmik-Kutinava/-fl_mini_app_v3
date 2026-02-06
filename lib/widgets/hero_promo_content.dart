import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/responsive.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_colors.dart';

class HeroPromoContent extends StatelessWidget {
  final String? title;
  final String? subtitle;

  const HeroPromoContent({
    super.key,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Адаптивная высота баннера - уменьшена для карусели
    final bannerHeight = Responsive.isMobile(context)
        ? screenHeight * 0.40
        : Responsive.isTablet(context)
            ? screenHeight * 0.38
            : screenHeight * 0.35;

    // Адаптивные размеры текста
    final subtitleFontSize = Responsive.responsiveSize(
      context,
      mobile: 16.0,
      tablet: 18.0,
      desktop: 20.0,
    );

    final padding = Responsive.responsiveSize(
      context,
      mobile: 24.0,
      tablet: 32.0,
      desktop: 48.0,
    );

    return Container(
      height: bannerHeight,
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: Responsive.responsiveSize(context, mobile: 20.0, tablet: 24.0, desktop: 32.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),
          // Большой текст промо - убран по требованию
          // Text(
          //   title ?? 'Каждому другу – по\nподарку! Выбирай и\nотправляй',
          //   ...
          // ),
          const SizedBox(height: 16),
          // Подзаголовок (опционально)
          if (subtitle != null)
            Text(
              subtitle!.toUpperCase(), // UPPERCASE для терминального стиля
              style: AppTextStyles.body(AppColors.accent).copyWith(
                fontSize: subtitleFontSize,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 0),
                    blurRadius: 10,
                    color: AppColors.accent.withOpacity(0.5),
                  ),
                ],
              ),
            ).animate()
                .fadeIn(delay: 300.ms, duration: 600.ms)
                .slideY(begin: 0.2, end: 0, delay: 300.ms, duration: 600.ms),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

