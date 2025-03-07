import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/network_distribution.dart';
import '../models/pyusd_fact.dart';

class PYUSDAnalyticsProvider extends ChangeNotifier {
  // GCP RPC Configuration
  final String _gcpRpcUrl = dotenv.env['GCP_RPC_URL'] ?? '';
  final String _gcpApiKey = dotenv.env['GCP_API_KEY'] ?? '';

  // PYUSD Contract Address (Ethereum)
  final String _pyusdContract = '0x36b40228133cb20F83d4AED93E00865d435F36A1';

  // Analytics Data
  double totalSupply = 0;
  double supplyChangePercentage = 0;
  int totalHolders = 0;
  double holdersChangePercentage = 0;
  double volume24h = 0;
  double volumeChangePercentage = 0;
  int totalTransactions = 0;
  double transactionsChangePercentage = 0;

  // Chart Data
  List<double> supplyHistory = [];
  List<String> supplyLabels = [];

  List<double> transactionData = [];
  List<String> transactionLabels = [];

  List<NetworkDistribution> networkDistribution = [];

  List<PYUSDFact> pyusdFacts = [];

  PYUSDAnalyticsProvider() {
    // Initialize empty data
    _initializeEmptyData();
  }

  void _initializeEmptyData() {
    // Sample data until real data is fetched
    totalSupply = 0;
    supplyChangePercentage = 0;
    totalHolders = 0;
    holdersChangePercentage = 0;
    volume24h = 0;
    volumeChangePercentage = 0;
    totalTransactions = 0;
    transactionsChangePercentage = 0;

    supplyHistory = List.generate(7, (index) => 0);
    supplyLabels = List.generate(7, (index) => '');

    transactionData = List.generate(7, (index) => 0);
    transactionLabels = List.generate(7, (index) => '');

    networkDistribution = [];

    pyusdFacts = [];
  }

  Future<void> fetchDashboardData(String timeRange) async {
    try {
      // Start with loading states
      _initializeEmptyData();
      notifyListeners();

      // Fetch total supply
      totalSupply = await _fetchTotalSupply();

      // Fetch historical supply data
      await _fetchSupplyHistory(timeRange);

      // Fetch holder statistics
      await _fetchHolderStats(timeRange);

      // Fetch transaction data
      await _fetchTransactionData(timeRange);

      // Fetch volume data
      await _fetchVolumeData(timeRange);

      // Fetch network distribution
      await _fetchNetworkDistribution();

      // Fetch PYUSD facts (this might be static or from a different source)
      await _fetchPYUSDFacts();

      // Notify listeners about the updated data
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      // Handle error gracefully - possibly revert to mock data
      _loadMockData(timeRange);
      notifyListeners();
    }
  }

  // This is a placeholder - in a real app, you would implement actual API calls
  Future<Map<String, dynamic>> _callRpcMethod(
      String method, List<dynamic> params) async {
    if (_gcpRpcUrl.isEmpty || _gcpApiKey.isEmpty) {
      throw Exception('GCP RPC URL or API Key not configured');
    }

    final response = await http.post(
      Uri.parse('$_gcpRpcUrl?key=$_gcpApiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': method,
        'params': params,
        'id': 1,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to call RPC method: $method');
    }
  }

  // Sample implementation to fetch PYUSD total supply
  Future<double> _fetchTotalSupply() async {
    try {
      // Call the totalSupply method on the PYUSD contract
      final methodId = '0x18160ddd'; // Function selector for totalSupply()
      final callData = {
        'to': _pyusdContract,
        'data': methodId,
      };

      final response = await _callRpcMethod('eth_call', [callData, 'latest']);

      if (response.containsKey('result')) {
        // Convert hex result to decimal and divide by 10^6 (PYUSD has 6 decimals)
        final hexValue = response['result'];
        final bigInt = BigInt.parse(hexValue);
        return bigInt.toDouble() / 1000000;
      }

      return 0;
    } catch (e) {
      debugPrint('Error fetching total supply: $e');
      return 0;
    }
  }

  // For demo purposes, we'll use mock data
  void _loadMockData(String timeRange) {
    // Key metrics based on time range
    switch (timeRange) {
      case '24h':
        totalSupply = 1234567890;
        supplyChangePercentage = 0.8;
        totalHolders = 45678;
        holdersChangePercentage = 1.2;
        volume24h = 56789012;
        volumeChangePercentage = 2.3;
        totalTransactions = 345678;
        transactionsChangePercentage = 1.7;
        break;
      case '7d':
        totalSupply = 1234567890;
        supplyChangePercentage = 2.5;
        totalHolders = 45678;
        holdersChangePercentage = 3.8;
        volume24h = 56789012;
        volumeChangePercentage = -1.2;
        totalTransactions = 345678;
        transactionsChangePercentage = 5.3;
        break;
      case '30d':
        totalSupply = 1234567890;
        supplyChangePercentage = 8.3;
        totalHolders = 45678;
        holdersChangePercentage = 12.5;
        volume24h = 56789012;
        volumeChangePercentage = 7.8;
        totalTransactions = 345678;
        transactionsChangePercentage = 15.2;
        break;
      default:
        totalSupply = 1234567890;
        supplyChangePercentage = 2.5;
        totalHolders = 45678;
        holdersChangePercentage = 3.8;
        volume24h = 56789012;
        volumeChangePercentage = -1.2;
        totalTransactions = 345678;
        transactionsChangePercentage = 5.3;
    }

    // Supply history
    if (timeRange == '7d') {
      supplyHistory = [
        1220000000,
        1223000000,
        1225000000,
        1227000000,
        1229000000,
        1232000000,
        1234567890,
      ];
      supplyLabels = [
        'Mar 1',
        'Mar 2',
        'Mar 3',
        'Mar 4',
        'Mar 5',
        'Mar 6',
        'Mar 7'
      ];
    } else if (timeRange == '30d') {
      supplyHistory = [
        1140000000,
        1160000000,
        1175000000,
        1185000000,
        1195000000,
        1210000000,
        1234567890,
      ];
      supplyLabels = [
        'Feb 5',
        'Feb 10',
        'Feb 15',
        'Feb 20',
        'Feb 25',
        'Mar 1',
        'Mar 7'
      ];
    } else {
      supplyHistory = [
        1232000000,
        1232500000,
        1233000000,
        1233400000,
        1233800000,
        1234200000,
        1234567890,
      ];
      supplyLabels = [
        '6h ago',
        '5h ago',
        '4h ago',
        '3h ago',
        '2h ago',
        '1h ago',
        'Now'
      ];
    }

    // Transaction activity
    if (timeRange == '7d') {
      transactionData = [12300, 15600, 14200, 16800, 18500, 17200, 19600];
      transactionLabels = [
        'Mar 1',
        'Mar 2',
        'Mar 3',
        'Mar 4',
        'Mar 5',
        'Mar 6',
        'Mar 7'
      ];
    } else if (timeRange == '30d') {
      transactionData = [
        285000,
        310000,
        325000,
        342000,
        356000,
        372000,
        398000
      ];
      transactionLabels = [
        'Feb 5',
        'Feb 10',
        'Feb 15',
        'Feb 20',
        'Feb 25',
        'Mar 1',
        'Mar 7'
      ];
    } else {
      transactionData = [2100, 2350, 2420, 2680, 2780, 2900, 3050];
      transactionLabels = [
        '6h ago',
        '5h ago',
        '4h ago',
        '3h ago',
        '2h ago',
        '1h ago',
        'Now'
      ];
    }

    // Network distribution
    networkDistribution = [
      NetworkDistribution(
        network: 'Ethereum',
        percentage: 78.5,
        amount: 969134000,
      ),
      NetworkDistribution(
        network: 'Solana',
        percentage: 12.8,
        amount: 158024700,
      ),
      NetworkDistribution(
        network: 'Avalanche',
        percentage: 5.2,
        amount: 64197530,
      ),
      NetworkDistribution(
        network: 'Polygon',
        percentage: 3.5,
        amount: 43209876,
      ),
    ];

    // PYUSD Facts
    pyusdFacts = [
      PYUSDFact(
        title: 'Largest Transaction',
        description:
            'The largest PYUSD transaction to date was \$12.5M on February 15, 2025, from a major institutional wallet.',
        icon: Icons.arrow_circle_up,
      ),
      PYUSDFact(
        title: 'Growth Rate',
        description:
            'PYUSD supply has grown by 25% in the last quarter, making it one of the fastest-growing stablecoins.',
        icon: Icons.trending_up,
      ),
      PYUSDFact(
        title: 'Merchant Adoption',
        description:
            'Over 500 merchants now accept PYUSD for payments, with integration through PayPal\'s existing infrastructure.',
        icon: Icons.store,
      ),
      PYUSDFact(
        title: 'DeFi Integration',
        description:
            'PYUSD is integrated with 15 major DeFi protocols with over \$350M in total value locked.',
        icon: Icons.account_balance,
      ),
    ];
  }
}
