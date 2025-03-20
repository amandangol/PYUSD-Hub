// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PyusdDataProvider()),
      ],
      child: const PyusdTrackerApp(),
    ),
  );
}

class PyusdTrackerApp extends StatelessWidget {
  const PyusdTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PYUSD Supply Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PyusdDashboard(),
    );
  }
}

class PyusdDashboard extends StatefulWidget {
  const PyusdDashboard({super.key});

  @override
  State<PyusdDashboard> createState() => _PyusdDashboardState();
}

class _PyusdDashboardState extends State<PyusdDashboard> {
  @override
  void initState() {
    super.initState();
    // Fetch data when the app starts
    Future.microtask(() =>
        Provider.of<PyusdDataProvider>(context, listen: false).fetchAllData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PYUSD Supply & Minting Data'),
      ),
      body: Consumer<PyusdDataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dataProvider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${dataProvider.errorMessage}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => dataProvider.fetchAllData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => dataProvider.fetchAllData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Supply Information Cards
                  SupplyInfoCards(dataProvider: dataProvider),

                  const SizedBox(height: 24),

                  // Supply Over Time Chart
                  const Text(
                    'PYUSD Supply Over Time',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SupplyChart(dataProvider: dataProvider),
                  ),

                  const SizedBox(height: 24),

                  // Minting History
                  const Text(
                    'Recent Minting Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  MintingHistoryList(dataProvider: dataProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SupplyInfoCards extends StatelessWidget {
  final PyusdDataProvider dataProvider;

  const SupplyInfoCards({super.key, required this.dataProvider});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        _buildInfoCard(
          title: 'Total Supply',
          value: formatter.format(dataProvider.totalSupply),
          icon: Icons.account_balance,
          color: Colors.blue,
        ),
        _buildInfoCard(
          title: 'Circulating Supply',
          value: formatter.format(dataProvider.circulatingSupply),
          icon: Icons.currency_exchange,
          color: Colors.green,
        ),
        _buildInfoCard(
          title: 'Total Minted',
          value: formatter.format(dataProvider.totalMinted),
          icon: Icons.add_circle_outline,
          color: Colors.purple,
        ),
        _buildInfoCard(
          title: 'Total Burned',
          value: formatter.format(dataProvider.totalBurned),
          icon: Icons.remove_circle_outline,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SupplyChart extends StatelessWidget {
  final PyusdDataProvider dataProvider;

  const SupplyChart({super.key, required this.dataProvider});

  @override
  Widget build(BuildContext context) {
    if (dataProvider.supplyHistory.isEmpty) {
      return const Center(child: Text('No supply history available'));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1000000000,
          verticalInterval: 1,
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= dataProvider.supplyHistory.length ||
                    value < 0) {
                  return const Text('');
                }
                return Transform.rotate(
                  angle: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      DateFormat('MM/dd').format(
                        dataProvider.supplyHistory[value.toInt()].timestamp,
                      ),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value >= 1000000000
                      ? '${(value / 1000000000).toStringAsFixed(1)}B'
                      : value >= 1000000
                          ? '${(value / 1000000).toStringAsFixed(1)}M'
                          : '${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 40,
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: dataProvider.supplyHistory.length.toDouble() - 1,
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              dataProvider.supplyHistory.length,
              (index) => FlSpot(
                index.toDouble(),
                dataProvider.supplyHistory[index].supply,
              ),
            ),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class MintingHistoryList extends StatelessWidget {
  final PyusdDataProvider dataProvider;

  const MintingHistoryList({super.key, required this.dataProvider});

  @override
  Widget build(BuildContext context) {
    if (dataProvider.mintingHistory.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No minting history available'),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: dataProvider.mintingHistory.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final event = dataProvider.mintingHistory[index];
          final formatter =
              NumberFormat.currency(symbol: '\$', decimalDigits: 2);
          final dateFormatter = DateFormat('MMM dd, yyyy HH:mm');

          return ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  event.isMint ? Colors.green.shade100 : Colors.red.shade100,
              child: Icon(
                event.isMint ? Icons.add : Icons.remove,
                color: event.isMint ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              event.isMint ? 'Mint' : 'Burn',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${dateFormatter.format(event.timestamp)}\nTransaction: ${event.txHash.substring(0, 10)}...',
            ),
            trailing: Text(
              formatter.format(event.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: event.isMint ? Colors.green : Colors.red,
              ),
            ),
            isThreeLine: true,
          );
        },
      ),
    );
  }
}

// Data model classes
class SupplyDataPoint {
  final DateTime timestamp;
  final double supply;

  SupplyDataPoint({required this.timestamp, required this.supply});
}

class MintingEvent {
  final DateTime timestamp;
  final double amount;
  final bool isMint;
  final String txHash;
  final String address;

  MintingEvent({
    required this.timestamp,
    required this.amount,
    required this.isMint,
    required this.txHash,
    required this.address,
  });
}

// Provider class for PYUSD data
class PyusdDataProvider extends ChangeNotifier {
  // Service URLs - Replace with your actual GCP service URLs
  final String _gcpRpcUrl =
      'https://blockchain.googleapis.com/v1/projects/oceanic-impact-451616-f5/locations/us-central1/endpoints/ethereum-mainnet/rpc?key=AIzaSyAnZZi8DTOXLn3zcRKoGYtRgMl-YQnIo1Q';
  final String _bigQueryServiceUrl =
      'https://your-bigquery-backend-service.com/pyusd';

  // PYUSD contract address on Ethereum
  final String _pyusdContractAddress =
      '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8'; // Replace with actual PYUSD address

  // Data state
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasError = false;

  // Supply data
  double _totalSupply = 0;
  double _circulatingSupply = 0;
  double _totalMinted = 0;
  double _totalBurned = 0;
  List<SupplyDataPoint> _supplyHistory = [];
  List<MintingEvent> _mintingHistory = [];

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _hasError;
  double get totalSupply => _totalSupply;
  double get circulatingSupply => _circulatingSupply;
  double get totalMinted => _totalMinted;
  double get totalBurned => _totalBurned;
  List<SupplyDataPoint> get supplyHistory => _supplyHistory;
  List<MintingEvent> get mintingHistory => _mintingHistory;

  // Fetch all data
  Future<void> fetchAllData() async {
    _setLoading(true);
    _clearError();

    try {
      // Fetch data in parallel for efficiency
      await Future.wait([
        _fetchCurrentSupply(),
        _fetchSupplyHistory(),
        _fetchMintingHistory(),
      ]);
    } catch (e) {
      _setError('Failed to fetch data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch current supply using eth_call
  // lib/main.dart (continued)

  // Fetch current supply using eth_call
  Future<void> _fetchCurrentSupply() async {
    try {
      // Total supply function signature from PYUSD ERC20 contract
      const totalSupplySignature = '0x18160ddd'; // totalSupply()

      // Circulating supply function signature (varies by token implementation)
      const circulatingSupplySignature = '0xd6a0c7af'; // circulatingSupply()

      // Call RPC endpoint for total supply
      final totalSupplyResponse = await http.post(
        Uri.parse(_gcpRpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'eth_call',
          'params': [
            {
              'to': _pyusdContractAddress,
              'data': totalSupplySignature,
            },
            'latest'
          ],
          'id': 1,
        }),
      );

      // Call RPC endpoint for circulating supply
      final circulatingSupplyResponse = await http.post(
        Uri.parse(_gcpRpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'eth_call',
          'params': [
            {
              'to': _pyusdContractAddress,
              'data': circulatingSupplySignature,
            },
            'latest'
          ],
          'id': 2,
        }),
      );

      // Parse responses
      final totalSupplyData = jsonDecode(totalSupplyResponse.body);
      final circulatingSupplyData = jsonDecode(circulatingSupplyResponse.body);

      if (totalSupplyData['error'] != null) {
        throw Exception('RPC error: ${totalSupplyData['error']['message']}');
      }

      // Convert hex strings to numbers (PYUSD has 6 decimals like USDC)
      _totalSupply = _hexToDecimal(totalSupplyData['result']) / 1000000;

      // If circulating supply call was successful, use that value
      // Otherwise, assume circulating supply equals total supply (simplified version)
      if (circulatingSupplyData['error'] == null) {
        _circulatingSupply =
            _hexToDecimal(circulatingSupplyData['result']) / 1000000;
      } else {
        // Fallback: For tokens that don't expose circulating supply directly
        _circulatingSupply = _totalSupply;
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to fetch current supply: ${e.toString()}');
    }
  }

  // Convert hex string to decimal number
  double _hexToDecimal(String hexString) {
    // Remove '0x' prefix if present
    final cleanHex =
        hexString.startsWith('0x') ? hexString.substring(2) : hexString;
    return int.parse(cleanHex, radix: 16).toDouble();
  }

  // Fetch supply history from BigQuery
  Future<void> _fetchSupplyHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$_bigQueryServiceUrl/supply_history'),
      );

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      _supplyHistory = List<SupplyDataPoint>.from(
        data['data'].map((item) => SupplyDataPoint(
              timestamp: DateTime.parse(item['timestamp']),
              supply: item['supply'].toDouble(),
            )),
      );

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to fetch supply history: ${e.toString()}');
    }
  }

  // Fetch minting history from BigQuery
  Future<void> _fetchMintingHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$_bigQueryServiceUrl/minting_history'),
      );

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      _mintingHistory = List<MintingEvent>.from(
        data['data'].map((item) => MintingEvent(
              timestamp: DateTime.parse(item['timestamp']),
              amount: item['amount'].toDouble(),
              isMint: item['type'] == 'mint',
              txHash: item['transaction_hash'],
              address: item['address'],
            )),
      );

      // Calculate totals
      _totalMinted = data['totals']['minted'].toDouble();
      _totalBurned = data['totals']['burned'].toDouble();

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to fetch minting history: ${e.toString()}');
    }
  }

  // Helper methods for state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _hasError = true;
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }
}
