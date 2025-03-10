import 'package:flutter/material.dart';
import '../authentication/screen/create_wallet_screen.dart';
import '../authentication/screen/import_wallet_screen.dart';

class WalletSelectionScreen extends StatelessWidget {
  const WalletSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor =
        isDarkMode ? theme.colorScheme.primary : const Color(0xFF3D56F0);
    final backgroundColor = isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Wallet Setup',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Welcome to PYUSD Wallet',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose how you want to set up your wallet',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),

              const SizedBox(height: 48),

              // Wallet options
              // Create new wallet option
              _buildOptionCard(
                context: context,
                icon: Icons.add_circle_outline_rounded,
                title: 'Create New Wallet',
                description: 'Generate a new wallet with recovery phrase',
                onTap: () {
                  // Pass the context directly since WalletService is now available globally
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateWalletScreen(),
                    ),
                  );
                },
                isDarkMode: isDarkMode,
                primaryColor: primaryColor,
              ),

              const SizedBox(height: 24),

              // Import wallet option
              _buildOptionCard(
                context: context,
                icon: Icons.file_download_outlined,
                title: 'Import Existing Wallet',
                description: 'Restore wallet using recovery phrase',
                onTap: () {
                  // Pass the context directly since WalletService is now available globally
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ImportWalletScreen(),
                    ),
                  );
                },
                isDarkMode: isDarkMode,
                primaryColor: primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required bool isDarkMode,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF252543) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDarkMode ? Colors.white54 : Colors.black45,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
