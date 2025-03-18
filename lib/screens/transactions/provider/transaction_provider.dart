import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Transaction tracking
  final Map<String, DateTime> _lastTransactionCheck = {};
  final Map<String, int> _transactionCheckRetries = {};
  static const int _maxTransactionCheckRetries = 20;
  static const Duration _transactionCheckInterval = Duration(seconds: 15);

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

  // Transaction tracking
  final Map<NetworkType, Map<String, TransactionModel>> _pendingTransactionMap =
      {};

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
      _pendingTransactionMap[network] = {};
    }

    // Load any pending transactions from SharedPreferences
    loadPendingTransactionsFromPrefs();
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
          return tx.tokenSymbol == 'ETH'; // ETH transactions have ETH as symbol
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

// In TransactionProvider.dart - modify the checkPendingTransactionsStatus method

  Future<void> checkPendingTransactionsStatus() async {
    if (_disposed) return;

    final address = _authProvider.getCurrentAddress();
    if (address == null || address.isEmpty) return;

    final currentNetwork = _networkProvider.currentNetwork;
    final pendingTxs =
        _pendingTransactionMap[currentNetwork]?.values.toList() ?? [];

    if (pendingTxs.isEmpty) return;

    final rpcUrl = _networkProvider.currentRpcEndpoint;
    bool hasChanges = false;

    // Create a list of transactions to remove after processing
    final pendingTxsToRemove = <String>[];

    for (final pendingTx in List<TransactionModel>.from(pendingTxs)) {
      final txHash = pendingTx.hash;

      // Skip if we've checked this transaction too recently
      final lastCheck = _lastTransactionCheck[txHash];
      if (lastCheck != null &&
          DateTime.now().difference(lastCheck) < _transactionCheckInterval) {
        continue;
      }

      // Update last check time
      _lastTransactionCheck[txHash] = DateTime.now();

      try {
        // Get transaction details from blockchain
        final txDetails = await _rpcService.getTransactionDetails(
          rpcUrl,
          txHash,
          currentNetwork,
          address,
        );

        // Log the transaction details for debugging
        print(
            'Transaction check: $txHash, Status: ${txDetails?.status ?? "null"}');

        // Skip further processing if txDetails is null
        if (txDetails == null) {
          print('Transaction details not found for $txHash, will retry later');
          continue;
        }

        // If transaction is now confirmed or failed
        if (txDetails.status != TransactionStatus.pending) {
          print(
              'Transaction status changed: $txHash, New status: ${txDetails.status}');

          // Find the transaction in the main list to update it
          final index = _transactionsByNetwork[currentNetwork]
              ?.indexWhere((tx) => tx.hash == txHash);

          if (index != null && index != -1) {
            // Update the transaction with confirmed details
            _transactionsByNetwork[currentNetwork]![index] = txDetails;
            print(
                'Updated transaction at index $index with status ${txDetails.status}');
          } else {
            // If transaction not found in main list, add it
            _transactionsByNetwork[currentNetwork]?.insert(0, txDetails);
            print('Added new transaction with status ${txDetails.status}');
          }

          // Mark this transaction for removal from pending transactions
          pendingTxsToRemove.add(txHash);
          hasChanges = true;
        } else {
          // Transaction still pending, increment retry counter with a max limit
          final retries = _transactionCheckRetries[txHash] ?? 0;
          if (retries < _maxTransactionCheckRetries) {
            _transactionCheckRetries[txHash] = retries + 1;
          } else {
            // We've tried too many times, consider updating UI to show "status unknown"
            print('Max retries reached for transaction: $txHash');

            // Mark this transaction for removal to prevent infinite checking
            pendingTxsToRemove.add(txHash);
            hasChanges = true;
          }
        }
      } catch (e) {
        print('Error checking transaction status: $e');
        // Don't increment retry counter for network issues
        if (!e.toString().contains("Failed host lookup") &&
            !e.toString().contains("Connection refused")) {
          final retries = _transactionCheckRetries[txHash] ?? 0;
          _transactionCheckRetries[txHash] = retries + 1;
        }
      }
    }

    // Remove transactions that have been marked for removal
    for (final txHash in pendingTxsToRemove) {
      final txToRemove = _pendingTransactionMap[currentNetwork]?[txHash];
      if (txToRemove != null) {
        _pendingTransactionMap[currentNetwork]?.remove(txHash);
        _transactionCheckRetries.remove(txHash);
        _lastTransactionCheck.remove(txHash);
        await _removePendingTransactionFromPrefs(txToRemove);
      }
    }

    // Notify listeners if any changes were made
    if (hasChanges && !_disposed) {
      _safeNotifyListeners();
    }
  }

  // Helper method to remove a pending transaction from SharedPreferences
  Future<void> _removePendingTransactionFromPrefs(TransactionModel tx) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing pending transactions for this network
      final String key = 'pending_transactions_${tx.network.toString()}';
      final String? existingJson = prefs.getString(key);

      if (existingJson != null) {
        List<Map<String, dynamic>> pendingList =
            List<Map<String, dynamic>>.from(jsonDecode(existingJson));

        // Remove the transaction
        pendingList.removeWhere((item) => item['hash'] == tx.hash);

        // Save back to SharedPreferences
        await prefs.setString(key, jsonEncode(pendingList));
        print('Removed transaction from pending storage: ${tx.hash}');
      }
    } catch (e) {
      print('Error removing pending transaction: $e');
    }
  }

  // Improved transaction processing to handle duplicates and properly manage transactions
  List<TransactionModel> _processTransactions(List<dynamic> ethTxs,
      List<dynamic> tokenTxs, String address, NetworkType currentNetwork) {
    // Track all transactions by hash for deduplication
    final Map<String, TransactionModel> processedTransactions = {};
    final Set<String> processedHashes = {};

    // Process ETH transactions first
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
      final gasPrice = tx['gasPrice'] ?? '0';
      final confirmations = tx['confirmations'] ?? '0';

      processedTransactions[hash] = TransactionModel(
        hash: hash,
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
        tokenSymbol: 'ETH', // Explicitly set to ETH
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

    // Add locally stored pending transactions that aren't in the fetched data
    final pendingTxs =
        _pendingTransactionMap[currentNetwork]?.values.toList() ?? [];

    for (final pendingTx in pendingTxs) {
      // Only add pending transactions that weren't already processed from API
      if (!processedHashes.contains(pendingTx.hash)) {
        processedTransactions[pendingTx.hash] = pendingTx;
      }
      // If the transaction was processed but has a different status, update pending map
      else if (processedTransactions.containsKey(pendingTx.hash) &&
          processedTransactions[pendingTx.hash]!.status !=
              TransactionStatus.pending) {
        // Remove confirmed/failed transactions from pending map
        _pendingTransactionMap[currentNetwork]?.remove(pendingTx.hash);
        // Also remove from tracking maps
        _transactionCheckRetries.remove(pendingTx.hash);
        _lastTransactionCheck.remove(pendingTx.hash);
        // Remove from persistent storage
        _removePendingTransactionFromPrefs(pendingTx);
      }
    }

    // Convert map to list and sort by timestamp
    final result = processedTransactions.values.toList();
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return result;
  }

  Future<void> fetchTransactions(
      {bool forceRefresh = false, bool skipPendingCheck = false}) async {
    if (_disposed) return;

    final address = _authProvider.getCurrentAddress();
    if (address == null || address.isEmpty || _isFetchingTransactions) return;

    // Always check pending transactions first unless explicitly skipped
    if (!skipPendingCheck) {
      await checkPendingTransactionsStatus(); // Make sure this gets called
    }
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

  void addPendingTransaction(
      String txHash, bool isToken, String to, double amount,
      {String? tokenSymbol, String? tokenName, int? tokenDecimals}) {
    if (_disposed) return;

    final address = _authProvider.getCurrentAddress();
    if (address == null || address.isEmpty) return;

    final currentNetwork = _networkProvider.currentNetwork;

    // Check if this transaction is already in the pending map
    if (_pendingTransactionMap[currentNetwork]?.containsKey(txHash) == true) {
      // Transaction already exists as pending, don't add it again
      print('Transaction already in pending list: $txHash');
      return;
    }

    // Create new pending transaction
    final pendingTx = TransactionModel(
      hash: txHash,
      timestamp: DateTime.now(),
      from: address,
      to: to,
      amount: amount,
      gasUsed: 0, // Will be updated when confirmed
      gasPrice: 0, // Will be updated when confirmed
      status: TransactionStatus.pending,
      direction: TransactionDirection.outgoing,
      confirmations: 0,
      network: currentNetwork,
      tokenSymbol: isToken ? tokenSymbol : 'ETH',
      tokenName: tokenName,
      tokenDecimals: tokenDecimals,
    );

    // Initialize maps if needed
    if (_pendingTransactionMap[currentNetwork] == null) {
      _pendingTransactionMap[currentNetwork] = {};
    }
    if (_transactionsByNetwork[currentNetwork] == null) {
      _transactionsByNetwork[currentNetwork] = [];
    }

    // Store in pending map
    _pendingTransactionMap[currentNetwork]![txHash] = pendingTx;

    // Add to beginning of transactions list (newest first)
    // First remove any existing transaction with the same hash to avoid duplicates
    _transactionsByNetwork[currentNetwork]!
        .removeWhere((tx) => tx.hash == txHash);

    // Then add the new pending transaction
    _transactionsByNetwork[currentNetwork]!.insert(0, pendingTx);

    // Store in SharedPreferences
    _storePendingTransactionToPrefs(pendingTx);

    // Initialize tracking variables
    _lastTransactionCheck[txHash] = DateTime.now();
    _transactionCheckRetries[txHash] = 0;

    // Ensure the UI is updated immediately
    _safeNotifyListeners();
  }

  Future<void> _storePendingTransactionToPrefs(TransactionModel tx) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing pending transactions for this network
      final String key = 'pending_transactions_${tx.network.toString()}';
      final String? existingJson = prefs.getString(key);

      List<Map<String, dynamic>> pendingList = [];
      if (existingJson != null) {
        pendingList = List<Map<String, dynamic>>.from(jsonDecode(existingJson));
      }

      // Add the new transaction if it doesn't already exist
      if (!pendingList.any((item) => item['hash'] == tx.hash)) {
        pendingList.add(tx.toJson());

        // Save back to SharedPreferences
        await prefs.setString(key, jsonEncode(pendingList));
        print('Stored pending transaction in SharedPreferences: ${tx.hash}');
      }
    } catch (e) {
      print('Error storing pending transaction: $e');
    }
  }

  // Method to load pending transactions from SharedPreferences
  Future<void> loadPendingTransactionsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load for all available networks
      for (final network in _networkProvider.availableNetworks) {
        final String key = 'pending_transactions_${network.toString()}';
        final String? pendingJson = prefs.getString(key);

        if (pendingJson != null) {
          final List<dynamic> pendingList = jsonDecode(pendingJson);

          // Initialize maps if needed
          if (_pendingTransactionMap[network] == null) {
            _pendingTransactionMap[network] = {};
          }
          if (_transactionsByNetwork[network] == null) {
            _transactionsByNetwork[network] = [];
          }

          // Convert JSON back to TransactionModel objects
          for (final txJson in pendingList) {
            try {
              final tx = TransactionModel.fromJson(txJson);

              // Only keep pending transactions that are recent (less than 24 hours old)
              if (DateTime.now().difference(tx.timestamp).inHours < 24) {
                _pendingTransactionMap[network]![tx.hash] = tx;

                // Also add to the main transactions list to ensure they're displayed
                if (!_transactionsByNetwork[network]!
                    .any((t) => t.hash == tx.hash)) {
                  _transactionsByNetwork[network]!.insert(0, tx);
                }

                // Initialize tracking variables
                _lastTransactionCheck[tx.hash] = DateTime.now();
                _transactionCheckRetries[tx.hash] = 0;
              }
            } catch (e) {
              print('Error parsing pending transaction: $e');
            }
          }
        }
      }

      // Notify listeners to update UI
      _safeNotifyListeners();
    } catch (e) {
      print('Error loading pending transactions: $e');
    }
  }

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

      // Add the transaction to pending list immediately
      addPendingTransaction(txHash, false, toAddress, amount);

      // Post-transaction operations with disposal check
      await _refreshAfterTransaction();
      return txHash;
    } catch (e) {
      final error = 'Failed to send ETH: $e';
      _setError(error);
      throw Exception(error);
    } finally {
      if (!_disposed) {
        _setLoading(false);
      }
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

      // Add the transaction to pending list immediately
      addPendingTransaction(txHash, true, toAddress, amount,
          tokenSymbol: 'PYUSD',
          tokenName: 'PayPal USD',
          tokenDecimals: tokenDecimals);

      // Post-transaction operations with disposal check
      await _refreshAfterTransaction();
      return txHash;
    } catch (e) {
      final error = 'Failed to send PYUSD: $e';
      _setError(error);
      throw Exception(error);
    } finally {
      if (!_disposed) {
        _setLoading(false);
      }
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
