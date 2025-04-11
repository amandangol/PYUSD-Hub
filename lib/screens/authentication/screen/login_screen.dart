import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_hub/utils/snackbar_utils.dart';
import 'package:pyusd_hub/widgets/pyusd_components.dart';
import '../provider/auth_provider.dart';
import '../widget/pin_input_widget.dart.dart';
import '../../../providers/navigation_provider.dart';
import '../../../routes/app_routes.dart';
import 'wallet_selection_screen.dart';
import '../../../screens/onboarding/view/onboarding_screen.dart';

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
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_pinController.text.isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Please enter your PIN';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool success =
          await authProvider.authenticateWithPIN(_pinController.text);
      if (!mounted) return;

      if (success) {
        await authProvider.saveAuthState();
        if (!mounted) return;

        // Set the wallet screen before navigation
        context.read<NavigationProvider>().setWalletScreen();

        // Use a post-frame callback to ensure the widget is still mounted
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.main,
            (route) => false,
          );
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Invalid PIN';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Authentication failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool success = await authProvider.authenticateWithBiometrics();
      if (!mounted) return;

      if (success) {
        await authProvider.saveAuthState();
        if (!mounted) return;

        // Set the wallet screen before navigation
        context.read<NavigationProvider>().setWalletScreen();

        // Use a post-frame callback to ensure the widget is still mounted
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.main,
            (route) => false,
          );
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Biometric authentication failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
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
      builder: (BuildContext dialogContext) => PyusdDialog(
        title: 'Reset Wallet Access',
        content:
            'You will be redirected to the wallet selection screen to create a new wallet or import an existing one. Your current wallet data will remain on the device but you will need to import it again.',
        confirmText: 'Continue',
        cancelText: 'Cancel',
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          _navigateToWalletSelection();
        },
      ),
    );
  }

  void _navigateToWalletSelection() {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    authProvider.logout().then((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                const WalletSelectionScreen(forceNavigateToSelect: true),
          ),
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
    final authProvider = Provider.of<AuthProvider>(context);
    final walletAddress = authProvider.wallet?.address ?? '';
    final shortenedAddress = walletAddress.isNotEmpty
        ? '${walletAddress.substring(0, 6)}...${walletAddress.substring(walletAddress.length - 4)}'
        : '';

    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog before exiting
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => PyusdDialog(
            title: 'Exit App',
            content: 'Are you sure you want to exit the app?',
            confirmText: 'Exit',
            cancelText: 'Cancel',
            onConfirm: () => Navigator.of(context).pop(true),
            onCancel: () => Navigator.of(context).pop(false),
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
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

                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.primaryContainer.withOpacity(0.5),
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
                      PyusdErrorMessage(
                        message: _errorMessage!,
                        borderRadius: 8,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Login button
                    PyusdButton(
                      onPressed: _isLoading ? null : _authenticateWithPIN,
                      text: 'Unlock Wallet',
                      isLoading: _isLoading,
                    ),

                    // Biometrics button
                    if (_isBiometricsAvailable) ...[
                      const SizedBox(height: 16),
                      PyusdButton(
                        onPressed:
                            _isLoading ? null : _authenticateWithBiometrics,
                        text: 'Use Biometrics',
                        isOutlined: true,
                        icon: Icon(Icons.fingerprint,
                            color: theme.colorScheme.primary),
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
                    TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const FirstTimeOnboardingScreen(),
                              ));
                        },
                        child: const Text('Test Onboarding')),
                    const SizedBox(height: 24),
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
