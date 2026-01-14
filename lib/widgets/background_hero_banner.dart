import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../constants/app_colors.dart';

class BackgroundHeroBanner extends StatefulWidget {
  final ScrollController? scrollController;
  final String? imageUrl;

  const BackgroundHeroBanner({super.key, this.scrollController, this.imageUrl});

  @override
  State<BackgroundHeroBanner> createState() => _BackgroundHeroBannerState();
}

class _BackgroundHeroBannerState extends State<BackgroundHeroBanner> {
  // URL видео фона из Supabase Storage
  static const String _videoBackgroundUrl =
      'https://wntvxdgxzenehfzvorae.supabase.co/storage/v1/object/public/product-images/grok-video-e1b52f68-34b4-4887-a4f3-90282da9d9a1.gif';

  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(_videoBackgroundUrl),
      );

      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (error) {
      print('⚠️ Ошибка инициализации видео фона: $error');
      if (mounted) {
        setState(() {
          _hasError = true;
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
        offset: widget.scrollController != null &&
                widget.scrollController!.hasClients
            ? Offset(0, -widget.scrollController!.offset * 0.3)
            : Offset.zero,
        child: _hasError || !_isInitialized
            ? _buildGradientBackground()
            : FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
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
