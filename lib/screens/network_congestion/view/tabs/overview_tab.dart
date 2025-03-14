import 'package:flutter/material.dart';
import '../../model/networkcongestion_model.dart';
import '../widgets/congestion_meter.dart';
import '../widgets/status_card.dart';

class OverviewTab extends StatelessWidget {
  final NetworkCongestionData congestionData;

  const OverviewTab({super.key, required this.congestionData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Global status widget with refresh info
          StatusCard(congestionData: congestionData),

          const SizedBox(height: 16),

          // Network Status Overview
          _buildNetworkStatusSection(),

          const SizedBox(height: 16),

          // Network Queue Status
          _buildNetworkQueueSection(),

          const SizedBox(height: 16),

          // Network Metrics
          _buildNetworkMetricsSection(),
        ],
      ),
    );
  }

  // Network Status Section (modified for cleaner look)
  Widget _buildNetworkStatusSection() {
    return Card(
      elevation: 3,
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

  // Network Queue Section (with improved layout)
  Widget _buildNetworkQueueSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Queue Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQueueStatItem(
                  'Pending Queue Size',
                  congestionData.pendingQueueSize.toString(),
                  Icons.pending,
                  congestionData.pendingQueueSize > 10000
                      ? Colors.red
                      : congestionData.pendingQueueSize > 5000
                          ? Colors.orange
                          : Colors.green,
                ),
                _buildQueueStatItem(
                  'Average Block Size',
                  '${(congestionData.averageBlockSize / 1024).toStringAsFixed(2)} KB',
                  Icons.storage,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Network Metrics section
  Widget _buildNetworkMetricsSection() {
    return Card(
      elevation: 3,
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
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
            const SizedBox(height: 16),
            const Text(
              'Network Utilization',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: congestionData.gasUsagePercentage / 100,
              backgroundColor: Colors.grey[200],
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
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
              '${congestionData.gasUsagePercentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for UI elements
  Widget _buildStatusItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Column(
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQueueStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
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

  Widget _buildMetricItem(String label, String value, Color color) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
