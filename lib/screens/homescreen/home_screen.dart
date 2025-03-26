import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/pyusd_components.dart';
import '../authentication/provider/auth_provider.dart';
import '../../providers/network_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../utils/snackbar_utils.dart';
import '../transactions/model/transaction_model.dart';
import '../transactions/provider/transaction_provider.dart';
import '../transactions/view/receive_transaction/receive_screen.dart';
import '../transactions/view/send_transaction/send_screen.dart';
import 'widgets/action_button.dart';
import 'widgets/balance_card.dart';
import 'widgets/network_status_card.dart';
import 'widgets/transaction_section.dart';
import 'provider/homescreen_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  bool _hasError = false;
  Timer? _debounceTimer;
  Timer? _refreshTimer;
  AnimationController? _refreshIndicatorController;

  @override
  void initState() {
    super.initState();
    _refreshIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initialize the HomeScreenProvider
      await context.read<HomeScreenProvider>().initialize();
      _initializeData();
      // Set up periodic refresh
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (mounted) {
          _refreshWalletData(showLoadingIndicator: false);
        }
      });
    });
  }

  void _initializeData() {
    if (!mounted) return;

    // Initial data load
    _refreshWalletData(showLoadingIndicator: true);
  }

  @override
  void dispose() {
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

      // Single refresh call that updates both transactions and balances
      await transactionProvider.refreshWalletData(forceRefresh: forceRefresh);
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
    final primaryColor =
        isDarkMode ? theme.colorScheme.primary : const Color(0xFF3D56F0);
    final backgroundColor = isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;

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
        onRefreshPressed: () => _refreshWalletData(forceRefresh: true),
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
        .select<WalletProvider, double>((provider) => provider.ethBalance);

    final tokenBalance = context
        .select<WalletProvider, double>((provider) => provider.tokenBalance);

    final isRefreshing = context.select<WalletProvider, bool>(
        (provider) => provider.isBalanceRefreshing);

    final isInitialLoad = context
        .select<WalletProvider, bool>((provider) => provider.isInitialLoad);

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
}
