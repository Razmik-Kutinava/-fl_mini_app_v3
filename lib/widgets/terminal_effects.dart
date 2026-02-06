import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// 🖥️ CRT ЭФФЕКТЫ ДЛЯ ТЕРМИНАЛЬНОГО СТИЛЯ

/// Виджет с эффектом CRT экрана (scanlines, мерцание)
class CRTEffect extends StatefulWidget {
  final Widget child;
  final bool enableScanlines;
  final bool enableFlicker;

  const CRTEffect({
    super.key,
    required this.child,
    this.enableScanlines = true,
    this.enableFlicker = true,
  });

  @override
  State<CRTEffect> createState() => _CRTEffectState();
}

class _CRTEffectState extends State<CRTEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _flickerController;

  @override
  void initState() {
    super.initState();
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _flickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = widget.child;

    // Эффект мерцания
    if (widget.enableFlicker) {
      result = AnimatedBuilder(
        animation: _flickerController,
        builder: (context, child) {
          final opacity = 0.15 + (_flickerController.value * 0.05);
          return Opacity(
            opacity: opacity.clamp(0.15, 0.2),
            child: child,
          );
        },
        child: result,
      );
    }

    // Эффект scanlines (полосы)
    if (widget.enableScanlines) {
      result = Stack(
        children: [
          result,
          Positioned.fill(
            child: CustomPaint(
              painter: ScanlinesPainter(),
            ),
          ),
        ],
      );
    }

    return result;
  }
}

/// Рисует scanlines (полосы CRT экрана)
class ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withOpacity(0.03)
      ..strokeWidth = 1;

    // Вертикальные полосы
    for (double i = 0; i < size.height; i += 2) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ScanlinesPainter oldDelegate) => false;
}

/// Виджет с неоновым свечением
class NeonGlow extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double blurRadius;
  final double spreadRadius;

  const NeonGlow({
    super.key,
    required this.child,
    this.glowColor = AppColors.accent,
    this.blurRadius = 10,
    this.spreadRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.2),
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Виджет с мигающим эффектом (для статусов)
class BlinkEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minOpacity;
  final double maxOpacity;

  const BlinkEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minOpacity = 0.5,
    this.maxOpacity = 1.0,
  });

  @override
  State<BlinkEffect> createState() => _BlinkEffectState();
}

class _BlinkEffectState extends State<BlinkEffect>
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

    _animation = Tween<double>(
      begin: widget.minOpacity,
      end: widget.maxOpacity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Виджет с движущейся сканирующей линией
class ScanLine extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ScanLine({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Positioned(
              top: _controller.value * MediaQuery.of(context).size.height,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.accent.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Терминальная рамка с левой границей
class TerminalBorder extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsets padding;

  const TerminalBorder({
    super.key,
    required this.child,
    this.borderColor = AppColors.borderGlow,
    this.borderWidth = 2,
    this.padding = const EdgeInsets.only(left: 20, top: 15, bottom: 15, right: 15),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: borderColor,
            width: borderWidth,
          ),
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Терминальная секция с заголовком
class TerminalSection extends StatelessWidget {
  final String title;
  final Widget child;
  final String? prefix;

  const TerminalSection({
    super.key,
    required this.title,
    required this.child,
    this.prefix = '> ',
  });

  @override
  Widget build(BuildContext context) {
    return TerminalBorder(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$prefix$title',
            style: AppTextStyles.h3(),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
