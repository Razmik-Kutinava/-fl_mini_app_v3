import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/product.dart';
import '../screens/product_modifiers_screen.dart';
import 'terminal_effects.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        print('Opening ProductModifiersScreen for: ${product.name}');
        print('Product modifiers: ${product.modifiers}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductModifiersScreen(product: product),
          ),
        );
      },
      behavior: HitTestBehavior.translucent,
      child: NeonGlow(
        child: Container(
          decoration: BoxDecoration(
            // Прямые углы (без borderRadius)
            color: AppColors.cardBackground,
            border: Border.all(
              color: AppColors.borderSecondary,
              width: 1,
            ),
            boxShadow: AppColors.neonGlow,
          ),
          child: Stack(
            children: [
              // Image
              product.imageUrl.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        color: AppColors.accentDarker,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.coffee,
                          size: 50,
                          color: AppColors.accent.withOpacity(0.5),
                        ),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Shimmer.fromColors(
                        baseColor: AppColors.accentDarker,
                        highlightColor: AppColors.accentMedium,
                        child: Container(
                          color: AppColors.background,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          color: AppColors.accentDarker,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.coffee,
                            size: 50,
                            color: AppColors.accent.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
              // Терминальный overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground.withOpacity(0.95),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.borderGlow,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Код продукта
                      Text(
                        '[CODE: ${product.id.substring(0, 3).toUpperCase()}]',
                        style: AppTextStyles.bodyTiny(AppColors.textTertiary),
                      ),
                      const SizedBox(height: 4),
                      // Название (UPPERCASE)
                      Text(
                        product.name.toUpperCase(),
                        style: AppTextStyles.h3(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Цена
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentDarker,
                              border: Border.all(
                                color: AppColors.borderAccent,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${product.price.toStringAsFixed(0)} ₽',
                              style: AppTextStyles.price(),
                            ),
                          ),
                          // Кнопка добавления
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.accentDarker,
                              border: Border.all(
                                color: AppColors.borderGlow,
                                width: 1,
                              ),
                              boxShadow: AppColors.neonGlow,
                            ),
                            child: Icon(
                              Icons.add,
                              color: AppColors.accent,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ],
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
