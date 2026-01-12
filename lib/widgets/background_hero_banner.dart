import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class BackgroundHeroBanner extends StatelessWidget {
  final ScrollController? scrollController;
  final String? imageUrl;

  const BackgroundHeroBanner({super.key, this.scrollController, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Transform.translate(
        // Параллакс эффект при скролле
        offset: scrollController != null && scrollController!.hasClients
            ? Offset(0, -scrollController!.offset * 0.3)
            : Offset.zero,
        child: Image.asset(
          'assets/image/gif.gif',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('⚠️ Ошибка загрузки GIF: $error');
            return _buildGradientBackground();
          },
        ),
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.heroGradient),
    );
  }
}
