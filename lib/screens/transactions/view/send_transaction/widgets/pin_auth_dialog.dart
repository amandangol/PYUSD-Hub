import 'package:flutter/material.dart';

import '../../../../authentication/widget/pin_input_widget.dart.dart';

class PinAuthDialog extends StatefulWidget {
  final String title;
  final String message;

  const PinAuthDialog({
    Key? key,
    required this.title,
    required this.message,
  }) : super(key: key);

  @override
  State<PinAuthDialog> createState() => _PinAuthDialogState();
}

class _PinAuthDialogState extends State<PinAuthDialog> {
  final TextEditingController _pinController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          PinInput(
            controller: _pinController,
            onCompleted: (pin) {
              if (pin.length == 6) {
                Navigator.of(context).pop(pin);
              }
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_pinController.text.length == 6) {
              Navigator.of(context).pop(_pinController.text);
            } else {
              setState(() {
                _error = 'Please enter a 6-digit PIN';
              });
            }
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
