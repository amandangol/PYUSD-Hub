import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../model/networkcongestion_model.dart';
import '../../provider/network_congestion_provider.dart';

class AnalysisTab extends StatefulWidget {
  final NetworkCongestionProvider provider;
  final NetworkCongestionData congestionData;

  const AnalysisTab({
    Key? key,
    required this.provider,
    required this.congestionData,
  }) : super(key: key);

  @override
  State<AnalysisTab> createState() => _AnalysisTabState();
}

class _AnalysisTabState extends State<AnalysisTab> {
  Map<String, dynamic>? _transactionPatterns;
  Map<String, dynamic>? _networkHealth;
  Map<String, dynamic>? _gasPrediction;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalysisData();
  }

  Future<void> _loadAnalysisData() async {
    setState(() => _isLoading = true);
    try {
      final patterns = await widget.provider.analyzeTransactionPatterns();
      final health = await widget.provider.analyzeNetworkHealth();
      final prediction = await widget.provider.predictGasPrice();

      setState(() {
        _transactionPatterns = patterns;
        _networkHealth = health;
        _gasPrediction = prediction;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analysis data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAnalysisData,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTransactionVolumeAnalysis(),
              const SizedBox(height: 24),
              _buildNetworkHealthOverview(),
              const SizedBox(height: 24),
              _buildGasPriceAnalysis(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionVolumeAnalysis() {
    if (_transactionPatterns == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PYUSD Transaction Volume Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        24,
                        (index) => FlSpot(
                          index.toDouble(),
                          _transactionPatterns!['hourlyDistribution'][index]
                              .toDouble(),
                        ),
                      ),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCard(
                  'Avg Transaction Value',
                  '${(_transactionPatterns!['averageTransactionValue'] / 1e6).toStringAsFixed(2)} PYUSD',
                ),
                _buildMetricCard(
                  'Total Transactions',
                  widget.congestionData.pyusdTransactionCount.toString(),
                ),
                _buildMetricCard(
                  'Pending Transactions',
                  widget.congestionData.pendingPyusdTxCount.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkHealthOverview() {
    if (_networkHealth == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Health Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildHealthMetricRow(
              'Block Production Rate',
              '${(_networkHealth!['blockProductionRate'] * 60).toStringAsFixed(2)} blocks/min',
            ),
            _buildHealthMetricRow(
              'Gas Efficiency',
              '${(_networkHealth!['gasEfficiency'] * 100).toStringAsFixed(1)}%',
            ),
            _buildHealthMetricRow(
              'Transaction Success Rate',
              '${(_networkHealth!['transactionSuccessRate'] * 100).toStringAsFixed(1)}%',
            ),
            _buildHealthMetricRow(
              'Average Confirmation Time',
              '${_networkHealth!['averageConfirmationTime'].toStringAsFixed(1)} sec',
            ),
            const SizedBox(height: 16),
            const Text(
              'Historical Performance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildHealthMetricRow(
              'Blocks per Hour',
              widget.congestionData.blocksPerHour.toString(),
            ),
            _buildHealthMetricRow(
              'Average Block Size',
              '${(widget.congestionData.averageBlockSize / 1000).toStringAsFixed(1)} KB',
            ),
            _buildHealthMetricRow(
              'Transactions per Block',
              widget.congestionData.averageTxPerBlock.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGasPriceAnalysis() {
    if (_gasPrediction == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gas Price Analysis & Predictions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPredictionRow(
              'Current Gas Price',
              '${widget.congestionData.currentGasPrice.toStringAsFixed(2)} Gwei',
            ),
            _buildPredictionRow(
              'Short-term (5 blocks)',
              '${_gasPrediction!['shortTerm'].toStringAsFixed(2)} Gwei',
            ),
            _buildPredictionRow(
              'Medium-term (20 blocks)',
              '${_gasPrediction!['mediumTerm'].toStringAsFixed(2)} Gwei',
            ),
            _buildPredictionRow(
              'Prediction Confidence',
              '${(_gasPrediction!['confidence'] * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 16),
            const Text(
              'Factors Affecting Gas Price',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            ..._gasPrediction!['factors'].entries.map(
                  (entry) => _buildPredictionRow(
                    entry.key,
                    '${(entry.value * 100).toStringAsFixed(1)}%',
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
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
    );
  }

  Widget _buildHealthMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
