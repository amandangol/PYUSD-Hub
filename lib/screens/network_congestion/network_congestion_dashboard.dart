import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'model/network_congestion_model.dart';
import 'provider/network_congestion_provider.dart';
import 'package:flutter/painting.dart';
import 'dart:ui' as ui;

class NetworkCongestionDashboard extends StatefulWidget {
  const NetworkCongestionDashboard({Key? key}) : super(key: key);

  @override
  State<NetworkCongestionDashboard> createState() =>
      _NetworkCongestionDashboardState();
}

class _NetworkCongestionDashboardState extends State<NetworkCongestionDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final formatter = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkCongestionProvider>(
      builder: (context, provider, child) {
        final currentData = provider.currentData;
        final status = provider.getNetworkStatus();

        return Scaffold(
          appBar: AppBar(
            title: const Text('PYUSD Network Traffic'),
            actions: [
              IconButton(
                  onPressed: () => provider.startMonitoring,
                  icon: const Icon(Icons.refresh))
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Dashboard'),
                Tab(text: 'PYUSD Stats'),
                Tab(text: 'Traffic Visualization'),
              ],
            ),
          ),
          body: provider.isLoading && currentData == null
              ? const Center(child: CircularProgressIndicator())
              : provider.error != null
                  ? Center(child: Text('Error: ${provider.error}'))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDashboardTab(provider, status),
                        _buildPYUSDStatsTab(provider),
                        Placeholder(),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildDashboardTab(
      NetworkCongestionProvider provider, NetworkStatus status) {
    final currentData = provider.currentData;
    if (currentData == null)
      return const Center(child: Text('No data available'));

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNetworkStatusCard(status),
            const SizedBox(height: 16),
            _buildKeyMetricsCard(currentData),
            const SizedBox(height: 16),
            _buildGasPriceChart(provider.historicalData),
            const SizedBox(height: 16),
            _buildUtilizationChart(provider.historicalData),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkStatusCard(NetworkStatus status) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              status.color.withOpacity(0.7),
              status.color.withOpacity(0.3)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Network Status: ${status.level}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  status.level == 'Low'
                      ? Icons.check_circle
                      : status.level == 'Medium'
                          ? Icons.warning
                          : Icons.error,
                  color: status.level == 'Low'
                      ? Colors.green[700]
                      : status.level == 'Medium'
                          ? Colors.orange[700]
                          : Colors.red[700],
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(status.description),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsCard(NetworkCongestionData data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Network Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMetricItem(
                  Icons.local_gas_station,
                  'Gas Price',
                  '${data.gasPrice.toStringAsFixed(2)} Gwei',
                  Colors.purple,
                ),
                _buildMetricItem(
                  Icons.pending_actions,
                  'Pending Txs',
                  formatter.format(data.pendingTransactions),
                  Colors.amber,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMetricItem(
                  Icons.currency_exchange,
                  'PYUSD Txs',
                  formatter.format(data.pyusdTransactions),
                  Colors.blue,
                ),
                _buildMetricItem(
                  Icons.graphic_eq,
                  'Network Load',
                  '${data.networkUtilization.toStringAsFixed(1)}%',
                  data.networkUtilization < 30
                      ? Colors.green
                      : data.networkUtilization < 70
                          ? Colors.orange
                          : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
      IconData icon, String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGasPriceChart(List<NetworkCongestionData> historicalData) {
    if (historicalData.isEmpty) {
      return const SizedBox();
    }

    final spots = historicalData
        .asMap()
        .entries
        .map((entry) => FlSpot(
            entry.value.timestamp.millisecondsSinceEpoch.toDouble(),
            entry.value.gasPrice))
        .toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gas Price Trend (Gwei)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final DateTime date =
                              DateTime.fromMillisecondsSinceEpoch(
                                  value.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('HH:mm').format(date),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.purple,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.purple.withOpacity(0.2),
                      ),
                    ),
                  ],
                  minX: spots.isNotEmpty ? spots.first.x : 0,
                  maxX: spots.isNotEmpty ? spots.last.x : 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockRangeIndicator(int fromBlock, int toBlock) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.data_usage, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'Analyzing blocks: $fromBlock to $toBlock',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilizationChart(List<NetworkCongestionData> historicalData) {
    if (historicalData.isEmpty) {
      return const SizedBox();
    }

    final spots = historicalData
        .asMap()
        .entries
        .map((entry) => FlSpot(
            entry.value.timestamp.millisecondsSinceEpoch.toDouble(),
            entry.value.networkUtilization))
        .toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Utilization (%)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final DateTime date =
                              DateTime.fromMillisecondsSinceEpoch(
                                  value.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('HH:mm').format(date),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.teal,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.teal.withOpacity(0.2),
                      ),
                    ),
                  ],
                  minX: spots.isNotEmpty ? spots.first.x : 0,
                  maxX: spots.isNotEmpty ? spots.last.x : 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPYUSDStatsTab(NetworkCongestionProvider provider) {
    final currentData = provider.currentData;
    if (currentData == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPYUSDMetricsCard(currentData),
            const SizedBox(height: 16),
            _buildPYUSDTransactionsChart(provider.historicalData),
            const SizedBox(height: 16),
            _buildPYUSDVolumeChart(provider.historicalData),
            const SizedBox(height: 16),
            _buildPYUSDExplanationCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPYUSDMetricsCard(NetworkCongestionData data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.7),
              Colors.blue.withOpacity(0.3)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.currency_exchange, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'PYUSD Metrics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Transactions',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatter.format(data.pyusdTransactions),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Volume (USD)',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${formatter.format(data.pyusdVolume)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPYUSDTransactionsChart(
      List<NetworkCongestionData> historicalData) {
    if (historicalData.isEmpty) {
      return const SizedBox();
    }

    final spots = historicalData
        .asMap()
        .entries
        .map((entry) => FlSpot(
            entry.value.timestamp.millisecondsSinceEpoch.toDouble(),
            entry.value.pyusdTransactions.toDouble()))
        .toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PYUSD Transaction Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final DateTime date =
                              DateTime.fromMillisecondsSinceEpoch(
                                  value.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('HH:mm').format(date),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
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
                  minX: spots.isNotEmpty ? spots.first.x : 0,
                  maxX: spots.isNotEmpty ? spots.last.x : 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPYUSDVolumeChart(List<NetworkCongestionData> historicalData) {
    if (historicalData.isEmpty) {
      return const SizedBox();
    }

    final spots = historicalData
        .asMap()
        .entries
        .map((entry) => FlSpot(
            entry.value.timestamp.millisecondsSinceEpoch.toDouble(),
            entry.value.pyusdVolume))
        .toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PYUSD Volume Trend (USD)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final DateTime date =
                              DateTime.fromMillisecondsSinceEpoch(
                                  value.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('HH:mm').format(date),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.2),
                      ),
                    ),
                  ],
                  minX: spots.isNotEmpty ? spots.first.x : 0,
                  maxX: spots.isNotEmpty ? spots.last.x : 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPYUSDExplanationCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What is PYUSD?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'PYUSD is a regulated stablecoin pegged to the US dollar. It runs on the Ethereum blockchain and is designed for payments, savings, and international transfers.',
            ),
            SizedBox(height: 12),
            Text(
              'Impact on Network Congestion',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'As a popular stablecoin, PYUSD transactions can contribute to overall network congestion on Ethereum. High transaction volume can lead to higher gas fees and longer confirmation times for all Ethereum users.',
            ),
          ],
        ),
      ),
    );
  }
}
