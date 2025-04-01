import 'package:flutter/material.dart';

class CloudWidget extends StatelessWidget {
  final double size;
  final double opacity;
  final bool darkMode;

  const CloudWidget({
    super.key,
    required this.size,
    required this.opacity,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    final Color cloudColor = darkMode
        ? Colors.grey.shade700.withOpacity(opacity)
        : Colors.white.withOpacity(opacity);

    return SizedBox(
      width: size * 2.5,
      height: size,
      child: Stack(
        children: [
          // Main cloud body
          Positioned(
            left: size * 0.5,
            top: size * 0.3,
            child: Container(
              width: size * 1.5,
              height: size * 0.5,
              decoration: BoxDecoration(
                color: cloudColor,
                borderRadius: BorderRadius.circular(size * 0.25),
              ),
            ),
          ),
          // Cloud puffs
          Positioned(
            left: size * 0.3,
            top: size * 0.1,
            child: Container(
              width: size * 0.7,
              height: size * 0.7,
              decoration: BoxDecoration(
                color: cloudColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: size * 0.8,
            top: 0,
            child: Container(
              width: size * 0.8,
              height: size * 0.8,
              decoration: BoxDecoration(
                color: cloudColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: size * 1.4,
            top: size * 0.1,
            child: Container(
              width: size * 0.7,
              height: size * 0.7,
              decoration: BoxDecoration(
                color: cloudColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
