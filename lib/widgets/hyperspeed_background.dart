import 'dart:math';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_colors.dart';

/// Анимированный фон "гиперпространство" в стиле Millennium Falcon Hyperspeed
/// Эффект полёта через звёздное поле на сверхсветовой скорости
class HyperspeedBackground extends StatefulWidget {
  final ScrollController? scrollController;

  const HyperspeedBackground({super.key, this.scrollController});

  @override
  State<HyperspeedBackground> createState() => _HyperspeedBackgroundState();
}

class _HyperspeedBackgroundState extends State<HyperspeedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Star> _stars;
  final Random _random = Random();
  
  // Количество звёзд
  static const int _starCount = 200;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..repeat();
    
    _stars = List.generate(_starCount, (_) => _createStar());
  }

  Star _createStar({bool fromCenter = true}) {
    // Угол движения звезды (от центра во все стороны)
    final angle = _random.nextDouble() * 2 * pi;
    
    // Начальное расстояние от центра (0 = центр, 1 = край)
    final startDistance = fromCenter 
        ? _random.nextDouble() * 0.1 // Начинаем близко к центру
        : _random.nextDouble() * 0.5 + 0.5; // Или уже в движении
    
    return Star(
      angle: angle,
      distance: startDistance,
      speed: _random.nextDouble() * 0.015 + 0.008, // Скорость движения
      brightness: _random.nextDouble() * 0.7 + 0.3,
      length: _random.nextDouble() * 0.4 + 0.2, // Длина "хвоста"
      hue: _random.nextDouble() * 60 + 200, // Оттенок (синий-фиолетовый)
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Обновляем позиции звёзд
        for (int i = 0; i < _stars.length; i++) {
          _stars[i] = _stars[i].move();
          
          // Если звезда улетела за экран, создаём новую из центра
          if (_stars[i].distance > 1.5) {
            _stars[i] = _createStar(fromCenter: true);
          }
        }
        
        return CustomPaint(
          painter: HyperspeedPainter(
            stars: _stars,
            scrollOffset: widget.scrollController?.hasClients == true
                ? widget.scrollController!.offset
                : 0,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

/// Звезда в гиперпространстве
class Star {
  final double angle;      // Угол направления движения
  final double distance;   // Расстояние от центра (0-1+)
  final double speed;      // Скорость движения
  final double brightness; // Яркость (0-1)
  final double length;     // Длина хвоста
  final double hue;        // Оттенок цвета

  Star({
    required this.angle,
    required this.distance,
    required this.speed,
    required this.brightness,
    required this.length,
    required this.hue,
  });

  Star move() {
    // Ускорение по мере удаления от центра
    final acceleration = 1.0 + distance * 2.0;
    return Star(
      angle: angle,
      distance: distance + speed * acceleration,
      speed: speed,
      brightness: brightness,
      length: length,
      hue: hue,
    );
  }
}

/// CustomPainter для отрисовки эффекта гиперпространства
class HyperspeedPainter extends CustomPainter {
  final List<Star> stars;
  final double scrollOffset;

  HyperspeedPainter({
    required this.stars,
    this.scrollOffset = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.4);
    
    // Рисуем глубокий космический фон с градиентом
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.3),
        radius: 1.2,
        colors: [
          const Color(0xFF0a0a1a), // Глубокий тёмно-синий в центре
          const Color(0xFF050510), // Почти чёрный
          const Color(0xFF000005), // Абсолютно тёмный
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);
    
    // Добавляем лёгкое свечение в центре (точка входа в гиперпространство)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1a2a5a).withOpacity(0.4),
          const Color(0xFF0a1030).withOpacity(0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.5));
    canvas.drawCircle(center, size.width * 0.5, glowPaint);
    
    // Рисуем звёзды
    for (final star in stars) {
      _drawStar(canvas, size, center, star);
    }
  }

  void _drawStar(Canvas canvas, Size size, Offset center, Star star) {
    // Максимальное расстояние = диагональ экрана
    final maxDistance = sqrt(size.width * size.width + size.height * size.height) / 2;
    
    // Вычисляем позицию конца звезды (текущая позиция)
    final endX = center.dx + cos(star.angle) * star.distance * maxDistance;
    final endY = center.dy + sin(star.angle) * star.distance * maxDistance;
    
    // Вычисляем позицию начала звезды (хвост)
    final tailDistance = star.distance - star.length * star.distance * 0.5;
    final startX = center.dx + cos(star.angle) * tailDistance * maxDistance;
    final startY = center.dy + sin(star.angle) * tailDistance * maxDistance;
    
    // Интенсивность зависит от расстояния (ярче = дальше от центра)
    final intensity = (star.distance * star.brightness).clamp(0.0, 1.0);
    
    // Толщина линии увеличивается с расстоянием
    final strokeWidth = 1.0 + star.distance * 3.0;
    
    // Безопасные значения для HSL (все в диапазоне 0-1)
    final safeHue = (star.hue % 360).clamp(0.0, 360.0);
    final safeSaturation = (0.8 - star.distance * 0.3).clamp(0.0, 1.0);
    final safeLightness = (0.5 + star.distance * 0.5).clamp(0.0, 1.0);
    
    // Цвет звезды с оттенком от синего к белому
    final color = HSLColor.fromAHSL(
      intensity.clamp(0.0, 1.0),
      safeHue,
      safeSaturation,
      safeLightness,
    ).toColor();
    
    // Рисуем линию с градиентом (от прозрачного к яркому)
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withOpacity(0),
          color.withOpacity(intensity * 0.5),
          color.withOpacity(intensity),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromPoints(
        Offset(startX, startY),
        Offset(endX, endY),
      ))
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(
      Offset(startX, startY),
      Offset(endX, endY),
      paint,
    );
    
    // Добавляем яркую точку на конце (звезда)
    if (star.distance > 0.3) {
      final dotPaint = Paint()
        ..color = Colors.white.withOpacity(intensity * 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(endX, endY),
        strokeWidth * 0.6,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HyperspeedPainter oldDelegate) => true;
}
