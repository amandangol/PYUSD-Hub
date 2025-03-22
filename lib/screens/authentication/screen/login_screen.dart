import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_hub/utils/snackbar_utils.dart';
import '../provider/auth_provider.dart';
import '../../../main.dart';
import '../widget/pin_input_widget.dart.dart';
import 'onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isBiometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometrics();
    });
  }

  Future<void> _checkBiometrics() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final biometricsAvailable = await authProvider.checkBiometrics();
    final biometricsEnabled = await authProvider.isBiometricsEnabled();

    if (mounted) {
      setState(() {
        _isBiometricsAvailable = biometricsAvailable && biometricsEnabled;
      });

      if (_isBiometricsAvailable) {
        _authenticateWithBiometrics();
      }
    }
  }

  Future<void> _authenticateWithPIN() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_pinController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your PIN';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool success =
          await authProvider.authenticateWithPIN(_pinController.text);
      if (success) {
        await authProvider.saveAuthState();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid PIN';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool success = await authProvider.authenticateWithBiometrics();
      if (success) {
        await authProvider.saveAuthState();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      } else {
        setState(() {
          _errorMessage = 'Biometric authentication failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showResetWalletDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Reset Wallet Access'),
        content: const Text(
          'You will be redirected to the onboarding screen to create a new wallet or import an existing one. Your current wallet data will remain on the device but you will need to import it again.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _navigateToOnboarding();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _navigateToOnboarding() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    authProvider.logout().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) =>
                  const OnboardingScreen(forceOnboarding: true)),
          (route) => false,
        );
      });
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletAddress =
        Provider.of<AuthProvider>(context).wallet?.address ?? '';
    final shortenedAddress = walletAddress.isNotEmpty
        ? '${walletAddress.substring(0, 7)}...${walletAddress.substring(walletAddress.length - 4)}'
        : '';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),

                  // App logo or brand identity
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      "assets/images/pyusdlogo.png",
                      height: 64,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Welcome Back',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Enter your PIN to unlock your wallet',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Wallet address display with copy button
                  if (walletAddress.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            shortenedAddress,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: 'Monospace',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            iconSize: 18,
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              // Copy to clipboard functionality
                              SnackbarUtil.showSnackbar(
                                  context: context,
                                  message: 'Address copied to clipboard');
                            },
                            icon: const Icon(Icons.copy_outlined),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],

                  // PIN Input
                  PinInput(
                    controller: _pinController,
                    onCompleted: (_) => _authenticateWithPIN(),
                  ),
                  const SizedBox(height: 16),

                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.errorContainer.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                            size: 18,
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
                    const SizedBox(height: 16),
                  ],

                  // Login button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _authenticateWithPIN,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onPrimary,
                      backgroundColor: theme.colorScheme.primary,
                      minimumSize: const Size.fromHeight(56),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Unlock Wallet',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),

                  // Biometrics button
                  if (_isBiometricsAvailable) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed:
                          _isLoading ? null : _authenticateWithBiometrics,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        side: BorderSide(color: theme.colorScheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(Icons.fingerprint,
                          color: theme.colorScheme.primary),
                      label: Text('Use Biometrics',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.primary,
                          )),
                    ),
                  ],

                  // Forgot PIN / Reset access section
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: _isLoading ? null : _showResetWalletDialog,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                    child: Text(
                      'Forgot PIN? Reset Wallet Access',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
