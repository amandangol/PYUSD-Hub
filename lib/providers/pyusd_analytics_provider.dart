// import 'package:flutter/material.dart';
// import 'package:googleapis/bigquery/v2.dart';
// import 'package:googleapis_auth/auth_io.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:flutter/services.dart';

// class DailyAnalyticsData {
//   final String date;
//   final double volume;
//   final int transactions;
//   final int uniqueAddresses;

//   DailyAnalyticsData({
//     required this.date,
//     required this.volume,
//     required this.transactions,
//     required this.uniqueAddresses,
//   });
// }

// class PyusdAnalyticsProvider with ChangeNotifier {
//   bool _isLoading = false;
//   String? _error;
//   List<DailyAnalyticsData> _dailyData = [];
//   double _totalVolume = 0;
//   int _totalTransactions = 0;
//   int _uniqueAddresses = 0;

//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   List<DailyAnalyticsData> get dailyData => _dailyData;
//   double get totalVolume => _totalVolume;
//   int get totalTransactions => _totalTransactions;
//   int get uniqueAddresses => _uniqueAddresses;

//   // Google Cloud credentials
//   static const String _projectId = 'oceanic-impact-451616-f5';

//   Future<void> fetchAnalytics() async {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       print('Starting analytics fetch...');
//       // Initialize BigQuery client with service account credentials
//       final client = await _getAuthenticatedClient();
//       print('Authentication successful');

//       final bigquery = BigqueryApi(client);
//       print('BigQuery API initialized');

//       // Execute the query - using the public Ethereum dataset with correct schema
//       const query = '''
//         #standardSQL
//        #standardSQL
// WITH 
//   pyusd_transfers AS (
//     SELECT
//       block_timestamp,
//       from_address,
//       to_address,
//       CAST(SUBSTR(input, 75, 64) AS FLOAT64) / POW(10, 6) AS amount
//     FROM
//       `bigquery-public-data.goog_blockchain_ethereum_mainnet_us.transactions`
//     WHERE
//       DATE(block_timestamp) BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY) 
//       AND CURRENT_DATE()
//       -- This is the PYUSD contract address
//       AND to_address = '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8'
//       -- This is the transfer function signature
//       AND input LIKE '0xa9059cbb%'
//   )
// SELECT
//   DATE(block_timestamp) AS block_date,
//   COUNT(*) AS transaction_count,
//   COUNT(DISTINCT from_address) AS unique_senders,
//   COUNT(DISTINCT to_address) AS unique_recipients,
//   COALESCE(SUM(amount), 0) AS pyusd_transferred
// FROM
//   pyusd_transfers
// GROUP BY
//   block_date
// ORDER BY
//   block_date DESC
//       ''';

//       final queryRequest = QueryRequest()
//         ..query = query
//         ..useLegacySql = false; // Explicitly set to use standard SQL
//       print('Query submitted, waiting for results...');
//       final queryResponse = await bigquery.jobs.query(
//         queryRequest,
//         _projectId,
//       );

//       print('Query completed: ${queryResponse.jobComplete}');
//       print('Rows returned: ${queryResponse.rows?.length ?? 0}');

//       if (queryResponse.jobComplete == true) {
//         _processQueryResults(queryResponse);
//       } else {
//         throw Exception('Query job did not complete');
//       }
//     } catch (e) {
//       _error = e.toString();
//       print('Error fetching analytics: $e');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<http.Client> _getAuthenticatedClient() async {
//     try {
//       // Load service account credentials
//       final String jsonString =
//           await rootBundle.loadString('assets/keys/service-account.json');
//       final Map<String, dynamic> json = jsonDecode(jsonString);

//       // Create service account credentials
//       final credentials = ServiceAccountCredentials.fromJson(json);

//       // Get authenticated client
//       final scopes = [BigqueryApi.bigqueryScope];
//       final client = await clientViaServiceAccount(credentials, scopes);

//       return client;
//     } catch (e) {
//       print('Error getting authenticated client: $e');
//       rethrow;
//     }
//   }

//   void _processQueryResults(QueryResponse response) {
//     _dailyData = [];
//     _totalVolume = 0;
//     _totalTransactions = 0;
//     final Set<String> uniqueAddressesSet = {};

//     if (response.rows != null && response.rows!.isNotEmpty) {
//       for (var row in response.rows!) {
//         try {
//           final date = row.f![0].v.toString();
//           final transactions = int.parse(row.f![1].v.toString());
//           final uniqueSenders = int.parse(row.f![2].v.toString());
//           final uniqueRecipients = int.parse(row.f![3].v.toString());
//           final volume = double.parse(row.f![4].v.toString());

//           // This is just a daily count, not tracking actual addresses
//           final dailyUniqueAddresses = uniqueSenders + uniqueRecipients;

//           _dailyData.add(DailyAnalyticsData(
//             date: date,
//             volume: volume,
//             transactions: transactions,
//             uniqueAddresses: dailyUniqueAddresses,
//           ));

//           _totalVolume += volume;
//           _totalTransactions += transactions;

//           // You can't track actual addresses this way since you don't have the addresses
//           // Just add the count for simplicity
//           _uniqueAddresses += dailyUniqueAddresses;
//         } catch (e) {
//           print('Error processing row: $e');
//         }
//       }
//     } else {
//       // Handle empty result set
//       print('No data returned from query');
//     }
//   }
// }
