import 'package:flutter/material.dart';

class SessionWarningDialog extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onLogout;
  final String title;
  final String message;

  const SessionWarningDialog({
    super.key,
    required this.onContinue,
    required this.onLogout,
    this.title = 'Session About to Expire',
    this.message =
        'Your session will expire in 30 seconds due to inactivity. Do you want to continue?',
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
              Icons.timer,
              size: 48,
              color: Colors.amber,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: onContinue,
            child: const Text('Continue Session'),
          ),
          TextButton(
            onPressed: onLogout,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout Now'),
          ),
        ],
      ),
    );
  }
}
