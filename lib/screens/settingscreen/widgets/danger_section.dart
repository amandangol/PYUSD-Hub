// lib/widgets/settings/danger_section.dart
import 'package:flutter/material.dart';

class DangerSection extends StatelessWidget {
  final Function onLogoutTap;

  const DangerSection({
    super.key,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;

    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        title: Text(
          'Log Out',
          style: TextStyle(
            color: theme.colorScheme.error,
          ),
        ),
        leading: Icon(
          Icons.logout,
          color: theme.colorScheme.error,
        ),
        onTap: () => onLogoutTap(),
      ),
    );
  }
}
