import 'package:flutter/material.dart';

class SessionTimeoutDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final String title;
  final String message;
  final String buttonText;
  final Color? titleColor;
  final Color? messageColor;
  final Color? iconColor;
  final Color? buttonTextColor;
  final Color? buttonBackgroundColor;

  const SessionTimeoutDialog({
    super.key,
    required this.onConfirm,
    this.title = 'Session Expired',
    this.message =
        'Your session has expired due to inactivity. For security reasons, you have been logged out.',
    this.buttonText = 'OK',
    this.titleColor,
    this.messageColor,
    this.iconColor = Colors.redAccent,
    this.buttonTextColor,
    this.buttonBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissal with back button
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: titleColor ?? theme.colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: messageColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                foregroundColor: buttonTextColor ?? Colors.white,
                backgroundColor:
                    buttonBackgroundColor ?? theme.colorScheme.error,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                buttonText,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: buttonTextColor ?? Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
