import 'dart:async';
import 'package:flutter/material.dart';
import '../model/network_activity_model.dart';

class NetworkActivityProvider extends ChangeNotifier {
  List<NetworkActivityData> _transactions = [];
  bool _isLoading = false;
  Timer? _refreshTimer;

  List<NetworkActivityData> get transactions => _transactions;
  bool get isLoading => _isLoading;

  NetworkActivityProvider() {
    initialize();
    // Refresh data every 30 seconds
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    await refresh();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      // TODO: Implement actual API call to fetch PYUSD network activity
      // For now, we'll use mock data
      _transactions = List.generate(
        20,
        (index) => NetworkActivityData(
          timestamp: DateTime.now().subtract(Duration(minutes: index)),
          transactionCount: 1,
          volume: (100 + index * 10).toDouble(),
          fromAddress: '0x${index.toString().padLeft(40, '0')}',
          toAddress: '0x${(index + 1).toString().padLeft(40, '0')}',
          transactionHash: '0x${index.toString().padLeft(64, '0')}',
        ),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing network activity: $e');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
