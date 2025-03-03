import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final Color primaryColor;
  final bool isDarkMode;
  final VoidCallback onSendPressed;
  final VoidCallback onReceivePressed;
  final VoidCallback onSwapPressed;
  final VoidCallback onHistoryPressed;

  const ActionButtons({
    Key? key,
    required this.primaryColor,
    required this.isDarkMode,
    required this.onSendPressed,
    required this.onReceivePressed,
    required this.onSwapPressed,
    required this.onHistoryPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          context,
          Icons.arrow_upward_rounded,
          'Send',
          onSendPressed,
        ),
        _buildActionButton(
          context,
          Icons.swap_horiz_rounded,
          'Swap',
          onSwapPressed,
        ),
        _buildActionButton(
          context,
          Icons.arrow_downward_rounded,
          'Receive',
          onReceivePressed,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? primaryColor.withOpacity(0.2)
                  : primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
