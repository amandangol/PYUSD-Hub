import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/notification_service.dart';
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
    required WalletProvider walletProvider,
    required TransactionDetailProvider detailProvider,
    required NotificationService notificationService,
  })  : _authProvider = authProvider,
        _networkProvider = networkProvider,
        _walletProvider = walletProvider,
        _detailProvider = detailProvider,
        _notificationService = notificationService {
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
      List<Map<String, dynamic>> ethTxs,
      List<Map<String, dynamic>> tokenTxs,
      String address,
      NetworkType currentNetwork) {
    final Map<String, TransactionModel> processedTransactions = {};
    final Set<String> processedHashes = {};

    for (final tx in ethTxs) {
      if (tx['hash'] == null) continue;

      final hash = tx['hash'];
      processedHashes.add(hash);

      final direction = _compareAddresses(tx['from'] ?? '', address)
          ? TransactionDirection.outgoing
          : TransactionDirection.incoming;

      TransactionStatus status;
      if (tx['blockNumber'] == null || tx['blockNumber'] == '0') {
        status = TransactionStatus.pending;
      } else if (int.parse(tx['isError'] ?? '0') == 1) {
        status = TransactionStatus.failed;
      } else {
        status = TransactionStatus.confirmed;
      }

      DateTime timestamp;
      if (tx['timeStamp'] != null) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(
            int.parse(tx['timeStamp']) * 1000);
      } else {
        timestamp = DateTime.now();
      }

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

    for (final tx in tokenTxs) {
      if (tx['hash'] == null) continue;

      final hash = tx['hash'];
      processedHashes.add(hash);

      final direction = _compareAddresses(tx['from'], address)
          ? TransactionDirection.outgoing
          : TransactionDirection.incoming;

      TransactionStatus status;
      if (tx['blockNumber'] == null || tx['blockNumber'] == '0') {
        status = TransactionStatus.pending;
      } else if (int.parse(tx['isError'] ?? '0') == 1) {
        status = TransactionStatus.failed;
      } else {
        status = TransactionStatus.confirmed;
      }

      DateTime timestamp;
      if (tx['timeStamp'] != null) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(
            int.parse(tx['timeStamp']) * 1000);
      } else {
        timestamp = DateTime.now();
      }

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

    final result = processedTransactions.values.toList();
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return result;
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

      final futures = await Future.wait([
        _rpcService.getTransactions(
          address,
          currentNetwork,
          page: _currentPage,
          perPage: _perPage,
        ),
        _rpcService.getTokenTransactions(
          address,
          currentNetwork,
          page: _currentPage,
          perPage: _perPage,
        ),
      ]);

      if (disposed) return;

      final ethTxs = futures[0];
      final tokenTxs = futures[1];

      final newTransactions =
          _processTransactions(ethTxs, tokenTxs, address, currentNetwork);
      _updateTransactionState(newTransactions, currentNetwork, forceRefresh);

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

  void _updateTransactionState(List<TransactionModel> newTransactions,
      NetworkType network, bool forceRefresh) {
    for (var tx in newTransactions) {
      _transactionCache[tx.hash] = tx;
    }

    if (forceRefresh) {
      _transactionsByNetwork[network] = newTransactions;
    } else {
      _transactionsByNetwork[network]?.addAll(newTransactions);
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

            await refreshWalletData(forceRefresh: true);
            notifyListeners();
          }
        } else if (details?.status == TransactionStatus.failed) {
          _activeMonitoring[txHash] = false;
          timer.cancel();

          await refreshWalletData(forceRefresh: true);
          notifyListeners();
        }
      } catch (e) {
        print('Background monitoring error for $txHash: $e');
      }
    });

    _pendingTransactionTimers[txHash] = monitoringTimer;
  }

  Future<void> refreshWalletData({bool forceRefresh = false}) async {
    if (disposed) return;

    final address = _authProvider.getCurrentAddress();
    if (address == null || address.isEmpty) return;

    if (!forceRefresh && _isRefreshLocked) return;

    _isRefreshLocked = true;
    _isFetchingTransactions = true;
    safeNotifyListeners(this);

    try {
      final currentNetwork = _networkProvider.currentNetwork;
      final rpcUrl = _networkProvider.currentRpcEndpoint;

      if (forceRefresh) {
        _currentPage = 1;
        _transactionsByNetwork[currentNetwork]?.clear();
      }

      final futures = await Future.wait([
        _rpcService.getTransactions(
          address,
          currentNetwork,
          page: _currentPage,
          perPage: _perPage,
        ),
        _rpcService.getTokenTransactions(
          address,
          currentNetwork,
          page: _currentPage,
          perPage: _perPage,
        ),
        _rpcService.getEthBalance(rpcUrl, address),
        _rpcService.getTokenBalance(
          rpcUrl,
          _tokenContractAddresses[currentNetwork] ?? '',
          address,
          decimals: 6,
        ),
      ]);

      if (disposed) return;

      final ethTxs = futures[0] as List<Map<String, dynamic>>;
      final tokenTxs = futures[1] as List<Map<String, dynamic>>;
      final ethBalance = futures[2] as double;
      final tokenBalance = futures[3] as double;

      final newTransactions = _processTransactions(
        ethTxs,
        tokenTxs,
        address,
        currentNetwork,
      );

      if (forceRefresh) {
        _transactionsByNetwork[currentNetwork] = newTransactions;
      } else {
        _transactionsByNetwork[currentNetwork] = [
          ...(_transactionsByNetwork[currentNetwork] ?? []),
          ...newTransactions,
        ];
      }

      _walletProvider.updateBalances(ethBalance, tokenBalance);

      _hasMoreTransactions = newTransactions.length >= _perPage;
      if (!forceRefresh) {
        _currentPage++;
      }

      _lastSuccessfulRefresh = DateTime.now();
    } catch (e) {
      print('Error refreshing wallet data: $e');
      setError(this, 'Failed to refresh wallet data: $e');
    } finally {
      _isRefreshLocked = false;
      _isFetchingTransactions = false;
      if (!disposed) {
        notifyListeners();
      }
    }
  }

  Future<void> forceRefresh() async {
    await refreshWalletData(forceRefresh: true);
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
