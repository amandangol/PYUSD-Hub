import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

/// A collection of reusable UI components for the PYUSD Hub app.

/// A reusable app bar component with customizable styling.

class PyusdAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDarkMode;
  final VoidCallback? onRefreshPressed;
  final bool hasWallet;
  final String? title;
  final String? networkName;
  final bool showLogo;
  final Widget? customBackButton;
  final VoidCallback? onBackPressed;

  const PyusdAppBar({
    super.key,
    required this.isDarkMode,
    this.onRefreshPressed,
    this.title,
    this.networkName,
    this.hasWallet = false,
    this.showLogo = true,
    this.customBackButton,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: customBackButton ??
          (onBackPressed != null
              ? IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  onPressed: onBackPressed,
                )
              : null),
      automaticallyImplyLeading:
          customBackButton == null && onBackPressed == null,
      title: Row(
        children: [
          if (showLogo)
            Image.asset(
              'assets/images/pyusdlogo.png',
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.paid, size: 24);
              },
            ),
          if (showLogo && title != null) const SizedBox(width: 8),
          if (title != null)
            Text(
              title!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
        ],
      ),
      actions: [
        if (networkName != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Chip(
              label: Text(
                networkName!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              backgroundColor: isDarkMode
                  ? (networkName!.contains('Testnet')
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.green.withOpacity(0.2))
                  : (networkName!.contains('Testnet')
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1)),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              visualDensity: VisualDensity.compact,
              avatar: Icon(
                networkName!.contains('Testnet')
                    ? Icons.wifi_tethering
                    : Icons.public,
                size: 16,
                color: networkName!.contains('Testnet')
                    ? Colors.orange
                    : Colors.green,
              ),
            ),
          ),
        if (hasWallet && onRefreshPressed != null)
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
            ),
            onPressed: onRefreshPressed,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// A customizable button component with support for loading state, outlined style, and icons.

class PyusdButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool isOutlined;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;
  final double elevation;
  final Widget? icon;
  final bool isFullWidth;

  const PyusdButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
    this.height = 56,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 16,
    this.elevation = 0,
    this.icon,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final defaultBackgroundColor =
        isDarkMode ? theme.colorScheme.primary : const Color(0xFF3D56F0);
    const defaultForegroundColor = Colors.white;

    Widget button = isOutlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: Size(width ?? 0, height ?? 56),
              side: BorderSide(color: theme.colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
            child: _buildButtonContent(),
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              foregroundColor: foregroundColor ?? defaultForegroundColor,
              backgroundColor: backgroundColor ?? defaultBackgroundColor,
              minimumSize: Size(width ?? 0, height ?? 56),
              elevation: elevation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
            child: _buildButtonContent(),
          );

    if (isFullWidth) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// A reusable card component with customizable styling.
class PyusdCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final double elevation;
  final Border? border;
  final BoxShadow? shadow;

  const PyusdCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 12,
    this.backgroundColor,
    this.elevation = 1,
    this.border,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: theme.dividerColor,
              width: 1,
            ),
        boxShadow: shadow != null
            ? [shadow!]
            : elevation > 0
                ? [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
      ),
      child: child,
    );
  }
}

/// A reusable error message component.
class PyusdErrorMessage extends StatelessWidget {
  final String message;
  final double borderRadius;
  final EdgeInsets? padding;
  final double? iconSize;
  final double? fontSize;

  const PyusdErrorMessage({
    super.key,
    required this.message,
    this.borderRadius = 8,
    this.padding,
    this.iconSize,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: iconSize ?? 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
                fontSize: fontSize ?? 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A reusable dialog component.
class PyusdDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? cancelText;
  final String confirmText;
  final VoidCallback? onCancel;
  final VoidCallback onConfirm;
  final bool isDestructive;
  final double borderRadius;
  final Widget? icon;

  const PyusdDialog({
    super.key,
    required this.title,
    required this.content,
    this.cancelText,
    required this.confirmText,
    this.onCancel,
    required this.onConfirm,
    this.isDestructive = false,
    this.borderRadius = 16,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 8),
          ],
          Text(title),
        ],
      ),
      content: Text(
        content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      actions: [
        if (cancelText != null)
          TextButton(
            onPressed: onCancel ?? () => Navigator.of(context).pop(),
            child: Text(cancelText!),
          ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? theme.colorScheme.error : null,
            foregroundColor: isDestructive ? theme.colorScheme.onError : null,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}

/// A reusable text field component.
class PyusdTextField extends StatelessWidget {
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
  final String? errorText;

  const PyusdTextField({
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
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        suffixText: suffixText,
        errorText: errorText,
      ),
      validator: validator,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
    );
  }
}

/// A reusable PIN input component.
class PyusdPinInput extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onCompleted;
  final int pinLength;
  final String? label;

  const PyusdPinInput({
    super.key,
    required this.controller,
    this.onCompleted,
    this.pinLength = 6,
    this.label,
  });

  @override
  State<PyusdPinInput> createState() => _PyusdPinInputState();
}

class _PyusdPinInputState extends State<PyusdPinInput> {
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

/// A reusable list tile component.
class PyusdListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final Color? tileColor;
  final EdgeInsets? contentPadding;

  const PyusdListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.tileColor,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          title: Text(title),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                )
              : null,
          leading: leading,
          trailing: trailing,
          onTap: onTap,
          tileColor: tileColor,
          contentPadding: contentPadding,
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

/// A reusable bottom navigation bar component.
class PyusdBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;

  const PyusdBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor:
          Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      items: items,
    );
  }
}

/// A reusable bottom sheet component.
class PyusdBottomSheet extends StatelessWidget {
  final Widget child;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final Color? backgroundColor;
  final double borderRadius;

  const PyusdBottomSheet({
    super.key,
    required this.child,
    this.initialChildSize = 0.7,
    this.minChildSize = 0.4,
    this.maxChildSize = 0.95,
    this.backgroundColor,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? theme.colorScheme.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(borderRadius)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Draggable handle indicator
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TraceButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isLoading;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;
  final double? width;

  const TraceButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.backgroundColor = Colors.purple,
    this.foregroundColor = Colors.white,
    this.isLoading = false,
    this.horizontalPadding = 10,
    this.verticalPadding = 12,
    this.borderRadius = 8,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return Container(
        width: 24,
        height: 24,
        padding: const EdgeInsets.all(2.0),
        child: CircularProgressIndicator(
          color: foregroundColor,
          strokeWidth: 3,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Text(text),
    );
  }
}
