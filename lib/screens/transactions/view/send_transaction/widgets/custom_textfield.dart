import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pyusd_hub/widgets/pyusd_components.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final Icon? prefixIcon;
  final String? suffixText;
  final FocusNode? focusNode;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.suffixIcon,
    this.prefixIcon,
    this.suffixText,
    this.focusNode,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  String? _errorText;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validateInput);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validateInput);
    super.dispose();
  }

  void _validateInput() {
    if (widget.validator != null) {
      final error = widget.validator!(widget.controller.text);
      setState(() {
        _errorText = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PyusdTextField(
      controller: widget.controller,
      labelText: widget.labelText,
      hintText: widget.hintText,
      validator: widget.validator,
      onChanged: (value) {
        if (widget.onChanged != null) {
          widget.onChanged!(value);
        }
        _validateInput();
      },
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      suffixIcon: widget.suffixIcon,
      prefixIcon: widget.prefixIcon,
      suffixText: widget.suffixText,
      focusNode: widget.focusNode,
      errorText: _errorText,
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 50,
      child: PyusdButton(
        onPressed: onPressed,
        text: child is Text ? (child as Text).data ?? '' : '',
        backgroundColor: color,
        borderRadius: 10,
        icon: child is Row ? (child as Row).children.first : null,
      ),
    );
  }
}
