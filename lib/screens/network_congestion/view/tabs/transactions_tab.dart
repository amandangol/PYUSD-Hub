import 'package:flutter/material.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../provider/network_congestion_provider.dart';
import '../widgets/stats_card.dart';
import '../widgets/transaction_listitem.dart';

class TransactionsTab extends StatefulWidget {
  final NetworkCongestionProvider provider;
  final TabController tabController;

  const TransactionsTab({
    super.key,
    required this.provider,
    required this.tabController,
  });

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction Activity Overview
          // _buildTransactionOverview(),

          const SizedBox(height: 16),

          // Recent PYUSD Transactions (expanded view)
          _buildPyusdActivitySection(expandedView: true),
        ],
      ),
    );
  }

  // Transaction Activity Overview
  Widget _buildTransactionOverview() {
    final data = widget.provider.congestionData;
    final transactions = widget.provider.recentPyusdTransactions;

    // Calculate total volume in the last 24 hours from transactions
    double totalVolume24h = 0;
    if (transactions.isNotEmpty) {
      final DateTime now = DateTime.now();
      final DateTime yesterday = now.subtract(const Duration(hours: 24));

      for (var tx in transactions) {
        // Check if transaction has timestamp
        if (tx.containsKey('timestamp')) {
          final int? timestamp = FormatterUtils.parseHexSafely(tx['timestamp']);
          if (timestamp != null) {
            final DateTime txTime =
                DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
            if (txTime.isAfter(yesterday)) {
              // Add value to total volume if transaction is within last 24 hours
              final double? value =
                  FormatterUtils.parseHexSafely(tx['value'])?.toDouble();
              if (value != null) {
                totalVolume24h += value / 1e18; // Convert from wei to ETH
              }
            }
          }
        }
      }
    }

    // Format volume in millions with 2 decimal places
    final String formattedVolume =
        '\$${(totalVolume24h / 1000000).toStringAsFixed(2)}M';

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

            // Transaction statistics with real values
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Last 24h',
                    value: '${data.confirmedPyusdTxCount}',
                    icon: Icons.swap_horiz,
                    color: Colors.blue,
                    description: 'PYUSD txs',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatsCard(
                    title: 'Volume 24h',
                    value: formattedVolume,
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
                Expanded(
                  child: StatsCard(
                    title: 'Active Users',
                    value: '${_calculateUniqueAddresses(transactions)}',
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

// Helper method to calculate unique addresses involved in transactions
  int _calculateUniqueAddresses(List<Map<String, dynamic>> transactions) {
    final Set<String> uniqueAddresses = {};

    for (var tx in transactions) {
      if (tx.containsKey('from') && tx['from'] is String) {
        uniqueAddresses.add(tx['from'].toLowerCase());
      }
      if (tx.containsKey('to') && tx['to'] is String) {
        uniqueAddresses.add(tx['to'].toLowerCase());
      }
    }

    return uniqueAddresses.length;
  }

  // PYUSD Activity Section
  Widget _buildPyusdActivitySection({bool expandedView = false}) {
    final transactions = widget.provider.recentPyusdTransactions;
    final latestBlockNumber = widget.provider.congestionData.lastBlockNumber;
    final oldestBlockNumber = widget.provider.recentBlocks.isNotEmpty
        ? FormatterUtils.parseHexSafely(
            widget.provider.recentBlocks.last['number'])
        : null;

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
                  'Recent PYUSD Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (transactions.isNotEmpty)
                  Text(
                    'Showing ${transactions.length} transactions',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            if (latestBlockNumber != null && oldestBlockNumber != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Showing transactions from blocks ${oldestBlockNumber} to ${latestBlockNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            transactions.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No recent PYUSD transactions detected',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      const Divider(),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return TransactionListItem(
                            onTap: () async {
                              final String txHash = transaction['hash'] ?? '';

                              if (txHash.isEmpty) return;

                              final url =
                                  Uri.parse('https://etherscan.io/tx/$txHash');
                              try {
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not launch explorer'),
                                  ),
                                );
                              }
                            },
                            transaction: transaction,
                          );
                        },
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
