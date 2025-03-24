import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/pyusd_components.dart';
import '../provider/auth_provider.dart';
import 'create_wallet_screen.dart';
import 'import_wallet_screen.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final bool forceOnboarding;

  const OnboardingScreen({super.key, this.forceOnboarding = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWalletStatus();
    });
  }

  Future<void> _checkWalletStatus() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initWallet();

    // Only auto-navigate to login if not in force-onboarding mode
    if (!widget.forceOnboarding && authProvider.wallet != null && mounted) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _navigateToCreateWallet() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CreateWalletScreen()));
  }

  void _navigateToImportWallet() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ImportWalletScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            )
          : _buildOnboardingContent(theme),
    );
  }

  Widget _buildLoginOption() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final theme = Theme.of(context);

    // Only show this if a wallet exists but we're in forceOnboarding mode
    if (widget.forceOnboarding && authProvider.wallet != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 24.0),
        child: TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()));
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          child: Text(
            'Log in with existing wallet',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildOnboardingContent(ThemeData theme) {
    return SafeArea(
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

                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      "assets/images/pyusdlogo.png",
                      height: 80,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'PYUSD Hub',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  'Secure, non-custodial wallet for managing your digital assets',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 48),

                // Create Wallet Button
                PyusdButton(
                  onPressed: _navigateToCreateWallet,
                  text: 'Create New Wallet',
                ),
                const SizedBox(height: 16),

                // Import Wallet Button
                PyusdButton(
                  onPressed: _navigateToImportWallet,
                  text: 'Import Existing Wallet',
                  isOutlined: true,
                ),

                _buildLoginOption(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
