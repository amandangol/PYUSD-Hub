// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// // Import services
// import '../service/bigquery_service.dart';
// import '../service/pyusd_service.dart';

// class PyusdDataProvider extends ChangeNotifier {
//   // Services
//   final PyusdService _ethereumService = PyusdService();
//   final BigQueryService _bigQueryService = BigQueryService();

//   // PYUSD contract address on Ethereum
//   static const String pyusdContractAddress =
//       '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8';

//   bool isLoading = true;
//   bool isError = false;
//   String errorMessage = '';

//   // Dashboard metrics
//   double totalSupply = 0;
//   double marketCap = 0;
//   int totalHolders = 0;
//   double volume24h = 0;
//   double currentPrice = 1.0; // Stablecoin, expected to be close to $1

//   // Historical data
//   List<Map<String, dynamic>> supplyHistory = [];
//   double supplyGrowthRate = 0;

//   // Distribution data
//   Map<String, double> holderDistribution = {};

//   // Transaction data
//   List<Map<String, dynamic>> recentTransactions = [];

//   // Network impact data
//   Map<String, dynamic> networkMetrics = {
//     'txCount24h': 0,
//     'gasUsed24h': 0.0,
//     'networkPercentage': 0.0,
//   };

//   // Key insights
//   Map<String, String> keyInsights = {
//     'growth': '',
//     'adoption': '',
//     'network': '',
//   };

//   // Initialize data
//   Future<void> initializeData() async {
//     isLoading = true;
//     isError = false;
//     notifyListeners();

//     try {
//       // Fetch core data in parallel
//       await Future.wait([
//         _fetchTotalSupply(),
//         _fetchHolderData(),
//         _fetchTransactionData(),
//         _fetchHistoricalData(),
//       ]);

//       // Calculate derived metrics
//       _calculateNetworkMetrics();
//       _generateKeyInsights();

//       isLoading = false;
//     } catch (e) {
//       isError = true;
//       errorMessage = 'Failed to load dashboard data: ${e.toString()}';
//       print('Error initializing data: $e');
//     } finally {
//       isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Refresh data
//   Future<void> refreshData() async {
//     isLoading = true;
//     notifyListeners();

//     try {
//       await initializeData();
//     } catch (e) {
//       print('Error refreshing data: $e');
//     } finally {
//       isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Fetch the total supply of PYUSD
//   Future<void> _fetchTotalSupply() async {
//     try {
//       totalSupply = await _ethereumService.getTotalSupply();
//       // For stablecoins, market cap is generally equivalent to total supply
//       marketCap = totalSupply;
//     } catch (e) {
//       print('Error fetching total supply: $e');
//       // Use cached value if available, otherwise set to 0
//       if (totalSupply == 0) {
//         totalSupply = 0;
//         marketCap = 0;
//       }
//     }
//   }

//   // Fetch holder data from BigQuery
//   Future<void> _fetchHolderData() async {
//     try {
//       final holderData = await _bigQueryService.queryHolderDistribution();

//       if (holderData.containsKey('rows') && holderData['rows'] != null) {
//         holderDistribution = {};
//         int totalHolderCount = 0;

//         for (var row in holderData['rows']) {
//           List f = row['f'];
//           String category = f[0]['v'];
//           int holderCount = _safeParseInt(f[1]['v']);
//           double percentage = _safeParseDouble(f[3]['v']);

//           holderDistribution[category] = percentage;
//           totalHolderCount += holderCount;
//         }

//         totalHolders = totalHolderCount;
//       }
//     } catch (e) {
//       print('Error fetching holder data: $e');
//       // Keep existing data if available
//     }
//   }

//   // Fetch recent transactions
//   Future<void> _fetchTransactionData() async {
//     try {
//       final transactions = await _ethereumService.getRecentTransfers(5);

//       recentTransactions = transactions
//           .map((tx) => {
//                 'from': tx['from'],
//                 'to': tx['to'],
//                 'amount': _safeParseDouble(tx['amount']).toStringAsFixed(2),
//                 'txHash': tx['txHash'],
//                 'timestamp': tx['timestamp'] ?? DateTime.now().toString(),
//               })
//           .toList();
//     } catch (e) {
//       print('Error fetching transaction data: $e');
//       // Keep existing data if available
//     }
//   }

//   // Fetch historical supply data
//   Future<void> _fetchHistoricalData() async {
//     try {
//       // Get 30-day supply metrics
//       final supplyMetrics = await _bigQueryService.queryDailySupplyMetrics(30);

//       if (supplyMetrics.containsKey('rows') && supplyMetrics['rows'] != null) {
//         supplyHistory = [];

//         for (var row in supplyMetrics['rows']) {
//           List f = row['f'];

//           supplyHistory.add({
//             'date': f[0]['v'] ?? '',
//             'minted': _safeParseDouble(f[1]['v']),
//             'burned': _safeParseDouble(f[2]['v']),
//             'netChange': _safeParseDouble(f[3]['v']),
//           });
//         }

//         // Calculate growth rate if we have enough data
//         if (supplyHistory.length >= 2) {
//           double initialSupply = 0;
//           double netChange = 0;

//           try {
//             // Calculate total net change
//             netChange = supplyHistory
//                 .map((e) => e['netChange'] as double)
//                 .reduce((a, b) => a + b);

//             // Estimate initial supply
//             initialSupply = totalSupply - netChange;

//             // Calculate growth rate (monthly)
//             if (initialSupply > 0) {
//               supplyGrowthRate = ((totalSupply / initialSupply) - 1) * 100;
//             }
//           } catch (e) {
//             print('Error calculating growth rate: $e');
//             supplyGrowthRate = 0;
//           }
//         }
//       }
//     } catch (e) {
//       print('Error fetching historical data: $e');
//       // Keep existing data if available
//     }
//   }

//   // Calculate network metrics from historical data
//   void _calculateNetworkMetrics() {
//     try {
//       // Calculate PYUSD's impact on Ethereum network
//       double avgDailyTxs = 0;
//       double avgGasUsed = 0;

//       // Use data from recent transactions if available
//       if (recentTransactions.isNotEmpty) {
//         avgDailyTxs =
//             recentTransactions.length * 24 / 5; // Extrapolate to 24 hours
//       }

//       // Use data from BigQuery if available
//       if (supplyHistory.isNotEmpty && supplyHistory.length >= 7) {
//         // Calculate average daily mints and burns
//         double avgMintBurnTxs = supplyHistory
//             .take(7)
//             .map((day) => (day['minted'] as double) > 0 ? 1 : 0)
//             .fold(0, (a, b) => a + b);

//         avgMintBurnTxs += supplyHistory
//             .take(7)
//             .map((day) => (day['burned'] as double) > 0 ? 1 : 0)
//             .fold(0, (a, b) => a + b);

//         avgMintBurnTxs /= 7;

//         // Add this to our estimate
//         avgDailyTxs = (avgDailyTxs + avgMintBurnTxs) / 2;
//       }

//       // Estimate gas usage (approximate)
//       avgGasUsed =
//           avgDailyTxs * 65000; // Estimate 65,000 gas per PYUSD transaction

//       // Update network metrics
//       networkMetrics = {
//         'txCount24h': avgDailyTxs.round(),
//         'gasUsed24h': avgGasUsed / 1000000000, // Convert to Gwei
//         'networkPercentage': (avgDailyTxs / 1000000) *
//             100, // Estimate based on ~1M daily ETH txs
//       };
//     } catch (e) {
//       print('Error calculating network metrics: $e');
//     }
//   }

//   // Generate key insights for the dashboard
//   void _generateKeyInsights() {
//     // Growth insight
//     if (supplyGrowthRate > 0) {
//       keyInsights['growth'] =
//           'PYUSD supply has grown by ${supplyGrowthRate.toStringAsFixed(2)}% in the last 30 days';
//     } else if (supplyGrowthRate < 0) {
//       keyInsights['growth'] =
//           'PYUSD supply has decreased by ${(-supplyGrowthRate).toStringAsFixed(2)}% in the last 30 days';
//     } else {
//       keyInsights['growth'] =
//           'PYUSD supply has remained stable over the last 30 days';
//     }

//     // Adoption insight
//     if (holderDistribution.isNotEmpty) {
//       String topCategory = '';
//       double topPercentage = 0;

//       holderDistribution.forEach((category, percentage) {
//         if (percentage > topPercentage) {
//           topCategory = category;
//           topPercentage = percentage;
//         }
//       });

//       keyInsights['adoption'] =
//           '$topCategory holders control ${topPercentage.toStringAsFixed(1)}% of PYUSD supply';
//     } else {
//       keyInsights['adoption'] =
//           'PYUSD is held by $totalHolders unique addresses';
//     }

//     // Network insight
//     keyInsights['network'] =
//         'PYUSD transactions account for approximately ${networkMetrics['networkPercentage'].toStringAsFixed(2)}% of Ethereum network activity';
//   }

//   // Safe parsing utilities
//   int _safeParseInt(dynamic value) {
//     if (value == null) return 0;
//     try {
//       if (value is int) return value;
//       return int.parse(value.toString());
//     } catch (e) {
//       return 0;
//     }
//   }

//   double _safeParseDouble(dynamic value) {
//     if (value == null) return 0.0;
//     try {
//       if (value is double) return value;
//       return double.parse(value.toString());
//     } catch (e) {
//       return 0.0;
//     }
//   }
// }
