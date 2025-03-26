import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final Color primaryColor;
  final bool isDarkMode;
  final VoidCallback onSendPressed;
  final VoidCallback onReceivePressed;
  final VoidCallback onSwapPressed;

  const ActionButtons({
    super.key,
    required this.primaryColor,
    required this.isDarkMode,
    required this.onSendPressed,
    required this.onReceivePressed,
    required this.onSwapPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ActionButton(
          icon: Icons.arrow_upward,
          label: 'Send',
          onPressed: onSendPressed,
          color: primaryColor,
          isDarkMode: isDarkMode,
        ),
        ActionButton(
          icon: Icons.arrow_downward,
          label: 'Receive',
          onPressed: onReceivePressed,
          color: primaryColor,
          isDarkMode: isDarkMode,
        ),
        ActionButton(
          icon: Icons.swap_horiz,
          label: 'Swap',
          onPressed: onSwapPressed,
          color: primaryColor,
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final bool isDarkMode;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
