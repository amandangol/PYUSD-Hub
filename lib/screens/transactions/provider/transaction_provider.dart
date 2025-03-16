import 'package:flutter/material.dart';
import '../../../authentication/provider/auth_provider.dart';
import '../../../services/ethereum_rpc_service.dart';
import '../../../providers/network_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../model/transaction_model.dart';

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
  bool _disposed = false;
  bool _hasMoreTransactions = true;
  int _currentPage = 1;
  static const int _perPage = 20;
  DateTime? _lastRefresh;
  static const _cacheValidDuration = Duration(minutes: 2);

  // Getters
  List<TransactionModel> get transactions =>
      _transactionsByNetwork[_networkProvider.currentNetwork] ?? [];
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreTransactions => _hasMoreTransactions;
  bool get isFetchingTransactions => _isFetchingTransactions;

  // Constructor with dependency injection
  TransactionProvider({
    required AuthProvider authProvider,
    required NetworkProvider networkProvider,
    required WalletProvider walletProvider,
  })  : _authProvider = authProvider,
        _networkProvider = networkProvider,
        _walletProvider = walletProvider {
    _initializeTransactionMaps();
    _networkProvider.addListener(_onNetworkChanged);

    // Initial transactions fetch - only if wallet is initialized
    if (_authProvider.getCurrentAddress() != null) {
      fetchTransactions();
    }
  }

  // Initialize maps for all available networks
  void _initializeTransactionMaps() {
    for (final network in _networkProvider.availableNetworks) {
      _transactionsByNetwork[network] = [];
    }
  }

  // Handle network change
  void _onNetworkChanged() {
    if (!_disposed) {
      fetchTransactions(forceRefresh: true);
    }
  }

  // Get transactions with optional filtering
  List<TransactionModel> getFilteredTransactions({
    TransactionDirection? direction,
    String? tokenSymbol,
  }) {
    final allTransactions = transactions;

    return allTransactions.where((tx) {
      // Filter by direction if specified
      if (direction != null && tx.direction != direction) {
        return false;
      }

      // Filter by token symbol if specified
      if (tokenSymbol != null) {
        if (tokenSymbol == 'ETH') {
          return tx.tokenSymbol ==
              null; // ETH transactions have no token symbol
        } else {
          return tx.tokenSymbol == tokenSymbol;
        }
      }

      return true;
    }).toList();
  }

  // Fetch transaction details
  Future<TransactionDetailModel?> getTransactionDetails(String txHash) async {
    if (_disposed) return null;

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

  // Fetch transactions with cancellation support
  Future<void> fetchTransactions({bool forceRefresh = false}) async {
    if (_disposed) return;

    final address = _authProvider.getCurrentAddress();
    if (address == null || address.isEmpty || _isFetchingTransactions) return;

    // Check if cache is valid
    if (!forceRefresh && _lastRefresh != null) {
      final timeSinceLastRefresh = DateTime.now().difference(_lastRefresh!);
      if (timeSinceLastRefresh < _cacheValidDuration &&
          transactions.isNotEmpty) {
        return;
      }
    }

    _isFetchingTransactions = true;
    _safeNotifyListeners();

    try {
      final currentNetwork = _networkProvider.currentNetwork;

      // Reset data if forced refresh
      if (forceRefresh) {
        _currentPage = 1;
        _hasMoreTransactions = true;
        _transactionsByNetwork[currentNetwork] = [];
      }

      // Skip if we already loaded all transactions
      if (!_hasMoreTransactions && !forceRefresh) {
        _isFetchingTransactions = false;
        _safeNotifyListeners();
        return;
      }

      // Fetch normal transactions
      final ethTxs = await _rpcService.getTransactions(
        address,
        currentNetwork,
        page: _currentPage,
        perPage: _perPage,
      );

      // Fetch token transactions
      final tokenTxs = await _rpcService.getTokenTransactions(
        address,
        currentNetwork,
        page: _currentPage,
        perPage: _perPage,
      );

      if (_disposed) return; // Check if disposed after async operations

      // Process transactions
      final newTransactions =
          _processTransactions(ethTxs, tokenTxs, address, currentNetwork);

      // Determine if we have more transactions
      _hasMoreTransactions = newTransactions.length >= _perPage;
      _currentPage++;

      // Add to existing transactions
      if (_transactionsByNetwork[currentNetwork] == null) {
        _transactionsByNetwork[currentNetwork] = [];
      }

      if (forceRefresh) {
        _transactionsByNetwork[currentNetwork] = newTransactions;
      } else {
        _transactionsByNetwork[currentNetwork]!.addAll(newTransactions);
      }

      // Update last refresh time
      _lastRefresh = DateTime.now();
    } catch (e) {
      _setError('Failed to fetch transactions: $e');
    } finally {
      if (!_disposed) {
        _isFetchingTransactions = false;
        _safeNotifyListeners();
      }
    }
  }

  // Process and combine transactions
  List<TransactionModel> _processTransactions(List<dynamic> ethTxs,
      List<dynamic> tokenTxs, String address, NetworkType currentNetwork) {
    List<TransactionModel> newTransactions = [];

    // Process ETH transactions
    for (final tx in ethTxs) {
      // Skip transactions with missing critical data
      if (tx['hash'] == null ||
          tx['timeStamp'] == null ||
          tx['to'] == null ||
          tx['to'] == '') continue;

      final direction = _compareAddresses(tx['from'] ?? '', address)
          ? TransactionDirection.outgoing
          : TransactionDirection.incoming;

      final status = int.parse(tx['isError'] ?? '0') == 0
          ? TransactionStatus.confirmed
          : TransactionStatus.failed;

      final timestamp = DateTime.fromMillisecondsSinceEpoch(
          int.parse(tx['timeStamp']) * 1000);

      // Handle numeric values safely
      final value = tx['value'] ?? '0';
      final gasUsed = tx['gasUsed'] ?? '0';
      final gasPrice = tx['gasPrice'] ?? '0';
      final confirmations = tx['confirmations'] ?? '0';

      newTransactions.add(TransactionModel(
        hash: tx['hash'],
        timestamp: timestamp,
        from: tx['from'] ?? '',
        to: tx['to'] ?? '',
        amount: double.parse(value) / 1e18,
        gasUsed: double.parse(gasUsed),
        gasPrice: double.parse(gasPrice) / 1e9,
        status: status,
        direction: direction,
        confirmations: int.parse(confirmations),
        network: currentNetwork,
      ));
    }

    // Process token transactions
    for (final tx in tokenTxs) {
      final direction = _compareAddresses(tx['from'], address)
          ? TransactionDirection.outgoing
          : TransactionDirection.incoming;

      final timestamp = DateTime.fromMillisecondsSinceEpoch(
          int.parse(tx['timeStamp']) * 1000);

      // Token amount with proper decimals
      final decimals = int.parse(tx['tokenDecimal']);
      final rawAmount = BigInt.parse(tx['value']);
      final tokenAmount =
          rawAmount.toDouble() / BigInt.from(10).pow(decimals).toDouble();

      newTransactions.add(TransactionModel(
        hash: tx['hash'],
        timestamp: timestamp,
        from: tx['from'],
        to: tx['to'],
        amount: tokenAmount,
        gasUsed: double.parse(tx['gasUsed']),
        gasPrice: double.parse(tx['gasPrice']) / 1e9,
        status: TransactionStatus.confirmed,
        direction: direction,
        confirmations: int.parse(tx['confirmations']),
        tokenSymbol: tx['tokenSymbol'],
        tokenName: tx['tokenName'],
        tokenDecimals: decimals,
        tokenContractAddress: tx['contractAddress'],
        network: currentNetwork,
      ));
    }

    // Sort by timestamp, newest first
    newTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return newTransactions;
  }

  // Load more transactions
  Future<void> loadMoreTransactions() async {
    if (!_hasMoreTransactions || _isFetchingTransactions || _disposed) return;
    await fetchTransactions();
  }

  // Helper method to compare addresses (case-insensitive)
  bool _compareAddresses(String? address1, String? address2) {
    if (address1 == null || address2 == null) return false;
    return address1.toLowerCase() == address2.toLowerCase();
  }

  // Send ETH to another address
  Future<String> sendETH(String toAddress, double amount,
      {double? gasPrice, int? gasLimit}) async {
    if (_disposed) throw Exception('TransactionProvider is disposed');
    if (_authProvider.wallet == null)
      throw Exception('Wallet is not initialized');

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

      // Post-transaction operations with disposal check
      await _refreshAfterTransaction();
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
    if (_disposed) throw Exception('TransactionProvider is disposed');
    if (_authProvider.wallet == null)
      throw Exception('Wallet is not initialized');

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

      // Post-transaction operations with disposal check
      await _refreshAfterTransaction();
      return txHash;
    } catch (e) {
      final error = 'Failed to send PYUSD: $e';
      _setError(error);
      throw Exception(error);
    } finally {
      _setLoading(false);
    }
  }

  // Common refresh logic after transactions
  Future<void> _refreshAfterTransaction() async {
    if (_disposed) return;

    await Future.delayed(const Duration(seconds: 2));

    if (!_disposed) {
      await _walletProvider.refreshBalances(forceRefresh: true);

      if (!_disposed) {
        await fetchTransactions(forceRefresh: true);
      }
    }
  }

  // Estimate gas for ETH transfer
  Future<int> estimateEthTransferGas(String toAddress, double amount) async {
    if (_disposed) return 21000; // Default gas if disposed
    if (_authProvider.wallet == null)
      throw Exception('Wallet is not initialized');

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
      return 21000; // Default gas limit for ETH transfers
    }
  }

  // Estimate gas for PYUSD token transfer
  Future<int> estimateTokenTransferGas(String toAddress, double amount) async {
    if (_disposed) return 100000; // Default gas if disposed
    if (_authProvider.wallet == null)
      throw Exception('Wallet is not initialized');

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
      return 100000; // Default gas limit for token transfers
    }
  }

  // Get estimated transaction fee as a formatted string
  Future<String> getEstimatedFee(
      String toAddress, double amount, bool isToken) async {
    if (_disposed) return 'Fee calculation unavailable';

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
    if (_disposed) throw Exception('TransactionProvider is disposed');

    final address = _authProvider.getCurrentAddress();
    if (address == null) throw Exception('Wallet address not available');

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
    if (_disposed)
      return isToken ? 100000 : 21000; // Default values if disposed

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
    if (_disposed) return 20.0; // Default gas price if disposed

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
    if (_disposed) return;
    _isLoading = loading;
    _safeNotifyListeners();
  }

  void _setError(String? errorMsg) {
    if (_disposed) return;
    _error = errorMsg;
    print('TransactionProvider error: $errorMsg');
    _safeNotifyListeners();
  }

  // Safe way to notify listeners preventing "called after dispose" errors
  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void clearError() {
    if (_disposed) return;
    _error = null;
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _networkProvider.removeListener(_onNetworkChanged);
    super.dispose();
  }
}
