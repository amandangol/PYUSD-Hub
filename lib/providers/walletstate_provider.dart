import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/authentication/provider/auth_provider.dart';
import '../services/ethereum_rpc_service.dart';
import 'network_provider.dart';

class WalletStateProvider extends ChangeNotifier {
  final AuthProvider _authProvider;
  final NetworkProvider _networkProvider;
  final EthereumRpcService _rpcService = EthereumRpcService();
  final Map<NetworkType, DateTime> _lastRefreshTimes = {};
  final Duration _cacheDuration = const Duration(minutes: 3);

  // Balances
  final Map<NetworkType, double> _balances = {};
  final Map<NetworkType, double> _tokenBalances = {};

  // Token contract addresses
  final Map<NetworkType, String> _tokenContractAddresses = {
    NetworkType.sepoliaTestnet: '0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9',
    NetworkType.ethereumMainnet: '0x6c3ea9036406852006290770bedfcaba0e23a0e8',
  };

  // State
  bool _isBalanceRefreshing = false;
  bool _isInitialLoad = true;
  String? _error;
  bool _isDisposed = false;

  Timer? _debounceTimer;
  StreamSubscription? _networkChangeSubscription;

  final bool _isRefreshLocked = false;
  static const Duration _minRefreshInterval = Duration(seconds: 5);
  DateTime? _lastSuccessfulRefresh;
  static const Duration _rpcTimeout = Duration(seconds: 10);

  // Getters
  double get ethBalance => _balances[_networkProvider.currentNetwork] ?? 0.0;
  double get tokenBalance =>
      _tokenBalances[_networkProvider.currentNetwork] ?? 0.0;
  bool get isBalanceRefreshing => _isBalanceRefreshing;
  bool get isInitialLoad => _isInitialLoad;
  String? get error => _error;
  bool? get hasError => false;
  NetworkType get currentNetwork => _networkProvider.currentNetwork;

  bool _isCacheValid(NetworkType network) {
    final lastRefresh = _lastRefreshTimes[network];
    if (lastRefresh == null) return false;

    return DateTime.now().difference(lastRefresh) < _cacheDuration;
  }

  // Constructor with dependency injection
  WalletStateProvider({
    required AuthProvider authProvider,
    required NetworkProvider networkProvider,
  })  : _authProvider = authProvider,
        _networkProvider = networkProvider {
    _initializeBalanceMaps();
    _setupNetworkListener();
    _loadInitialBalances();
  }

  void _setupNetworkListener() {
    // Remove any existing listener first
    _networkChangeSubscription?.cancel();
    _networkProvider.addListener(_onNetworkChanged);
  }

  // Initialize maps for all available networks
  void _initializeBalanceMaps() {
    for (final network in _networkProvider.availableNetworks) {
      _balances[network] = 0.0;
      _tokenBalances[network] = 0.0;
    }
  }

  // Load initial balances without refresh mechanism
  void _loadInitialBalances() {
    final address = _authProvider.getCurrentAddress();
    if (address != null && address.isNotEmpty) {
      _loadBalances(address);
    }
  }

  // Handle network change
  void _onNetworkChanged() {
    final address = _authProvider.getCurrentAddress();
    if (address != null && address.isNotEmpty) {
      _loadBalances(address);
    }
  }

  // Get Sepolia faucet link
  String getSepoliaFaucetLink() {
    final address = _authProvider.getCurrentAddress();
    if (address == null) return '';
    return 'https://sepolia-faucet.pk910.de/?address=$address';
  }

  Future<void> refreshBalances() async {
    if (_isDisposed) return;

    final address = _authProvider.getCurrentAddress();
    if (address == null || address.isEmpty) return;

    _isBalanceRefreshing = true;
    notifyListeners();

    try {
      await _loadBalances(address);
    } catch (e) {
      print('Error refreshing balances: $e');
    } finally {
      if (!_isDisposed) {
        _isBalanceRefreshing = false;
        notifyListeners();
      }
    }
  }

  // Load balances without refresh mechanism
  Future<void> _loadBalances(String address) async {
    if (_isDisposed) return;

    _isBalanceRefreshing = true;
    notifyListeners();

    try {
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      final currentNetwork = _networkProvider.currentNetwork;

      // Create timeout futures
      final ethFuture = _rpcService
          .getEthBalance(rpcUrl, address)
          .timeout(_rpcTimeout, onTimeout: () => ethBalance);

      final tokenFuture = _getTokenBalance(rpcUrl, address, currentNetwork)
          .timeout(_rpcTimeout, onTimeout: () => tokenBalance);

      // Run both requests in parallel with timeout
      final results = await Future.wait([
        ethFuture,
        tokenFuture,
      ], eagerError: true);

      if (!_isDisposed) {
        // Update balances only if both calls succeed
        _balances[currentNetwork] = results[0];
        _tokenBalances[currentNetwork] = results[1];

        // Cache the successful results
        _lastRefreshTimes[currentNetwork] = DateTime.now();
        _isInitialLoad = false;
      }
    } catch (e) {
      print('Error in _loadBalances: $e');
      // If there's an error, keep the old values
      _isInitialLoad = false;
    } finally {
      if (!_isDisposed) {
        _isBalanceRefreshing = false;
        notifyListeners();
      }
    }
  }

  Future<double> _getTokenBalance(
      String rpcUrl, String address, NetworkType network) async {
    final tokenContractAddress = _tokenContractAddresses[network];
    if (tokenContractAddress == null || tokenContractAddress.isEmpty) {
      print('Debug: No token contract address for network $network');
      return tokenBalance;
    }

    try {
      return await _rpcService.getTokenBalance(
        rpcUrl,
        tokenContractAddress,
        address,
        decimals: 6,
      );
    } catch (e) {
      print('Debug: Error fetching token balance: $e');
      return tokenBalance;
    }
  }

  // Check if enough ETH balance including gas
  Future<bool> hasSufficientEthBalance(double amount, double gasFeeEth) async {
    final totalCost = amount + gasFeeEth;
    return ethBalance >= totalCost;
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
    _isDisposed = true;
    _debounceTimer?.cancel();
    _networkChangeSubscription?.cancel();
    _networkProvider.removeListener(_onNetworkChanged);
    super.dispose();
  }

  void updateBalances(double ethBalance, double tokenBalance) {
    if (_isDisposed) return;

    final currentNetwork = _networkProvider.currentNetwork;
    _balances[currentNetwork] = ethBalance;
    _tokenBalances[currentNetwork] = tokenBalance;
    _isBalanceRefreshing = false;
    _isInitialLoad = false;
    notifyListeners();
  }
}
