import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import '../../../main.dart';
import '../widget/pin_input_widget.dart.dart';
import 'onboarding_screen.dart'; // Make sure this import is correct

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
    // Use post-frame callback to avoid setState during build
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

      // Automatically prompt for biometric auth if available
      if (_isBiometricsAvailable) {
        _authenticateWithBiometrics();
      }
    }
  }

// In login_screen.dart - Update the _authenticateWithPIN method
  Future<void> _authenticateWithPIN() async {
    // Change this line
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
        // Save authentication state
        await authProvider.saveAuthState();

        // Navigate to main app
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
        // Save authentication state
        await authProvider.saveAuthState();

        // Navigate to main app
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

  void _navigateToMainApp() {
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const MainApp()));
  }

  // Modified method to reset wallet access
  void _showResetWalletDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext dialogContext) => AlertDialog(
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
          TextButton(
            onPressed: () {
              // Close the dialog first
              Navigator.of(dialogContext).pop();
              // Then navigate to onboarding
              _navigateToOnboarding();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _navigateToOnboarding() {
    // Get the auth provider without listening to changes
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Complete the logout operation and then navigate
    authProvider.logout().then((_) {
      // Use a post-frame callback for clean navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Navigate with forceOnboarding flag set to true
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) =>
                  const OnboardingScreen(forceOnboarding: true)),
          (route) => false, // Remove all previous routes
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
        ? '${walletAddress.substring(0, 6)}...${walletAddress.substring(walletAddress.length - 4)}'
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Wallet'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Wallet icon
              Icon(
                Icons.lock_outline,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),

              // Wallet address display
              if (walletAddress.isNotEmpty) ...[
                Text(
                  'Wallet',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Text(
                    shortenedAddress,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // PIN Input
              PinInput(
                controller: _pinController,
                onCompleted: (_) => _authenticateWithPIN(),
              ),
              const SizedBox(height: 16),

              // Error message
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                const SizedBox(height: 16),
              ],

              // Login button
              ElevatedButton(
                onPressed: _isLoading ? null : _authenticateWithPIN,
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
                    : const Text('Unlock'),
              ),

              // Biometrics button
              if (_isBiometricsAvailable) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _authenticateWithBiometrics,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Use Biometrics'),
                ),
              ],

              // Forgot PIN / Reset access section
              const SizedBox(height: 24),
              TextButton(
                onPressed: _isLoading ? null : _showResetWalletDialog,
                child: Text(
                  'Forgot PIN? Reset Access',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
