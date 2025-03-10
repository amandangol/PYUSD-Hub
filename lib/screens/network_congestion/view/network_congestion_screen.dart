import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/networkcongestion_model.dart';
import '../provider/network_congestion_provider.dart';
import 'widgets/congestion_meter.dart';
import 'widgets/gasprice_chart.dart';
import 'widgets/stats_card.dart';
import 'widgets/transaction_listitem.dart';

class NetworkDashboardScreen extends StatefulWidget {
  const NetworkDashboardScreen({Key? key}) : super(key: key);

  @override
  State<NetworkDashboardScreen> createState() => _NetworkDashboardScreenState();
}

class _NetworkDashboardScreenState extends State<NetworkDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data when screen is first loaded
    Future.microtask(() =>
        Provider.of<NetworkCongestionProvider>(context, listen: false)
            .initialize());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PYUSD Network Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<NetworkCongestionProvider>(context, listen: false)
                  .refresh();
            },
          ),
        ],
      ),
      body: Consumer<NetworkCongestionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final congestionData = provider.congestionData;

          return RefreshIndicator(
            onRefresh: () async {
              await provider.refresh();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Network Status Overview
                  _buildNetworkStatusSection(congestionData),

                  const SizedBox(height: 24),

                  // Gas Price Chart
                  _buildGasPriceSection(congestionData),

                  const SizedBox(height: 24),

                  // PYUSD Transaction Activity
                  _buildPyusdActivitySection(provider),

                  const SizedBox(height: 24),

                  // Recent Blocks
                  _buildRecentBlocksSection(provider),

                  const SizedBox(height: 24),

                  // Network Metrics
                  _buildNetworkMetricsSection(congestionData),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNetworkStatusSection(NetworkCongestionData congestionData) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ethereum Network Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CongestionMeter(
                    level: congestionData.congestionLevel,
                    label: 'Network Congestion',
                    description: congestionData.congestionDescription,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusItem(
                        'Current Gas Price',
                        '${congestionData.currentGasPrice.toStringAsFixed(2)} Gwei',
                        Icons.local_gas_station,
                      ),
                      const SizedBox(height: 8),
                      _buildStatusItem(
                        'Pending Transactions',
                        congestionData.pendingTransactions.toString(),
                        Icons.pending_actions,
                      ),
                      const SizedBox(height: 8),
                      _buildStatusItem(
                        'Block Utilization',
                        '${congestionData.gasUsagePercentage.toStringAsFixed(1)}%',
                        Icons.storage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildGasPriceSection(NetworkCongestionData congestionData) {
    return Card(
      elevation: 4,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGasInfoItem(
                  'Current',
                  '${congestionData.currentGasPrice.toStringAsFixed(3)} Gwei',
                  congestionData.currentGasPrice >
                          congestionData.averageGasPrice
                      ? Colors.orange
                      : Colors.green,
                ),
                _buildGasInfoItem(
                  'Average',
                  '${congestionData.averageGasPrice.toStringAsFixed(3)} Gwei',
                  Colors.blue,
                ),
                _buildGasInfoItem(
                  'Diff',
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

  Widget _buildGasInfoItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPyusdActivitySection(NetworkCongestionProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   'PYUSD Transaction Activity',
            //   style: TextStyle(
            //     fontSize: 18,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            const SizedBox(height: 16),
            const Text(
              'Recent PYUSD Transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            provider.recentPyusdTransactions.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No recent PYUSD transactions detected',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.recentPyusdTransactions.length > 5
                        ? 5
                        : provider.recentPyusdTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = provider.recentPyusdTransactions[index];
                      return TransactionListItem(transaction: tx);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBlocksSection(NetworkCongestionProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Blocks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            provider.recentBlocks.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No recent blocks detected',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.recentBlocks.length > 3
                        ? 3
                        : provider.recentBlocks.length,
                    itemBuilder: (context, index) {
                      final block = provider.recentBlocks[index];

                      // Safely parse hexadecimal values
                      int blockNumber = 0;
                      int timestamp = 0;
                      int gasUsed = 0;
                      int gasLimit =
                          1; // Default to 1 to avoid division by zero

                      try {
                        // Check if values have '0x' prefix and parse accordingly
                        if (block['number'] != null) {
                          final numStr = block['number'].toString();
                          blockNumber = numStr.startsWith('0x')
                              ? int.parse(numStr.substring(2), radix: 16)
                              : int.tryParse(numStr) ?? 0;
                        }

                        if (block['timestamp'] != null) {
                          final timeStr = block['timestamp'].toString();
                          timestamp = timeStr.startsWith('0x')
                              ? int.parse(timeStr.substring(2), radix: 16)
                              : int.tryParse(timeStr) ?? 0;
                        }

                        if (block['gasUsed'] != null) {
                          final gasUsedStr = block['gasUsed'].toString();
                          gasUsed = gasUsedStr.startsWith('0x')
                              ? int.parse(gasUsedStr.substring(2), radix: 16)
                              : int.tryParse(gasUsedStr) ?? 0;
                        }

                        if (block['gasLimit'] != null) {
                          final gasLimitStr = block['gasLimit'].toString();
                          gasLimit = gasLimitStr.startsWith('0x')
                              ? int.parse(gasLimitStr.substring(2), radix: 16)
                              : int.tryParse(gasLimitStr) ?? 1;
                        }
                      } catch (e) {
                        // Handle parsing errors
                        print('Error parsing block data: $e');
                      }

                      final date =
                          DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
                      final formattedDate =
                          DateFormat('MMM dd, HH:mm:ss').format(date);

                      // Safely handle transactions list
                      final List txList = block['transactions'] ?? [];
                      final txCount = txList.length;

                      // Calculate gas percentage
                      final gasPercentage =
                          gasLimit > 0 ? (gasUsed / gasLimit) * 100 : 0;

                      // Etherscan URL for the block
                      final etherscanUrl =
                          'https://etherscan.io/block/$blockNumber';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Block #$blockNumber',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Add the Etherscan link icon here
                                      InkWell(
                                        onTap: () {
                                          launchUrl(Uri.parse(etherscanUrl));
                                        },
                                        child: const Icon(
                                          Icons.open_in_new,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildBlockInfoItem(
                                      'Transactions', '$txCount'),
                                  _buildBlockInfoItem(
                                    'Gas Used',
                                    '${gasPercentage.toStringAsFixed(1)}%',
                                    gasPercentage > 90
                                        ? Colors.red
                                        : gasPercentage > 70
                                            ? Colors.orange
                                            : Colors.green,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockInfoItem(String label, String value, [Color? valueColor]) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkMetricsSection(NetworkCongestionData congestionData) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Performance Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Network Latency',
                    '${congestionData.networkLatency.toStringAsFixed(0)} ms',
                    congestionData.networkLatency > 500
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Block Time',
                    '${congestionData.blockTime.toStringAsFixed(1)} sec',
                    congestionData.blockTime > 15
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: congestionData.gasUsagePercentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                congestionData.gasUsagePercentage > 90
                    ? Colors.red
                    : congestionData.gasUsagePercentage > 70
                        ? Colors.orange
                        : Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Network Utilization: ${congestionData.gasUsagePercentage.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: valueColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
