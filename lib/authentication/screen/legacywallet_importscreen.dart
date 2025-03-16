import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../authentication/provider/auth_provider.dart';
import '../../common/pyusd_appbar.dart';

class LegacyWalletImportScreen extends StatefulWidget {
  const LegacyWalletImportScreen({Key? key}) : super(key: key);

  @override
  State<LegacyWalletImportScreen> createState() =>
      _LegacyWalletImportScreenState();
}

class _LegacyWalletImportScreenState extends State<LegacyWalletImportScreen> {
  final TextEditingController _privateKeyController = TextEditingController();
  final TextEditingController _mnemonicController = TextEditingController();
  bool _isPrivateKeyImport = true;
  bool _obscureText = true;

  @override
  void dispose() {
    _privateKeyController.dispose();
    _mnemonicController.dispose();
    super.dispose();
  }

  Future<void> _importWallet(AuthProvider authProvider) async {
    if (_isPrivateKeyImport) {
      final privateKey = _privateKeyController.text.trim();
      if (privateKey.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a private key')),
        );
        return;
      }
      await authProvider.importWalletFromPrivateKey(privateKey);
    } else {
      final mnemonic = _mnemonicController.text.trim();
      if (mnemonic.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a mnemonic phrase')),
        );
        return;
      }
      await authProvider.importWalletFromMnemonic(mnemonic);
    }

    if (authProvider.wallet != null && mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor =
        isDarkMode ? theme.colorScheme.primary : const Color(0xFF3D56F0);
    final backgroundColor = isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PyusdAppBar(
        isDarkMode: isDarkMode,
        hasWallet: false,
        title: 'Import Wallet',
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Toggle between import methods
                Row(
                  children: [
                    Expanded(
                      child: _buildToggleButton(
                        'Private Key',
                        _isPrivateKeyImport,
                        () => setState(() => _isPrivateKeyImport = true),
                        primaryColor,
                        isDarkMode,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildToggleButton(
                        'Mnemonic',
                        !_isPrivateKeyImport,
                        () => setState(() => _isPrivateKeyImport = false),
                        primaryColor,
                        isDarkMode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Private Key input
                if (_isPrivateKeyImport) ...[
                  Text(
                    'Enter your private key:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _privateKeyController,
                    decoration: InputDecoration(
                      hintText: '0x...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureText,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Warning: Never share your private key with anyone!',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                    ),
                  ),
                ]
                // Mnemonic input
                else ...[
                  Text(
                    'Enter your recovery phrase (mnemonic):',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _mnemonicController,
                    decoration: InputDecoration(
                      hintText: 'Enter 12 or 24 word recovery phrase',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureText,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    minLines: 3,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Words should be separated by spaces',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Warning: Never share your recovery phrase with anyone!',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Import button
                ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () => _importWallet(authProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Import Wallet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                // Error message
                if (authProvider.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authProvider.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildToggleButton(
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color primaryColor,
    bool isDarkMode,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : isDarkMode
                    ? Colors.white30
                    : Colors.black26,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? primaryColor
                : isDarkMode
                    ? Colors.white70
                    : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
