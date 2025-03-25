import 'dart:async';
import 'package:flutter/material.dart';
import '../../authentication/provider/auth_provider.dart';
import '../../../services/ethereum_rpc_service.dart';
import '../../../providers/network_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../utils/provider_utils.dart';
import '../model/transaction_model.dart';
import 'transactiondetail_provider.dart';

class TransactionProvider extends ChangeNotifier
    with ProviderUtils, CacheUtils<List<TransactionModel>> {
  final AuthProvider _authProvider;
  final NetworkProvider _networkProvider;
  final WalletProvider _walletProvider;
  final TransactionDetailProvider _detailProvider;
  final EthereumRpcService _rpcService = EthereumRpcService();

  // Transactions
  final Map<NetworkType, List<TransactionModel>> _transactionsByNetwork = {};

  // Token contract addresses
  final Map<NetworkType, String> _tokenContractAddresses = {
    NetworkType.sepoliaTestnet: '0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9',
    NetworkType.ethereumMainnet: '0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9',
  };

  // State
  bool _isFetchingTransactions = false;
  bool _hasMoreTransactions = true;
  int _currentPage = 1;
  static const int _perPage = 20;
  DateTime? _lastRefresh;
  static const _cacheValidDuration = Duration(minutes: 2);

  // Add a map to store pending transactions
  final Map<String, Timer> _pendingTransactionTimers = {};

  // Add a map to store pending transactions
  final Map<String, TransactionModel> _pendingTransactions = {};

  // Getters
  List<TransactionModel> get transactions {
    final currentNetwork = _networkProvider.currentNetwork;
    final List<TransactionModel> allTransactions = [
      // Add pending transactions first
      ..._pendingTransactions.values
          .where((tx) => tx.network == currentNetwork),
      // Then add confirmed transactions
      ...(_transactionsByNetwork[currentNetwork] ?? []),
    ];

    // Sort by timestamp, with pending always first
    allTransactions.sort((a, b) {
      if (a.status == TransactionStatus.pending &&
          b.status != TransactionStatus.pending) {
        return -1;
      }
      if (b.status == TransactionStatus.pending &&
          a.status != TransactionStatus.pending) {
        return 1;
      }
      return b.timestamp.compareTo(a.timestamp);
    });

    return allTransactions;
  }

  bool get hasMoreTransactions => _hasMoreTransactions;
  bool get isFetchingTransactions => _isFetchingTransactions;

  // Constructor with dependency injection
  TransactionProvider({
    required AuthProvider authProvider,
    required NetworkProvider networkProvider,
    required WalletProvider walletProvider,
    required TransactionDetailProvider detailProvider,
  })  : _authProvider = authProvider,
        _networkProvider = networkProvider,
        _walletProvider = walletProvider,
        _detailProvider = detailProvider {
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
    if (!disposed) {
      fetchTransactions(forceRefresh: true);
    }
  }

  // Get transactions with optional filtering
  List<TransactionModel> getFilteredTransactions({
    TransactionDirection? direction,
    String? tokenSymbol,
    TransactionStatus? status,
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
          return tx.tokenSymbol == 'ETH'; // ETH transactions have ETH as symbol
        } else {
          return tx.tokenSymbol == tokenSymbol;
        }
      }

      // Filter by status if specified
      if (status != null && tx.status != status) {
        return false;
      }

      return true;
    }).toList();
  }

  // Fetch transaction details (using TransactionDetailProvider)
  Future<TransactionDetailModel?> getTransactionDetails(String txHash) async {
    if (disposed) return null;

    try {
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      final currentNetwork = _networkProvider.currentNetwork;
      final address = _authProvider.getCurrentAddress() ?? '';

      return await _detailProvider.getTransactionDetails(
        txHash: txHash,
        rpcUrl: rpcUrl,
        networkType: currentNetwork,
        currentAddress: address,
      );
    } catch (e) {
      setError(this, 'Failed to get transaction details: $e');
      return null;
    }
  }

  // Improved transaction processing to handle duplicates and properly manage transactions
  List<TransactionModel> _processTransactions(
      List<Map<String, dynamic>> ethTxs,
      List<Map<String, dynamic>> tokenTxs,
      String address,
      NetworkType currentNetwork) {
    final Map<String, TransactionModel> processedTransactions = {};
    final Set<String> processedHashes = {};

    // print('\n=== Processing Transactions ===');
    // print('ETH Transactions: ${ethTxs.length}');
    // print('Token Transactions: ${tokenTxs.length}');

    // Process ETH transactions
    for (final tx in ethTxs) {
      if (tx['hash'] == null) continue;

      final hash = tx['hash'];
      processedHashes.add(hash);

      final direction = _compareAddresses(tx['from'] ?? '', address)
          ? TransactionDirection.outgoing
          : TransactionDirection.incoming;

      // Determine transaction status
      TransactionStatus status;
      if (tx['blockNumber'] == null || tx['blockNumber'] == '0') {
        status = TransactionStatus.pending;
      } else if (int.parse(tx['isError'] ?? '0') == 1) {
        status = TransactionStatus.failed;
      } else {
        status = TransactionStatus.confirmed;
      }

      // Handle timestamp
      DateTime timestamp;
      if (tx['timeStamp'] != null) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(
            int.parse(tx['timeStamp']) * 1000);
      } else {
        timestamp = DateTime.now();
      }

      // Safe parsing of numeric values
      final value = tx['value'] ?? '0';
      final gasUsed = tx['gasUsed'] ?? '0';
      final gasLimit = tx['gasLimit'] ?? '0';
      final gasPrice = tx['gasPrice'] ?? '0';
      final confirmations = tx['confirmations'] ?? '0';

      processedTransactions[hash] = TransactionModel(
        hash: hash,
        timestamp: timestamp,
        from: tx['from'] ?? '',
        to: tx['to'] ?? '',
        amount: double.parse(value) / 1e18,
        gasUsed: double.parse(gasUsed),
        gasLimit: double.parse(gasLimit),
        gasPrice: double.parse(gasPrice) / 1e9,
        status: status,
        direction: direction,
        confirmations: int.parse(confirmations),
        network: currentNetwork,
        tokenSymbol: 'ETH',
      );
    }

    // Process token transactions
    for (final tx in tokenTxs) {
      if (tx['hash'] == null) continue;

      final hash = tx['hash'];
      processedHashes.add(hash);

      final direction = _compareAddresses(tx['from'], address)
          ? TransactionDirection.outgoing
          : TransactionDirection.incoming;

      // Determine transaction status
      TransactionStatus status;
      if (tx['blockNumber'] == null || tx['blockNumber'] == '0') {
        status = TransactionStatus.pending;
      } else if (int.parse(tx['isError'] ?? '0') == 1) {
        status = TransactionStatus.failed;
      } else {
        status = TransactionStatus.confirmed;
      }

      // Handle timestamp
      DateTime timestamp;
      if (tx['timeStamp'] != null) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(
            int.parse(tx['timeStamp']) * 1000);
      } else {
        timestamp = DateTime.now();
      }

      // Token amount with proper decimals
      final decimals = int.parse(tx['tokenDecimal'] ?? '18');
      final rawAmount = BigInt.tryParse(tx['value'] ?? '0') ?? BigInt.zero;
      final tokenAmount =
          rawAmount.toDouble() / BigInt.from(10).pow(decimals).toDouble();

      processedTransactions[hash] = TransactionModel(
        hash: hash,
        timestamp: timestamp,
        from: tx['from'] ?? '',
        to: tx['to'] ?? '',
        amount: tokenAmount,
        gasUsed: double.tryParse(tx['gasUsed'] ?? '0') ?? 0.0,
        gasLimit: double.tryParse(tx['gasLimit'] ?? '0') ?? 0.0,
        gasPrice: double.tryParse(tx['gasPrice'] ?? '0') ?? 0.0 / 1e9,
        status: status,
        direction: direction,
        confirmations: int.tryParse(tx['confirmations'] ?? '0') ?? 0,
        tokenSymbol: tx['tokenSymbol'],
        tokenName: tx['tokenName'],
        tokenDecimals: decimals,
        tokenContractAddress: tx['contractAddress'],
        network: currentNetwork,
      );
    }

    // Convert map to list and sort by timestamp (newest first)
    final result = processedTransactions.values.toList();
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // print('Final processed transactions: ${result.length}');
    // print('=== End Processing Transactions ===\n');

    return result;
  }

  Future<void> fetchTransactions({
    bool forceRefresh = false,
  }) async {
    if (disposed) return;

    // print('\n=== Starting Fetch Transactions ===');
    // print('Force Refresh: $forceRefresh');
    // print(
    //     'Current Main Transactions: ${_transactionsByNetwork[_networkProvider.currentNetwork]?.length ?? 0}');

    final address = _authProvider.getCurrentAddress();
    if (address == null || address.isEmpty || _isFetchingTransactions) return;

    // Check if cache is valid
    if (!forceRefresh && _lastRefresh != null) {
      final timeSinceLastRefresh = DateTime.now().difference(_lastRefresh!);
      if (timeSinceLastRefresh < _cacheValidDuration &&
          transactions.isNotEmpty) {
        print('Using cached transactions');
        return;
      }
    }

    _isFetchingTransactions = true;
    safeNotifyListeners(this);

    try {
      final currentNetwork = _networkProvider.currentNetwork;

      // Reset data if forced refresh
      if (forceRefresh) {
        _currentPage = 1;
        _hasMoreTransactions = true;
        _transactionsByNetwork[currentNetwork] = [];
        // print('Reset transaction data for force refresh');
      }

      // Skip if we already loaded all transactions
      if (!_hasMoreTransactions && !forceRefresh) {
        _isFetchingTransactions = false;
        safeNotifyListeners(this);
        // print('No more transactions to load');
        return;
      }

      // Fetch normal transactions
      final ethTxs = await _rpcService.getTransactions(
        address,
        currentNetwork,
        page: _currentPage,
        perPage: _perPage,
      );
      print('Fetched ${ethTxs.length} ETH transactions');

      // Fetch token transactions
      final tokenTxs = await _rpcService.getTokenTransactions(
        address,
        currentNetwork,
        page: _currentPage,
        perPage: _perPage,
      );
      // print('Fetched ${tokenTxs.length} token transactions');

      if (disposed) return;

      // Process transactions
      final newTransactions =
          _processTransactions(ethTxs, tokenTxs, address, currentNetwork);
      // print('Processed ${newTransactions.length} total transactions');

      // Determine if we have more transactions
      _hasMoreTransactions = newTransactions.length >= _perPage;
      _currentPage++;

      // Add to existing transactions
      if (_transactionsByNetwork[currentNetwork] == null) {
        _transactionsByNetwork[currentNetwork] = [];
      }

      if (forceRefresh) {
        _transactionsByNetwork[currentNetwork] = newTransactions;
        print('Replaced transactions list with new transactions');
      } else {
        _transactionsByNetwork[currentNetwork]!.addAll(newTransactions);
        print('Added new transactions to existing list');
      }

      // Update last refresh time
      _lastRefresh = DateTime.now();
    } catch (e) {
      setError(this, 'Failed to fetch transactions: $e');
      print('Error fetching transactions: $e');
    } finally {
      if (!disposed) {
        _isFetchingTransactions = false;
        safeNotifyListeners(this);
      }
    }

    print(
        'Final Main Transactions: ${_transactionsByNetwork[_networkProvider.currentNetwork]?.length ?? 0}');
    print('=== End Fetch Transactions ===\n');
  }

  Future<void> loadMoreTransactions() async {
    if (!_hasMoreTransactions || _isFetchingTransactions || disposed) return;
    await fetchTransactions();
  }

  // Helper method to compare addresses (case-insensitive)
  bool _compareAddresses(String? address1, String? address2) {
    if (address1 == null || address2 == null) return false;
    return address1.toLowerCase() == address2.toLowerCase();
  }

  // Helper to create pending transaction
  TransactionModel _createPendingTransaction({
    required String txHash,
    required String toAddress,
    required double amount,
    required String? tokenSymbol,
    required double gasPrice,
    required int gasLimit,
  }) {
    final fromAddress = _authProvider.getCurrentAddress() ?? '';

    return TransactionModel(
      hash: txHash,
      timestamp: DateTime.now(),
      from: fromAddress,
      to: toAddress,
      amount: amount,
      gasUsed: 0.0,
      gasLimit: gasLimit.toDouble(),
      gasPrice: gasPrice,
      status: TransactionStatus.pending,
      direction: TransactionDirection.outgoing,
      confirmations: 0,
      network: _networkProvider.currentNetwork,
      tokenSymbol: tokenSymbol,
    );
  }

  // Modified sendETH method
  Future<String> sendETH(String toAddress, double amount,
      {double? gasPrice, int? gasLimit}) async {
    if (disposed) throw Exception('TransactionProvider is disposed');

    try {
      final txHash = await _rpcService.sendEthTransaction(
        _networkProvider.currentRpcEndpoint,
        _authProvider.wallet!.privateKey,
        toAddress,
        amount,
        gasPrice: gasPrice,
        gasLimit: gasLimit,
      );

      // Create and add pending transaction
      final pendingTx = _createPendingTransaction(
        txHash: txHash,
        toAddress: toAddress,
        amount: amount,
        tokenSymbol: null,
        gasPrice: gasPrice ?? 2.0,
        gasLimit: gasLimit ?? 21000,
      );

      // Add to pending transactions
      _pendingTransactions[txHash] = pendingTx;
      notifyListeners();

      // Start monitoring
      _monitorTransaction(txHash);

      return txHash;
    } catch (e) {
      throw Exception('Failed to send ETH: $e');
    }
  }

  // Modified sendPYUSD method
  Future<String> sendPYUSD(String toAddress, double amount,
      {double? gasPrice, int? gasLimit}) async {
    if (disposed) throw Exception('TransactionProvider is disposed');

    try {
      final tokenAddress = _getTokenAddressForCurrentNetwork();
      final txHash = await _rpcService.sendTokenTransaction(
        _networkProvider.currentRpcEndpoint,
        _authProvider.wallet!.privateKey,
        tokenAddress,
        toAddress,
        amount,
        6,
        gasPrice: gasPrice,
        gasLimit: gasLimit,
      );

      // Create and add pending transaction
      final pendingTx = _createPendingTransaction(
        txHash: txHash,
        toAddress: toAddress,
        amount: amount,
        tokenSymbol: 'PYUSD',
        gasPrice: gasPrice ?? 2.0,
        gasLimit: gasLimit ?? 100000,
      );

      // Add to pending transactions
      _pendingTransactions[txHash] = pendingTx;
      notifyListeners();

      // Start monitoring
      _monitorTransaction(txHash);

      return txHash;
    } catch (e) {
      throw Exception('Failed to send PYUSD: $e');
    }
  }

  // Modified monitoring method
  void _monitorTransaction(String txHash) {
    if (disposed) return;

    const checkInterval = Duration(seconds: 5);
    _pendingTransactionTimers[txHash] =
        Timer.periodic(checkInterval, (timer) async {
      try {
        final details = await _rpcService.getTransactionDetails(
          _networkProvider.currentRpcEndpoint,
          txHash,
          _networkProvider.currentNetwork,
          _authProvider.getCurrentAddress() ?? '',
        );

        if (details != null && details.status != TransactionStatus.pending) {
          // Transaction is no longer pending
          timer.cancel();
          _pendingTransactionTimers.remove(txHash);
          _pendingTransactions.remove(txHash);

          // Refresh the full transaction list
          await fetchTransactions(forceRefresh: true);
        }
      } catch (e) {
        print('Error monitoring transaction $txHash: $e');
      }
    });
  }

  // Add helper method to check if there are pending transactions
  bool get hasPendingTransactions => _pendingTransactions.isNotEmpty;

  // Common refresh logic after transactions
  Future<void> _refreshAfterTransaction() async {
    if (disposed) return;

    // print('\n=== Starting Transaction Refresh ===');
    // print(
    //     'Current Main Transactions: ${_transactionsByNetwork[_networkProvider.currentNetwork]?.length ?? 0}');

    // Add a small delay to allow the transaction to be mined
    await Future.delayed(const Duration(seconds: 2));

    if (!disposed) {
      // Refresh balances first
      await _walletProvider.refreshBalances(forceRefresh: true);
      print('Balances refreshed');

      if (!disposed) {
        // Then refresh transactions
        await fetchTransactions(forceRefresh: true);
        print('Transactions refreshed');
      }
    }

    // print(
    //     'Final Main Transactions: ${_transactionsByNetwork[_networkProvider.currentNetwork]?.length ?? 0}');
    // print('=== End Transaction Refresh ===\n');
  }

  // Estimate gas for ETH transfer
  Future<int> estimateEthTransferGas(String toAddress, double amount) async {
    if (disposed) return 21000; // Default gas if disposed
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
      setError(this, 'Failed to estimate gas: $e');
      return 21000; // Default gas limit for ETH transfers
    }
  }

  // Estimate gas for PYUSD token transfer
  Future<int> estimateTokenTransferGas(String toAddress, double amount) async {
    if (disposed) return 100000; // Default gas if disposed
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
      setError(this, 'Failed to estimate token gas: $e');
      return 100000; // Default gas limit for token transfers
    }
  }

  // Get estimated transaction fee as a formatted string
  Future<String> getEstimatedFee(
      String toAddress, double amount, bool isToken) async {
    if (disposed) return 'Fee calculation unavailable';

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
    if (disposed) throw Exception('TransactionProvider is disposed');

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
    if (disposed) {
      return isToken ? 100000 : 21000; // Default values if disposed
    }

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
    if (disposed) return 20.0; // Default gas price if disposed

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

  // Add method to get gas price suggestions
  Future<Map<String, double>> getGasPriceSuggestions() async {
    try {
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      return await _rpcService.getDetailedGasPrices(rpcUrl);
    } catch (e) {
      print('Error getting gas prices: $e');
      return {
        'slow': 20.0,
        'standard': 25.0,
        'fast': 30.0,
      };
    }
  }

  // Simplified gas price suggestions
  Future<Map<String, GasOption>> getGasOptions() async {
    try {
      final rpcUrl = _networkProvider.currentRpcEndpoint;

      // Get current network gas price
      final baseGasPrice = await _rpcService.getGasPrice(rpcUrl);

      return {
        'eco': GasOption(
          name: 'Eco',
          price: baseGasPrice * 1.1, // 10% above base
          timeEstimate: '5-10 min',
          recommended: false,
        ),
        'standard': GasOption(
          name: 'Standard',
          price: baseGasPrice * 1.5, // 50% above base
          timeEstimate: '2-5 min',
          recommended: true,
        ),
        'fast': GasOption(
          name: 'Fast',
          price: baseGasPrice * 2.0, // 100% above base
          timeEstimate: '30-60 sec',
          recommended: false,
        ),
      };
    } catch (e) {
      print('Error getting gas options: $e');
      // Fallback values
      return {
        'eco': GasOption(
          name: 'Eco',
          price: 65.0,
          timeEstimate: '5-10 min',
          recommended: false,
        ),
        'standard': GasOption(
          name: 'Standard',
          price: 75.0,
          timeEstimate: '2-5 min',
          recommended: true,
        ),
        'fast': GasOption(
          name: 'Fast',
          price: 85.0,
          timeEstimate: '30-60 sec',
          recommended: false,
        ),
      };
    }
  }

  @override
  void dispose() {
    markDisposed();
    _networkProvider.removeListener(_onNetworkChanged);
    // Cancel all pending transaction timers
    for (final timer in _pendingTransactionTimers.values) {
      timer.cancel();
    }
    _pendingTransactionTimers.clear();
    _pendingTransactions.clear();
    super.dispose();
  }
}

// Add this class for better gas option handling
class GasOption {
  final String name;
  final double price;
  final String timeEstimate;
  final bool recommended;

  GasOption({
    required this.name,
    required this.price,
    required this.timeEstimate,
    this.recommended = false,
  });
}
