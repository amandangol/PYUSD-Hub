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
                        _buildTrafficVisualizationTab(provider),
                      ],
                    ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => provider.startMonitoring(),
            child: const Icon(Icons.refresh),
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
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.gasPrice))
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
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    leftTitles: AxisTitles(
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
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.purple.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
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
        .map((entry) =>
            FlSpot(entry.key.toDouble(), entry.value.networkUtilization))
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
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    leftTitles: AxisTitles(
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
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.teal.withOpacity(0.2),
                      ),
                    ),
                  ],
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
    if (currentData == null)
      return const Center(child: Text('No data available'));

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
            entry.key.toDouble(), entry.value.pyusdTransactions.toDouble()))
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
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    leftTitles: AxisTitles(
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
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                  ],
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
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.pyusdVolume))
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
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    leftTitles: AxisTitles(
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
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.2),
                      ),
                    ),
                  ],
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What is PYUSD?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'PYUSD is a regulated stablecoin pegged to the US dollar. It runs on the Ethereum blockchain and is designed for payments, savings, and international transfers.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Impact on Network Congestion',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'As a popular stablecoin, PYUSD transactions can contribute to overall network congestion on Ethereum. High transaction volume can lead to higher gas fees and longer confirmation times for all Ethereum users.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficVisualizationTab(NetworkCongestionProvider provider) {
    return const NetworkTrafficVisualization();
  }
}

class NetworkTrafficVisualization extends StatefulWidget {
  const NetworkTrafficVisualization({Key? key}) : super(key: key);

  @override
  State<NetworkTrafficVisualization> createState() =>
      _NetworkTrafficVisualizationState();
}

class _NetworkTrafficVisualizationState
    extends State<NetworkTrafficVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<VehicleData> _vehicles = [];
  List<BuildingData> _buildings = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(() {
        _updateVehicles();
        setState(() {});
      });

    _generateBuildings();
    _generateVehicles();
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateBuildings() {
    _buildings = List.generate(6, (index) {
      return BuildingData(
        height: 100 + (index * 20.0),
        width: 60 + (index % 3 * 20.0),
        color: Colors.grey.shade800,
        hasLights: index % 2 == 0,
      );
    });
  }

  void _generateVehicles() {
    final provider =
        Provider.of<NetworkCongestionProvider>(context, listen: false);
    final utilization = provider.currentData?.networkUtilization ?? 50.0;

    // Number of vehicles based on congestion
    final vehicleCount = ((utilization / 100.0) * 15).round() + 5;

    // Generate vehicles
    _vehicles = List.generate(vehicleCount, (index) {
      final isBlue = index % 5 == 0; // PYUSD transactions are blue

      return VehicleData(
        speed: isBlue
            ? 2.0 + (Random().nextDouble() * 2.0)
            : 1.0 + (Random().nextDouble() * 3.0),
        size: isBlue ? 20.0 : 15.0 + (Random().nextDouble() * 10.0),
        color: isBlue
            ? Colors.blue
            : [
                Colors.red,
                Colors.green,
                Colors.amber,
                Colors.purple
              ][Random().nextInt(4)],
        lane: Random().nextInt(3),
      );
    });
  }

  void _updateVehicles() {
    for (int i = 0; i < _vehicles.length; i++) {
      final vehicle = _vehicles[i];
      final newX = (vehicle.position.dx - vehicle.speed) %
          MediaQuery.of(context).size.width;

      _vehicles[i] = VehicleData(
        speed: vehicle.speed,
        size: vehicle.size,
        color: vehicle.color,
        lane: vehicle.lane,
        position: Offset(newX, 100.0 + (vehicle.lane * 50.0)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkCongestionProvider>(
      builder: (context, provider, child) {
        final utilization = provider.currentData?.networkUtilization ?? 50.0;
        final status = provider.getNetworkStatus();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Network Traffic Visualization',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: status.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Current Congestion: ${utilization.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Blue vehicles represent PYUSD transactions',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Text(
                        '• Other vehicles represent regular Ethereum transactions',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.grey[900],
                child: CustomPaint(
                  painter: TrafficPainter(
                    vehicles: _vehicles,
                    buildings: _buildings,
                    congestionLevel: utilization / 100.0,
                  ),
                  child: Container(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class TrafficPainter extends CustomPainter {
  final List<VehicleData> vehicles;
  final List<BuildingData> buildings;
  final double congestionLevel;

  TrafficPainter({
    required this.vehicles,
    required this.buildings,
    required this.congestionLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw sky
    final skyPaint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // Draw stars
    final starPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 100; i++) {
      final x = Random().nextDouble() * size.width;
      final y = Random().nextDouble() * size.height * 0.5;
      final starSize = Random().nextDouble() * 2.0;
      canvas.drawCircle(Offset(x, y), starSize, starPaint);
    }

    // Draw buildings
    for (int i = 0; i < buildings.length; i++) {
      final building = buildings[i];
      final buildingPaint = Paint()..color = building.color;

      final x = i * (size.width / buildings.length);
      final y = size.height - building.height;

      canvas.drawRect(
        Rect.fromLTWH(x, y, building.width, building.height),
        buildingPaint,
      );

      // Draw windows
      if (building.hasLights) {
        final windowPaint = Paint()..color = Colors.yellow.withOpacity(0.8);
        final windowRows = (building.height / 20).floor();
        final windowCols = (building.width / 15).floor();

        for (int row = 0; row < windowRows; row++) {
          for (int col = 0; col < windowCols; col++) {
            if (Random().nextBool()) {
              canvas.drawRect(
                Rect.fromLTWH(
                  x + col * 15 + 3,
                  y + row * 20 + 3,
                  10,
                  15,
                ),
                windowPaint,
              );
            }
          }
        }
      }
    }

    // Draw road
    final roadPaint = Paint()..color = Colors.grey[800]!;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 180, size.width, 180),
      roadPaint,
    );

    // Draw lane markings
    final markingPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 2; i++) {
      final y = size.height - 130 + (i * 50);

      for (int j = 0; j < (size.width / 40).ceil(); j++) {
        canvas.drawLine(
          Offset(j * 40, y),
          Offset(j * 40 + 20, y),
          markingPaint,
        );
      }
    }

    // Draw vehicles
    for (final vehicle in vehicles) {
      final vehiclePaint = Paint()..color = vehicle.color;

      final y = size.height - 155 + (vehicle.lane * 50);

      // Draw vehicle body
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            vehicle.position.dx,
            y,
            vehicle.size * 1.5,
            vehicle.size,
          ),
          const Radius.circular(5),
        ),
        vehiclePaint,
      );

      // Draw windows
      final windowPaint = Paint()..color = Colors.white.withOpacity(0.7);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            vehicle.position.dx + vehicle.size * 0.8,
            y + vehicle.size * 0.2,
            vehicle.size * 0.4,
            vehicle.size * 0.4,
          ),
          const Radius.circular(3),
        ),
        windowPaint,
      );

      // Draw headlights
      final headlightPaint = Paint()..color = Colors.yellow.withOpacity(0.8);
      canvas.drawCircle(
        Offset(
            vehicle.position.dx + vehicle.size * 1.45, y + vehicle.size * 0.3),
        vehicle.size * 0.1,
        headlightPaint,
      );
      canvas.drawCircle(
        Offset(
            vehicle.position.dx + vehicle.size * 1.45, y + vehicle.size * 0.7),
        vehicle.size * 0.1,
        headlightPaint,
      );
    }

    // Draw traffic congestion indicator
    final statusTextStyle = TextStyle(
      color: congestionLevel < 0.3
          ? Colors.green
          : congestionLevel < 0.7
              ? Colors.orange
              : Colors.red,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );

    final textSpan = TextSpan(
      text:
          'Network Congestion: ${(congestionLevel * 100).toStringAsFixed(1)}%',
      style: statusTextStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr, // Correct usage
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(20, 20));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class VehicleData {
  final double speed;
  final double size;
  final Color color;
  final int lane;
  final Offset position;

  const VehicleData({
    required this.speed,
    required this.size,
    required this.color,
    required this.lane,
    this.position = const Offset(0, 0),
  });
}

class BuildingData {
  final double height;
  final double width;
  final Color color;
  final bool hasLights;

  const BuildingData({
    required this.height,
    required this.width,
    required this.color,
    this.hasLights = false,
  });
}
