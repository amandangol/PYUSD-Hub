import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/notification_service.dart';
import '../../authentication/provider/auth_provider.dart';
import '../../../services/ethereum_rpc_service.dart';
import '../../../services/firebase_transaction_service.dart';
import '../../../providers/network_provider.dart';
import '../../../providers/walletstate_provider.dart';
import '../../../utils/provider_utils.dart';
import '../model/transaction_model.dart';
import 'transactiondetail_provider.dart';

class TransactionProvider extends ChangeNotifier
    with ProviderUtils, CacheUtils<List<TransactionModel>> {
  final AuthProvider _authProvider;
  final NetworkProvider _networkProvider;
  final WalletStateProvider _walletProvider;
  final TransactionDetailProvider _detailProvider;
  final EthereumRpcService _rpcService = EthereumRpcService();
  final FirebaseTransactionService _firebaseService;
  final NotificationService _notificationService;

  final Map<NetworkType, List<TransactionModel>> _transactionsByNetwork = {};
  final Map<NetworkType, String> _tokenContractAddresses = {
    NetworkType.sepoliaTestnet: '0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9',
    NetworkType.ethereumMainnet: '0x6c3ea9036406852006290770bedfcaba0e23a0e8',
  };

  bool _isFetchingTransactions = false;
  bool _hasMoreTransactions = true;
  int _currentPage = 1;
  static const int _perPage = 20;
  DateTime? _lastRefresh;
  static const _cacheValidDuration = Duration(minutes: 2);
  final Map<String, Timer> _pendingTransactionTimers = {};
  final Map<String, TransactionModel> _pendingTransactions = {};
  final Map<String, TransactionModel> _transactionCache = {};
  bool _isRefreshLocked = false;
  static const Duration _minRefreshInterval = Duration(seconds: 15);
  DateTime? _lastSuccessfulRefresh;
  final Map<String, bool> _activeMonitoring = {};
  static TransactionProvider? _instance;

  static TransactionProvider get instance {
    assert(_instance != null, 'TransactionProvider not initialized');
    return _instance!;
  }

  List<TransactionModel> get transactions {
    final currentNetwork = _networkProvider.currentNetwork;
    final List<TransactionModel> allTransactions = [
      ..._pendingTransactions.values
          .where((tx) => tx.network == currentNetwork),
      ...(_transactionsByNetwork[currentNetwork] ?? []),
    ];

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
  bool get hasPendingTransactions => _pendingTransactions.isNotEmpty;

  TransactionProvider({
    required AuthProvider authProvider,
    required NetworkProvider networkProvider,
    required WalletStateProvider walletProvider,
    required TransactionDetailProvider detailProvider,
    required NotificationService notificationService,
  })  : _authProvider = authProvider,
        _networkProvider = networkProvider,
        _walletProvider = walletProvider,
        _detailProvider = detailProvider,
        _notificationService = notificationService,
        _firebaseService = FirebaseTransactionService(networkProvider) {
    _instance = this;
    _initializeTransactionMaps();
    _networkProvider.addListener(_onNetworkChanged);

    if (_authProvider.getCurrentAddress() != null) {
      fetchTransactions();
    }
  }

  void _initializeTransactionMaps() {
    for (final network in _networkProvider.availableNetworks) {
      _transactionsByNetwork[network] = [];
    }
  }

  void _onNetworkChanged() {
    if (!disposed) {
      _currentPage = 1;
      _hasMoreTransactions = true;
      _isRefreshLocked = false;
      _lastSuccessfulRefresh = null;
      _transactionsByNetwork[_networkProvider.currentNetwork]?.clear();

      fetchTransactions(forceRefresh: true);
    }
  }

  List<TransactionModel> getFilteredTransactions({
    TransactionDirection? direction,
    String? tokenSymbol,
    TransactionStatus? status,
  }) {
    return transactions.where((tx) {
      if (direction != null && tx.direction != direction) {
        return false;
      }

      if (tokenSymbol != null) {
        if (tokenSymbol == 'ETH') {
          return tx.tokenSymbol == 'ETH';
        } else {
          return tx.tokenSymbol == tokenSymbol;
        }
      }

      if (status != null && tx.status != status) {
        return false;
      }

      return true;
    }).toList();
  }

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

  List<TransactionModel> _processTransactions(
      List<Map<String, dynamic>> transactions,
      String address,
      NetworkType currentNetwork) {
    final List<TransactionModel> processedTransactions = [];

    for (final tx in transactions) {
      try {
        final direction = tx['direction'] == 'normal'
            ? (tx['from'].toString().toLowerCase() == address.toLowerCase()
                ? TransactionDirection.outgoing
                : TransactionDirection.incoming)
            : TransactionDirection.outgoing;

        final status = tx['status'] == 'confirmed'
            ? TransactionStatus.confirmed
            : tx['status'] == 'failed'
                ? TransactionStatus.failed
                : TransactionStatus.pending;

        final timestamp =
            DateTime.fromMillisecondsSinceEpoch(tx['timestamp'] * 1000);

        // Convert numeric values to double
        final amount = (tx['amount'] as num).toDouble();
        final gasUsed = (tx['gasUsed'] as num).toDouble();
        final gasLimit = (tx['gasLimit'] as num).toDouble();
        final gasPrice = (tx['gasPrice'] as num).toDouble();
        final confirmations = tx['confirmations'] as int;

        // Get token details
        final tokenSymbol = tx['tokenSymbol'] as String? ?? 'ETH';
        final tokenName = tx['tokenName'] as String?;
        final tokenDecimals = tx['tokenDecimals'] as int?;
        final tokenContractAddress = tx['tokenContractAddress'] as String?;

        processedTransactions.add(TransactionModel(
          hash: tx['hash'] as String,
          timestamp: timestamp,
          from: tx['from'] as String,
          to: tx['to'] as String,
          amount: amount,
          gasUsed: gasUsed,
          gasLimit: gasLimit,
          gasPrice: gasPrice,
          status: status,
          direction: direction,
          confirmations: confirmations,
          network: currentNetwork,
          tokenSymbol: tokenSymbol,
          tokenName: tokenName,
          tokenDecimals: tokenDecimals,
          tokenContractAddress: tokenContractAddress,
        ));
      } catch (e) {
        print('Error processing transaction: $e');
        continue;
      }
    }

    return processedTransactions;
  }

  Future<void> fetchTransactions({bool forceRefresh = false}) async {
    if (disposed) return;

    final address = _authProvider.getCurrentAddress();
    if (address == null || address.isEmpty) return;

    if (_isRefreshLocked && !forceRefresh) return;

    if (!forceRefresh && _lastSuccessfulRefresh != null) {
      final timeSinceLastRefresh =
          DateTime.now().difference(_lastSuccessfulRefresh!);
      if (timeSinceLastRefresh < _minRefreshInterval) return;
    }

    _isRefreshLocked = true;
    _isFetchingTransactions = true;
    safeNotifyListeners(this);

    try {
      final currentNetwork = _networkProvider.currentNetwork;

      // Get current pending transactions before refreshing
      final currentPendingTransactions = _pendingTransactions.values
          .where((tx) => tx.network == currentNetwork)
          .toList();

      // Check if we have cached data that's still valid
      if (!forceRefresh &&
          _transactionsByNetwork.containsKey(currentNetwork) &&
          _transactionsByNetwork[currentNetwork]!.isNotEmpty &&
          _lastRefresh != null) {
        final cacheAge = DateTime.now().difference(_lastRefresh!);
        if (cacheAge < const Duration(minutes: 5)) {
          // Use cached data if it's less than 5 minutes old
          _isFetchingTransactions = false;
          safeNotifyListeners(this);
          _isRefreshLocked = false;
          return;
        }
      }

      // Use a more efficient approach to fetch transactions
      final transactions = await _fetchAllTransactions(address, currentNetwork);

      if (disposed) return;

      // Update transaction state while preserving pending transactions
      _updateTransactionState(transactions, currentNetwork, forceRefresh);

      // Restart monitoring for any pending transactions that were preserved
      for (var pendingTx in currentPendingTransactions) {
        if (_pendingTransactions.containsKey(pendingTx.hash)) {
          _startTransactionMonitoring(pendingTx.hash);
        }
      }

      _lastSuccessfulRefresh = DateTime.now();
    } catch (e) {
      setError(this, 'Failed to fetch transactions: $e');
    } finally {
      _isRefreshLocked = false;
      if (!disposed) {
        _isFetchingTransactions = false;
        safeNotifyListeners(this);
      }
    }
  }

  Future<List<TransactionModel>> _fetchAllTransactions(
      String address, NetworkType network) async {
    try {
      // Get transactions from Firebase first
      final firebaseTransactions = await _firebaseService.getTransactions();

      // Get transactions from local storage
      final cachedTransactions =
          await _loadCachedTransactions(address, network);

      // Only fetch from network if we need to
      if (cachedTransactions.isEmpty ||
          DateTime.now().difference(_lastSuccessfulRefresh ?? DateTime(2000)) >
              const Duration(minutes: 5)) {
        // Use the new Etherscan method to fetch transactions
        final transactions = await _rpcService.getTransactionsFromEtherscan(
          _networkProvider.currentRpcEndpoint,
          address,
          network,
        );

        final processedTransactions = _processTransactions(
          transactions,
          address,
          network,
        );

        // Save confirmed and failed transactions to Firebase
        for (final tx in processedTransactions) {
          if (tx.status == TransactionStatus.confirmed ||
              tx.status == TransactionStatus.failed) {
            await _firebaseService.saveTransaction(tx);
          }
        }

        // Cache the results
        await _cacheTransactions(processedTransactions, address, network);

        // Combine Firebase and new transactions
        final allTransactions = [
          ...firebaseTransactions,
          ...processedTransactions
        ];
        return allTransactions;
      }

      return [...firebaseTransactions, ...cachedTransactions];
    } catch (e) {
      print('Error fetching all transactions: $e');
      // Return cached transactions if available, otherwise empty list
      return await _loadCachedTransactions(address, network);
    }
  }

  Future<void> _cacheTransactions(List<TransactionModel> transactions,
      String address, NetworkType network) async {
    // Implementation depends on your caching strategy (shared_preferences, hive, etc.)
    // This is a placeholder
  }

  Future<List<TransactionModel>> _loadCachedTransactions(
      String address, NetworkType network) async {
    // Implementation depends on your caching strategy
    // This is a placeholder
    return [];
  }

  void _updateTransactionState(List<TransactionModel> newTransactions,
      NetworkType network, bool forceRefresh) {
    // First, update the transaction cache
    for (var tx in newTransactions) {
      _transactionCache[tx.hash] = tx;
    }

    // Get current pending transactions for this network
    final currentPendingTransactions = _pendingTransactions.values
        .where((tx) => tx.network == network)
        .toList();

    // Filter out any pending transactions that have been confirmed or failed
    final updatedPendingTransactions =
        currentPendingTransactions.where((pendingTx) {
      final newTx = newTransactions.firstWhere(
        (tx) => tx.hash == pendingTx.hash,
        orElse: () => pendingTx,
      );
      return newTx.status == TransactionStatus.pending;
    }).toList();

    // Update pending transactions map
    _pendingTransactions.clear();
    for (var tx in updatedPendingTransactions) {
      _pendingTransactions[tx.hash] = tx;
    }

    // Combine confirmed/failed transactions with pending ones
    final allTransactions = [
      ...updatedPendingTransactions,
      ...newTransactions.where((tx) => tx.status != TransactionStatus.pending),
    ];

    if (forceRefresh) {
      _transactionsByNetwork[network] = allTransactions;
    } else {
      _transactionsByNetwork[network]?.addAll(allTransactions);
    }

    _hasMoreTransactions = newTransactions.length >= _perPage;
    _currentPage++;
    _lastRefresh = DateTime.now();
  }

  Future<void> loadMoreTransactions() async {
    if (!_hasMoreTransactions || _isFetchingTransactions || disposed) return;
    await fetchTransactions();
  }

  bool _compareAddresses(String? address1, String? address2) {
    if (address1 == null || address2 == null) return false;
    return address1.toLowerCase() == address2.toLowerCase();
  }

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

  Future<String> sendETH(String toAddress, double amount,
      {double? gasPrice, int? gasLimit}) async {
    if (disposed) throw Exception('TransactionProvider is disposed');

    String? txHash;
    try {
      txHash = await _rpcService.sendEthTransaction(
        _networkProvider.currentRpcEndpoint,
        _authProvider.wallet!.privateKey,
        toAddress,
        amount,
        gasPrice: gasPrice,
        gasLimit: gasLimit,
      );

      final pendingTx = _createPendingTransaction(
        txHash: txHash,
        toAddress: toAddress,
        amount: amount,
        tokenSymbol: 'ETH',
        gasPrice: gasPrice ?? 2.0,
        gasLimit: gasLimit ?? 21000,
      );

      _pendingTransactions[txHash] = pendingTx;
      notifyListeners();

      try {
        await _notificationService.showTransactionNotification(
          txHash: txHash,
          tokenSymbol: 'ETH',
          amount: amount,
          status: TransactionStatus.pending,
        );
      } catch (e) {
        print('Error showing pending notification: $e');
      }

      _startTransactionMonitoring(txHash);

      final isConfirmed = await verifyTransactionStatus(txHash);
      if (isConfirmed) {
        print('Transaction verified as confirmed: $txHash');
      }

      return txHash;
    } catch (e) {
      print('Error sending ETH transaction: $e');
      if (txHash != null) {
        try {
          await _notificationService.showTransactionNotification(
            txHash: txHash,
            tokenSymbol: 'ETH',
            amount: amount,
            status: TransactionStatus.failed,
          );
        } catch (notifError) {
          print('Error showing failure notification: $notifError');
        }
      }
      throw Exception('Failed to send ETH: $e');
    }
  }

  Future<String> sendPYUSD(String toAddress, double amount,
      {double? gasPrice, int? gasLimit}) async {
    if (disposed) throw Exception('TransactionProvider is disposed');

    String? txHash;
    try {
      final tokenAddress = _getTokenAddressForCurrentNetwork();
      txHash = await _rpcService.sendTokenTransaction(
        _networkProvider.currentRpcEndpoint,
        _authProvider.wallet!.privateKey,
        tokenAddress,
        toAddress,
        amount,
        6,
        gasPrice: gasPrice,
        gasLimit: gasLimit,
      );

      final pendingTx = _createPendingTransaction(
        txHash: txHash,
        toAddress: toAddress,
        amount: amount,
        tokenSymbol: 'PYUSD',
        gasPrice: gasPrice ?? 2.0,
        gasLimit: gasLimit ?? 100000,
      );

      _pendingTransactions[txHash] = pendingTx;
      notifyListeners();

      try {
        await _notificationService.showTransactionNotification(
          txHash: txHash,
          tokenSymbol: 'PYUSD',
          amount: amount,
          status: TransactionStatus.pending,
        );
      } catch (e) {
        print('Error showing pending notification: $e');
      }

      _startTransactionMonitoring(txHash);

      final isConfirmed = await verifyTransactionStatus(txHash);
      if (isConfirmed) {
        print('Transaction verified as confirmed: $txHash');
      }

      return txHash;
    } catch (e) {
      print('Error sending PYUSD transaction: $e');
      if (txHash != null) {
        try {
          await _notificationService.showTransactionNotification(
            txHash: txHash,
            tokenSymbol: 'PYUSD',
            amount: amount,
            status: TransactionStatus.failed,
          );
        } catch (notifError) {
          print('Error showing failure notification: $notifError');
        }
      }
      throw Exception('Failed to send PYUSD: $e');
    }
  }

  Future<void> _monitorInBackground(String txHash) async {
    Timer? monitoringTimer;
    int retryCount = 0;
    const maxRetries = 20; // Maximum number of retries (1 minute total)

    monitoringTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_activeMonitoring.containsKey(txHash) ||
          !_activeMonitoring[txHash]!) {
        timer.cancel();
        _activeMonitoring.remove(txHash);
        return;
      }

      try {
        final details = await _rpcService.getTransactionDetails(
          _networkProvider.currentRpcEndpoint,
          txHash,
          _networkProvider.currentNetwork,
          _authProvider.getCurrentAddress() ?? '',
        );

        if (details?.status == TransactionStatus.confirmed) {
          final pendingTx = _pendingTransactions[txHash];
          if (pendingTx != null) {
            try {
              await _notificationService.showTransactionNotification(
                txHash: txHash,
                tokenSymbol: pendingTx.tokenSymbol ?? 'ETH',
                amount: pendingTx.amount,
                status: TransactionStatus.confirmed,
              );
            } catch (e) {
              print('Error sending confirmation notification: $e');
            }

            _pendingTransactions.remove(txHash);
            _activeMonitoring[txHash] = false;
            timer.cancel();

            // Force refresh to update the transaction list
            await refreshWalletData(forceRefresh: true);
            notifyListeners();
          }
        } else if (details?.status == TransactionStatus.failed) {
          _pendingTransactions.remove(txHash);
          _activeMonitoring[txHash] = false;
          timer.cancel();

          // Force refresh to update the transaction list
          await refreshWalletData(forceRefresh: true);
          notifyListeners();
        } else {
          // Transaction is still pending
          retryCount++;
          if (retryCount >= maxRetries) {
            // If we've reached max retries, stop monitoring but keep the transaction as pending
            _activeMonitoring[txHash] = false;
            timer.cancel();
            print(
                'Stopped monitoring transaction $txHash after $maxRetries retries');
          }
        }
      } catch (e) {
        print('Background monitoring error for $txHash: $e');
        retryCount++;
        if (retryCount >= maxRetries) {
          _activeMonitoring[txHash] = false;
          timer.cancel();
        }
      }
    });

    _pendingTransactionTimers[txHash] = monitoringTimer;
  }

  Future<void> refreshWalletData({bool forceRefresh = false}) async {
    await fetchTransactions(forceRefresh: forceRefresh);
  }

  Future<int> estimateEthTransferGas(String toAddress, double amount) async {
    if (disposed) return 21000;
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
      return 21000;
    }
  }

  Future<int> estimateTokenTransferGas(String toAddress, double amount) async {
    if (disposed) return 100000;
    if (_authProvider.wallet == null) {
      throw Exception('Wallet is not initialized');
    }

    try {
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      final tokenAddress = _getTokenAddressForCurrentNetwork();

      return await _rpcService.estimateTokenGas(
        rpcUrl,
        _authProvider.wallet!.address,
        tokenAddress,
        toAddress,
        amount,
        6,
      );
    } catch (e) {
      setError(this, 'Failed to estimate token gas: $e');
      return 100000;
    }
  }

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

  Future<Map<String, double>> calculateTransactionFee(
      String toAddress, double amount, bool isToken) async {
    if (disposed) throw Exception('TransactionProvider is disposed');

    final address = _authProvider.getCurrentAddress();
    if (address == null) throw Exception('Wallet address not available');

    try {
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      final gasPrice = await _rpcService.getGasPrice(rpcUrl);
      final int estimatedGas =
          await _estimateGas(rpcUrl, address, toAddress, amount, isToken);

      final feeInWei = BigInt.from(gasPrice * 1e9) * BigInt.from(estimatedGas);
      final feeInEth = feeInWei.toDouble() / (1e18);

      return {
        'gasPrice': gasPrice,
        'estimatedGas': estimatedGas.toDouble(),
        'feeInEth': feeInEth
      };
    } catch (e) {
      throw Exception('Failed to calculate transaction fee: $e');
    }
  }

  Future<int> _estimateGas(String rpcUrl, String fromAddress, String toAddress,
      double amount, bool isToken) async {
    if (disposed) {
      return isToken ? 100000 : 21000;
    }

    if (isToken) {
      final tokenAddress = _getTokenAddressForCurrentNetwork();
      return await _rpcService.estimateTokenGas(
          rpcUrl, fromAddress, tokenAddress, toAddress, amount, 6);
    } else {
      return await _rpcService.estimateEthGas(
          rpcUrl, fromAddress, toAddress, amount);
    }
  }

  Future<double> getCurrentGasPrice() async {
    if (disposed) return 20.0;

    try {
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      return await _rpcService.getGasPrice(rpcUrl);
    } catch (e) {
      return 20.0;
    }
  }

  String _getTokenAddressForCurrentNetwork() {
    final tokenAddress =
        _tokenContractAddresses[_networkProvider.currentNetwork];
    if (tokenAddress == null || tokenAddress.isEmpty) {
      throw Exception('Token contract address not found for this network');
    }
    return tokenAddress;
  }

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

  Future<Map<String, GasOption>> getGasOptions() async {
    try {
      final rpcUrl = _networkProvider.currentRpcEndpoint;
      final baseGasPrice = await _rpcService.getGasPrice(rpcUrl);

      return {
        'eco': GasOption(
          name: 'Eco',
          price: baseGasPrice * 0.8,
          timeEstimate: '5-10 min',
          recommended: false,
        ),
        'standard': GasOption(
          name: 'Standard',
          price: baseGasPrice,
          timeEstimate: '2-5 min',
          recommended: true,
        ),
        'fast': GasOption(
          name: 'Fast',
          price: baseGasPrice * 1.2,
          timeEstimate: '30-60 sec',
          recommended: false,
        ),
      };
    } catch (e) {
      print('Error getting gas options: $e');
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

  Future<bool> verifyTransactionStatus(String txHash) async {
    try {
      final details = await _rpcService.getTransactionDetails(
        _networkProvider.currentRpcEndpoint,
        txHash,
        _networkProvider.currentNetwork,
        _authProvider.getCurrentAddress() ?? '',
      );

      return details?.status == TransactionStatus.confirmed;
    } catch (e) {
      print('Error verifying transaction status: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _pendingTransactionTimers.forEach((_, timer) => timer.cancel());
    _pendingTransactionTimers.clear();
  }

  void stopMonitoring(String txHash) {
    _activeMonitoring.remove(txHash);
  }

  void stopAllMonitoring() {
    _activeMonitoring.clear();
  }

  void cleanup() {
    _activeMonitoring.clear();
    _pendingTransactions.clear();
    _pendingTransactionTimers.forEach((_, timer) => timer.cancel());
    _pendingTransactionTimers.clear();
    _transactionCache.clear();
  }

  Future<void> _startTransactionMonitoring(String txHash) async {
    _activeMonitoring[txHash] = true;

    try {
      final details = await _rpcService.getTransactionDetails(
        _networkProvider.currentRpcEndpoint,
        txHash,
        _networkProvider.currentNetwork,
        _authProvider.getCurrentAddress() ?? '',
      );

      await _monitorInBackground(txHash);
    } catch (e) {
      print('Error starting transaction monitoring: $e');
      _activeMonitoring[txHash] = false;
    }
  }

  void clearNetworkData(NetworkType network) {
    _transactionsByNetwork[network]?.clear();
    _currentPage = 1;
    _hasMoreTransactions = true;
  }
}

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
