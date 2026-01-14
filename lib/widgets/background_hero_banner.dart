import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class BackgroundHeroBanner extends StatelessWidget {
  final ScrollController? scrollController;
  final String? imageUrl;

  const BackgroundHeroBanner({super.key, this.scrollController, this.imageUrl});

  // URL GIF фона из Supabase Storage
  static const String _gifBackgroundUrl =
      'https://wntvxdgxzenehfzvorae.supabase.co/storage/v1/object/public/product-images/grok-video-e1b52f68-34b4-4887-a4f3-90282da9d9a1.gif';

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Transform.translate(
        // Параллакс эффект при скролле
        offset: scrollController != null && scrollController!.hasClients
            ? Offset(0, -scrollController!.offset * 0.3)
            : Offset.zero,
        child: Image.network(
          _gifBackgroundUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('⚠️ Ошибка загрузки GIF фона: $error');
            return _buildGradientBackground();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            // Показываем градиент во время загрузки
            return _buildGradientBackground();
          },
          // GIF автоматически зацикливается браузером
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
