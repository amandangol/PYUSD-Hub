import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../../widgets/loading_overlay.dart';
import '../provider/auth_provider.dart';

class ImportWalletScreen extends StatefulWidget {
  const ImportWalletScreen({super.key});

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen> {
  final TextEditingController _mnemonicController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  TextEditingController _pinController = TextEditingController();

  @override
  void dispose() {
    _mnemonicController.dispose();
    super.dispose();
  }

  Future<void> _importWallet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final pin = _pinController.text.trim();
      final mnemonic = _mnemonicController.text.trim();

      await authProvider.importWalletFromMnemonic(mnemonic, pin);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainApp()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return LoadingOverlay(
      isLoading: _isLoading,
      loadingText: 'Importing your wallet...',
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
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
          iconTheme: IconThemeData(
            color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Import Existing Wallet',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enter your recovery phrase to access your wallet',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Recovery phrase input
                    Row(
                      children: [
                        Icon(
                          Icons.vpn_key_rounded,
                          color: isDarkMode
                              ? theme.colorScheme.primary
                              : const Color(0xFF3D56F0),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recovery Phrase',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
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
                      child: TextFormField(
                        controller: _mnemonicController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDarkMode
                              ? const Color(0xFF252543)
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          hintText: 'Enter words separated by spaces',
                          hintStyle: TextStyle(
                            color: isDarkMode ? Colors.white38 : Colors.black38,
                          ),
                          helperText:
                              'Each word should be separated by a single space',
                          helperStyle: TextStyle(
                            color: isDarkMode ? Colors.white38 : Colors.black38,
                          ),
                          alignLabelWithHint: true,
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your recovery phrase';
                          }

                          final wordCount = value.trim().split(' ').length;
                          if (![12, 15, 18, 21, 24].contains(wordCount)) {
                            return 'Recovery phrase must have 12, 15, 18, 21, or 24 words';
                          }

                          return null;
                        },
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Paste button
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data != null && data.text != null) {
                            _mnemonicController.text = data.text!;
                          }
                        },
                        icon: Icon(
                          Icons.content_paste_rounded,
                          color: isDarkMode
                              ? theme.colorScheme.primary
                              : const Color(0xFF3D56F0),
                        ),
                        label: Text(
                          'Paste from Clipboard',
                          style: TextStyle(
                            color: isDarkMode
                                ? theme.colorScheme.primary
                                : const Color(0xFF3D56F0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDarkMode
                                  ? theme.colorScheme.primary.withOpacity(0.5)
                                  : const Color(0xFF3D56F0).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Import Information
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF252543)
                            : const Color(0xFFF5F7FF),
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
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? theme.colorScheme.primary
                                          .withOpacity(0.2)
                                      : const Color(0xFF3D56F0)
                                          .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.shield_rounded,
                                  color: isDarkMode
                                      ? theme.colorScheme.primary
                                      : const Color(0xFF3D56F0),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Security Tips',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? theme.colorScheme.primary
                                      : const Color(0xFF3D56F0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SecurityTip(
                            icon: Icons.location_on,
                            text: 'Ensure you are in a private location',
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 12),
                          SecurityTip(
                            icon: Icons.people_alt_outlined,
                            text:
                                'Never share your recovery phrase with anyone',
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 12),
                          SecurityTip(
                            icon: Icons.warning_amber_rounded,
                            text:
                                'This app will never ask for your recovery phrase outside of this import screen',
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Import button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _importWallet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode
                              ? theme.colorScheme.primary
                              : const Color(0xFF3D56F0),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: isDarkMode
                              ? theme.colorScheme.primary.withOpacity(0.4)
                              : const Color(0xFF3D56F0).withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Import Wallet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SecurityTip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDarkMode;

  const SecurityTip({
    Key? key,
    required this.icon,
    required this.text,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}
