import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final String address;
  final Color primaryColor;
  final ThemeData theme;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const ActionButtons({
    super.key,
    required this.address,
    required this.primaryColor,
    required this.theme,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = address.isNotEmpty;

    return Row(
      children: [
        // Copy button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isEnabled ? onCopy : null,
            icon: const Icon(Icons.copy_rounded, size: 20),
            label: const Text(
              'Copy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.primary),
              ),
              elevation: 0,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Share button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isEnabled ? onShare : null,
            icon: const Icon(Icons.share_rounded, size: 20),
            label: const Text(
              'Share',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              shadowColor: theme.colorScheme.primary.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }
}
