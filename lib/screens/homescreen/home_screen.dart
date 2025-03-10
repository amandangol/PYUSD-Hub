import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_forensics/authentication/provider/auth_provider.dart';
import 'package:pyusd_forensics/providers/network_provider.dart';
import 'package:pyusd_forensics/providers/transaction_provider.dart';
import '../../common/pyusd_appbar.dart';
import '../../providers/wallet_provider.dart';
import '../../utils/snackbar_utils.dart';
import '../transactions/receive_transaction/receive_screen.dart';
import '../transactions/send_transaction/send_screen.dart';
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
  bool _initialRefreshDone = false;

  // Add debounce timer
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Schedule data refresh after widget is built, but only once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialRefreshDone) {
        _refreshWalletData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshWalletData({bool forceRefresh = false}) async {
    // Prevent multiple refreshes in quick succession using debounce
    if (_isRefreshing && !forceRefresh) return;

    // Cancel any existing timer
    _debounceTimer?.cancel();

    // Set up a new timer
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;

      setState(() {
        _isRefreshing = true;
      });

      try {
        final walletProvider =
            Provider.of<WalletProvider>(context, listen: false);

        await walletProvider.refreshBalances();

        // Mark initial refresh as done to prevent duplicate refreshes
        _initialRefreshDone = true;
      } catch (e) {
        print('Error refreshing wallet data: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isRefreshing = false;
          });
        }
      }
    });
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
          hasWallet: true, // Set to true when wallet is available
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
                networkName: networkProvider.currentNetwork.toString(),
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
                    // Refresh after sending transaction
                    _refreshWalletData();
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
