// lib/widgets/settings/about_section.dart
import 'package:flutter/material.dart';

class AboutSection extends StatelessWidget {
  final String appVersion;

  const AboutSection({
    super.key,
    required this.appVersion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;

    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            title: const Text('App Version'),
            subtitle: Text(
              appVersion,
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to Privacy Policy
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy Policy will open soon'),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to Terms of Service
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terms of Service will open soon'),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Support'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to Support screen or launch support link
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support section will open soon'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
