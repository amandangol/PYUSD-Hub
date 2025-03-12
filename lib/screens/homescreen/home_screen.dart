import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_forensics/authentication/provider/auth_provider.dart';
import 'package:pyusd_forensics/providers/network_provider.dart';
import 'package:pyusd_forensics/screens/transactions/provider/transaction_provider.dart';
import '../../common/pyusd_appbar.dart';
import '../../providers/wallet_provider.dart';
import '../../utils/snackbar_utils.dart';
import '../transactions/view/receive_transaction/receive_screen.dart';
import '../transactions/view/send_transaction/send_screen.dart';
import '../settingscreen/settings_screen.dart';
import 'widgets/action_button.dart';
import 'widgets/balance_card.dart';
import 'widgets/network_status_card.dart';
import 'widgets/transaction_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  // Track the last refresh time
  DateTime? _lastRefreshTime;
  // Minimum duration between auto-refreshes (5 minutes)
  final _refreshCooldown = const Duration(minutes: 5);

  @override
  void initState() {
    super.initState();

    // Check if we need to refresh on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRefreshIfNeeded();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Check if refresh is needed based on time elapsed
  void _checkAndRefreshIfNeeded() {
    final now = DateTime.now();

    // If no previous refresh or if cooldown period has passed
    if (_lastRefreshTime == null ||
        now.difference(_lastRefreshTime!) > _refreshCooldown) {
      // Refresh in background without blocking UI
      _refreshWalletData(showLoadingIndicator: false);
    }
  }

  Future<void> _refreshWalletData(
      {bool forceRefresh = false, bool showLoadingIndicator = true}) async {
    // Prevent concurrent refreshes
    if (_isRefreshing && !forceRefresh) return;

    // Only show loading indicator if explicitly requested
    if (showLoadingIndicator) {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);

      await walletProvider.refreshBalances(forceRefresh: forceRefresh);
      transactionProvider.fetchTransactions(forceRefresh: true);

      // Update the last refresh timestamp
      _lastRefreshTime = DateTime.now();
    } catch (e) {
      print('Error refreshing wallet data: $e');
    } finally {
      if (mounted && showLoadingIndicator) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final networkProvider = Provider.of<NetworkProvider>(context);

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final primaryColor =
        isDarkMode ? theme.colorScheme.primary : const Color(0xFF3D56F0);
    final backgroundColor = isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;

    // Get the current wallet address - either from the local wallet or WalletConnect
    final currentWalletAddress = authProvider.getCurrentAddress() ?? '';

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: PyusdAppBar(
          isDarkMode: isDarkMode,
          hasWallet: true,
          onSettingsPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
          onRefreshPressed: () => _refreshWalletData(forceRefresh: true),
        ),
        body: _buildWalletContent(walletProvider, transactionProvider,
            networkProvider, isDarkMode, primaryColor, currentWalletAddress));
  }

  Widget _buildWalletContent(
      WalletProvider walletProvider,
      TransactionProvider transactionProvider,
      NetworkProvider networkProvider,
      bool isDarkMode,
      Color primaryColor,
      String walletAddress) {
    String networkTypeToString(NetworkType networkType) {
      return networkType.name;
    }

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
              BalanceCard(
                ethBalance: walletProvider.ethBalance,
                tokenBalance: walletProvider.tokenBalance, // Add tokenBalance
                walletAddress: walletAddress,
                isRefreshing: walletProvider.isBalanceRefreshing,
                primaryColor: primaryColor,
                networkName:
                    networkTypeToString(networkProvider.currentNetwork),
              ),

              // Action Buttons
              const SizedBox(height: 24),
              ActionButtons(
                primaryColor: primaryColor,
                isDarkMode: isDarkMode,
                onSendPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SendTransactionScreen()),
                  ).then((_) {
                    if (mounted) {
                      // Check if providers are still valid before refreshing
                      _refreshWalletData();
                    }
                  });
                },
                onReceivePressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ReceiveScreen()),
                  );
                },
                onSwapPressed: () {
                  SnackbarUtil.showSnackbar(
                    context: context,
                    message: "Swap Feature coming soon",
                  );
                },
              ),

              // Network Status Card
              const SizedBox(height: 24),
              NetworkStatusCard(
                isDarkMode: isDarkMode,
              ),

              const SizedBox(height: 24),
              TransactionsSection(
                transactions: transactionProvider.transactions,
                currentAddress: walletAddress,
                isLoading: transactionProvider.isLoading &&
                    !walletProvider.isBalanceRefreshing,
                isDarkMode: isDarkMode,
                primaryColor: primaryColor, // Added primaryColor parameter
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NetworkOption extends StatelessWidget {
  final String name;
  final bool isSelected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const NetworkOption({
    Key? key,
    required this.name,
    required this.isSelected,
    required this.isDarkMode,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withOpacity(0.1)
              : isDarkMode
                  ? Colors.transparent
                  : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? Colors.green.withOpacity(0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.green : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.green
                    : isDarkMode
                        ? Colors.white70
                        : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
