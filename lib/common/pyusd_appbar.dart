import 'package:flutter/material.dart';

class PyusdAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDarkMode;
  final VoidCallback? onRefreshPressed;
  final bool hasWallet;
  final String? title;
  final bool showLogo;
  final Widget? customBackButton;
  final VoidCallback? onBackPressed;

  const PyusdAppBar({
    super.key,
    required this.isDarkMode,
    this.onRefreshPressed,
    this.title,
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
