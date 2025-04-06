import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/pyusd_components.dart';
import '../../authentication/provider/auth_provider.dart';
import '../../../providers/network_provider.dart';
import '../../../providers/walletstate_provider.dart';
import '../../../utils/snackbar_utils.dart';
import '../../transactions/model/transaction_model.dart';
import '../../transactions/provider/transaction_provider.dart';
import '../../transactions/provider/transactiondetail_provider.dart';
import '../../transactions/view/receive_transaction/receive_screen.dart';
import '../../transactions/view/send_transaction/send_screen.dart';
import '../provider/walletscreen_provider.dart';
import '../widgets/action_button.dart';
import '../widgets/balance_card.dart';
import '../widgets/network_status_card.dart';
import '../widgets/transaction_section.dart';
import '../../onboarding/provider/onboarding_provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _hasError = false;
  Timer? _debounceTimer;
  NetworkProvider? _networkProvider;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    // Listen for network changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _networkProvider = Provider.of<NetworkProvider>(context, listen: false);
      _networkProvider?.addListener(_onNetworkChanged);
      _initializeData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store a reference to the provider here to safely use in dispose
    _networkProvider = Provider.of<NetworkProvider>(context, listen: false);
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    final walletScreenProvider =
        Provider.of<WaletScreenProvider>(context, listen: false);
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);
    final walletStateProvider =
        Provider.of<WalletStateProvider>(context, listen: false);

    // Add listener for transaction updates
    transactionProvider.addListener(_onTransactionUpdate);

    await walletScreenProvider.refreshAllData();
    await walletStateProvider.refreshBalances();
  }

  void _onTransactionUpdate() {
    if (!mounted) return;

    // Refresh balances when transaction status changes
    final walletStateProvider =
        Provider.of<WalletStateProvider>(context, listen: false);
    walletStateProvider.refreshBalances();
  }

  @override
  void dispose() {
    // Safely remove listener using the stored reference
    if (_networkProvider != null) {
      _networkProvider!.removeListener(_onNetworkChanged);
    }

    // Remove transaction update listener
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);
    transactionProvider.removeListener(_onTransactionUpdate);

    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onNetworkChanged() {
    if (!mounted) return;

    // Cancel any existing debounce timer
    _debounceTimer?.cancel();

    // Set a debounce timer to prevent multiple refreshes
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      // Network change handling is now managed by providers
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = Provider.of<OnboardingProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Show demo mode or no wallet view if in demo mode or no wallet
    if (!onboardingProvider.hasCompletedOnboarding) {
      // Redirect to onboarding if not completed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      });
      return const SizedBox.shrink();
    }

    // Check if we have a wallet and are authenticated
    if (!authProvider.hasWallet || !authProvider.isAuthenticated) {
      return _buildDemoWalletView(context);
    }

    // Original wallet screen implementation
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PyusdAppBar(
        isDarkMode: isDarkMode,
        hasWallet: true,
        showLogo: true,
        title: "PYUSD Wallet",
      ),
      body: _buildBody(
          isDarkMode: isDarkMode,
          primaryColor: theme.colorScheme.primary,
          walletAddress: authProvider.getCurrentAddress() ?? '',
          networkName: _networkProvider?.currentNetworkDisplayName ?? ''),
    );
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final walletScreenProvider =
          Provider.of<WaletScreenProvider>(context, listen: false);
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);
      final walletStateProvider =
          Provider.of<WalletStateProvider>(context, listen: false);
      final networkProvider =
          Provider.of<NetworkProvider>(context, listen: false);
      final transactionDetailProvider =
          Provider.of<TransactionDetailProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentAddress = authProvider.getCurrentAddress() ?? '';

      // Clear transaction details cache
      transactionDetailProvider.clearCache();

      // Refresh all data in parallel
      await Future.wait([
        transactionProvider.fetchTransactions(forceRefresh: true),
        walletStateProvider.refreshBalances(),
      ]);

      // Pre-fetch transaction details for recent transactions
      if (transactionProvider.transactions.isNotEmpty) {
        transactionDetailProvider.preFetchTransactionDetails(
          transactions: transactionProvider.transactions.take(5).toList(),
          rpcUrl: networkProvider.currentRpcEndpoint,
          networkType: networkProvider.currentNetwork,
          currentAddress: currentAddress,
        );
      }

      // Force UI update
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error refreshing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Widget _buildBody(
      {required bool isDarkMode,
      required Color primaryColor,
      required String walletAddress,
      required String networkName}) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error message if needed
              if (_hasError) _buildErrorMessage(),

              // Balance card with selective rebuilds
              _buildBalanceCard(
                isDarkMode: isDarkMode,
                primaryColor: primaryColor,
                walletAddress: walletAddress,
                networkName: networkName,
              ),

              const SizedBox(height: 24),

              // Action buttons
              ActionButtons(
                primaryColor: primaryColor,
                isDarkMode: isDarkMode,
                onSendPressed: _navigateToSend,
                onReceivePressed: _navigateToReceive,
                onSwapPressed: _showSwapMessage,
              ),

              const SizedBox(height: 24),

              // Network status card
              NetworkStatusCard(isDarkMode: isDarkMode),

              const SizedBox(height: 24),

              // Add transaction list section
              _buildTransactionList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'There was an error loading data.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard({
    required bool isDarkMode,
    required Color primaryColor,
    required String walletAddress,
    required String networkName,
  }) {
    // Use Selector to minimize rebuilds, but ensure fresh data
    final ethBalance = context
        .select<WalletStateProvider, double>((provider) => provider.ethBalance);

    final tokenBalance = context.select<WalletStateProvider, double>(
        (provider) => provider.tokenBalance);

    final isRefreshing = context.select<WalletStateProvider, bool>(
        (provider) => provider.isBalanceRefreshing);

    final isInitialLoad = context.select<WalletStateProvider, bool>(
        (provider) => provider.isInitialLoad);

    return BalanceCard(
      ethBalance: ethBalance,
      tokenBalance: tokenBalance,
      walletAddress: walletAddress,
      isRefreshing: isRefreshing || isInitialLoad,
      primaryColor: primaryColor,
      // networkName: networkName,
    );
  }

  // Navigation methods
  void _navigateToSend() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const SendTransactionScreen()),
    ).then((transactionSent) {
      // No refresh needed after transaction
    });
  }

  void _navigateToReceive() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReceiveScreen()),
    );
  }

  void _showSwapMessage() {
    SnackbarUtil.showSnackbar(
      context: context,
      message: "Swap Feature coming soon",
    );
  }

  Widget _buildDemoWalletView(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PyusdAppBar(
        isDarkMode: isDarkMode,
        showLogo: true,
        title: "Demo Mode",
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Create or Import a Wallet',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'To access wallet features, you need to create a new wallet or import an existing one.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Meanwhile, you can explore other features of the app in demo mode!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
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
                  child: const Text('Create New Wallet'),
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
                  child: const Text('Import Existing Wallet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCreateWallet(BuildContext context) async {
    final onboardingProvider =
        Provider.of<OnboardingProvider>(context, listen: false);

    // If in demo mode, exit demo mode first
    if (onboardingProvider.isDemoMode) {
      await onboardingProvider.exitDemoMode();
    }

    if (mounted) {
      // Navigate to create wallet screen using string route
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/create-wallet',
        (route) => false,
      );
    }
  }

  void _handleImportWallet(BuildContext context) async {
    final onboardingProvider =
        Provider.of<OnboardingProvider>(context, listen: false);

    // If in demo mode, exit demo mode first
    if (onboardingProvider.isDemoMode) {
      await onboardingProvider.exitDemoMode();
    }

    if (mounted) {
      // Navigate to import wallet screen using string route
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/import-wallet',
        (route) => false,
      );
    }
  }

  Widget _buildTransactionList() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentAddress = authProvider.getCurrentAddress() ?? '';

    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        return TransactionSection(
          isDarkMode: isDarkMode,
          currentAddress: currentAddress,
        );
      },
    );
  }
}
