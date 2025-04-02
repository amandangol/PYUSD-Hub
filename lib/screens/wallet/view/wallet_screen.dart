import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/pyusd_components.dart';
import '../../authentication/provider/auth_provider.dart';
import '../../../providers/network_provider.dart';
import '../../../providers/walletstate_provider.dart';
import '../../../utils/snackbar_utils.dart';
import '../../onboarding/view/onboarding_screen.dart';
import '../../transactions/model/transaction_model.dart';
import '../../transactions/provider/transaction_provider.dart';
import '../../transactions/view/receive_transaction/receive_screen.dart';
import '../../transactions/view/send_transaction/send_screen.dart';
import '../widgets/action_button.dart';
import '../widgets/balance_card.dart';
import '../widgets/network_status_card.dart';
import '../widgets/transaction_section.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  bool _hasError = false;
  Timer? _debounceTimer;
  Timer? _refreshTimer;
  AnimationController? _refreshIndicatorController;
  NetworkProvider? _networkProvider;

  @override
  void initState() {
    super.initState();
    _refreshIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

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

  void _initializeData() {
    if (!mounted) return;

    // Initial data load
    _refreshWalletData(showLoadingIndicator: true);
  }

  @override
  void dispose() {
    // Safely remove listener using the stored reference
    if (_networkProvider != null) {
      _networkProvider!.removeListener(_onNetworkChanged);
    }

    _debounceTimer?.cancel();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    _refreshIndicatorController?.dispose();
    super.dispose();
  }

  Future<void> _refreshWalletData({
    bool forceRefresh = false,
    bool showLoadingIndicator = true,
  }) async {
    if (_isRefreshing && !forceRefresh) return;
    if (!mounted) return;

    setState(() {
      _isRefreshing = true;
      _hasError = false;
    });

    if (showLoadingIndicator) {
      _refreshIndicatorController?.repeat();
    }

    try {
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);
      final walletProvider =
          Provider.of<WalletStateProvider>(context, listen: false);

      // Start both refreshes immediately and wait for them to complete
      final balanceFuture =
          walletProvider.refreshBalances(forceRefresh: forceRefresh);
      final transactionsFuture =
          transactionProvider.refreshWalletData(forceRefresh: forceRefresh);

      // Use Future.wait with a timeout
      await Future.wait(
        [balanceFuture, transactionsFuture],
        eagerError: false, // Continue even if one fails
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          // Handle timeout gracefully
          print('Refresh timeout - some operations may not have completed');
          return [null, null];
        },
      );
    } catch (e) {
      print('Error refreshing wallet data: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        if (showLoadingIndicator) {
          _refreshIndicatorController?.stop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use select instead of Provider.of where possible to minimize rebuilds
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.scaffoldBackgroundColor;

    // Get wallet address only once
    final currentWalletAddress = context.select<AuthProvider, String?>(
            (provider) => provider.getCurrentAddress()) ??
        '';

    // Read network name once
    final networkName = context.select<NetworkProvider, String>(
        (provider) => provider.currentNetworkDisplayName);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PyusdAppBar(
        isDarkMode: isDarkMode,
        hasWallet: true,
        showLogo: true,
        title: "PYUSD Wallet",
        networkName: networkName,
      ),
      body: _buildBody(
          isDarkMode: isDarkMode,
          primaryColor: primaryColor,
          walletAddress: currentWalletAddress,
          networkName: networkName),
    );
  }

  Widget _buildBody(
      {required bool isDarkMode,
      required Color primaryColor,
      required String walletAddress,
      required String networkName}) {
    return RefreshIndicator(
      onRefresh: () => _refreshWalletData(forceRefresh: true),
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

              // Transactions with selective rebuilds
              _buildTransactionsSection(
                isDarkMode: isDarkMode,
                primaryColor: primaryColor,
                walletAddress: walletAddress,
              ),
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
                'There was an error loading data. Pull down to refresh.',
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

  Widget _buildTransactionsSection({
    required bool isDarkMode,
    required Color primaryColor,
    required String walletAddress,
  }) {
    final transactions =
        context.select<TransactionProvider, List<TransactionModel>>(
            (provider) => provider.transactions);
    final isLoading = context.select<TransactionProvider, bool>(
        (provider) => provider.isFetchingTransactions);

    return TransactionsSection(
      transactions: transactions,
      currentAddress: walletAddress,
      isLoading: isLoading,
      isDarkMode: isDarkMode,
      primaryColor: primaryColor,
    );
  }

  // Navigation methods
  void _navigateToSend() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const SendTransactionScreen()),
    ).then((transactionSent) {
      if (mounted && transactionSent == true) {
        // Only refresh if a transaction was actually sent
        _refreshWalletData(forceRefresh: true);
      }
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

  void _onNetworkChanged() {
    if (mounted) {
      // Clear any existing errors
      setState(() {
        _hasError = false;
      });

      // Add a small delay to allow the network change to complete
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _refreshWalletData(forceRefresh: true);
        }
      });
    }
  }
}
