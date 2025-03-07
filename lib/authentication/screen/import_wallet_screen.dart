import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../services/wallet_service.dart';
import '../../widgets/loading_overlay.dart';

class ImportWalletScreen extends StatefulWidget {
  const ImportWalletScreen({Key? key}) : super(key: key);

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen> {
  final TextEditingController _mnemonicController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;
  late WalletService _walletService;

  @override
  void initState() {
    super.initState();
    _walletService = Provider.of<WalletService>(context, listen: false);
  }

  @override
  void dispose() {
    _mnemonicController.dispose();
    super.dispose();
  }

  Future<void> _importWallet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final mnemonic = _mnemonicController.text.trim();

      // Validate mnemonic
      if (!await _walletService.validateMnemonic(mnemonic)) {
        setState(() {
          _error = 'Invalid recovery phrase. Please check and try again.';
          _isLoading = false;
        });
        return;
      }

      // Import wallet from mnemonic
      await _walletService.createWalletFromMnemonic(mnemonic);

      // Navigate to the main app
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainApp()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to import wallet: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor =
        isDarkMode ? theme.colorScheme.primary : const Color(0xFF3D56F0);
    final backgroundColor = isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;

    return LoadingOverlay(
      isLoading: _isLoading,
      loadingText: 'Importing wallet...',
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Import Wallet',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import Using Recovery Phrase',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color:
                          isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter your 12-word recovery phrase to restore your wallet',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Recovery phrase input
                  TextFormField(
                    controller: _mnemonicController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Enter your recovery phrase, words separated by spaces',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.white38 : Colors.black38,
                      ),
                      fillColor: isDarkMode ? Colors.black12 : Colors.grey[100],
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              isDarkMode ? Colors.white24 : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              isDarkMode ? Colors.white24 : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Recovery phrase is required';
                      }

                      final wordCount = value.trim().split(' ').length;
                      if (wordCount != 12) {
                        return 'Recovery phrase must contain 12 words';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Helper text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white10 : Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isDarkMode ? Colors.white70 : Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Words should be separated by spaces. Check that each word is spelled correctly.',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Import button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _importWallet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Import Wallet'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Security note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white10 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode ? Colors.white24 : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Security Reminder',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Never share your recovery phrase with anyone. Be cautious of phishing attempts and only enter your phrase in trusted applications.',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
