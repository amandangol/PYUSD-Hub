// lib/widgets/settings/appearance_section.dart
import 'package:flutter/material.dart';
import '../../../providers/theme_provider.dart';

class AppearanceSection extends StatelessWidget {
  final ThemeProvider themeProvider;

  const AppearanceSection({
    Key? key,
    required this.themeProvider,
  }) : super(key: key);

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
            title: const Text('Dark Mode'),
            subtitle: Text(
              'Use dark theme for the app',
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
            secondary: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: primaryColor,
            ),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.setDarkMode(value);
            },
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }
}
