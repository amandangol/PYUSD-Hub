import 'package:flutter/material.dart';
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
          _buildGasFeeEstimator(),
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

  // Gas Fee Estimator
  Widget _buildGasFeeEstimator() {
    // These are estimates - in a real app, you'd calculate these values
    final lowGwei = congestionData.currentGasPrice * 0.8;
    final mediumGwei = congestionData.currentGasPrice;
    final highGwei = congestionData.currentGasPrice * 1.2;

    // Assume average ETH transfer gas usage
    const gasUsed = 21000;

    // Calculate USD cost (example ETH price = $3000)
    const ethPrice = 3000.0;
    const gweiToEth = 0.000000001;

    final lowCostEth = lowGwei * gasUsed * gweiToEth;
    final mediumCostEth = mediumGwei * gasUsed * gweiToEth;
    final highCostEth = highGwei * gasUsed * gweiToEth;

    final lowCostUsd = lowCostEth * ethPrice;
    final mediumCostUsd = mediumCostEth * ethPrice;
    final highCostUsd = highCostEth * ethPrice;

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
          ],
        ),
      ),
    );
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
}
