import 'package:flutter/material.dart';
import 'hyperspeed_background.dart';

class BackgroundHeroBanner extends StatelessWidget {
  final ScrollController? scrollController;
  final String? imageUrl;

  const BackgroundHeroBanner({super.key, this.scrollController, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: HyperspeedBackground(
        scrollController: scrollController,
      ),
    );
  }
}
