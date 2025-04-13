import 'package:flutter/material.dart';

class WarningBox extends StatelessWidget {
  final ThemeData theme;

  const WarningBox({
    super.key,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final warningColor = theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warningColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: warningColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: warningColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: warningColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Only send PYUSD or ETH to this address. Sending other assets may result in permanent loss.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: warningColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
