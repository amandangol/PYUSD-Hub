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
              _buildTransactionVolumeChart(),
              const SizedBox(height: 24),
              _buildGasPriceAnalysis(),
              const SizedBox(height: 24),
              _buildNetworkHealthMetrics(),
              const SizedBox(height: 24),
              _buildTransactionPatterns(),
              const SizedBox(height: 24),
              _buildGasPricePrediction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionVolumeChart() {
    if (_transactionPatterns == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PYUSD Transaction Volume',
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
                      spots: _generateTransactionSpots(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
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

  List<FlSpot> _generateTransactionSpots() {
    final hourlyDistribution =
        _transactionPatterns?['hourlyDistribution'] as List<int>?;
    if (hourlyDistribution == null) return [];

    return List.generate(
      hourlyDistribution.length,
      (index) => FlSpot(
        index.toDouble(),
        hourlyDistribution[index].toDouble(),
      ),
    );
  }

  Widget _buildGasPriceAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gas Price Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGasMetricCard(
                  'Current Gas',
                  '${widget.congestionData.currentGasPrice.toStringAsFixed(2)} Gwei',
                ),
                _buildGasMetricCard(
                  'Average Gas',
                  '${widget.congestionData.averageGasPrice.toStringAsFixed(2)} Gwei',
                ),
                _buildGasMetricCard(
                  'Network Load',
                  '${widget.congestionData.gasUsagePercentage.toStringAsFixed(1)}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGasMetricCard(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
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

  Widget _buildNetworkHealthMetrics() {
    if (_networkHealth == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Health',
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
              'Network Congestion',
              '${(_networkHealth!['networkCongestion'] * 100).toStringAsFixed(1)}%',
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
              'Avg Confirmation Time',
              '${(_networkHealth!['averageConfirmationTime'] / 60).toStringAsFixed(1)} min',
            ),
          ],
        ),
      ),
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

  Widget _buildTransactionPatterns() {
    if (_transactionPatterns == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Patterns',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPatternRow(
              'Confirmed PYUSD TX',
              widget.congestionData.confirmedPyusdTxCount.toString(),
            ),
            _buildPatternRow(
              'Pending PYUSD TX',
              widget.congestionData.pendingPyusdTxCount.toString(),
            ),
            _buildPatternRow(
              'Average Block Size',
              '${(widget.congestionData.averageBlockSize / 1024).toStringAsFixed(2)} KB',
            ),
            if (_transactionPatterns!['averageTransactionValue'] > 0)
              _buildPatternRow(
                'Average Transaction Value',
                '${(_transactionPatterns!['averageTransactionValue'] / 1e18).toStringAsFixed(4)} PYUSD',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternRow(String label, String value) {
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

  Widget _buildGasPricePrediction() {
    if (_gasPrediction == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gas Price Prediction',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPredictionRow(
              'Short-term (5 blocks)',
              '${_gasPrediction!['shortTerm'].toStringAsFixed(2)} Gwei',
            ),
            _buildPredictionRow(
              'Medium-term (20 blocks)',
              '${_gasPrediction!['mediumTerm'].toStringAsFixed(2)} Gwei',
            ),
            _buildPredictionRow(
              'Confidence',
              '${(_gasPrediction!['confidence'] * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 16),
            const Text(
              'Factors',
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
