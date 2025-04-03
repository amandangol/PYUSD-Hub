import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_routes.dart';
import '../provider/onboarding_provider.dart';

class FirstTimeOnboardingScreen extends StatefulWidget {
  const FirstTimeOnboardingScreen({super.key});

  @override
  State<FirstTimeOnboardingScreen> createState() =>
      _FirstTimeOnboardingScreenState();
}

class _FirstTimeOnboardingScreenState extends State<FirstTimeOnboardingScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage(OnboardingProvider provider) {
    if (provider.currentPage < provider.totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding(provider);
    }
  }

  void _completeOnboarding(OnboardingProvider provider) async {
    await provider.completeOnboarding();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.walletSelection);
    }
  }

  void _handleDemoMode(BuildContext context) async {
    try {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      await provider.completeOnboarding(demoMode: true);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.main,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = Provider.of<OnboardingProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () => _completeOnboarding(onboardingProvider),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  onboardingProvider.setPage(index);
                },
                children: [
                  _buildWelcomePage(theme),
                  _buildSecurityPage(theme),
                  _buildFeaturesPage(theme),
                  _buildGetStartedPage(theme),
                ],
              ),
            ),

            // Page indicator and buttons
            Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Page indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onboardingProvider.totalPages,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == onboardingProvider.currentPage
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Next/Get Started button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _nextPage(onboardingProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        onboardingProvider.isLastPage ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Welcome icon
          Icon(
            Icons.account_balance_wallet,
            size: 100,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            'Welcome to PYUSD Hub',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            'Your secure wallet for managing digital assets',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Key benefits
          _buildFeatureItem(
            theme,
            Icons.security,
            'Secure & Non-custodial',
            'You have full control of your assets',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            theme,
            Icons.speed,
            'Fast & Efficient',
            'Quick transactions with optimal gas fees',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            theme,
            Icons.insights,
            'Detailed Analytics',
            'Track your portfolio performance',
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Security icon
          Icon(
            Icons.shield,
            size: 100,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            'Bank-Grade Security',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            'Your security is our top priority',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Security features
          _buildFeatureItem(
            theme,
            Icons.fingerprint,
            'Biometric Authentication',
            'Secure access with fingerprint or face ID',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            theme,
            Icons.enhanced_encryption,
            'Advanced Encryption',
            'Military-grade encryption for your data',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            theme,
            Icons.key,
            'Private Keys Never Leave Your Device',
            'Your keys remain secure on your device',
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Features icon
          Icon(
            Icons.auto_awesome,
            size: 100,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            'Powerful Features',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            'Everything you need to manage your digital assets',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // App features
          _buildFeatureItem(
            theme,
            Icons.account_balance_wallet,
            'Wallet Management',
            'Send, receive, and track your assets',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            theme,
            Icons.insights,
            'Transaction Insights',
            'Detailed analytics of your transactions',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            theme,
            Icons.network_check,
            'Network Status',
            'Real-time network congestion monitoring',
          ),
        ],
      ),
    );
  }

  Widget _buildGetStartedPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Get started icon
          Icon(
            Icons.rocket_launch,
            size: 100,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            'Ready to Get Started?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            'Choose how you want to begin your journey',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Options - Using ElevatedButton instead of PyusdButton to avoid layout issues
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleCreateWallet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Create New Wallet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _handleImportWallet(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Import Existing Wallet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _handleDemoMode(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.secondary,
                side: BorderSide(color: theme.colorScheme.secondary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Explore in Demo Mode',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCreateWallet(BuildContext context) async {
    try {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      await provider.completeOnboarding();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.createWallet,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _handleImportWallet(BuildContext context) async {
    try {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      await provider.completeOnboarding();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.importWallet,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildFeatureItem(
    ThemeData theme,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
