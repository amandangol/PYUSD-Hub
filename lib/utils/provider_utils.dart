import 'package:flutter/material.dart';

/// A mixin that provides common functionality for providers
mixin ProviderUtils {
  bool _disposed = false;
  bool _isLoading = false;
  String? _error;

  // Use getters for immutable access
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get disposed => _disposed;

  // Optimize notification by adding batch notification support
  void safeNotifyListeners(ChangeNotifier provider, {bool batch = false}) {
    if (!_disposed && !batch) {
      provider.notifyListeners();
    }
  }

  // Add batch operations support
  void batchNotify(ChangeNotifier provider, void Function() operations) {
    if (_disposed) return;

    operations();
    provider.notifyListeners();
  }

  // Optimize state management
  void setLoadingState(ChangeNotifier provider, bool loading,
      {bool notify = true}) {
    if (_disposed || _isLoading == loading) return;

    _isLoading = loading;
    if (!loading) _error = null;
    if (notify) safeNotifyListeners(provider);
  }

  // Add error handling with optional notification
  void setError(ChangeNotifier provider, String errorMsg,
      {bool notify = true}) {
    if (_disposed) return;

    _error = errorMsg;
    print('Provider error: $errorMsg');
    if (notify) safeNotifyListeners(provider);
  }

  // Add error clearing with optional notification
  void clearError(ChangeNotifier provider, {bool notify = true}) {
    if (_disposed || _error == null) return;

    _error = null;
    if (notify) safeNotifyListeners(provider);
  }

  void markDisposed() {
    _disposed = true;
  }
}

/// A mixin that provides caching functionality for providers
mixin CacheUtils<T> {
  final Map<String, T> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration defaultCacheExpiration = Duration(minutes: 10);

  // Add cache statistics
  int get cacheSize => _cache.length;
  DateTime? getItemTimestamp(String key) => _cacheTimestamps[key];

  // Optimize cache retrieval with optional refresh check
  T? getCachedItem(
    String key, {
    Duration? expiration,
    bool checkExpiration = true,
  }) {
    if (!_cache.containsKey(key)) return null;

    if (checkExpiration) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp == null ||
          DateTime.now().difference(timestamp) >=
              (expiration ?? defaultCacheExpiration)) {
        return null;
      }
    }
    return _cache[key];
  }

  // Add batch caching support
  void cacheItems(Map<String, T> items) {
    final now = DateTime.now();
    items.forEach((key, item) {
      _cache[key] = item;
      _cacheTimestamps[key] = now;
    });
  }

  void cacheItem(String key, T item) {
    _cache[key] = item;
    _cacheTimestamps[key] = DateTime.now();
  }

  // Add selective cache clearing
  void clearCache({String? key, Duration? olderThan}) {
    if (key != null) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    } else if (olderThan != null) {
      final threshold = DateTime.now().subtract(olderThan);
      _cacheTimestamps.removeWhere((key, timestamp) {
        if (timestamp.isBefore(threshold)) {
          _cache.remove(key);
          return true;
        }
        return false;
      });
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }

  // Optimize cache cleanup
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
  final Set<String> _completedOperations = {};

  bool isOperationOngoing(String key) => _ongoingOperations.containsKey(key);
  bool isOperationCompleted(String key) => _completedOperations.contains(key);

  Future<T>? getOngoingOperation(String key) => _ongoingOperations[key];

  // Add operation tracking with completion callback
  void trackOperation(String key, Future<T> operation) {
    _ongoingOperations[key] = operation;

    operation.whenComplete(() {
      _ongoingOperations.remove(key);
      _completedOperations.add(key);
    });
  }

  void removeOngoingOperation(String key) {
    _ongoingOperations.remove(key);
  }

  void clearOngoingOperations() {
    _ongoingOperations.clear();
    _completedOperations.clear();
  }
}
