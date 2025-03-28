import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../services/bigquery_service.dart';

class InsightsProvider extends ChangeNotifier {
  final BigQueryService _bigQueryService;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _stats = {
    'uniqueSenders': 0,
    'uniqueReceivers': 0,
    'totalVolume': 0.0,
    'totalTransactions': 0,
  };
  List<Map<String, dynamic>> _topHolders = [];
  List<Map<String, dynamic>> _dailyVolume = [];
  int _retryCount = 0;
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(minutes: 10);

  InsightsProvider(this._bigQueryService);

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get stats => _stats;
  List<Map<String, dynamic>> get topHolders => _topHolders;
  List<Map<String, dynamic>> get dailyVolume => _dailyVolume;

  Future<void> fetchInsightsData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Fetching insights data...');
      final data = await _bigQueryService.getAllPYUSDData();
      debugPrint('Received data: $data');

      if (data['stats'] != null) {
        _stats = Map<String, dynamic>.from(data['stats']);
      }

      if (data['topHolders'] != null) {
        final holders = data['topHolders'] as List;
        _topHolders = holders.map((holder) {
          if (holder is Map<String, dynamic>) {
            return holder;
          }
          return {
            'address': '',
            'balance': 0.0,
          };
        }).toList();
      } else {
        _topHolders = [];
      }

      // For now, we'll use empty daily volume since it's not implemented yet
      _dailyVolume = [];

      debugPrint('Successfully updated insights data');
      _error = null;
    } catch (e) {
      debugPrint('Error fetching insights data: $e');
      _error = e.toString();
      // Set default values on error
      _stats = {
        'uniqueSenders': 0,
        'uniqueReceivers': 0,
        'totalVolume': 0.0,
        'totalTransactions': 0,
      };
      _topHolders = [];
      _dailyVolume = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchWithRetry() async {
    while (_retryCount < maxRetries) {
      try {
        final data = await _bigQueryService.getAllPYUSDData();

        _stats = data['stats'] as Map<String, dynamic>;
        _dailyVolume = List<Map<String, dynamic>>.from(data['dailyVolumes']);
        _topHolders = List<Map<String, dynamic>>.from(data['topHolders']);

        debugPrint('Insights data updated successfully');
        debugPrint('Stats: $_stats');
        debugPrint('Daily volumes: ${_dailyVolume?.length} points');
        debugPrint('Top holders: ${_topHolders?.length} addresses');

        // Reset retry count on success
        _retryCount = 0;
        return;
      } catch (e) {
        if (e.toString().contains('Quota exceeded')) {
          _retryCount++;
          if (_retryCount < maxRetries) {
            debugPrint(
                'Quota exceeded. Retrying in ${retryDelay.inMinutes} minutes... (Attempt $_retryCount of $maxRetries)');
            await Future.delayed(retryDelay);
            continue;
          }
        }
        rethrow;
      }
    }

    throw Exception(
        'Failed to fetch data after $maxRetries attempts. Please try again later.');
  }

  String formatNumber(num number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(2)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)}K';
    }
    return number.toString();
  }

  String formatAddress(String address) {
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}
