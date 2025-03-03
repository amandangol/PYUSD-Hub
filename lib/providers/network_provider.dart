import 'package:flutter/foundation.dart';
import 'dart:math';

class NetworkProvider with ChangeNotifier {
  bool _isLoading = true;
  String _congestionLevel = 'medium';
  double _currentGasPrice = 23.5;
  double _fastGasPrice = 32.0;
  double _standardGasPrice = 23.5;
  double _slowGasPrice = 18.2;
  List<double> _gasPriceHistory = [];
  Map<String, double> _pyusdTransferVolume = {};
  Map<String, double> _bridgeActivity = {};
  int _totalTransactions = 0;
  int _uniqueAddresses = 0;
  int _totalBridgeVolume = 0;

  bool get isLoading => _isLoading;
  String get congestionLevel => _congestionLevel;
  double get currentGasPrice => _currentGasPrice;
  double get fastGasPrice => _fastGasPrice;
  double get standardGasPrice => _standardGasPrice;
  double get slowGasPrice => _slowGasPrice;
  List<double> get gasPriceHistory => _gasPriceHistory;
  Map<String, double> get pyusdTransferVolume => _pyusdTransferVolume;
  Map<String, double> get bridgeActivity => _bridgeActivity;
  int get totalTransactions => _totalTransactions;
  int get uniqueAddresses => _uniqueAddresses;
  int get totalBridgeVolume => _totalBridgeVolume;

  NetworkProvider() {
    _gasPriceHistory =
        List.generate(24, (_) => Random().nextDouble() * 40 + 10);
    _pyusdTransferVolume = {
      'Ethereum': 45325423.32,
      'Avalanche': 12534234.65,
      'Solana': 8674532.12,
      'Optimism': 4563245.87,
      'Arbitrum': 3452167.43,
    };
    _bridgeActivity = {
      'Wormhole': 34.5,
      'Portal': 26.3,
      'Hop': 18.7,
      'Across': 12.2,
      'Stargate': 8.3,
    };
    _totalTransactions = 145324;
    _uniqueAddresses = 34521;
    _totalBridgeVolume = 74523124;
  }

  double getGasPricePercentile() {
    const double maxGasPrice = 100.0;
    return _currentGasPrice / maxGasPrice;
  }

  Future<void> fetchNetworkData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate fetching data from API
      await Future.delayed(const Duration(seconds: 2));

      // In a real app, you would fetch data from GCP RPC here
      // Update values based on fetched data
      _currentGasPrice = Random().nextDouble() * 40 + 10;
      _fastGasPrice = _currentGasPrice * 1.5;
      _standardGasPrice = _currentGasPrice;
      _slowGasPrice = _currentGasPrice * 0.8;

      // Update congestion level based on gas price
      if (_currentGasPrice < 20) {
        _congestionLevel = 'low';
      } else if (_currentGasPrice < 40) {
        _congestionLevel = 'medium';
      } else {
        _congestionLevel = 'high';
      }

      // Update gas price history
      _gasPriceHistory =
          List.generate(24, (_) => Random().nextDouble() * 40 + 10);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
