import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_hub/screens/trace/widgets/trace_widgets.dart';
import '../../../widgets/pyusd_components.dart';
import '../provider/auth_provider.dart';
import '../widget/pin_input_widget.dart.dart';
import '../../../routes/app_routes.dart';

class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isLoading = false;
  bool _isReturningFromMnemonic = false;
  String? _errorMessage;
  bool _isBiometricsAvailable = false;
  bool _enableBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _isBiometricsAvailable = await authProvider.checkBiometrics();
    if (mounted) setState(() {});
  }

  Future<void> _createWallet() async {
    // Validate PIN
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final validation = authProvider.validatePIN(_pinController.text);

    if (!validation.isValid) {
      setState(() {
        _errorMessage = validation.error;
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
      // Create wallet with PIN
      await authProvider.createWallet(_pinController.text);

      // Enable biometrics if selected and available
      if (_isBiometricsAvailable && _enableBiometrics) {
        await authProvider.enableBiometrics(_pinController.text);
      }

      if (mounted && authProvider.wallet != null) {
        // Navigate to show mnemonic screen with the PIN
        final result = await Navigator.of(context).pushNamed(
          AppRoutes.showMnemonic,
          arguments: {
            'mnemonic': authProvider.wallet!.mnemonic,
            'pin': _pinController.text,
          },
        );

        // Handle return from mnemonic screen
        if (mounted && result == null) {
          // null means user went back
          setState(() {
            _isReturningFromMnemonic = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _resetWalletCreation() {
    setState(() {
      _isReturningFromMnemonic = false;
      _isLoading = false;
      _errorMessage = null;
      _pinController.clear();
      _confirmPinController.clear();
      if (_isBiometricsAvailable) {
        _enableBiometrics = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show the "ready to create new wallet" screen only when returning from mnemonic
    if (_isReturningFromMnemonic) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PyusdAppBar(
          isDarkMode: theme.brightness == Brightness.dark,
          title: "Create Wallet",
          showLogo: false,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Start Fresh',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You exited before finishing your wallet setup.\nStart fresh to create a new wallet.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  PyusdButton(
                    isLoading: _isLoading,
                    borderRadius: 12,
                    onPressed: _resetWalletCreation,
                    text: 'Start New Wallet Setup',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PyusdAppBar(
        isDarkMode: theme.brightness == Brightness.dark,
        title: "Create Wallet",
        showLogo: false,
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
              Text(
                'Enter PIN',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
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

              // Biometric authentication option
              if (_isBiometricsAvailable) ...[
                const SizedBox(height: 16),
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
                        'Biometric Authentication',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enable fingerprint for quick and secure access',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Enable Biometrics'),
                        value: _enableBiometrics,
                        onChanged: (bool value) {
                          setState(() {
                            _enableBiometrics = value;
                          });
                        },
                        secondary: Icon(
                          Icons.fingerprint,
                          color: _enableBiometrics
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],

              const SizedBox(height: 32),

              // Create wallet button
              PyusdButton(
                onPressed: _isLoading ? null : _createWallet,
                text: _isLoading ? 'Creating Wallet...' : 'Create Wallet',
                isLoading: _isLoading,
                borderRadius: 12,
              ),

              const SizedBox(height: 24),

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

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }
}
