import 'package:flutter/material.dart';
import '../../../../services/market_service.dart';
import '../../model/networkcongestion_model.dart';
import '../widgets/gasprice_chart.dart';

class GasTab extends StatelessWidget {
  final NetworkCongestionData congestionData;

  const GasTab({super.key, required this.congestionData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gas Price Overview Card
          _buildGasOverviewCard(),

          const SizedBox(height: 16),

          // Gas Price Trend Chart
          _buildGasPriceSection(),

          const SizedBox(height: 16),

          // Gas Fee Estimator
          GasFeeEstimator(
            currentGasPrice: congestionData.currentGasPrice,
          ),
        ],
      ),
    );
  }

  // Gas Overview Card
  Widget _buildGasOverviewCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Gas Prices',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPriorityGasCard(
                  'Low Priority',
                  (congestionData.currentGasPrice * 0.8).toStringAsFixed(2),
                  'Slower',
                  Colors.green,
                ),
                _buildPriorityGasCard(
                  'Medium Priority',
                  congestionData.currentGasPrice.toStringAsFixed(2),
                  'Standard',
                  Colors.blue,
                ),
                _buildPriorityGasCard(
                  'High Priority',
                  (congestionData.currentGasPrice * 1.2).toStringAsFixed(2),
                  'Faster',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityGasCard(
      String title, String price, String speed, Color color) {
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
          '$price Gwei',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            speed,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // Gas Price Section
  Widget _buildGasPriceSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gas Price Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Recent gas prices (Gwei) - lower is better',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: GasPriceChart(
                gasPrices: congestionData.historicalGasPrices,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGasInfoItem(
                  'Current',
                  '${congestionData.currentGasPrice.toStringAsFixed(2)} Gwei',
                  congestionData.currentGasPrice >
                          congestionData.averageGasPrice
                      ? Colors.orange
                      : Colors.green,
                ),
                _buildGasInfoItem(
                  'Average (24h)',
                  '${congestionData.averageGasPrice.toStringAsFixed(2)} Gwei',
                  Colors.blue,
                ),
                _buildGasInfoItem(
                  'Change',
                  '${((congestionData.currentGasPrice / congestionData.averageGasPrice) * 100 - 100).toStringAsFixed(1)}%',
                  congestionData.currentGasPrice >
                          congestionData.averageGasPrice
                      ? Colors.red
                      : Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Gas Fee Estimator
class GasFeeEstimator extends StatefulWidget {
  final double currentGasPrice;

  const GasFeeEstimator({
    Key? key,
    required this.currentGasPrice,
  }) : super(key: key);

  @override
  State<GasFeeEstimator> createState() => _GasFeeEstimatorState();
}

class _GasFeeEstimatorState extends State<GasFeeEstimator> {
  // Market service instance
  final MarketService _marketService = MarketService();

  // ETH price state
  double _ethPrice = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEthPrice();
  }

  // Fetch current ETH price
  Future<void> _fetchEthPrice() async {
    try {
      final prices = await _marketService.getCurrentPrices(['ETH']);
      setState(() {
        _ethPrice = prices['ETH'] ?? 0.0;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching ETH price: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // These are estimates - we use the current gas price from congestion data
    final lowGwei = widget.currentGasPrice * 0.8;
    final mediumGwei = widget.currentGasPrice;
    final highGwei = widget.currentGasPrice * 1.2;

    // Assume average ETH transfer gas usage
    const gasUsed = 21000;

    // Convert gwei to ETH
    const gweiToEth = 0.000000001;

    // Calculate costs in ETH
    final lowCostEth = lowGwei * gasUsed * gweiToEth;
    final mediumCostEth = mediumGwei * gasUsed * gweiToEth;
    final highCostEth = highGwei * gasUsed * gweiToEth;

    // Calculate costs in USD
    final lowCostUsd = lowCostEth * _ethPrice;
    final mediumCostUsd = mediumCostEth * _ethPrice;
    final highCostUsd = highCostEth * _ethPrice;

    if (_isLoading) {
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Fee Estimator',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Estimated costs for a standard ETH transfer',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current ETH Price: \$${_ethPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(3),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                const TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Priority',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Text('Gas Price',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Time', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Cost (USD)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('Low', style: TextStyle(color: Colors.green)),
                    ),
                    Text('${lowGwei.toStringAsFixed(1)} Gwei'),
                    const Text('~5 min'),
                    Text('\$${lowCostUsd.toStringAsFixed(4)}'),
                  ],
                ),
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child:
                          Text('Medium', style: TextStyle(color: Colors.blue)),
                    ),
                    Text('${mediumGwei.toStringAsFixed(1)} Gwei'),
                    const Text('~2 min'),
                    Text('\$${mediumCostUsd.toStringAsFixed(4)}'),
                  ],
                ),
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child:
                          Text('High', style: TextStyle(color: Colors.orange)),
                    ),
                    Text('${highGwei.toStringAsFixed(1)} Gwei'),
                    const Text('<1 min'),
                    Text('\$${highCostUsd.toStringAsFixed(4)}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _fetchEthPrice,
                  tooltip: 'Refresh ETH price',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildGasInfoItem(String label, String value, Color color) {
  return Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
    ],
  );
}
