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

  final int _totalPages = 5;

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
            // Progress indicator and skip button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // Back button
                  if (onboardingProvider.currentPage > 0)
                    IconButton(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      ),
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  // Progress indicator
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (onboardingProvider.currentPage + 1) / _totalPages,
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                      minHeight: 4,
                    ),
                  ),
                  // Skip button
                  TextButton(
                    onPressed: () => _completeOnboarding(onboardingProvider),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
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
                  _buildWalletFeaturesPage(theme),
                  _buildInsightsPage(theme),
                  _buildNetworkToolsPage(theme),
                  _buildGetStartedPage(theme),
                ],
              ),
            ),

            // Page indicator and buttons
            Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Page indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _totalPages,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width:
                            index == onboardingProvider.currentPage ? 24 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
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
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              "assets/images/pyusdlogo.png",
              height: 64,
            ),
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

  Widget _buildWalletFeaturesPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 100,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 40),
          Text(
            'Complete Wallet Management',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Everything you need to manage your digital assets',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildFeatureItem(
            theme,
            Icons.swap_horiz,
            'Send & Receive',
            'Easily transfer PYUSD and ETH',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            theme,
            Icons.security,
            'Secure Storage',
            'Non-custodial wallet with biometric security',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            theme,
            Icons.history,
            'Transaction History',
            'Detailed transaction tracking and analysis',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights,
            size: 100,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 40),
          Text(
            'Market Insights & Analytics',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Stay informed with real-time market data',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildFeatureItem(
            theme,
            Icons.show_chart,
            'Price Tracking',
            'Real-time PYUSD price and market data',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            theme,
            Icons.article,
            'News Feed',
            'Latest PYUSD and crypto market news',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            theme,
            Icons.analytics,
            'Exchange Analytics',
            'Track PYUSD trading across exchanges',
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkToolsPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hub,
            size: 100,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 40),
          Text(
            'Advanced Network Tools',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Monitor and analyze network activity',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildFeatureItem(
            theme,
            Icons.speed,
            'Network Congestion',
            'Real-time gas prices and network status',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            theme,
            Icons.account_tree,
            'Transaction Tracing',
            'Detailed transaction analysis tools',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            theme,
            Icons.location_city,
            'PYUSD City View',
            'Visualize network activity in 3D',
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
          Icon(
            Icons.rocket_launch,
            size: 100,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 40),
          Text(
            'Ready to Get Started?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Choose how you want to begin your journey',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleCreateWallet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
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
