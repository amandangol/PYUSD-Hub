import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../receive_screen.dart';
import '../send_screen.dart';
import '../settings_screen.dart';
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

        // Force a complete refresh of both balance and transactions
        await walletProvider.refreshWalletData();

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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final primaryColor =
        isDarkMode ? theme.colorScheme.primary : const Color(0xFF3D56F0);
    final backgroundColor = isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/pyusdlogo.png',
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.paid, size: 24);
              },
            ),
            const SizedBox(width: 8),
            Text(
              'PYUSD Wallet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
            ),
            onPressed: () => _refreshWalletData(forceRefresh: true),
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) {
                // Refresh after returning from settings, but don't force
                _refreshWalletData();
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshWalletData(forceRefresh: true),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance Card
                BalanceCard(
                  balance: walletProvider.balance,
                  walletAddress: walletProvider.wallet?.address ?? '',
                  isRefreshing: walletProvider.isBalanceRefreshing,
                  primaryColor: primaryColor,
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Swap feature coming soon')),
                    );
                  },
                  onHistoryPressed: () {
                    _scrollController.animateTo(
                      300, // Approximate position of transactions
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                ),

                // Network Status Card
                const SizedBox(height: 24),
                NetworkStatusCard(isDarkMode: isDarkMode),

                // Transactions Section
                const SizedBox(height: 24),
                TransactionsSection(
                  transactions: walletProvider.transactions,
                  currentAddress: walletProvider.wallet?.address ?? '',
                  isLoading: walletProvider.isLoading &&
                      !walletProvider.isBalanceRefreshing,
                  isDarkMode: isDarkMode,
                  primaryColor: primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
