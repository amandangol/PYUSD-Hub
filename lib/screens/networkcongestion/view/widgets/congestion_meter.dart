import 'package:flutter/material.dart';
import 'dart:math' as math;

class CongestionMeter extends StatelessWidget {
  final int level;
  final String label;
  final String description;

  const CongestionMeter({
    super.key,
    required this.level,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate color based on level
    Color gaugeColor;
    if (level < 30) {
      gaugeColor = Colors.green;
    } else if (level < 60) {
      gaugeColor = Colors.orange;
    } else if (level < 80) {
      gaugeColor = Colors.deepOrange;
    } else {
      gaugeColor = Colors.red;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          width: 100,
          child: CustomPaint(
            painter: GaugePainter(
              value: level,
              color: gaugeColor,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$level%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: gaugeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GaugePainter extends CustomPainter {
  final int value;
  final Color color;

  GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw background arc
    final bgPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      bgPaint,
    );

    // Draw value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;

    final valueAngle = (value / 100) * math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      math.pi * 0.75,
      valueAngle,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
