import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../../widgets/pyusd_components.dart';
import '../provider/auth_provider.dart';
import '../service/wallet_service.dart';
import '../widget/pin_input_widget.dart.dart';
import '../../../providers/navigation_provider.dart';

class ImportWalletScreen extends StatefulWidget {
  const ImportWalletScreen({super.key});

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen> {
  final TextEditingController _mnemonicController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _pinMatch = true;

  @override
  void dispose() {
    _mnemonicController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _validatePins() {
    if (_pinController.text != _confirmPinController.text) {
      setState(() {
        _pinMatch = false;
      });
    } else {
      setState(() {
        _pinMatch = true;
      });
    }
  }

  Future<void> _importWallet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_pinController.text != _confirmPinController.text) {
      setState(() {
        _errorMessage = "PINs don't match";
      });
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

      // Validate mnemonic before proceeding
      if (!await _validateMnemonic(mnemonic)) {
        setState(() {
          _errorMessage =
              "Invalid recovery phrase. Please check and try again.";
          _isLoading = false;
        });
        return;
      }

      await authProvider.importWalletFromMnemonic(mnemonic, pin);

      if (mounted) {
        // Set the wallet screen before navigation
        context.read<NavigationProvider>().setWalletScreen();
        // Navigate to main app and clear the navigation stack
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/main',
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Add this new method to validate the mnemonic
  Future<bool> _validateMnemonic(String mnemonic) async {
    try {
      // First check if the mnemonic is valid using the bip39 package
      final walletService = WalletService();
      return await walletService.validateMnemonic(mnemonic);
    } catch (e) {
      return false;
    }
  }

  void _showSecurityTips() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Security Tips',
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SecurityTip(
              icon: Icons.location_on,
              text: 'Ensure you are in a private location',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),
            SecurityTip(
              icon: Icons.people_alt_outlined,
              text: 'Never share your recovery phrase with anyone',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),
            SecurityTip(
              icon: Icons.warning_amber_rounded,
              text:
                  'This app will never ask for your recovery phrase outside of this import screen',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),
            SecurityTip(
              icon: Icons.lock_outline,
              text:
                  'Create a strong PIN you can remember but others cannot guess',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: PyusdButton(
                onPressed: () => Navigator.pop(context),
                text: 'Got it',
                borderRadius: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PyusdAppBar(
        showLogo: false,
        isDarkMode: isDarkMode,
        title: "Import Wallet",
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildConfirmingView(theme)
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter your recovery phrase to access your wallet',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Recovery phrase input
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
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode
                                    ? Colors.black.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
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
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'Enter words separated by spaces',
                              hintStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.white38
                                    : Colors.black38,
                                fontSize: 14,
                              ),
                              helperText:
                                  'Each word should be separated by a single space',
                              helperStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.white38
                                    : Colors.black38,
                                fontSize: 12,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  Icons.content_paste_rounded,
                                  size: 18,
                                  color: isDarkMode
                                      ? theme.colorScheme.primary
                                      : const Color(0xFF3D56F0),
                                ),
                                onPressed: () async {
                                  final data =
                                      await Clipboard.getData('text/plain');
                                  if (data != null && data.text != null) {
                                    _mnemonicController.text = data.text!;
                                  }
                                },
                              ),
                            ),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 14,
                            ),
                            maxLines: 3,
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

                        const SizedBox(height: 24),

                        // PIN setup section
                        Text(
                          'Create New PIN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You\'ll use this PIN to access your wallet',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // PIN input
                        PinInput(
                          controller: _pinController,
                          onCompleted: (value) {
                            if (_confirmPinController.text.isNotEmpty) {
                              _validatePins();
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirm PIN
                        Text(
                          'Confirm PIN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        PinInput(
                          controller: _confirmPinController,
                          onCompleted: (value) {
                            if (_pinController.text.isNotEmpty) {
                              _validatePins();
                            }
                          },

                          // error: !_pinMatch,
                        ),

                        if (!_pinMatch) ...[
                          const SizedBox(height: 8),
                          Text(
                            'PINs do not match',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ],

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
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Import button
                        PyusdButton(
                          onPressed: _importWallet,
                          text: 'Import Wallet',
                          borderRadius: 12,
                          elevation: 2,
                        ),

                        const SizedBox(height: 16),
                        Center(
                          child: TextButton.icon(
                            onPressed: _showSecurityTips,
                            icon: Icon(
                              Icons.shield_outlined,
                              size: 16,
                              color: isDarkMode
                                  ? theme.colorScheme.primary
                                  : const Color(0xFF3D56F0),
                            ),
                            label: Text(
                              'View Security Tips',
                              style: TextStyle(
                                color: isDarkMode
                                    ? theme.colorScheme.primary
                                    : const Color(0xFF3D56F0),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
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
    );
  }

  Widget _buildConfirmingView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Setting up your wallet...',
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

class SecurityTip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDarkMode;

  const SecurityTip({
    super.key,
    required this.icon,
    required this.text,
    required this.isDarkMode,
  });

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
