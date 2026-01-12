import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:video_player/video_player.dart';
import '../constants/app_colors.dart';
import '../utils/responsive.dart';

class BackgroundHeroBanner extends StatefulWidget {
  final ScrollController? scrollController;
  final String? imageUrl;
  
  const BackgroundHeroBanner({
    super.key,
    this.scrollController,
    this.imageUrl,
  });

  @override
  State<BackgroundHeroBanner> createState() => _BackgroundHeroBannerState();
}

class _BackgroundHeroBannerState extends State<BackgroundHeroBanner> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset(
        'assets/image/grok-video-e1b52f68-34b4-4887-a4f3-90282da9d9a1.mp4',
      );
      
      await _videoController!.initialize();
      _videoController!.setLooping(true); // Зацикливание
      _videoController!.play();
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      print('⚠️ Ошибка инициализации видео: $e');
      if (mounted) {
        setState(() {
          _hasVideoError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Transform.translate(
        // Параллакс эффект при скролле
        offset: widget.scrollController != null && widget.scrollController!.hasClients
            ? Offset(0, -widget.scrollController!.offset * 0.3)
            : Offset.zero,
        child: Stack(
          children: [
            // Видео фон (приоритет)
            if (_isVideoInitialized && _videoController != null && !_hasVideoError)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              )
            // Fallback - градиент или изображение
            else if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
              Positioned.fill(
                child: Image.network(
                  widget.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildGradientBackground(),
                ),
              )
            else
              _buildGradientBackground(),
            
            // Декоративные элементы - снежинки
            _buildSnowflakes(),
            
            // Декоративные круги (как на скриншоте)
            _buildDecorativeCircles(),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
      ),
    );
  }

  Widget _buildSnowflakes() {
    return Positioned.fill(
      child: CustomPaint(
        painter: SnowflakesPainter(),
      ),
    );
  }

  Widget _buildDecorativeCircles() {
    return Builder(
      builder: (context) {
        // Адаптивные размеры кругов
        final largeCircleSize = Responsive.responsiveSize(
          context,
          mobile: 200.0,
          tablet: 250.0,
          desktop: 300.0,
        );

        final mediumCircleSize = Responsive.responsiveSize(
          context,
          mobile: 150.0,
          tablet: 180.0,
          desktop: 220.0,
        );

        final smallCircleSize = Responsive.responsiveSize(
          context,
          mobile: 80.0,
          tablet: 100.0,
          desktop: 120.0,
        );

        return Stack(
          children: [
            // Большой круг справа вверху
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: largeCircleSize,
                height: largeCircleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            // Средний круг справа внизу
            Positioned(
              right: 60,
              bottom: -60,
              child: Container(
                width: mediumCircleSize,
                height: mediumCircleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            // Маленькие круги
            Positioned(
              left: 50,
              top: 100,
              child: Container(
                width: smallCircleSize,
                height: smallCircleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Кастомный painter для снежинок
class SnowflakesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Рисуем простые снежинки
    for (int i = 0; i < 15; i++) {
      final x = (i * 73) % size.width.toInt();
      final y = (i * 137) % size.height.toInt();
      _drawSnowflake(canvas, Offset(x.toDouble(), y.toDouble()), paint);
    }
  }

  void _drawSnowflake(Canvas canvas, Offset center, Paint paint) {
    final radius = 3.0;
    canvas.drawCircle(center, radius, paint);
    
    // Простые линии снежинки
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;
    
    canvas.drawLine(
      Offset(center.dx - radius * 2, center.dy),
      Offset(center.dx + radius * 2, center.dy),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 2),
      Offset(center.dx, center.dy + radius * 2),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

