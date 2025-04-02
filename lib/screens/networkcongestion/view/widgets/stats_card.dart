import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String description;
  final bool isListView;
  final double? width;

  const StatsCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.description,
    this.isListView = false,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Adjust colors based on theme
    final cardColor = isDarkMode ? theme.colorScheme.surface : Colors.white;
    final borderColor =
        isDarkMode ? color.withOpacity(0.3) : color.withOpacity(0.2);
    final shadowColor =
        isDarkMode ? color.withOpacity(0.2) : color.withOpacity(0.15);
    final titleColor = isDarkMode
        ? theme.colorScheme.onSurface.withOpacity(0.7)
        : Colors.black54;
    final valueColor = color;
    final descriptionColor =
        isDarkMode ? theme.colorScheme.onSurface.withOpacity(0.5) : Colors.grey;
    final iconBackgroundColor =
        isDarkMode ? color.withOpacity(0.15) : color.withOpacity(0.1);

    return Container(
      width: width ?? (isListView ? double.infinity : 90),
      padding: EdgeInsets.symmetric(
        vertical: 8,
        horizontal: isListView ? 12 : 6,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: isListView
          ? _buildListViewLayout(
              titleColor: titleColor,
              valueColor: valueColor,
              descriptionColor: descriptionColor,
              iconBackgroundColor: iconBackgroundColor,
            )
          : _buildGridViewLayout(
              titleColor: titleColor,
              valueColor: valueColor,
              descriptionColor: descriptionColor,
              iconBackgroundColor: iconBackgroundColor,
            ),
    );
  }

  Widget _buildGridViewLayout({
    required Color titleColor,
    required Color valueColor,
    required Color descriptionColor,
    required Color iconBackgroundColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon with smaller circular background
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: iconBackgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(height: 4),

        // Title
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: titleColor,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),

        // Value (main data)
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
          textAlign: TextAlign.center,
        ),

        // Description
        Text(
          description,
          style: TextStyle(
            fontSize: 9,
            color: descriptionColor,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildListViewLayout({
    required Color titleColor,
    required Color valueColor,
    required Color descriptionColor,
    required Color iconBackgroundColor,
  }) {
    return Row(
      children: [
        // Icon with circular background
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBackgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),

        // Text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: titleColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Value (main data)
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),

        // Description
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: iconBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            description,
            style: TextStyle(
              fontSize: 10,
              color: valueColor,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
