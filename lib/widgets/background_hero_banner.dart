import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_colors.dart';
import 'hyperspeed_background.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_colors.dart';

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
