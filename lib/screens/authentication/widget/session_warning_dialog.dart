import 'package:flutter/material.dart';

class SessionWarningDialog extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onLogout;
  final String title;
  final String message;
  final Color? titleColor;
  final Color? messageColor;
  final Color? iconColor;
  final Color? continueButtonColor;
  final Color? logoutButtonColor;

  const SessionWarningDialog({
    super.key,
    required this.onContinue,
    required this.onLogout,
    this.title = 'Session About to Expire',
    this.message =
        'Your session will expire in 30 seconds due to inactivity. Do you want to continue?',
    this.titleColor,
    this.messageColor,
    this.iconColor = Colors.amber,
    this.continueButtonColor,
    this.logoutButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: titleColor ?? theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.timer,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onContinue,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        continueButtonColor ?? theme.colorScheme.primary,
                    side: BorderSide(
                        color:
                            continueButtonColor ?? theme.colorScheme.primary),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Continue Session',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: continueButtonColor ?? theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: onLogout,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: logoutButtonColor ?? Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Logout Now',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
