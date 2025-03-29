import 'package:flutter/material.dart';
import '../../../services/ethereum_rpc_service.dart';
import '../../../providers/network_provider.dart';
import '../../../utils/provider_utils.dart';
import '../model/transaction_model.dart';

class TransactionDetailProvider
    with
        ChangeNotifier,
        ProviderUtils,
        CacheUtils<TransactionDetailModel>,
        OngoingOperationUtils<TransactionDetailModel?> {
  final EthereumRpcService _rpcService = EthereumRpcService();

  // Cache expiration time (1 hour)
  static const Duration _cacheExpiration = Duration(hours: 1);

  // Cache for ongoing operations to prevent duplicate requests
  final Map<String, Future<TransactionDetailModel?>> _ongoingOperations = {};

  // Batch size for parallel processing
  static const int _batchSize = 5;

  final Map<String, Map<String, dynamic>> _traceCache = {};
  static const Duration _traceCacheExpiration = Duration(minutes: 30);

  Future<TransactionDetailModel?> getTransactionDetails({
    required String txHash,
    required String rpcUrl,
    required NetworkType networkType,
    required String currentAddress,
    bool forceRefresh = false,
  }) async {
    if (disposed) return null;

    // Check if there's an ongoing operation for this transaction
    if (_ongoingOperations.containsKey(txHash)) {
      return _ongoingOperations[txHash];
    }

    // Check cache first if not forcing refresh
    if (!forceRefresh) {
      final cachedTransaction =
          getCachedItem(txHash, expiration: _cacheExpiration);
      if (cachedTransaction != null) return cachedTransaction;
    }

    // Create the future and store it in ongoing operations
    final fetchFuture = _fetchTransactionDetails(
      txHash: txHash,
      rpcUrl: rpcUrl,
      networkType: networkType,
      currentAddress: currentAddress,
    );

    _ongoingOperations[txHash] = fetchFuture;

    try {
      final result = await fetchFuture;
      if (result != null && !disposed) {
        cacheItem(txHash, result);
      }
      return result;
    } finally {
      if (!disposed) {
        _ongoingOperations.remove(txHash);
      }
    }
  }

  // Private method to actually fetch transaction details
  Future<TransactionDetailModel?> _fetchTransactionDetails({
    required String txHash,
    required String rpcUrl,
    required NetworkType networkType,
    required String currentAddress,
  }) async {
    if (disposed) return null;

    setLoadingState(this, true);

    try {
      // Fetch transaction details from RPC service
      final details = await _rpcService.getTransactionDetails(
        rpcUrl,
        txHash,
        networkType,
        currentAddress,
      );

      return details;
    } catch (e) {
      setError(this, 'Error fetching transaction details: $e');
      return null;
    } finally {
      if (!disposed) {
        setLoadingState(this, false);
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
    if (disposed) return [];

    // First, deduplicate the hashes
    final uniqueHashes = txHashes.toSet().toList();
    final results = <TransactionDetailModel>[];
    final hashesToFetch = <String>[];

    // Check which transactions are already in cache
    for (final hash in uniqueHashes) {
      if (!forceRefresh) {
        final cachedTransaction =
            getCachedItem(hash, expiration: _cacheExpiration);
        if (cachedTransaction != null) {
          results.add(cachedTransaction);
          continue;
        }
      }

      if (_ongoingOperations.containsKey(hash)) {
        // Add to results if the operation completes successfully
        final future = _ongoingOperations[hash]!;
        future.then((result) {
          if (result != null && !disposed) results.add(result);
        });
      } else {
        hashesToFetch.add(hash);
      }
    }

    // If nothing to fetch, return immediately
    if (hashesToFetch.isEmpty) {
      return results;
    }

    setLoadingState(this, true);

    try {
      // Process hashes in smaller batches to avoid overloading the network
      for (int i = 0; i < hashesToFetch.length; i += _batchSize) {
        if (disposed) break;

        final end = (i + _batchSize < hashesToFetch.length)
            ? i + _batchSize
            : hashesToFetch.length;
        final batch = hashesToFetch.sublist(i, end);

        // Process batch
        final futures = batch.map((hash) {
          final future = _rpcService
              .getTransactionDetails(rpcUrl, hash, networkType, currentAddress)
              .then((details) {
            if (details != null && !disposed) {
              cacheItem(hash, details);
              return details;
            }
            return null;
          }).catchError((e) {
            print('Error fetching transaction $hash: $e');
            return null;
          });

          _ongoingOperations[hash] = future;
          return future;
        }).toList();

        // Wait for this batch to complete
        final batchResults = await Future.wait(futures);

        if (disposed) break;

        // Clean up ongoing operations and add results
        for (int j = 0; j < batch.length; j++) {
          _ongoingOperations.remove(batch[j]);
          if (batchResults[j] != null) {
            results.add(batchResults[j]!);
          }
        }

        // Add a small delay between batches to avoid rate limiting
        if (i + _batchSize < hashesToFetch.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      return results;
    } catch (e) {
      setError(this, 'Error fetching multiple transaction details: $e');
      return results; // Return what we have so far
    } finally {
      if (!disposed) {
        setLoadingState(this, false);
      }
    }
  }

  // Get detailed error info for failed transactions
  Future<String?> getTransactionErrorDetails({
    required String txHash,
    required String rpcUrl,
    required NetworkType networkType,
    required String currentAddress,
  }) async {
    if (disposed) return null;

    // First check if we already have this transaction with error data in cache
    final cachedTransaction =
        getCachedItem(txHash, expiration: _cacheExpiration);
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

  // Check if transaction details are already cached
  bool isTransactionCached(String txHash) {
    return getCachedItem(txHash, expiration: _cacheExpiration) != null;
  }

  // Get cached transaction details by hash
  TransactionDetailModel? getCachedTransactionDetails(String txHash) {
    return getCachedItem(txHash, expiration: _cacheExpiration);
  }

  Future<Map<String, dynamic>?> getTransactionTrace({
    required String txHash,
    required String rpcUrl,
    bool forceRefresh = false,
  }) async {
    if (disposed) return null;

    // Check cache first if not forcing refresh
    if (!forceRefresh && _traceCache.containsKey(txHash)) {
      final cacheEntry = _traceCache[txHash]!;
      final cacheTime = cacheEntry['timestamp'] as DateTime;
      if (DateTime.now().difference(cacheTime) < _traceCacheExpiration) {
        return cacheEntry['data'] as Map<String, dynamic>;
      }
    }

    try {
      final traceData = await _rpcService.getTransactionTrace(rpcUrl, txHash);

      if (traceData != null) {
        _traceCache[txHash] = {
          'data': traceData,
          'timestamp': DateTime.now(),
        };
      }

      return traceData;
    } catch (e) {
      setError(this, 'Error fetching transaction trace: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _traceCache.clear();
    markDisposed();
    clearOngoingOperations();
    super.dispose();
  }
}
