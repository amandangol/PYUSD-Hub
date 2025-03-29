import 'package:flutter/material.dart';
import '../../model/networkcongestion_model.dart';
import '../widgets/congestion_meter.dart';
import '../../../../widgets/common/info_dialog.dart';

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
          // Network Status Overview
          _buildNetworkStatusSection(context),

          const SizedBox(height: 16),

          // Network Queue Status
          _buildNetworkQueueSection(context),

          const SizedBox(height: 16),

          // Network Metrics
          _buildNetworkMetricsSection(context),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNetworkStatusSection(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Ethereum Network Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => InfoDialog.show(
                    context,
                    title: 'Network Status',
                    message:
                        'Real-time overview of the Ethereum network\'s current state and performance metrics.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => InfoDialog.show(
                      context,
                      title: 'Network Congestion',
                      message:
                          'Indicates the current congestion level of the Ethereum network. Higher levels mean longer transaction processing times and higher gas fees.',
                    ),
                    child: CongestionMeter(
                      level: congestionData.congestionLevel,
                      label: 'Network Congestion',
                      description: congestionData.congestionDescription,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusItemWithInfo(
                        context,
                        'Network Version',
                        congestionData.networkVersion,
                        Icons.info,
                        'Current version of the Ethereum network protocol.',
                      ),
                      const SizedBox(height: 8),
                      _buildStatusItemWithInfo(
                        context,
                        'Peer Count',
                        congestionData.peerCount.toString(),
                        Icons.people,
                        'Number of connected peers in the network. Higher count indicates better network connectivity.',
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

  Widget _buildNetworkQueueSection(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Network Queue Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => InfoDialog.show(
                    context,
                    title: 'Queue Status',
                    message:
                        'Current state of the network\'s transaction queue and block metrics.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQueueStatItemWithInfo(
                  context,
                  'Pending Queue Size',
                  congestionData.pendingQueueSize.toString(),
                  Icons.pending,
                  congestionData.pendingQueueSize > 10000
                      ? Colors.red
                      : congestionData.pendingQueueSize > 5000
                          ? Colors.orange
                          : Colors.green,
                  'Total number of transactions waiting in the network\'s pending queue.',
                ),
                _buildQueueStatItemWithInfo(
                  context,
                  'Block Time',
                  '${congestionData.blockTime.toStringAsFixed(1)} sec',
                  Icons.timer,
                  Colors.blue,
                  'Average time between new blocks being added to the blockchain.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkMetricsSection(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Network Performance Metrics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => InfoDialog.show(
                    context,
                    title: 'Performance Metrics',
                    message:
                        'Key performance indicators showing the network\'s current health and efficiency.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildMetricItemWithInfo(
                    context,
                    'Network Latency',
                    '${congestionData.networkLatency.toStringAsFixed(0)} ms',
                    Colors.blue,
                    'Average time taken for a transaction to be processed by the network. Lower latency indicates better performance.',
                  ),
                ),
                Expanded(
                  child: _buildMetricItemWithInfo(
                    context,
                    'Block Utilization',
                    '${congestionData.gasUsagePercentage.toStringAsFixed(1)}%',
                    Colors.green,
                    'Percentage of gas used in the latest block. Higher utilization indicates increased network activity.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricItemWithInfo(
              context,
              'Last Block Number',
              congestionData.lastBlockNumber.toString(),
              Colors.purple,
              'The most recent block number in the blockchain.',
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for UI elements
  Widget _buildStatusItemWithInfo(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    String infoMessage,
  ) {
    return GestureDetector(
      onTap: () => InfoDialog.show(
        context,
        title: label,
        message: infoMessage,
      ),
      child: Row(
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
          const SizedBox(width: 4),
          const Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildQueueStatItemWithInfo(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    String infoMessage,
  ) {
    return GestureDetector(
      onTap: () => InfoDialog.show(
        context,
        title: label,
        message: infoMessage,
      ),
      child: Column(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.info_outline,
                size: 14,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItemWithInfo(
    BuildContext context,
    String label,
    String value,
    Color color,
    String infoMessage,
  ) {
    return GestureDetector(
      onTap: () => InfoDialog.show(
        context,
        title: label,
        message: infoMessage,
      ),
      child: Card(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
