// lib/widgets/settings/security_section.dart
import 'package:flutter/material.dart';

import '../../../utils/snackbar_utils.dart';

class SecuritySection extends StatelessWidget {
  const SecuritySection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;

    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Biometric Authentication'),
            subtitle: Text(
              'Use fingerprint or face ID to unlock app',
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
            secondary: Icon(Icons.fingerprint, color: primaryColor),
            value: false, // Connect to a biometric provider
            onChanged: (value) {
              // Toggle biometric auth
              SnackbarUtil.showSnackbar(
                context: context,
                message: value
                    ? 'Biometric authentication enabled'
                    : 'Biometric authentication disabled',
              );
            },
            activeColor: primaryColor,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Change PIN'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              SnackbarUtil.showSnackbar(
                context: context,
                message: 'PIN change feature coming soon',
              );
            },
          ),
        ],
      ),
    );
  }
}
