import 'package:flutter/material.dart';
import 'promo_card.dart';
import '../models/product.dart';
import 'product_card.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class PromoSection extends StatelessWidget {
  final List<PromoItem> promotions;
  final List<Product> products;

  const PromoSection({
    super.key,
    required this.promotions,
    this.products = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Первая акция "Весеннее настроение" - всегда первая
    final firstPromo = promotions.isNotEmpty ? promotions[0] : null;
    // Первые два товара из категории
    final firstTwoProducts = products.take(2).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок "акции"
          Text(
            'АКЦИИ', // UPPERCASE для терминального стиля
            style: AppTextStyles.h1(),
          ),
          const SizedBox(height: 16),
          
          // Первая акция "Весеннее настроение" - одна в строке, квадратик
          if (firstPromo != null)
            Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final padding = 16.0 * 2; // горизонтальный padding контейнера
                final cardWidth = screenWidth - padding;
                return SizedBox(
                  width: double.infinity,
                  height: cardWidth,
                  child: PromoCard(
                    title: firstPromo.title,
                    imageUrl: firstPromo.imageUrl,
                    emoji: firstPromo.emoji,
                    gradient: firstPromo.gradient,
                    onTap: firstPromo.onTap,
                  ),
                );
              },
            ),
          
          // Визуальный разделитель
          if (firstTwoProducts.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              height: 1,
              color: AppColors.borderSecondary,
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
            const SizedBox(height: 16),
          ],
          
          // Две карточки товара в ряд
          if (firstTwoProducts.isNotEmpty)
            Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final padding = 16.0 * 2; // горизонтальный padding контейнера
                final spacing = 16.0; // расстояние между карточками
                final cardWidth = (screenWidth - padding - spacing) / 2;
                final cardHeight = cardWidth / 0.75; // aspectRatio 0.75 как в GridView
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: cardHeight,
                        child: ProductCard(product: firstTwoProducts[0]),
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: firstTwoProducts.length > 1
                          ? SizedBox(
                              height: cardHeight,
                              child: ProductCard(product: firstTwoProducts[1]),
                            )
                          : const SizedBox(),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

// Вспомогательный класс для данных промо
class PromoItem {
  final String title;
  final String? imageUrl;
  final String? emoji;
  final Gradient? gradient;
  final VoidCallback? onTap;

  PromoItem({
    required this.title,
    this.imageUrl,
    this.emoji,
    this.gradient,
    this.onTap,
  });
}

