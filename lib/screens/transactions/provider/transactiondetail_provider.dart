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

  // Cache expiration time (10 minutes)
  static const Duration _cacheExpiration = Duration(minutes: 10);

  // Get transaction details (from cache or fetch new)
  Future<TransactionDetailModel?> getTransactionDetails({
    required String txHash,
    required String rpcUrl,
    required NetworkType networkType,
    required String currentAddress,
    bool forceRefresh = false,
  }) async {
    if (disposed) return null;

    // Check cache first if not forcing refresh
    if (!forceRefresh) {
      final cachedTransaction =
          getCachedItem(txHash, expiration: _cacheExpiration);
      if (cachedTransaction != null) return cachedTransaction;
    }

    // If there's already an ongoing fetch for this transaction, return that instead of starting a new one
    if (isOperationOngoing(txHash)) {
      return getOngoingOperation(txHash);
    }

    // Create the future and store it in ongoing fetches
    final fetchFuture = _fetchTransactionDetails(
      txHash: txHash,
      rpcUrl: rpcUrl,
      networkType: networkType,
      currentAddress: currentAddress,
    );

    addOngoingOperation(txHash, fetchFuture);

    try {
      return await fetchFuture;
    } finally {
      if (!disposed) {
        removeOngoingOperation(txHash);
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

      // Cache the result if successful
      if (details != null && !disposed) {
        cacheItem(txHash, details);
      }

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

      if (isOperationOngoing(hash)) {
        // Add to hashes to wait for from ongoing fetches
        final future = getOngoingOperation(hash)!;
        future.then((result) {
          if (result != null && !disposed) results.add(result);
        });
      } else {
        hashesToFetch.add(hash);
      }
    }

    // If nothing to fetch, return immediately
    if (hashesToFetch.isEmpty && !isOperationOngoing(hashesToFetch.first)) {
      return results;
    }

    setLoadingState(this, true);

    try {
      if (hashesToFetch.isNotEmpty) {
        // Create batch futures in smaller chunks to avoid overloading the network
        const batchSize = 10;
        for (int i = 0; i < hashesToFetch.length; i += batchSize) {
          if (disposed) break;

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
              if (details != null && !disposed) {
                cacheItem(hash, details);
                return details;
              }
              return null;
            }).catchError((e) {
              print('Error fetching transaction $hash: $e');
              return null;
            });

            addOngoingOperation(hash, future);
            return future;
          }).toList();

          // Wait for this batch to complete
          final batchResults = await Future.wait(futures);

          if (disposed) break;

          // Clean up ongoing fetches and add results
          for (int j = 0; j < batch.length; j++) {
            removeOngoingOperation(batch[j]);
            if (batchResults[j] != null) {
              results.add(batchResults[j]!);
            }
          }
        }
      }

      if (disposed) return results;

      // Wait for any remaining ongoing fetches that we added to our tracking
      final remainingFutures = <Future<TransactionDetailModel?>>[];
      for (final hash in hashesToFetch) {
        if (isOperationOngoing(hash)) {
          final future = getOngoingOperation(hash);
          if (future != null) {
            remainingFutures.add(future);
          }
        }
      }

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
      setError(this, 'Error fetching multiple transaction details: $e');
      return results; // Return what we have so far
    } finally {
      if (!disposed) {
        setLoadingState(this, false);
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
    if (disposed) return null;

    // First check if we already have this transaction with trace data in cache
    final cachedTransaction =
        getCachedItem(txHash, expiration: _cacheExpiration);
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

  // Get raw trace data specifically for developers/debugging purposes
  Future<Map<String, dynamic>?> getRawTraceData({
    required String txHash,
    required String rpcUrl,
    required NetworkType networkType,
    required String currentAddress,
  }) async {
    if (disposed) return null;

    // First check if we already have this transaction with trace data in cache
    final cachedTransaction =
        getCachedItem(txHash, expiration: _cacheExpiration);
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

  // Check if transaction details are already cached
  bool isTransactionCached(String txHash) {
    return getCachedItem(txHash, expiration: _cacheExpiration) != null;
  }

  // Get cached transaction details by hash
  TransactionDetailModel? getCachedTransactionDetails(String txHash) {
    return getCachedItem(txHash, expiration: _cacheExpiration);
  }

  @override
  void dispose() {
    markDisposed();
    clearOngoingOperations();
    super.dispose();
  }
}
