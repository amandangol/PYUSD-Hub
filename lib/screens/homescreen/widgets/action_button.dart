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
        _ActionButton(
          onPressed: onSendPressed,
          label: 'Send',
          icon: Icons.arrow_upward_rounded,
          color: primaryColor,
          isDarkMode: isDarkMode,
        ),
        _ActionButton(
          onPressed: onReceivePressed,
          label: 'Receive',
          icon: Icons.arrow_downward_rounded,
          color: isDarkMode ? Colors.deepPurple : Colors.purple,
          isDarkMode: isDarkMode,
        ),
        _ActionButton(
          onPressed: onSwapPressed,
          label: 'Swap',
          icon: Icons.swap_horiz_rounded,
          color: isDarkMode ? Colors.teal : Colors.teal[600]!,
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color color;
  final bool isDarkMode;

  const _ActionButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
