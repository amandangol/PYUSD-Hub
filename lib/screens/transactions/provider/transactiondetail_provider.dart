import 'package:flutter/material.dart';
import '../../../services/gcp_rpc_service.dart';
import '../../../services/market_service.dart';
import '../../../providers/network_provider.dart';
import '../../../utils/provider_utils.dart';
import '../model/transaction_model.dart';

class TransactionDetailProvider
    with
        ChangeNotifier,
        ProviderUtils,
        CacheUtils<TransactionDetailModel>,
        OngoingOperationUtils<TransactionDetailModel?> {
  final GcpRpcService _rpcService = GcpRpcService();
  final MarketService _marketService = MarketService();

  // Cache expiration time (5 minutes)
  static const Duration _cacheExpiration = Duration(minutes: 5);

  // Cache for ongoing operations to prevent duplicate requests
  final Map<String, dynamic> _ongoingOperations = {};

  // Batch size for parallel processing
  static const int _batchSize = 5;

  final Map<String, Map<String, dynamic>> _traceCache = {};
  static const Duration _traceCacheExpiration = Duration(minutes: 30);

  final Map<String, Map<String, dynamic>> _marketCache = {};
  static const Duration _marketCacheExpiration = Duration(minutes: 5);

  final Map<String, TransactionDetailModel> _cachedDetails = {};
  DateTime _lastFetchTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Add AI analysis cache
  final Map<String, Map<String, dynamic>> _aiAnalysisCache = {};
  static const Duration _aiAnalysisCacheExpiration = Duration(minutes: 30);

  // Pre-fetch transaction details for recent transactions
  Future<void> preFetchTransactionDetails({
    required List<TransactionModel> transactions,
    required String rpcUrl,
    required NetworkType networkType,
    required String currentAddress,
  }) async {
    if (disposed) return;

    // Only pre-fetch the first 5 transactions
    final transactionsToFetch = transactions.take(5).toList();

    for (final tx in transactionsToFetch) {
      if (!_cachedDetails.containsKey(tx.hash)) {
        _getTransactionDetails(
          txHash: tx.hash,
          rpcUrl: rpcUrl,
          networkType: networkType,
          currentAddress: currentAddress,
        );
      }
    }
  }

  Future<TransactionDetailModel?> getTransactionDetails({
    required String txHash,
    required String rpcUrl,
    required NetworkType networkType,
    required String currentAddress,
    bool forceRefresh = false,
  }) async {
    if (disposed) return null;

    // Check if we have a cached version that's still valid
    if (!forceRefresh && _cachedDetails.containsKey(txHash)) {
      final cachedDetail = _cachedDetails[txHash]!;
      final cacheAge = DateTime.now().difference(cachedDetail.timestamp);
      if (cacheAge < _cacheExpiration) {
        return cachedDetail;
      }
    }

    // Check if there's an ongoing operation for this hash
    if (_ongoingOperations.containsKey(txHash)) {
      return _ongoingOperations[txHash];
    }

    try {
      final future = _getTransactionDetails(
        txHash: txHash,
        rpcUrl: rpcUrl,
        networkType: networkType,
        currentAddress: currentAddress,
      );

      _ongoingOperations[txHash] = future;
      final details = await future;
      _ongoingOperations.remove(txHash);

      return details;
    } catch (e) {
      _ongoingOperations.remove(txHash);
      print('Error getting transaction details: $e');
      return null;
    }
  }

  Future<TransactionDetailModel?> _getTransactionDetails({
    required String txHash,
    required String rpcUrl,
    required NetworkType networkType,
    required String currentAddress,
  }) async {
    try {
      final details = await _rpcService.getTransactionDetails(
        rpcUrl,
        txHash,
        networkType,
        currentAddress,
      );

      if (details != null) {
        _cachedDetails[txHash] = details;
        _lastFetchTime = DateTime.now();
      }

      return details;
    } catch (e) {
      print('Error in _getTransactionDetails: $e');
      return null;
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

  // Get cached transaction details by hash
  TransactionDetailModel? getCachedTransactionDetails(String txHash) {
    return _cachedDetails[txHash];
  }

  // Check if transaction details are already cached
  bool isTransactionCached(String txHash) {
    return _cachedDetails.containsKey(txHash);
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
      // Check if there's an ongoing operation for this hash
      if (_ongoingOperations.containsKey('trace_$txHash')) {
        final future = _ongoingOperations['trace_$txHash']
            as Future<Map<String, dynamic>?>;
        return future;
      }

      final future = _rpcService.getTransactionTrace(rpcUrl, txHash);
      _ongoingOperations['trace_$txHash'] = future;

      final traceData = await future;
      _ongoingOperations.remove('trace_$txHash');

      if (traceData != null) {
        // Save to cache with timestamp
        _traceCache[txHash] = {
          'data': traceData,
          'timestamp': DateTime.now(),
        };

        // Save to persistent storage
        await _saveTraceDataToStorage(txHash, traceData);
      }

      return traceData;
    } catch (e) {
      _ongoingOperations.remove('trace_$txHash');
      setError(this, 'Error fetching transaction trace: $e');
      return null;
    }
  }

  Future<Map<String, double>> getMarketData({
    required String txHash,
    required List<String> tokens,
    bool forceRefresh = false,
  }) async {
    if (disposed) return {};

    // Check cache first if not forcing refresh
    if (!forceRefresh && _marketCache.containsKey(txHash)) {
      final cacheEntry = _marketCache[txHash]!;
      final cacheTime = cacheEntry['timestamp'] as DateTime;
      if (DateTime.now().difference(cacheTime) < _marketCacheExpiration) {
        return Map<String, double>.from(
            cacheEntry['data'] as Map<String, dynamic>);
      }
    }

    try {
      // Check if there's an ongoing operation for this hash
      if (_ongoingOperations.containsKey('market_$txHash')) {
        final future =
            _ongoingOperations['market_$txHash'] as Future<Map<String, double>>;
        return future;
      }

      final future = _marketService.getCurrentPrices(tokens);
      _ongoingOperations['market_$txHash'] = future;

      final marketData = await future;
      _ongoingOperations.remove('market_$txHash');

      if (marketData.isNotEmpty) {
        // Save to cache with timestamp
        _marketCache[txHash] = {
          'data': marketData,
          'timestamp': DateTime.now(),
        };

        // Save to persistent storage
        await _saveMarketDataToStorage(txHash, marketData);
      }

      return marketData;
    } catch (e) {
      _ongoingOperations.remove('market_$txHash');
      setError(this, 'Error fetching market data: $e');
      return {};
    }
  }

  // Helper method to save trace data to persistent storage
  Future<void> _saveTraceDataToStorage(
      String txHash, Map<String, dynamic> traceData) async {
    try {
      // Implement storage logic here using shared_preferences or other storage solution
      // Example using shared_preferences:
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setString('trace_$txHash', jsonEncode({
      //   'data': traceData,
      //   'timestamp': DateTime.now().toIso8601String(),
      // }));
    } catch (e) {
      print('Error saving trace data to storage: $e');
    }
  }

  // Helper method to save market data to persistent storage
  Future<void> _saveMarketDataToStorage(
      String txHash, Map<String, double> marketData) async {
    try {
      // Implement storage logic here using shared_preferences or other storage solution
      // Example using shared_preferences:
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setString('market_$txHash', jsonEncode({
      //   'data': marketData,
      //   'timestamp': DateTime.now().toIso8601String(),
      // }));
    } catch (e) {
      print('Error saving market data to storage: $e');
    }
  }

  // Load cached data from storage on initialization
  Future<void> loadCachedData() async {
    try {
      // Implement loading logic here using shared_preferences or other storage solution
      // Example using shared_preferences:
      // final prefs = await SharedPreferences.getInstance();
      // final keys = prefs.getKeys();
      //
      // for (final key in keys) {
      //   if (key.startsWith('trace_')) {
      //     final txHash = key.substring(6);
      //     final data = jsonDecode(prefs.getString(key)!);
      //     _traceCache[txHash] = {
      //       'data': data['data'],
      //       'timestamp': DateTime.parse(data['timestamp']),
      //     };
      //   } else if (key.startsWith('market_')) {
      //     final txHash = key.substring(7);
      //     final data = jsonDecode(prefs.getString(key)!);
      //     _marketCache[txHash] = {
      //       'data': data['data'],
      //       'timestamp': DateTime.parse(data['timestamp']),
      //     };
      //   }
      // }
    } catch (e) {
      print('Error loading cached data: $e');
    }
  }

  // Add method to cache AI analysis
  void cacheAiAnalysis(String txHash, Map<String, dynamic> analysis) {
    _aiAnalysisCache[txHash] = {
      'data': analysis,
      'timestamp': DateTime.now(),
    };
  }

  // Add method to get cached AI analysis
  Map<String, dynamic>? getCachedAiAnalysis(String txHash) {
    final cacheEntry = _aiAnalysisCache[txHash];
    if (cacheEntry == null) return null;

    final cacheTime = cacheEntry['timestamp'] as DateTime;
    if (DateTime.now().difference(cacheTime) > _aiAnalysisCacheExpiration) {
      _aiAnalysisCache.remove(txHash);
      return null;
    }

    return cacheEntry['data'] as Map<String, dynamic>;
  }

  @override
  void clearCache({String? key, Duration? olderThan}) {
    if (key != null) {
      _cachedDetails.remove(key);
      _traceCache.remove(key);
      _marketCache.remove(key);
      _aiAnalysisCache.remove(key);
    } else if (olderThan != null) {
      final cutoffTime = DateTime.now().subtract(olderThan);
      _cachedDetails
          .removeWhere((_, detail) => detail.timestamp.isBefore(cutoffTime));
      _traceCache.removeWhere(
          (_, entry) => (entry['timestamp'] as DateTime).isBefore(cutoffTime));
      _marketCache.removeWhere(
          (_, entry) => (entry['timestamp'] as DateTime).isBefore(cutoffTime));
      _aiAnalysisCache.removeWhere(
          (_, entry) => (entry['timestamp'] as DateTime).isBefore(cutoffTime));
    } else {
      _cachedDetails.clear();
      _traceCache.clear();
      _marketCache.clear();
      _aiAnalysisCache.clear();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _traceCache.clear();
    _marketCache.clear();
    _cachedDetails.clear();
    _aiAnalysisCache.clear();
    markDisposed();
    clearOngoingOperations();
    super.dispose();
  }
}
