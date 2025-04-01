import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class PinInput extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onCompleted;
  final int pinLength;
  final String? label;

  const PinInput({
    super.key,
    required this.controller,
    this.onCompleted,
    this.pinLength = 6,
    this.label,
  });

  @override
  State<PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<PinInput> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Box-style pin theme
    final defaultPinTheme = PinTheme(
      width: 46,
      height: 56,
      textStyle: TextStyle(
        fontSize: 20,
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor,
        ),
      ),
    );

    // Different themes for different states
    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 2,
        ),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.5),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: Pinput(
                controller: widget.controller,
                length: widget.pinLength,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                obscureText: _obscureText,
                obscuringCharacter: '•',
                onCompleted: widget.onCompleted,
                keyboardType: TextInputType.number,
                crossAxisAlignment: CrossAxisAlignment.center,
                pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                showCursor: true,
                cursor: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      width: 2,
                      height: 22,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: _toggleVisibility,
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
