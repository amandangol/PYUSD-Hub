import 'package:flutter/material.dart';
import '../authentication/provider/auth_provider.dart';
import '../screens/transactions/transaction_details/model/transaction.dart';
import '../services/ethereum_rpc_service.dart';
import 'network_provider.dart';
import 'wallet_provider.dart';

class TransactionProvider extends ChangeNotifier {
  final AuthProvider _authProvider;
  final NetworkProvider _networkProvider;
  final WalletProvider _walletProvider;
  final EthereumRpcService _rpcService = EthereumRpcService();

  // Transactions
  final Map<NetworkType, List<TransactionModel>> _transactionsByNetwork = {};

  // Token contract addresses
  final Map<NetworkType, String> _tokenContractAddresses = {
    NetworkType.sepoliaTestnet: '0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9',
    NetworkType.ethereumMainnet: '0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9',
  };

  // State
  bool _isLoading = false;
  bool _isFetchingTransactions = false;
  String? _error;

  // Getters
  List<TransactionModel> get transactions =>
      _transactionsByNetwork[_networkProvider.currentNetwork] ?? [];
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Constructor with dependency injection
  TransactionProvider({
    required AuthProvider authProvider,
    required NetworkProvider networkProvider,
    required WalletProvider walletProvider,
  })  : _authProvider = authProvider,
        _networkProvider = networkProvider,
        _walletProvider = walletProvider {
    // Initialize transaction maps
    _initializeTransactionMaps();

    // Listen for network changes
    _networkProvider.addListener(_onNetworkChanged);

    // Initial transactions fetch
    fetchTransactions();
  }

  // Initialize maps for all available networks
  void _initializeTransactionMaps() {
    for (final network in _networkProvider.availableNetworks) {
      _transactionsByNetwork[network] = [];
    }
  }

  // Handle network change
  void _onNetworkChanged() {
    fetchTransactions(forceRefresh: true);
  }

  // Fetch transactions
  Future<void> fetchTransactions({bool forceRefresh = false}) async {
    if (!_authProvider.hasWallet) return;
    if (_isFetchingTransactions && !forceRefresh) return;

    final address = _authProvider.getCurrentAddress();
    if (address == null || address.isEmpty) return;

    _isFetchingTransactions = true;
    _setLoading(true);

    try {
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      final currentNetwork = _networkProvider.currentNetwork;

      // Fetch transactions (last 20)
      final transactions = await _rpcService.getTransactions(
        rpcUrl,
        address,
        currentNetwork,
        limit: 20,
      );

      _transactionsByNetwork[currentNetwork] = transactions;
    } catch (e) {
      print('Error fetching transactions: $e');
    } finally {
      _isFetchingTransactions = false;
      _setLoading(false);
    }
  }

  // Send ETH to another address
  Future<String> sendETH(String toAddress, double amount,
      {double? gasPrice, int? gasLimit}) async {
    if (_authProvider.wallet == null) {
      throw Exception('Wallet is not initialized');
    }

    _setLoading(true);
    try {
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      final txHash = await _rpcService.sendEthTransaction(
        rpcUrl,
        _authProvider.wallet!.privateKey,
        toAddress,
        amount,
        gasPrice: gasPrice,
        gasLimit: gasLimit,
      );

      // Force refresh after transaction
      await Future.delayed(const Duration(seconds: 2));
      await _walletProvider.refreshBalances(forceRefresh: true);
      await fetchTransactions(forceRefresh: true);

      return txHash;
    } catch (e) {
      final error = 'Failed to send ETH: $e';
      _setError(error);
      throw Exception(error);
    } finally {
      _setLoading(false);
    }
  }

  // Send PYUSD token to another address
  Future<String> sendPYUSD(String toAddress, double amount,
      {double? gasPrice, int? gasLimit}) async {
    if (_authProvider.wallet == null) {
      throw Exception('Wallet is not initialized');
    }

    _setLoading(true);
    try {
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      final tokenAddress = _getTokenAddressForCurrentNetwork();

      // PYUSD has 6 decimals
      const int tokenDecimals = 6;

      final txHash = await _rpcService.sendTokenTransaction(
        rpcUrl,
        _authProvider.wallet!.privateKey,
        tokenAddress,
        toAddress,
        amount,
        tokenDecimals,
        gasPrice: gasPrice,
        gasLimit: gasLimit,
      );

      // Force refresh after transaction
      await Future.delayed(const Duration(seconds: 2));
      await _walletProvider.refreshBalances(forceRefresh: true);
      await fetchTransactions(forceRefresh: true);

      return txHash;
    } catch (e) {
      final error = 'Failed to send PYUSD: $e';
      _setError(error);
      throw Exception(error);
    } finally {
      _setLoading(false);
    }
  }

  // Get transaction details
  Future<TransactionDetailModel?> getTransactionDetails(String txHash) async {
    try {
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      final currentNetwork = _networkProvider.currentNetwork;
      final address = _authProvider.getCurrentAddress() ?? '';

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

  // Estimate gas for ETH transfer
  Future<int> estimateEthTransferGas(String toAddress, double amount) async {
    if (_authProvider.wallet == null) {
      throw Exception('Wallet is not initialized');
    }

    try {
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      return await _rpcService.estimateEthGas(
        rpcUrl,
        _authProvider.wallet!.address,
        toAddress,
        amount,
      );
    } catch (e) {
      _setError('Failed to estimate gas: $e');
      // Return default gas limit for ETH transfers
      return 21000;
    }
  }

  // Estimate gas for PYUSD token transfer
  Future<int> estimateTokenTransferGas(String toAddress, double amount) async {
    if (_authProvider.wallet == null) {
      throw Exception('Wallet is not initialized');
    }

    try {
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      final tokenAddress = _getTokenAddressForCurrentNetwork();

      // PYUSD has 6 decimals
      const int tokenDecimals = 6;

      return await _rpcService.estimateTokenGas(
        rpcUrl,
        _authProvider.wallet!.address,
        tokenAddress,
        toAddress,
        amount,
        tokenDecimals,
      );
    } catch (e) {
      _setError('Failed to estimate token gas: $e');
      // Return default gas limit for token transfers
      return 100000;
    }
  }

  // Get estimated transaction fee as a formatted string
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

  // Calculate transaction fee details
  Future<Map<String, double>> calculateTransactionFee(
      String toAddress, double amount, bool isToken) async {
    final address = _authProvider.getCurrentAddress();
    if (address == null) {
      throw Exception('Wallet address not available');
    }

    try {
      final rpcUrl = _networkProvider.currentRpcEndpoint;

      // Get current gas price in Gwei
      final gasPrice = await _rpcService.getGasPrice(rpcUrl);

      // Estimate gas based on transaction type
      final int estimatedGas =
          await _estimateGas(rpcUrl, address, toAddress, amount, isToken);

      // Calculate fee in ETH
      final feeInWei = BigInt.from(gasPrice * 1e9) * BigInt.from(estimatedGas);
      final feeInEth = feeInWei.toDouble() / (1e18);

      return {
        'gasPrice': gasPrice, // in Gwei
        'estimatedGas': estimatedGas.toDouble(),
        'feeInEth': feeInEth
      };
    } catch (e) {
      throw Exception('Failed to calculate transaction fee: $e');
    }
  }

  // Helper method to estimate gas based on transaction type
  Future<int> _estimateGas(String rpcUrl, String fromAddress, String toAddress,
      double amount, bool isToken) async {
    if (isToken) {
      final tokenAddress = _getTokenAddressForCurrentNetwork();
      return await _rpcService.estimateTokenGas(rpcUrl, fromAddress,
          tokenAddress, toAddress, amount, 6 // PYUSD decimals
          );
    } else {
      return await _rpcService.estimateEthGas(
          rpcUrl, fromAddress, toAddress, amount);
    }
  }

  // Get current gas price
  Future<double> getCurrentGasPrice() async {
    try {
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      return await _rpcService.getGasPrice(rpcUrl);
    } catch (e) {
      // Default gas price in Gwei if estimation fails
      return 20.0;
    }
  }

  // Helper method to get token address for current network
  String _getTokenAddressForCurrentNetwork() {
    final tokenAddress =
        _tokenContractAddresses[_networkProvider.currentNetwork];
    if (tokenAddress == null || tokenAddress.isEmpty) {
      throw Exception('Token contract address not found for this network');
    }
    return tokenAddress;
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMsg) {
    _error = errorMsg;
    print('TransactionProvider error: $errorMsg');
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _networkProvider.removeListener(_onNetworkChanged);
    super.dispose();
  }
}

void updateDependencies(AuthProvider authProvider,
    NetworkProvider networkProvider, WalletProvider walletProvider) {
  // Update if references have changed
}
