import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_hub/screens/authentication/screen/login_screen.dart';
import 'package:pyusd_hub/screens/onboarding/view/onboarding_screen.dart';
import '../provider/auth_provider.dart';
import 'wallet_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initWallet();

      if (!mounted) return;

      // Add a minimum delay to show the splash screen
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      // Determine which screen to show
      if (authProvider.hasWallet) {
        // If we have a wallet, go to login screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        // If no wallet, go to onboarding
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WalletSelectionScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Handle any initialization errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initializing app: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo or app name
            FadeTransition(
              opacity: _animation,
              child: Column(
                children: [
                  Image.asset(
                    "assets/images/pyusdlogo.png",
                    height: 80,
                    width: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PYUSD Hub',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Loading indicator
            FadeTransition(
              opacity: _animation,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
