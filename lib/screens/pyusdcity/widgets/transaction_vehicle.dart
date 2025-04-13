import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../utils/formatter_utils.dart';

class TransactionVehicle extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final bool isPending;
  final String speed; // 'fast', 'medium', 'slow', 'waiting'
  final String transactionType; // 'pyusd', 'other'
  final double animationValue;

  const TransactionVehicle({
    super.key,
    required this.transaction,
    required this.isPending,
    required this.speed,
    required this.transactionType,
    required this.animationValue,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate bounce effect based on speed and animation
    final double bounceOffset = _calculateBounce();

    // Calculate tilt effect based on speed
    final double tiltAngle = _calculateTilt();

    return Transform.translate(
      offset: Offset(0, bounceOffset),
      child: Transform.rotate(
        angle: tiltAngle,
        child: Transform.scale(
          scale: 0.8,
          child: CustomPaint(
            size: const Size(60, 30),
            painter: CarPainter(
              speed: speed,
              isPending: isPending,
              transactionType: transactionType,
              animationValue: animationValue,
            ),
          ),
        ),
      ),
    );
  }

  double _calculateBounce() {
    // Create a subtle bounce effect based on animation value and speed
    double bounceHeight;
    switch (speed) {
      case 'fast':
        bounceHeight = 1.0;
        break;
      case 'medium':
        bounceHeight = 0.7;
        break;
      case 'slow':
      default:
        bounceHeight = 0.5;
    }

    // Use sine wave for smooth bounce
    return sin(animationValue * 2 * pi * 2) * bounceHeight;
  }

  double _calculateTilt() {
    // Create a slight tilt forward for fast vehicles, backward for slow
    double tiltFactor;
    switch (speed) {
      case 'fast':
        tiltFactor = -0.05; // Tilt forward
        break;
      case 'medium':
        tiltFactor = -0.02;
        break;
      case 'slow':
        tiltFactor = 0.01; // Slight backward tilt
        break;
      default:
        tiltFactor = 0.0;
    }

    return tiltFactor;
  }
}

class CarPainter extends CustomPainter {
  final String speed;
  final bool isPending;
  final String transactionType;
  final double animationValue;
  final Random _random = Random();

  CarPainter({
    required this.speed,
    required this.isPending,
    required this.transactionType,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    // Define colors based on transaction type and status
    final Color baseColor = transactionType == 'pyusd'
        ? (isPending ? Colors.orange : Colors.blue)
        : Colors.grey;

    // Add subtle color variation based on speed
    final Color adjustedColor = _adjustColorForSpeed(baseColor);

    final Color wheelColor = Colors.black87;
    final Color windowColor = Colors.lightBlueAccent.withOpacity(0.7);

    // Create gradient for the car body with improved shading
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        adjustedColor.withOpacity(0.9),
        adjustedColor,
        adjustedColor.withOpacity(0.8),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    // Apply enhanced shadow with motion blur effect
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(_getShadowOpacity())
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, _getShadowBlur());

    // Draw extended shadow for fast moving vehicles
    final shadowRect = speed == 'fast'
        ? Rect.fromLTWH(0, size.height - 5, size.width, 4)
        : Rect.fromLTWH(5, size.height - 5, size.width - 10, 4);
    canvas.drawOval(shadowRect, shadowPaint);

    // Main car body path - smoother curves
    final bodyPath = Path();

    // Use animation value to create slight distortion for motion effect
    final distortFactor =
        speed == 'fast' ? sin(animationValue * pi * 4) * 0.5 : 0.0;

    // Create body path with separate statements instead of chaining
    bodyPath.moveTo(10, size.height - 8); // Start at bottom left
    bodyPath.lineTo(15, size.height - 15 + distortFactor); // Up to wheel arch
    bodyPath.lineTo(20, size.height - 18 + distortFactor); // Front slope
    bodyPath.quadraticBezierTo(
        22.5,
        size.height - 22, // Control point for smooth curve
        25,
        size.height - 22 + distortFactor); // Hood start with smooth curve
    bodyPath.lineTo(
        size.width - 25, size.height - 22 + distortFactor); // Hood top
    bodyPath.quadraticBezierTo(
        size.width - 22.5,
        size.height - 22,
        size.width - 20,
        size.height - 18 + distortFactor); // Rear slope with curve
    bodyPath.lineTo(size.width - 15,
        size.height - 15 + distortFactor); // Down to wheel arch
    bodyPath.lineTo(size.width - 10, size.height - 8); // Bottom rear
    bodyPath.close();

    // Draw car body with gradient
    paint.shader = gradient.createShader(bodyPath.getBounds());
    canvas.drawPath(bodyPath, paint);

    // Draw smoother windows with gentle curves
    final windowPath = Path();
    windowPath.moveTo(25, size.height - 22 + distortFactor); // Start at hood
    windowPath.quadraticBezierTo(27.5, size.height - 24, 30,
        size.height - 26 + distortFactor * 0.5); // Curved windshield
    windowPath.lineTo(
        size.width - 30, size.height - 26 + distortFactor * 0.5); // Across roof
    windowPath.quadraticBezierTo(
        size.width - 27.5,
        size.height - 24,
        size.width - 25,
        size.height - 22 + distortFactor); // Curved rear window
    windowPath.close();

    paint
      ..shader = null
      ..color = windowColor;
    canvas.drawPath(windowPath, paint);

    // Draw wheels with improved animation
    paint.color = wheelColor;

    // Wheel rotation speed based on vehicle speed
    final wheelRotationSpeed = _getWheelRotationSpeed();

    // Front wheel with animation
    final frontWheelCenter = Offset(20, size.height - 8);
    _drawAnimatedWheel(canvas, frontWheelCenter, wheelRotationSpeed, paint);

    // Rear wheel with animation
    final rearWheelCenter = Offset(size.width - 20, size.height - 8);
    _drawAnimatedWheel(canvas, rearWheelCenter, wheelRotationSpeed, paint);

    // Add headlights
    _drawHeadlights(canvas, size, paint);

    // Add speed indicator with improved animation
    if (speed == 'fast' || speed == 'medium') {
      _drawSpeedLines(canvas, size, paint);
    }

    // Add exhaust effect
    _drawExhaustEffect(canvas, size, paint);

    // Add pending indicator if needed
    if (isPending) {
      _drawPendingIndicator(canvas, size, paint);
    }
  }

  void _drawAnimatedWheel(
      Canvas canvas, Offset center, double rotationSpeed, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(
        animationValue * 6.28318 * rotationSpeed); // 2*pi * speed factor

    // Draw wheel
    canvas.drawCircle(Offset.zero, 4, paint);

    // Draw wheel details (spokes)
    final spokePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2;
      canvas.drawLine(
        Offset.zero,
        Offset(cos(angle) * 3, sin(angle) * 3),
        spokePaint,
      );
    }

    canvas.restore();
  }

  void _drawHeadlights(Canvas canvas, Size size, Paint paint) {
    // Front headlight
    paint.color = Colors.yellow.withOpacity(0.8);
    canvas.drawCircle(Offset(15, size.height - 16), 2, paint);

    // Rear light
    paint.color = Colors.red.withOpacity(0.8);
    canvas.drawCircle(Offset(size.width - 15, size.height - 16), 2, paint);
  }

  void _drawSpeedLines(Canvas canvas, Size size, Paint paint) {
    paint.color = Colors.white.withOpacity(_getSpeedLinesOpacity());
    paint.strokeWidth = speed == 'fast' ? 1.8 : 1.2;
    paint.style = PaintingStyle.stroke;

    final speedLineCount = speed == 'fast' ? 4 : 2;
    final speedFactor = speed == 'fast' ? 15.0 : 8.0;

    // Calculate offset for animating the speed lines
    final speedOffset = (animationValue * speedFactor).toInt() % 10;

    for (var i = 0; i < speedLineCount; i++) {
      final x = size.width - 10 - (i * 7) - speedOffset;

      // Draw curved speed lines
      final path = Path();
      path.moveTo(x, size.height - 18);
      path.quadraticBezierTo(x - 3, size.height - 15, x - 6, size.height - 12);
      canvas.drawPath(path, paint);
    }
  }

  void _drawExhaustEffect(Canvas canvas, Size size, Paint paint) {
    if (speed == 'slow') return; // No exhaust for slow vehicles

    // Draw exhaust particles with animation
    final exhaustCount = speed == 'fast' ? 4 : 2;
    final baseX = 10.0; // Rear of the car
    final baseY = size.height - 12;

    for (int i = 0; i < exhaustCount; i++) {
      // Calculate particle position based on animation
      final offset = (animationValue * 4 + i / exhaustCount) % 1.0;
      final x = baseX - offset * 8;
      final y = baseY - offset * 2;
      final particleSize = 3 * (1 - offset);

      final exhaustPaint = Paint()
        ..color = Colors.grey.withOpacity(0.7 * (1 - offset))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, exhaustPaint);
    }
  }

  void _drawPendingIndicator(Canvas canvas, Size size, Paint paint) {
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final dotSize = 2.0;
    final spacing = 4.0;

    // Smoother pulsing animation for pending indicator
    for (var i = 0; i < 3; i++) {
      // Create smoother pulsing effect
      final pulsePhase = (animationValue * 2 + i / 3) % 1.0;
      // Use sine function for smooth pulsing
      final opacity = 0.3 + (sin(pulsePhase * 2 * pi) + 1) / 4;

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(
        Offset(centerX + (i - 1) * spacing, size.height - 30),
        dotSize + (sin(pulsePhase * 2 * pi) + 1) * 0.5, // Subtle size variation
        paint,
      );
    }
  }

  double _getWheelRotationSpeed() {
    switch (speed) {
      case 'fast':
        return 3.0;
      case 'medium':
        return 2.0;
      case 'slow':
        return 1.0;
      default:
        return 0.5;
    }
  }

  double _getShadowOpacity() {
    switch (speed) {
      case 'fast':
        return 0.4;
      case 'medium':
        return 0.3;
      default:
        return 0.2;
    }
  }

  double _getShadowBlur() {
    switch (speed) {
      case 'fast':
        return 4.0;
      case 'medium':
        return 3.0;
      default:
        return 2.0;
    }
  }

  double _getSpeedLinesOpacity() {
    // Make speed lines "pulse" with the animation
    final basePulse = (sin(animationValue * 2 * pi) + 1) / 4;

    switch (speed) {
      case 'fast':
        return 0.7 + basePulse;
      case 'medium':
        return 0.5 + basePulse;
      default:
        return 0.0;
    }
  }

  Color _adjustColorForSpeed(Color baseColor) {
    // Brighten colors for fast vehicles
    switch (speed) {
      case 'fast':
        return baseColor
            .withBlue(min(baseColor.blue + 20, 255))
            .withRed(min(baseColor.red + 10, 255));
      case 'medium':
        return baseColor;
      default:
        return baseColor
            .withBlue(max(baseColor.blue - 10, 0))
            .withRed(max(baseColor.red - 10, 0));
    }
  }

  @override
  bool shouldRepaint(CarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isPending != isPending ||
        oldDelegate.speed != speed ||
        oldDelegate.transactionType != transactionType;
  }
}
