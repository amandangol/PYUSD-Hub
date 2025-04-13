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
    return Transform.scale(
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
    );
  }
}

class CarPainter extends CustomPainter {
  final String speed;
  final bool isPending;
  final String transactionType;
  final double animationValue;

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

    final Color wheelColor = Colors.black87;
    final Color windowColor = Colors.lightBlueAccent.withOpacity(0.7);

    // Create gradient for the car body
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor,
        baseColor.withOpacity(0.8),
      ],
    );

    // Apply shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Draw shadow
    canvas.drawOval(
      Rect.fromLTWH(5, size.height - 5, size.width - 10, 4),
      shadowPaint,
    );

    // Main car body path
    final bodyPath = Path()
      ..moveTo(10, size.height - 8) // Start at bottom left
      ..lineTo(15, size.height - 15) // Up to wheel arch
      ..lineTo(20, size.height - 18) // Front slope
      ..lineTo(25, size.height - 22) // Hood start
      ..lineTo(size.width - 25, size.height - 22) // Hood top
      ..lineTo(size.width - 20, size.height - 18) // Rear slope
      ..lineTo(size.width - 15, size.height - 15) // Down to wheel arch
      ..lineTo(size.width - 10, size.height - 8) // Bottom rear
      ..close();

    // Draw car body with gradient
    paint.shader = gradient.createShader(bodyPath.getBounds());
    canvas.drawPath(bodyPath, paint);

    // Draw windows
    final windowPath = Path()
      ..moveTo(25, size.height - 22) // Start at hood
      ..lineTo(30, size.height - 26) // Up to windshield
      ..lineTo(size.width - 30, size.height - 26) // Across roof
      ..lineTo(size.width - 25, size.height - 22) // Down rear window
      ..close();

    paint
      ..shader = null
      ..color = windowColor;
    canvas.drawPath(windowPath, paint);

    // Draw wheels
    paint.color = wheelColor;
    // Front wheel with animation
    final frontWheelCenter = Offset(20, size.height - 8);
    canvas.save();
    canvas.translate(frontWheelCenter.dx, frontWheelCenter.dy);
    canvas.rotate(animationValue * 6.28318); // 2*pi
    canvas.translate(-frontWheelCenter.dx, -frontWheelCenter.dy);
    canvas.drawCircle(frontWheelCenter, 4, paint);
    canvas.restore();

    // Rear wheel with animation
    final rearWheelCenter = Offset(size.width - 20, size.height - 8);
    canvas.save();
    canvas.translate(rearWheelCenter.dx, rearWheelCenter.dy);
    canvas.rotate(animationValue * 6.28318); // 2*pi
    canvas.translate(-rearWheelCenter.dx, -rearWheelCenter.dy);
    canvas.drawCircle(rearWheelCenter, 4, paint);
    canvas.restore();

    // Add speed indicator
    if (speed == 'fast') {
      _drawSpeedLines(canvas, size, paint);
    }

    // Add pending indicator if needed
    if (isPending) {
      _drawPendingIndicator(canvas, size, paint);
    }
  }

  void _drawSpeedLines(Canvas canvas, Size size, Paint paint) {
    paint.color = Colors.white.withOpacity(0.6);
    paint.strokeWidth = 1.5;
    paint.style = PaintingStyle.stroke;

    final speedOffset = (animationValue * 10).toInt();
    for (var i = 0; i < 3; i++) {
      final x = size.width - 15 - (i * 8) + speedOffset;
      canvas.drawLine(
        Offset(x, size.height - 18),
        Offset(x - 5, size.height - 12),
        paint,
      );
    }
  }

  void _drawPendingIndicator(Canvas canvas, Size size, Paint paint) {
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final dotSize = 2.0;
    final spacing = 4.0;

    for (var i = 0; i < 3; i++) {
      final opacity = (1.0 - ((animationValue * 3 + i) % 1.0));
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(
        Offset(centerX + (i - 1) * spacing, size.height - 30),
        dotSize,
        paint,
      );
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
