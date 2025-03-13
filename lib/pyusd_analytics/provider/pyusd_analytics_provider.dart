// import 'package:flutter/foundation.dart';
// import '../model/pyusd_stats_model.dart';
// import '../service/pyusd_analytics_service.dart';

// class PyusdDashboardProvider with ChangeNotifier {
//   final PyusdDashboardService _service;

//   PyusdStats _stats = PyusdStats.initial();
//   bool _isLoading = false;
//   String? _error;

//   PyusdDashboardProvider({PyusdDashboardService? service})
//       : _service = service ?? PyusdDashboardService();

//   PyusdStats get stats => _stats;
//   bool get isLoading => _isLoading;
//   String? get error => _error;

//   Future<void> loadDashboardData() async {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       _stats = await _service.getPyusdDashboardData();
//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _isLoading = false;
//       _error = 'Failed to load PYUSD dashboard data: ${e.toString()}';
//       notifyListeners();
//     }
//   }

//   // Helper methods to filter and process data

//   List<ChartDataPoint> getSupplyHistoryForPeriod(int days) {
//     final now = DateTime.now();
//     final cutoffDate = now.subtract(Duration(days: days));

//     return _stats.supplyHistory
//         .where((point) => point.timestamp.isAfter(cutoffDate))
//         .toList();
//   }

//   List<ChartDataPoint> getPriceHistoryForPeriod(int days) {
//     final now = DateTime.now();
//     final cutoffDate = now.subtract(Duration(days: days));

//     return _stats.priceHistory
//         .where((point) => point.timestamp.isAfter(cutoffDate))
//         .toList();
//   }

//   List<TransactionStat> getTransactionStatsForPeriod(int days) {
//     final now = DateTime.now();
//     final cutoffDate = now.subtract(Duration(days: days));

//     return _stats.transactionStats
//         .where((stat) => stat.date.isAfter(cutoffDate))
//         .toList();
//   }

//   double getTransactionVolumeForPeriod(int days) {
//     final transactionStats = getTransactionStatsForPeriod(days);
//     return transactionStats.fold(0, (sum, stat) => sum + stat.volume);
//   }

//   int getTransactionCountForPeriod(int days) {
//     final transactionStats = getTransactionStatsForPeriod(days);
//     return transactionStats.fold(0, (sum, stat) => sum + stat.count);
//   }

//   double getAverageGasPriceForPeriod(int days) {
//     final transactionStats = getTransactionStatsForPeriod(days);
//     if (transactionStats.isEmpty) return 0;

//     final sum =
//         transactionStats.fold(0.0, (sum, stat) => sum + stat.avgGasPrice);
//     return sum / transactionStats.length;
//   }

//   @override
//   void dispose() {
//     _service.dispose();
//     super.dispose();
//   }
// }
