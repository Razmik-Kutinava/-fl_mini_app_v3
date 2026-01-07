import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'promo_card.dart';

class PromoSection extends StatelessWidget {
  final List<PromoItem> promotions;

  const PromoSection({
    super.key,
    required this.promotions,
  });

  @override
  Widget build(BuildContext context) {
    if (promotions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок "акции"
          Text(
            'акции',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Grid промо-карточек
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.0, // Квадратные карточки
            ),
            itemCount: promotions.length,
            itemBuilder: (context, index) {
              final promo = promotions[index];
              return PromoCard(
                title: promo.title,
                imageUrl: promo.imageUrl,
                emoji: promo.emoji,
                gradient: promo.gradient,
                onTap: promo.onTap,
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

