import 'package:flutter/material.dart';

class InfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? buttonText;
  final Color? textColor;
  final Color? subtitleColor;
  final Color? backgroundColor;
  final IconData? icon;
  final Color? iconColor;

  const InfoDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText,
    this.textColor,
    this.subtitleColor,
    this.backgroundColor,
    this.icon,
    this.iconColor,
  });

  /// Static method to show the dialog
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
    Color? textColor,
    Color? subtitleColor,
    Color? backgroundColor,
    IconData? icon,
    Color? iconColor,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor = isDarkMode ? Colors.white : Colors.black87;
    final defaultSubtitleColor = isDarkMode ? Colors.white70 : Colors.black54;
    final defaultBackgroundColor =
        isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final defaultIconColor = isDarkMode ? Colors.blue[300] : Colors.blue;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return InfoDialog(
          title: title,
          message: message,
          buttonText: buttonText,
          textColor: textColor ?? defaultTextColor,
          subtitleColor: subtitleColor ?? defaultSubtitleColor,
          backgroundColor: backgroundColor ?? defaultBackgroundColor,
          icon: icon ?? Icons.info_outline,
          iconColor: iconColor ?? defaultIconColor,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor?.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: subtitleColor,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: subtitleColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  buttonText ?? 'Got it',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
