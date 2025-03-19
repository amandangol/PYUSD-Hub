import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import 'create_wallet_screen.dart';
import 'import_wallet_screen.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final bool forceOnboarding;

  const OnboardingScreen({Key? key, this.forceOnboarding = false})
      : super(key: key);

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
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Setup'),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingScreen(primaryColor)
          : _buildOnboardingContent(theme, primaryColor),
    );
  }

  Widget _buildLoadingScreen(Color primaryColor) {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
      ),
    );
  }

  // Add this to your OnboardingScreen widget
  Widget _buildLoginOption() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Only show this if a wallet exists but we're in forceOnboarding mode
    if (widget.forceOnboarding && authProvider.wallet != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()));
          },
          child: const Text('Try to log in with existing wallet'),
        ),
      );
    }

    return const SizedBox.shrink(); // Return empty widget if condition not met
  }

  Widget _buildOnboardingContent(ThemeData theme, Color primaryColor) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              "assets/images/pyusdlogo.png",
              height: 80,
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              'PYUSD Wallet',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
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
            const SizedBox(height: 50),

            // Create Wallet Button
            ElevatedButton(
              onPressed: _navigateToCreateWallet,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Create New Wallet'),
            ),
            const SizedBox(height: 16),

            // Import Wallet Button
            OutlinedButton(
              onPressed: _navigateToImportWallet,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Import Existing Wallet'),
            ),
            _buildLoginOption()
          ],
        ),
      ),
    );
  }
}
