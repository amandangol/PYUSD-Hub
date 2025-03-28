import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pyusd_hub/widgets/pyusd_components.dart';

class CustomTextField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return PyusdTextField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      validator: validator,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      suffixText: suffixText,
      focusNode: focusNode,
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
