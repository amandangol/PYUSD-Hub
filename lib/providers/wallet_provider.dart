import 'dart:async';
import 'package:flutter/material.dart';
import '../authentication/provider/auth_provider.dart';
import '../services/ethereum_rpc_service.dart';
import 'network_provider.dart';

class WalletProvider extends ChangeNotifier {
  final AuthProvider _authProvider;
  final NetworkProvider _networkProvider;
  final EthereumRpcService _rpcService = EthereumRpcService();

  // Balances
  final Map<NetworkType, double> _balances = {};
  final Map<NetworkType, double> _tokenBalances = {};

  // Token contract addresses
  final Map<NetworkType, String> _tokenContractAddresses = {
    NetworkType.sepoliaTestnet: '0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9',
    NetworkType.ethereumMainnet: '0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9',
  };

  // State
  bool _isBalanceRefreshing = false;
  bool _isRefreshingBalance = false;
  String? _error;

  // Timer for auto-refresh
  Timer? _refreshTimer;

  // Getters
  double get ethBalance => _balances[_networkProvider.currentNetwork] ?? 0.0;
  double get tokenBalance =>
      _tokenBalances[_networkProvider.currentNetwork] ?? 0.0;
  bool get isBalanceRefreshing => _isBalanceRefreshing;
  String? get error => _error;
  NetworkType get currentNetwork => _networkProvider.currentNetwork;

  // Constructor with dependency injection
  WalletProvider({
    required AuthProvider authProvider,
    required NetworkProvider networkProvider,
  })  : _authProvider = authProvider,
        _networkProvider = networkProvider {
    // Initialize balance maps for all networks
    _initializeBalanceMaps();

    // Listen for network changes
    _networkProvider.addListener(_onNetworkChanged);

    // Start auto-refresh if wallet exists
    if (_authProvider.hasWallet) {
      _startAutoRefresh();
    }

    // Initial balance refresh
    refreshBalances();
  }

  // Initialize maps for all available networks
  void _initializeBalanceMaps() {
    for (final network in _networkProvider.availableNetworks) {
      _balances[network] = 0.0;
      _tokenBalances[network] = 0.0;
    }
  }

  // Handle network change
  void _onNetworkChanged() {
    refreshBalances(forceRefresh: true);
  }

  // Get Sepolia faucet link
  String getSepoliaFaucetLink() {
    final address = _authProvider.getCurrentAddress();
    if (address == null) return '';
    return 'https://sepolia-faucet.pk910.de/?address=$address';
  }

  // Refresh balances
  Future<void> refreshBalances({bool forceRefresh = false}) async {
    if (!_authProvider.hasWallet) return;
    if (_isRefreshingBalance && !forceRefresh) return;

    final address = _authProvider.getCurrentAddress();
    if (address == null || address.isEmpty) return;

    _isRefreshingBalance = true;
    _isBalanceRefreshing = true;
    notifyListeners();

    try {
      await _refreshBalances(address);
      clearError();
    } catch (e) {
      _setError('Error refreshing balances: $e');
    } finally {
      _isRefreshingBalance = false;
      _isBalanceRefreshing = false;
      notifyListeners();
    }
  }

  // Refresh balances for current network
  Future<void> _refreshBalances(String address) async {
    final rpcUrl = _networkProvider.currentRpcEndpoint;
    final currentNetwork = _networkProvider.currentNetwork;

    // Fetch ETH balance
    final ethBalance = await _rpcService.getEthBalance(rpcUrl, address);
    _balances[currentNetwork] = ethBalance;

    // Fetch token balance if applicable
    final tokenContractAddress = _tokenContractAddresses[currentNetwork];
    if (tokenContractAddress != null && tokenContractAddress.isNotEmpty) {
      final tokenBalance = await _rpcService.getTokenBalance(
        rpcUrl,
        tokenContractAddress,
        address,
      );
      _tokenBalances[currentNetwork] = tokenBalance;
    }
  }

  // Check if enough ETH balance including gas
  Future<bool> hasSufficientEthBalance(double amount, double gasFeeEth) async {
    final totalCost = amount + gasFeeEth;
    return ethBalance >= totalCost;
  }

  // Auto-refresh timer setup
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_authProvider.hasWallet) {
        refreshBalances();
      }
    });
  }

  // Helper methods
  void _setError(String? errorMsg) {
    _error = errorMsg;
    print('WalletProvider error: $errorMsg');
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _networkProvider.removeListener(_onNetworkChanged);
    super.dispose();
  }
}
