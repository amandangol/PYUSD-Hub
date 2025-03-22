import 'package:flutter/material.dart';

class SessionTimeoutDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final String title;
  final String message;
  final String buttonText;

  const SessionTimeoutDialog({
    super.key,
    required this.onConfirm,
    this.title = 'Session Expired',
    this.message =
        'Your session has expired due to inactivity. For security reasons, you have been logged out.',
    this.buttonText = 'OK',
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissal with back button
      child: AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Icon(
              Icons.lock_outline,
              size: 48,
              color: Colors.redAccent,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: onConfirm,
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
