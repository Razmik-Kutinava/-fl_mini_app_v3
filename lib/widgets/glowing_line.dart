import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Виджет светящейся линии для разделения секций
class GlowingLine extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final Axis direction;

  const GlowingLine({
    super.key,
    this.width,
    this.height,
    this.color,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final lineColor = color ?? AppColors.borderGlow;
    
    if (direction == Axis.horizontal) {
      return Container(
        width: width ?? double.infinity,
        height: height ?? 1,
        decoration: BoxDecoration(
          color: lineColor,
          boxShadow: AppColors.glowingLine,
        ),
      );
    } else {
      return Container(
        width: width ?? 1,
        height: height ?? double.infinity,
        decoration: BoxDecoration(
          color: lineColor,
          boxShadow: AppColors.glowingLine,
        ),
      );
    }
  }
}

/// Анимированная светящаяся линия
class AnimatedGlowingLine extends StatefulWidget {
  final double? width;
  final double? height;
  final Color? color;
  final Duration duration;

  const AnimatedGlowingLine({
    super.key,
    this.width,
    this.height,
    this.color,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<AnimatedGlowingLine> createState() => _AnimatedGlowingLineState();
}

class _AnimatedGlowingLineState extends State<AnimatedGlowingLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lineColor = widget.color ?? AppColors.borderGlow;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 1,
          decoration: BoxDecoration(
            color: lineColor.withOpacity(_animation.value),
            boxShadow: [
              BoxShadow(
                color: lineColor.withOpacity(_animation.value * 0.5),
                blurRadius: 5,
                spreadRadius: 0,
              ),
            ],
          ),
        );
      },
    );
  }
}
