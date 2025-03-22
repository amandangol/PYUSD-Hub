import 'package:flutter/material.dart';

/// A mixin that provides common functionality for providers
mixin ProviderUtils {
  bool _disposed = false;
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get disposed => _disposed;

  // Safe way to notify listeners preventing "called after dispose" errors
  void safeNotifyListeners(ChangeNotifier provider) {
    if (!_disposed) {
      provider.notifyListeners();
    }
  }

  // Set loading state and notify listeners
  void setLoadingState(ChangeNotifier provider, bool loading) {
    if (_disposed) return;

    if (_isLoading != loading) {
      _isLoading = loading;
      if (!loading) _error = null;
      safeNotifyListeners(provider);
    }
  }

  // Set error state and notify listeners
  void setError(ChangeNotifier provider, String errorMsg) {
    if (_disposed) return;

    _error = errorMsg;
    print('Provider error: $errorMsg');
    safeNotifyListeners(provider);
  }

  // Clear error state
  void clearError(ChangeNotifier provider) {
    if (_disposed) return;

    if (_error != null) {
      _error = null;
      safeNotifyListeners(provider);
    }
  }

  // Mark as disposed
  void markDisposed() {
    _disposed = true;
  }
}

/// A mixin that provides caching functionality for providers
mixin CacheUtils<T> {
  final Map<String, T> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration defaultCacheExpiration = Duration(minutes: 10);

  // Get cached item if not expired
  T? getCachedItem(String key, {Duration? expiration}) {
    if (_cache.containsKey(key)) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) <
              (expiration ?? defaultCacheExpiration)) {
        return _cache[key];
      }
    }
    return null;
  }

  // Cache an item
  void cacheItem(String key, T item) {
    _cache[key] = item;
    _cacheTimestamps[key] = DateTime.now();
  }

  // Clear cache for a specific key or all cache
  void clearCache({String? key}) {
    if (key != null) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }

  // Clean expired cache entries
  void cleanExpiredCache({Duration? expiration}) {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > (expiration ?? defaultCacheExpiration)) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }
}

/// A mixin that provides ongoing operation tracking functionality
mixin OngoingOperationUtils<T> {
  final Map<String, Future<T>> _ongoingOperations = {};

  // Check if an operation is ongoing
  bool isOperationOngoing(String key) => _ongoingOperations.containsKey(key);

  // Get ongoing operation if exists
  Future<T>? getOngoingOperation(String key) => _ongoingOperations[key];

  // Add ongoing operation
  void addOngoingOperation(String key, Future<T> operation) {
    _ongoingOperations[key] = operation;
  }

  // Remove ongoing operation
  void removeOngoingOperation(String key) {
    _ongoingOperations.remove(key);
  }

  // Clear all ongoing operations
  void clearOngoingOperations() {
    _ongoingOperations.clear();
  }
}
