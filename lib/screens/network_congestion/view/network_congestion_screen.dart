import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pyusd_forensics/utils/formatter_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/networkcongestion_model.dart';
import '../provider/network_congestion_provider.dart';
import 'widgets/congestion_meter.dart';
import 'widgets/gasprice_chart.dart';
import 'widgets/stats_card.dart';
import 'widgets/transaction_listitem.dart';

class NetworkDashboardScreen extends StatefulWidget {
  const NetworkDashboardScreen({super.key});

  @override
  State<NetworkDashboardScreen> createState() => _NetworkDashboardScreenState();
}

class _NetworkDashboardScreenState extends State<NetworkDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize tab controller with 4 tabs
    _tabController = TabController(length: 4, vsync: this);

    // Fetch data when screen is first loaded
    Future.microtask(() =>
        Provider.of<NetworkCongestionProvider>(context, listen: false)
            .initialize());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.local_gas_station), text: 'Gas'),
            Tab(icon: Icon(Icons.storage), text: 'Blocks'),
            Tab(icon: Icon(Icons.swap_horiz), text: 'Transactions'),
          ],
          isScrollable: false,
          indicatorWeight: 3,
        ),
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
            child: TabBarView(
              controller: _tabController,
              children: [
                // Overview Tab
                _buildOverviewTab(congestionData),

                // Gas Tab
                _buildGasTab(congestionData),

                // Blocks Tab
                _buildBlocksTab(provider),

                // Transactions Tab
                _buildTransactionsTab(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  // Tab Content Builders
  Widget _buildOverviewTab(NetworkCongestionData congestionData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Global status widget with refresh info
          _buildStatusCard(congestionData),

          const SizedBox(height: 16),

          // Network Status Overview
          _buildNetworkStatusSection(congestionData),

          const SizedBox(height: 16),

          // Network Queue Status
          _buildNetworkQueueSection(congestionData),

          const SizedBox(height: 16),

          // Network Metrics
          _buildNetworkMetricsSection(congestionData),
        ],
      ),
    );
  }

  Widget _buildGasTab(NetworkCongestionData congestionData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gas Price Overview Card
          _buildGasOverviewCard(congestionData),

          const SizedBox(height: 16),

          // Gas Price Trend Chart
          _buildGasPriceSection(congestionData),

          const SizedBox(height: 16),

          // Gas Fee Estimator (new component)
          _buildGasFeeEstimator(congestionData),
        ],
      ),
    );
  }

  Widget _buildBlocksTab(NetworkCongestionProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Block Information Overview
          _buildBlockInfoOverview(provider),

          const SizedBox(height: 16),

          // Recent Blocks List (expanded with more details)
          _buildRecentBlocksSection(provider, expandedView: true),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(NetworkCongestionProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction Activity Overview
          _buildTransactionOverview(provider),

          const SizedBox(height: 16),

          // Recent PYUSD Transactions (expanded view)
          _buildPyusdActivitySection(provider, expandedView: true),
        ],
      ),
    );
  }

  // Status Card with Last Refreshed and Last Block Timestamp
  Widget _buildStatusCard(NetworkCongestionData congestionData) {
    // Convert Unix timestamp to DateTime
    final lastBlockTime = congestionData.lastBlockTimestamp > 0
        ? DateTime.fromMillisecondsSinceEpoch(
            congestionData.lastBlockTimestamp * 1000)
        : null;

    final lastRefreshed = congestionData.lastRefreshed;

    // Calculate time difference for last block
    final now = DateTime.now();
    final lastBlockDiff =
        lastBlockTime != null ? now.difference(lastBlockTime) : null;
    final lastBlockAgo =
        lastBlockDiff != null ? _formatTimeDifference(lastBlockDiff) : 'N/A';

    // Calculate time difference for last refresh
    final lastRefreshDiff = now.difference(lastRefreshed);
    final lastRefreshAgo = _formatTimeDifference(lastRefreshDiff);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Last Block',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color:
                            lastBlockDiff != null && lastBlockDiff.inMinutes > 2
                                ? Colors.orange
                                : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lastBlockTime != null
                              ? DateFormat('HH:mm:ss').format(lastBlockTime)
                              : 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    lastBlockAgo,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          lastBlockDiff != null && lastBlockDiff.inMinutes > 2
                              ? Colors.orange
                              : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 30,
              width: 1,
              color: Colors.grey.withOpacity(0.3),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Last Refreshed',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.refresh,
                        size: 14,
                        color: lastRefreshDiff.inMinutes > 5
                            ? Colors.orange
                            : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('HH:mm:ss').format(lastRefreshed),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    lastRefreshAgo,
                    style: TextStyle(
                      fontSize: 11,
                      color: lastRefreshDiff.inMinutes > 5
                          ? Colors.orange
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to format time difference
  String _formatTimeDifference(Duration difference) {
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  // Network Status Section (modified for cleaner look)
  Widget _buildNetworkStatusSection(NetworkCongestionData congestionData) {
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
  Widget _buildNetworkQueueSection(NetworkCongestionData congestionData) {
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
  Widget _buildNetworkMetricsSection(NetworkCongestionData congestionData) {
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

  // Gas Tab Components

  // New Gas Overview Card
  Widget _buildGasOverviewCard(NetworkCongestionData congestionData) {
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
                  '${(congestionData.currentGasPrice * 0.8).toStringAsFixed(2)}',
                  'Slower',
                  Colors.green,
                ),
                _buildPriorityGasCard(
                  'Medium Priority',
                  '${congestionData.currentGasPrice.toStringAsFixed(2)}',
                  'Standard',
                  Colors.blue,
                ),
                _buildPriorityGasCard(
                  'High Priority',
                  '${(congestionData.currentGasPrice * 1.2).toStringAsFixed(2)}',
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

  // Gas Price Section (improved)
  Widget _buildGasPriceSection(NetworkCongestionData congestionData) {
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

  // New Gas Fee Estimator
  Widget _buildGasFeeEstimator(NetworkCongestionData congestionData) {
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

  // Blocks Tab Components

  Widget _buildBlockInfoOverview(NetworkCongestionProvider provider) {
    // Get the latest block if available
    final latestBlock =
        provider.recentBlocks.isNotEmpty ? provider.recentBlocks[0] : null;

    // Parse block number
    int blockNumber = 0;
    if (latestBlock != null && latestBlock['number'] != null) {
      final numStr = latestBlock['number'].toString();
      blockNumber = numStr.startsWith('0x')
          ? int.parse(numStr.substring(2), radix: 16)
          : int.tryParse(numStr) ?? 0;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Block Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (blockNumber > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Latest: #$blockNumber',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Block statistics
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildBlockStatCard(
                  'Avg Block Time',
                  provider.congestionData.averageBlockTime > 0
                      ? '${provider.congestionData.averageBlockTime.toStringAsFixed(1)} sec'
                      : 'Loading...',
                  Icons.timer,
                  Colors.blue,
                ),
                _buildBlockStatCard(
                  'Blocks/Hour',
                  provider.congestionData.blocksPerHour > 0
                      ? '~${provider.congestionData.blocksPerHour}'
                      : 'Loading...',
                  Icons.av_timer,
                  Colors.green,
                ),
                _buildBlockStatCard(
                  'Avg Tx/Block',
                  provider.congestionData.averageTxPerBlock > 0
                      ? '${provider.congestionData.averageTxPerBlock}'
                      : 'Loading...',
                  Icons.sync_alt,
                  Colors.purple,
                ),
                _buildBlockStatCard(
                  'Gas Limit',
                  provider.congestionData.gasLimit > 0
                      ? '${(provider.congestionData.gasLimit / 1000000).toStringAsFixed(1)}M'
                      : 'Loading...',
                  Icons.local_gas_station,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Recent Blocks List
  Widget _buildRecentBlocksSection(NetworkCongestionProvider provider,
      {bool expandedView = false}) {
    return Card(
      elevation: 3,
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
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemCount: expandedView
                        ? provider.recentBlocks.length
                        : (provider.recentBlocks.length > 3
                            ? 3
                            : provider.recentBlocks.length),
                    itemBuilder: (context, index) {
                      final block = provider.recentBlocks[index];

                      // Parse block data
                      final blockNumberHex =
                          block['number'] as String? ?? '0x0';
                      final blockNumber =
                          int.parse(blockNumberHex.substring(2), radix: 16);

                      // Parse timestamp
                      final timestampHex =
                          block['timestamp'] as String? ?? '0x0';
                      final timestamp =
                          int.parse(timestampHex.substring(2), radix: 16);
                      final blockTime =
                          DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

                      // Parse transactions
                      final transactions =
                          block['transactions'] as List<dynamic>? ?? [];

                      // Parse gas used and gas limit
                      final gasUsedHex = block['gasUsed'] as String? ?? '0x0';
                      final gasLimitHex = block['gasLimit'] as String? ?? '0x0';
                      final gasUsed =
                          int.parse(gasUsedHex.substring(2), radix: 16);
                      final gasLimit =
                          int.parse(gasLimitHex.substring(2), radix: 16);

                      // Calculate utilization
                      final utilization = (gasUsed / gasLimit) * 100;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#$blockNumber',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('HH:mm:ss').format(blockTime),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${transactions.length} txs',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        subtitle: expandedView
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text(
                                        'Miner: ',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        FormatterUtils.formatAddress(
                                            '${(block['miner'] as String?)}'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Gas Usage',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            const SizedBox(height: 4),
                                            LinearProgressIndicator(
                                              value: utilization / 100,
                                              backgroundColor: Colors.grey[200],
                                              minHeight: 6,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                utilization > 90
                                                    ? Colors.red
                                                    : utilization > 70
                                                        ? Colors.orange
                                                        : Colors.green,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${utilization.toStringAsFixed(1)}% (${(gasUsed / 1000000).toStringAsFixed(2)}M/${(gasLimit / 1000000).toStringAsFixed(2)}M)',
                                              style:
                                                  const TextStyle(fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_new, size: 18),
                          onPressed: () async {
                            // Open block explorer to view block details
                            final url = Uri.parse(
                                'https://etherscan.io/block/$blockNumber');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            } else {
                              throw 'Could not lauch $url';
                            }
                          },
                        ),
                        onTap: () {
                          // Show block details
                          // This would be implemented to show more details
                        },
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  // Transaction Activity Overview
  Widget _buildTransactionOverview(NetworkCongestionProvider provider) {
    final data = provider.congestionData;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PYUSD Transaction Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Transaction statistics
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Last 24h',
                    value: '1,284',
                    icon: Icons.swap_horiz,
                    color: Colors.blue,
                    description: 'PYUSD txs',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: StatsCard(
                    title: 'Volume 24h',
                    value: '\$2.76M',
                    icon: Icons.attach_money,
                    color: Colors.green,
                    description: 'PYUSD transferred',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Avg Confirmation',
                    value: '${data.blockTime.toStringAsFixed(1)}s',
                    icon: Icons.access_time,
                    color: Colors.orange,
                    description: 'For PYUSD txs',
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: StatsCard(
                    title: 'Active Users',
                    value: '876',
                    icon: Icons.people,
                    color: Colors.purple,
                    description: 'Unique wallets',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // PYUSD Activity Section
  Widget _buildPyusdActivitySection(NetworkCongestionProvider provider,
      {bool expandedView = false}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent PYUSD Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
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
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemCount: expandedView
                        ? provider.recentPyusdTransactions.length
                        : (provider.recentPyusdTransactions.length > 3
                            ? 3
                            : provider.recentPyusdTransactions.length),
                    itemBuilder: (context, index) {
                      final transaction =
                          provider.recentPyusdTransactions[index];

                      return TransactionListItem(
                        transaction: transaction,
                      );
                    },
                  ),
            if (!expandedView && provider.recentPyusdTransactions.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.list),
                    label: const Text('View All Transactions'),
                    onPressed: () {
                      // Switch to transactions tab
                      _tabController.animateTo(3);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper methods for building repeated UI elements

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
