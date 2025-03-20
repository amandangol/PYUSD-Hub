import 'package:flutter/material.dart';

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
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.pinLength, (index) => FocusNode());
    _controllers =
        List.generate(widget.pinLength, (index) => TextEditingController());

    // Listen to changes in each controller
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(() {
        // Update the main controller with combined pin
        final combinedPin = _controllers.map((c) => c.text).join();
        widget.controller.text = combinedPin;

        // Call onCompleted when all fields are filled
        if (combinedPin.length == widget.pinLength &&
            widget.onCompleted != null) {
          widget.onCompleted!(combinedPin);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    // Handle backspace when field is empty to focus previous field
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      return;
    }

    // Move focus to next field when a digit is entered
    if (value.length == 1 && index < widget.pinLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  widget.pinLength,
                  (index) => SizedBox(
                    width: 40,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      obscureText: _obscureText,
                      obscuringCharacter: '•',
                      style: const TextStyle(fontSize: 20),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: theme.colorScheme.primary, width: 2),
                        ),
                        // Show a hint to indicate the field is interactive
                        hintText: _obscureText ? "•" : "0",
                        hintStyle:
                            TextStyle(color: theme.hintColor.withOpacity(0.3)),
                      ),
                      // Handle both onChange and onSubmitted events
                      onChanged: (value) => _onChanged(value, index),
                      onSubmitted: (_) {
                        if (index < widget.pinLength - 1) {
                          _focusNodes[index + 1].requestFocus();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _toggleVisibility,
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
                color: theme.colorScheme.primary,
              ),
              tooltip: _obscureText ? 'Show PIN' : 'Hide PIN',
            ),
          ],
        ),
      ],
    );
  }
}
