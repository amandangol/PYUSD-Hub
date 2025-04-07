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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
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
      ),
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 90,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
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
