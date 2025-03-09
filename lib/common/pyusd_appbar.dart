import 'package:flutter/material.dart';

class PyusdAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDarkMode;
  final VoidCallback onSettingsPressed;
  final VoidCallback? onRefreshPressed;
  final bool hasWallet;

  const PyusdAppBar({
    Key? key,
    required this.isDarkMode,
    required this.onSettingsPressed,
    this.onRefreshPressed,
    this.hasWallet = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Image.asset(
            'assets/images/pyusdlogo.png',
            height: 24,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.paid, size: 24);
            },
          ),
          const SizedBox(width: 8),
          Text(
            'PYUSD Wallet',
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
        IconButton(
          icon: Icon(
            Icons.settings_outlined,
            color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
          ),
          onPressed: onSettingsPressed,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
