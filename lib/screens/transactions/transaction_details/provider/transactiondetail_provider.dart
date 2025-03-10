import 'package:flutter/material.dart';
import '../model/transaction.dart';
import '../../../../services/ethereum_rpc_service.dart';
import '../../../../providers/network_provider.dart';

class TransactionDetailProvider with ChangeNotifier {
  final EthereumRpcService _rpcService = EthereumRpcService();

  // Track loading states and errors
  bool _isLoading = false;
  String? _error;

  // Track ongoing fetches to prevent duplicate requests
  final Map<String, Future<TransactionDetailModel?>> _ongoingFetches = {};

  // Cache for transaction details to prevent duplicate fetches
  final Map<String, TransactionDetailModel> _transactionDetailsCache = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get transaction details (from cache or fetch new)
  Future<TransactionDetailModel?> getTransactionDetails({
    required String txHash,
    required String rpcUrl,
    required NetworkType networkType,
    required String currentAddress,
    bool forceRefresh = false,
  }) async {
    // Check cache first if not forcing refresh
    if (!forceRefresh && _transactionDetailsCache.containsKey(txHash)) {
      return _transactionDetailsCache[txHash];
    }

    // If there's already an ongoing fetch for this transaction, return that instead of starting a new one
    if (_ongoingFetches.containsKey(txHash)) {
      return _ongoingFetches[txHash];
    }

    // Set loading state and notify listeners
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Create the future and store it in ongoing fetches
    final fetchFuture = _fetchTransactionDetails(
      txHash: txHash,
      rpcUrl: rpcUrl,
      networkType: networkType,
      currentAddress: currentAddress,
    );

    _ongoingFetches[txHash] = fetchFuture;

    try {
      // Wait for the fetch to complete
      final result = await fetchFuture;
      return result;
    } finally {
      // Remove from ongoing fetches when done
      _ongoingFetches.remove(txHash);
    }
  }

  // Private method to actually fetch transaction details
  Future<TransactionDetailModel?> _fetchTransactionDetails({
    required String txHash,
    required String rpcUrl,
    required NetworkType networkType,
    required String currentAddress,
  }) async {
    try {
      // Fetch transaction details from RPC service
      final details = await _rpcService.getTransactionDetails(
        rpcUrl,
        txHash,
        networkType,
        currentAddress,
      );

      // Cache the result if successful
      if (details != null) {
        _transactionDetailsCache[txHash] = details;
      }

      return details;
    } catch (e) {
      _setError('Error fetching transaction details: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if transaction details are already cached
  bool isTransactionCached(String txHash) {
    return _transactionDetailsCache.containsKey(txHash);
  }

  // Get multiple transaction details in bulk
  Future<List<TransactionDetailModel>> getMultipleTransactionDetails({
    required List<String> txHashes,
    required String rpcUrl,
    required NetworkType networkType,
    required String currentAddress,
  }) async {
    final List<TransactionDetailModel> results = [];
    final List<String> hashesToFetch = [];

    // Check which transactions are already in cache
    for (final hash in txHashes) {
      if (_transactionDetailsCache.containsKey(hash)) {
        results.add(_transactionDetailsCache[hash]!);
      } else {
        hashesToFetch.add(hash);
      }
    }

    // If all transactions are in cache, return immediately
    if (hashesToFetch.isEmpty) {
      return results;
    }

    // Set loading state
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Create a list of futures for parallel fetching
      final futures = hashesToFetch
          .map((hash) => _rpcService
                  .getTransactionDetails(
                rpcUrl,
                hash,
                networkType,
                currentAddress,
              )
                  .then((details) {
                if (details != null) {
                  _transactionDetailsCache[hash] = details;
                  return details;
                }
                return null;
              }).catchError((e) {
                print('Error fetching transaction $hash: $e');
                return null;
              }))
          .toList();

      // Wait for all fetches to complete in parallel
      final fetchResults = await Future.wait(futures);

      // Add successful results to the results list
      for (final result in fetchResults) {
        if (result != null) {
          results.add(result);
        }
      }

      return results;
    } catch (e) {
      _setError('Error fetching multiple transaction details: $e');
      return results; // Return what we have so far
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear cache for a specific transaction or all transactions
  void clearCache({String? txHash}) {
    if (txHash != null) {
      _transactionDetailsCache.remove(txHash);
    } else {
      _transactionDetailsCache.clear();
    }
    notifyListeners();
  }

  // Update transaction status (useful for pending transactions)
  Future<TransactionDetailModel?> refreshTransactionStatus(
    String txHash,
    String rpcUrl,
    NetworkType networkType,
    String currentAddress,
  ) async {
    return await getTransactionDetails(
      txHash: txHash,
      rpcUrl: rpcUrl,
      networkType: networkType,
      currentAddress: currentAddress,
      forceRefresh: true,
    );
  }

  // Set error state and notify listeners
  void _setError(String errorMsg) {
    _error = errorMsg;
    print('TransactionDetailProvider error: $errorMsg');
    notifyListeners();
  }

  TransactionDetailModel? getCachedTransactionDetails(String txHash) {
    return _transactionDetailsCache[txHash];
  }

  // Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
