import 'package:flutter/material.dart';
import '../../../services/ethereum_rpc_service.dart';
import '../../../providers/network_provider.dart';
import '../model/transaction_model.dart';

class TransactionDetailProvider with ChangeNotifier {
  final EthereumRpcService _rpcService = EthereumRpcService();

  // Track loading states and errors
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  // Track ongoing fetches to prevent duplicate requests
  final Map<String, Future<TransactionDetailModel?>> _ongoingFetches = {};

  // Cache for transaction details to prevent duplicate fetches
  final Map<String, TransactionDetailModel> _transactionDetailsCache = {};

  // Cache expiration time (10 minutes)
  static const Duration _cacheExpiration = Duration(minutes: 10);
  final Map<String, DateTime> _cacheTimestamps = {};

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
    if (_disposed) return null;

    // Check cache first if not forcing refresh
    if (!forceRefresh) {
      final cachedTransaction = _getCachedTransaction(txHash);
      if (cachedTransaction != null) return cachedTransaction;
    }

    // If there's already an ongoing fetch for this transaction, return that instead of starting a new one
    if (_ongoingFetches.containsKey(txHash)) {
      return _ongoingFetches[txHash];
    }

    // Create the future and store it in ongoing fetches
    final fetchFuture = _fetchTransactionDetails(
      txHash: txHash,
      rpcUrl: rpcUrl,
      networkType: networkType,
      currentAddress: currentAddress,
    );

    _ongoingFetches[txHash] = fetchFuture;

    try {
      return await fetchFuture;
    } finally {
      if (!_disposed) {
        _ongoingFetches.remove(txHash);
      }
    }
  }

  // Check if a transaction is in the cache and not expired
  TransactionDetailModel? _getCachedTransaction(String txHash) {
    if (_transactionDetailsCache.containsKey(txHash)) {
      final timestamp = _cacheTimestamps[txHash];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheExpiration) {
        return _transactionDetailsCache[txHash];
      }
    }
    return null;
  }

  // Private method to actually fetch transaction details
  Future<TransactionDetailModel?> _fetchTransactionDetails({
    required String txHash,
    required String rpcUrl,
    required NetworkType networkType,
    required String currentAddress,
  }) async {
    if (_disposed) return null;

    _setLoadingState(true);

    try {
      // Fetch transaction details from RPC service
      final details = await _rpcService.getTransactionDetails(
        rpcUrl,
        txHash,
        networkType,
        currentAddress,
      );

      // Cache the result if successful
      if (details != null && !_disposed) {
        _transactionDetailsCache[txHash] = details;
        _cacheTimestamps[txHash] = DateTime.now();
      }

      return details;
    } catch (e) {
      _setError('Error fetching transaction details: $e');
      return null;
    } finally {
      if (!_disposed) {
        _setLoadingState(false);
      }
    }
  }

  // Get multiple transaction details in bulk with optimized parallel fetching
  Future<List<TransactionDetailModel>> getMultipleTransactionDetails({
    required List<String> txHashes,
    required String rpcUrl,
    required NetworkType networkType,
    required String currentAddress,
    bool forceRefresh = false,
  }) async {
    if (_disposed) return [];

    // First, deduplicate the hashes
    final uniqueHashes = txHashes.toSet().toList();
    final results = <TransactionDetailModel>[];
    final hashesToFetch = <String>[];

    // Check which transactions are already in cache
    for (final hash in uniqueHashes) {
      if (!forceRefresh) {
        final cachedTransaction = _getCachedTransaction(hash);
        if (cachedTransaction != null) {
          results.add(cachedTransaction);
          continue;
        }
      }

      if (_ongoingFetches.containsKey(hash)) {
        // Add to hashes to wait for from ongoing fetches
        final future = _ongoingFetches[hash]!;
        future.then((result) {
          if (result != null && !_disposed) results.add(result);
        });
      } else {
        hashesToFetch.add(hash);
      }
    }

    // If nothing to fetch, return immediately
    if (hashesToFetch.isEmpty && _ongoingFetches.isEmpty) {
      return results;
    }

    _setLoadingState(true);

    try {
      if (hashesToFetch.isNotEmpty) {
        // Create batch futures in smaller chunks to avoid overloading the network
        const batchSize = 10;
        for (int i = 0; i < hashesToFetch.length; i += batchSize) {
          if (_disposed) break;

          final end = (i + batchSize < hashesToFetch.length)
              ? i + batchSize
              : hashesToFetch.length;
          final batch = hashesToFetch.sublist(i, end);

          // Process batch
          final futures = batch.map((hash) {
            final future = _rpcService
                .getTransactionDetails(
                    rpcUrl, hash, networkType, currentAddress)
                .then((details) {
              if (details != null && !_disposed) {
                _transactionDetailsCache[hash] = details;
                _cacheTimestamps[hash] = DateTime.now();
                return details;
              }
              return null;
            }).catchError((e) {
              print('Error fetching transaction $hash: $e');
              return null;
            });

            _ongoingFetches[hash] = future;
            return future;
          }).toList();

          // Wait for this batch to complete
          final batchResults = await Future.wait(futures);

          if (_disposed) break;

          // Clean up ongoing fetches and add results
          for (int j = 0; j < batch.length; j++) {
            _ongoingFetches.remove(batch[j]);
            if (batchResults[j] != null) {
              results.add(batchResults[j]!);
            }
          }
        }
      }

      if (_disposed) return results;

      // Wait for any remaining ongoing fetches that we added to our tracking
      final remainingFutures = _ongoingFetches.values.toList();
      if (remainingFutures.isNotEmpty) {
        final remainingResults = await Future.wait(remainingFutures);
        for (final result in remainingResults) {
          if (result != null) {
            results.add(result);
          }
        }
      }

      return results;
    } catch (e) {
      _setError('Error fetching multiple transaction details: $e');
      return results; // Return what we have so far
    } finally {
      if (!_disposed) {
        _setLoadingState(false);
      }
    }
  }

  // Extract and return internal transactions from a transaction
  Future<List<Map<String, dynamic>>?> getInternalTransactions({
    required String txHash,
    required String rpcUrl,
    required NetworkType networkType,
    required String currentAddress,
  }) async {
    if (_disposed) return null;

    // First check if we already have this transaction with trace data in cache
    final cachedTransaction = _getCachedTransaction(txHash);
    if (cachedTransaction?.internalTransactions != null) {
      return cachedTransaction!.internalTransactions;
    }

    // If not in cache or no trace data, fetch the full transaction details
    final details = await getTransactionDetails(
      txHash: txHash,
      rpcUrl: rpcUrl,
      networkType: networkType,
      currentAddress: currentAddress,
      forceRefresh: true, // Force refresh to get the trace data
    );

    return details?.internalTransactions;
  }

  // Get detailed error info for failed transactions
  Future<String?> getTransactionErrorDetails({
    required String txHash,
    required String rpcUrl,
    required NetworkType networkType,
    required String currentAddress,
  }) async {
    if (_disposed) return null;

    // First check if we already have this transaction with error data in cache
    final cachedTransaction = _getCachedTransaction(txHash);
    if (cachedTransaction?.errorMessage != null) {
      return cachedTransaction!.errorMessage;
    }

    // If not in cache or no error message, fetch the full transaction details
    final details = await getTransactionDetails(
      txHash: txHash,
      rpcUrl: rpcUrl,
      networkType: networkType,
      currentAddress: currentAddress,
      forceRefresh: true, // Force refresh to get the error data
    );

    return details?.errorMessage;
  }

  // Get raw trace data specifically for developers/debugging purposes
  Future<Map<String, dynamic>?> getRawTraceData({
    required String txHash,
    required String rpcUrl,
    required NetworkType networkType,
    required String currentAddress,
  }) async {
    if (_disposed) return null;

    // First check if we already have this transaction with trace data in cache
    final cachedTransaction = _getCachedTransaction(txHash);
    if (cachedTransaction?.traceData != null) {
      return cachedTransaction!.traceData;
    }

    // If not in cache or no trace data, fetch the full transaction details
    final details = await getTransactionDetails(
      txHash: txHash,
      rpcUrl: rpcUrl,
      networkType: networkType,
      currentAddress: currentAddress,
      forceRefresh: true, // Force refresh to get the trace data
    );

    return details?.traceData;
  }

  // Helper to set loading state and notify listeners once
  void _setLoadingState(bool loading) {
    if (_disposed) return;

    if (_isLoading != loading) {
      _isLoading = loading;
      if (!loading) _error = null;
      notifyListeners();
    }
  }

  // Set error state and notify listeners
  void _setError(String errorMsg) {
    if (_disposed) return;

    _error = errorMsg;
    print('TransactionDetailProvider error: $errorMsg');
    notifyListeners();
  }

  // Check if transaction details are already cached
  bool isTransactionCached(String txHash) {
    return _getCachedTransaction(txHash) != null;
  }

  // Get cached transaction details by hash
  TransactionDetailModel? getCachedTransactionDetails(String txHash) {
    return _getCachedTransaction(txHash);
  }

  // Periodically clean expired cache entries
  void cleanExpiredCache() {
    if (_disposed) return;

    final now = DateTime.now();
    final expiredKeys = <String>[];

    _cacheTimestamps.forEach((hash, timestamp) {
      if (now.difference(timestamp) > _cacheExpiration) {
        expiredKeys.add(hash);
      }
    });

    for (final key in expiredKeys) {
      _transactionDetailsCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  // Clear cache for a specific transaction or all transactions
  void clearCache({String? txHash}) {
    if (_disposed) return;

    if (txHash != null) {
      _transactionDetailsCache.remove(txHash);
      _cacheTimestamps.remove(txHash);
    } else {
      _transactionDetailsCache.clear();
      _cacheTimestamps.clear();
    }
    notifyListeners();
  }

  // Clear error state
  void clearError() {
    if (_disposed) return;

    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ongoingFetches.clear();
    super.dispose();
  }
}
