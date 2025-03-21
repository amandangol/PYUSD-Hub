import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/pyusd_appbar.dart';
import '../provider/auth_provider.dart';
import 'mnemonic_screen.dart';
import 'pin_input_widget.dart.dart';

class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _createWallet() async {
    // Validate PIN
    if (_pinController.text.length < 6) {
      setState(() {
        _errorMessage = 'PIN must be at least 6 digits';
      });
      return;
    }

    if (_pinController.text != _confirmPinController.text) {
      setState(() {
        _errorMessage = 'PINs do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.createWallet(_pinController.text);

      if (mounted && authProvider.wallet != null) {
        // Navigate to mnemonic confirmation screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MnemonicConfirmationScreen(
              mnemonic: authProvider.wallet!.mnemonic,
              pin: _pinController.text,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to create wallet: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: PyusdAppBar(
        showLogo: false,
        isDarkMode: isDarkMode,
        title: "Create New Wallet",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set Security PIN',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Create a secure PIN to protect your wallet. You\'ll need this PIN to access your wallet and confirm transactions.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),

              // Enter PIN
              PinInput(
                controller: _pinController,
              ),
              const SizedBox(height: 24),

              // Confirm PIN
              Text(
                'Confirm PIN',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              PinInput(
                controller: _confirmPinController,
              ),
              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                const SizedBox(height: 16),
              ],

              // Create wallet button
              ElevatedButton(
                onPressed: _isLoading ? null : _createWallet,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Wallet'),
              ),
              const SizedBox(height: 16),

              // Security information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security Note',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your wallet is encrypted and stored only on this device. If you lose your PIN and recovery phrase, your funds will be lost permanently.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
