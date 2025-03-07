import 'dart:async';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../services/ethereum_rpc_service.dart';
import '../services/wallet_service.dart';
import 'network_provider.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();
  final EthereumRpcService _rpcService = EthereumRpcService();
  final NetworkProvider _networkProvider = NetworkProvider();

  WalletModel? _wallet;

  // WalletConnect state
  bool _isWalletConnected = false;
  String? _walletConnectAddress;

  // Balance and transactions maps for different networks
  Map<NetworkType, double> _balances = {
    NetworkType.sepoliaTestnet: 0.0,
    NetworkType.ethereumMainnet: 0.0,
  };

  Map<NetworkType, List<TransactionModel>> _transactionsByNetwork = {
    NetworkType.sepoliaTestnet: [],
    NetworkType.ethereumMainnet: [],
  };

  // PYUSD token balances
  Map<NetworkType, double> _tokenBalances = {
    NetworkType.sepoliaTestnet: 0.0,
    NetworkType.ethereumMainnet: 0.0,
  };

  // Loading states
  bool _isLoading = false;
  bool _isBalanceRefreshing = false;
  String? _error;

  // Add flags to prevent duplicate calls
  bool _isRefreshingBalance = false;
  bool _isFetchingTransactions = false;

  // Timer for auto-refresh
  Timer? _refreshTimer;

  // Token contract addresses (replace with actual PYUSD addresses for each network)
  final Map<NetworkType, String> _tokenContractAddresses = {
    NetworkType.sepoliaTestnet: '0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9',
    NetworkType.ethereumMainnet: '0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9',
  };

  // Getters
  WalletModel? get wallet => _wallet;
  NetworkProvider get networkProvider => _networkProvider;

  // Get balance for current network
  double get ethBalance => _balances[_networkProvider.currentNetwork] ?? 0.0;

  // Get token balance for current network
  double get tokenBalance =>
      _tokenBalances[_networkProvider.currentNetwork] ?? 0.0;

  // Get transactions for current network
  List<TransactionModel> get transactions =>
      _transactionsByNetwork[_networkProvider.currentNetwork] ?? [];

  bool get isLoading => _isLoading;
  bool get isBalanceRefreshing => _isBalanceRefreshing;
  String? get error => _error;
  bool get hasWallet => _wallet != null || _isWalletConnected;

  // Network related getters
  NetworkType get currentNetwork => _networkProvider.currentNetwork;
  String get currentNetworkName => _networkProvider.currentNetworkName;
  List<NetworkType> get availableNetworks => _networkProvider.availableNetworks;

  // WalletConnect getters
  bool get isWalletConnected => _isWalletConnected;
  String? get walletConnectAddress => _walletConnectAddress;

  // Constructor
  WalletProvider() {
    _networkProvider.addListener(_onNetworkChanged);
    initWallet();
  }

  // Handle network change
  void _onNetworkChanged() {
    refreshWalletData(forceRefresh: true);
    notifyListeners();
  }

  // Initialize wallet
  Future<void> initWallet() async {
    if (_isLoading) return;
    _setLoading(true);
    try {
      _wallet = await _walletService.loadWallet();
      if (_wallet != null) {
        // Start auto-refresh timer
        // Initial data load
        await refreshWalletData();
      }
    } catch (e) {
      _setError('Failed to initialize wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new wallet
  Future<void> createWallet() async {
    if (_isLoading) return;
    _setLoading(true);
    try {
      _wallet = await _walletService.createWallet();
      // Start auto-refresh after wallet creation
      _startAutoRefresh();
      await refreshWalletData();
    } catch (e) {
      _setError('Failed to create wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add these methods to your WalletProvider class

// Send ETH to another address
  Future<String> sendETH(String toAddress, double amount,
      {double? gasPrice, int? gasLimit}) async {
    if (_wallet == null) {
      throw Exception('Wallet is not initialized');
    }

    _setLoading(true);
    try {
      // Get RPC URL for current network
      final rpcUrl = _networkProvider.currentRpcEndpoint;

      // Use the EthereumRpcService to send the transaction
      final txHash = await _rpcService.sendEthTransaction(
        rpcUrl,
        _wallet!.privateKey,
        toAddress,
        amount,
        gasPrice: gasPrice,
        gasLimit: gasLimit,
      );

      // Refresh balance after sending
      refreshWalletData(forceRefresh: true);

      return txHash;
    } catch (e) {
      _setError('Failed to send ETH: $e');
      throw Exception('Failed to send ETH: $e');
    } finally {
      _setLoading(false);
    }
  }

// Send PYUSD token to another address
  Future<String> sendPYUSD(String toAddress, double amount,
      {double? gasPrice, int? gasLimit}) async {
    if (_wallet == null) {
      throw Exception('Wallet is not initialized');
    }

    _setLoading(true);
    try {
      // Get RPC URL and token contract address for current network
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      final currentNetwork = _networkProvider.currentNetwork;
      final tokenAddress = _tokenContractAddresses[currentNetwork];

      if (tokenAddress == null || tokenAddress.isEmpty) {
        throw Exception('Token contract address not found for this network');
      }

      // PYUSD has 6 decimals - this is important for the conversion
      const int tokenDecimals = 6;

      // Send the token transaction
      final txHash = await _rpcService.sendTokenTransaction(
        rpcUrl,
        _wallet!.privateKey,
        tokenAddress,
        toAddress,
        amount,
        tokenDecimals,
        gasPrice: gasPrice,
        gasLimit: gasLimit,
      );

      // Refresh balances after sending
      refreshWalletData(forceRefresh: true);

      return txHash;
    } catch (e) {
      _setError('Failed to send PYUSD: $e');
      throw Exception('Failed to send PYUSD: $e');
    } finally {
      _setLoading(false);
    }
  }

// Estimate gas for ETH transfer
  Future<int> estimateEthTransferGas(String toAddress, double amount) async {
    if (_wallet == null) {
      throw Exception('Wallet is not initialized');
    }

    try {
      // Get RPC URL for current network
      final rpcUrl = _networkProvider.currentRpcEndpoint;

      // Use the RPC service to estimate gas
      return await _rpcService.estimateEthGas(
        rpcUrl,
        _wallet!.address,
        toAddress,
        amount,
      );
    } catch (e) {
      _setError('Failed to estimate gas: $e');
      // Return default gas limit for ETH transfers if estimation fails
      return 21000;
    }
  }

// Estimate gas for PYUSD token transfer
  Future<int> estimateTokenTransferGas(String toAddress, double amount) async {
    if (_wallet == null) {
      throw Exception('Wallet is not initialized');
    }

    try {
      // Get RPC URL and token contract for current network
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      final currentNetwork = _networkProvider.currentNetwork;
      final tokenAddress = _tokenContractAddresses[currentNetwork];

      if (tokenAddress == null || tokenAddress.isEmpty) {
        throw Exception('Token contract address not found for this network');
      }

      // PYUSD has 6 decimals
      const int tokenDecimals = 6;

      // Use the RPC service to estimate gas for token transfer
      return await _rpcService.estimateTokenGas(
        rpcUrl,
        _wallet!.address,
        tokenAddress,
        toAddress,
        amount,
        tokenDecimals,
      );
    } catch (e) {
      _setError('Failed to estimate token gas: $e');
      // Return default gas limit for token transfers if estimation fails
      return 100000;
    }
  }

  Future<String> getEstimatedFee(
      String toAddress, double amount, bool isToken) async {
    try {
      final feeDetails =
          await calculateTransactionFee(toAddress, amount, isToken);
      return '${feeDetails['feeInEth']?.toStringAsFixed(8)} ETH';
    } catch (e) {
      return 'Fee calculation failed';
    }
  }

  Future<Map<String, double>> calculateTransactionFee(
      String toAddress, double amount, bool isToken) async {
    try {
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      final address = getCurrentAddress();

      if (address == null) {
        throw Exception('Wallet address not available');
      }

      // Get current gas price in Gwei
      final gasPrice = await _rpcService.getGasPrice(rpcUrl);

      // Estimate gas based on transaction type
      int estimatedGas;
      if (isToken) {
        final currentNetwork = _networkProvider.currentNetwork;
        final tokenAddress = _tokenContractAddresses[currentNetwork];
        if (tokenAddress == null) {
          throw Exception('Token address not found for this network');
        }

        estimatedGas = await _rpcService.estimateTokenGas(rpcUrl, address,
            tokenAddress, toAddress, amount, 6 // PYUSD decimals
            );
      } else {
        estimatedGas = await _rpcService.estimateEthGas(
            rpcUrl, address, toAddress, amount);
      }

      // Calculate fee in ETH
      final feeInWei = BigInt.from(gasPrice * 1e9) * BigInt.from(estimatedGas);
      final feeInEth = feeInWei.toDouble() / (1e18);

      return {
        'gasPrice': gasPrice, // in Gwei
        'estimatedGas': estimatedGas.toDouble(),
        'feeInEth': feeInEth
      };
    } catch (e) {
      print('Error calculating fee: $e');
      throw Exception('Failed to calculate transaction fee: $e');
    }
  }

// Update your existing methods to display gas fee information

// Get current gas price
  Future<double> getCurrentGasPrice() async {
    try {
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      return await _rpcService.getGasPrice(rpcUrl);
    } catch (e) {
      print('Error getting gas price: $e');
      return 20.0; // Default gas price in Gwei if estimation fails
    }
  }

// Helper method to check if an address is valid
  bool isValidAddress(String address) {
    // Simple regex check for Ethereum address format
    final regex = RegExp(r'^0x[a-fA-F0-9]{40}$');
    return regex.hasMatch(address);
  }

  Future<bool> hasSufficientEthBalance(double amount, String toAddress) async {
    try {
      // Calculate the transaction fee
      final feesMap = await calculateTransactionFee(toAddress, amount, false);
      final gasFeeEth = feesMap['feeInEth'] ?? 0.0;
      final totalCost = amount + gasFeeEth;

      // Check if current balance is sufficient
      return ethBalance >= totalCost;
    } catch (e) {
      print('Error checking balance: $e');
      // Fall back to a simplified check without gas calculations
      return ethBalance >= amount;
    }
  }

  // Import wallet from mnemonic
  Future<void> importWalletFromMnemonic(String mnemonic) async {
    if (_isLoading) return;
    _setLoading(true);
    try {
      _wallet = await _walletService.importWalletFromMnemonic(mnemonic);
      // Start auto-refresh after wallet import
      _startAutoRefresh();
      await refreshWalletData();
    } catch (e) {
      _setError('Failed to import wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Import wallet from private key
  Future<void> importWalletFromPrivateKey(String privateKey) async {
    if (_isLoading) return;
    _setLoading(true);
    try {
      _wallet = await _walletService.importWalletFromPrivateKey(privateKey);
      // Start auto-refresh after wallet import
      _startAutoRefresh();
      await refreshWalletData();
    } catch (e) {
      _setError('Failed to import wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Switch network
  Future<void> switchNetwork(NetworkType network) async {
    await _networkProvider.switchNetwork(network);
    // Network change notification is handled by _onNetworkChanged
  }

  // Get current address (wallet or walletconnect)
  String? getCurrentAddress() {
    if (_isWalletConnected && _walletConnectAddress != null) {
      return _walletConnectAddress;
    }
    return _wallet?.address;
  }

  // Get Sepolia faucet link
  String getSepoliaFaucetLink() {
    if (_wallet == null) return '';
    return 'https://sepolia-faucet.pk910.de/?address=${_wallet!.address}';
  }

  // Auto-refresh timer setup
  void _startAutoRefresh() {
    // Cancel any existing timer
    _refreshTimer?.cancel();

    // Set up a periodic refresh (every 30 seconds)
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (hasWallet) {
        refreshWalletData();
      }
    });
  }

  // Refresh wallet data (balances and transactions)
  Future<void> refreshWalletData({bool forceRefresh = false}) async {
    if (!hasWallet) return;
    if (_isRefreshingBalance && !forceRefresh) return;

    _isRefreshingBalance = true;
    _isBalanceRefreshing = true;
    notifyListeners();

    final address = getCurrentAddress();
    if (address == null || address.isEmpty) {
      _isRefreshingBalance = false;
      _isBalanceRefreshing = false;
      notifyListeners();
      return;
    }

    try {
      // Get RPC URL for current network
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      final currentNetwork = _networkProvider.currentNetwork;

      // Fetch ETH balance
      final ethBalance = await _rpcService.getEthBalance(rpcUrl, address);
      _balances[currentNetwork] = ethBalance;

      // Fetch PYUSD token balance (if applicable)
      final tokenContractAddress = _tokenContractAddresses[currentNetwork];
      if (tokenContractAddress != null && tokenContractAddress.isNotEmpty) {
        final tokenBalance = await _rpcService.getTokenBalance(
          rpcUrl,
          tokenContractAddress,
          address,
        );
        _tokenBalances[currentNetwork] = tokenBalance;
      }

      clearError(); // Clear any previous errors on successful refresh
    } catch (e) {
      _setError('Error refreshing wallet data: $e');
    } finally {
      _isRefreshingBalance = false;
      _isBalanceRefreshing = false;
      notifyListeners();
    }

    // Fetch transactions separately to avoid blocking the UI with balance updates
    fetchTransactions(forceRefresh: forceRefresh);
  }

  // Fetch transactions only
  Future<void> fetchTransactions({bool forceRefresh = false}) async {
    if (!hasWallet) return;
    if (_isFetchingTransactions && !forceRefresh) return;

    final address = getCurrentAddress();
    if (address == null || address.isEmpty) return;

    _isFetchingTransactions = true;
    _isLoading = true;
    notifyListeners();

    try {
      // Get RPC URL and current network
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      final currentNetwork = _networkProvider.currentNetwork;

      // Fetch transactions from RPC
      final transactions = await _rpcService.getTransactions(
        rpcUrl,
        address,
        currentNetwork,
        limit: 20, // Fetch last 20 transactions
      );

      _transactionsByNetwork[currentNetwork] = transactions;
    } catch (e) {
      print('Error fetching transactions: $e');
      // We don't set the error message here to avoid overriding balance errors
      // Just log to console to keep the UI clean
    } finally {
      _isFetchingTransactions = false;
      _isLoading = false;
      notifyListeners();
    }
  }

// Get transaction details
  Future<TransactionDetailModel?> getTransactionDetails(String txHash) async {
    try {
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      final currentNetwork = _networkProvider.currentNetwork;
      final address = getCurrentAddress() ?? '';

      return await _rpcService.getTransactionDetails(
        rpcUrl,
        txHash,
        currentNetwork,
        address,
      );
    } catch (e) {
      _setError('Failed to get transaction details: $e');
      return null;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

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
