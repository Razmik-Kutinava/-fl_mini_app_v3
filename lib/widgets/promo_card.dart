import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'terminal_effects.dart';

class PromoCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String? emoji;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const PromoCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.emoji,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: NeonGlow(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.zero, // SHARP CORNERS!
            border: Border.all(
              color: AppColors.borderGlow,
              width: 1,
            ),
            boxShadow: AppColors.neonGlow,
          ),
          child: Stack(
            children: [
              // Фоновое изображение или градиент
              if (imageUrl != null && imageUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Shimmer.fromColors(
                    baseColor: AppColors.accentDarker,
                    highlightColor: AppColors.accentMedium,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: gradient ?? AppColors.promoCardGradient1,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: gradient ?? AppColors.promoCardGradient1,
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: gradient ?? AppColors.promoCardGradient1,
                  ),
                ),

              // Декоративные элементы (эмодзи)
              if (emoji != null)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Text(
                    emoji!,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),

              // Градиентная подложка для текста
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.background.withOpacity(0.9),
                      ],
                    ),
                  ),
                ),
              ),

              // Название промо
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.borderGlow,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    title.toUpperCase(), // UPPERCASE для терминального стиля
                    style: AppTextStyles.h3(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

