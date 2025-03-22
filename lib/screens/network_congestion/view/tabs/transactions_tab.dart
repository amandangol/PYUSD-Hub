import 'package:flutter/material.dart';
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
          final int? timestamp = _parseHexValue(tx['timestamp']);
          if (timestamp != null) {
            final DateTime txTime =
                DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
            if (txTime.isAfter(yesterday)) {
              // Add value to total volume if transaction is within last 24 hours
              final double? value = _parseHexValue(tx['value'])?.toDouble();
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

// Helper method to parse hex values
  int? _parseHexValue(dynamic hexValue) {
    if (hexValue == null || hexValue is! String || !hexValue.startsWith('0x')) {
      return null;
    }
    return int.tryParse(hexValue.substring(2), radix: 16);
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
