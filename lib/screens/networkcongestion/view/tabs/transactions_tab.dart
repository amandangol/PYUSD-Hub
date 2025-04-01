import 'package:flutter/material.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';
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
          _buildTransactionOverview(),

          const SizedBox(height: 16),

          // Recent PYUSD Transactions
          _buildPyusdActivitySection(),
        ],
      ),
    );
  }

  // Transaction Activity Overview
  Widget _buildTransactionOverview() {
    final data = widget.provider.congestionData;
    final transactions = widget.provider.recentPyusdTransactions;

    // Only calculate metrics if we have transactions
    if (transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate total volume and format with appropriate suffix
    double totalVolume = _calculateTotalVolume(transactions);
    String formattedVolume =
        FormatterUtils.formatCurrencyWithSuffix(totalVolume);

    // Calculate unique addresses
    int uniqueAddresses = _calculateUniqueAddresses(transactions);

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

            // Transaction statistics in a grid
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                if (data.confirmedPyusdTxCount > 0)
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: StatsCard(
                      title: 'Transactions',
                      value: FormatterUtils.formatLargeNumber(
                          data.confirmedPyusdTxCount),
                      icon: Icons.swap_horiz,
                      color: Colors.blue,
                      description: 'PYUSD txs',
                    ),
                  ),
                if (totalVolume > 0)
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: StatsCard(
                      title: 'Volume',
                      value: formattedVolume,
                      icon: Icons.attach_money,
                      color: Colors.green,
                      description: 'PYUSD transferred',
                    ),
                  ),
                if (data.blockTime > 0)
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: StatsCard(
                      title: 'Avg Confirmation',
                      value: '${data.blockTime.toStringAsFixed(1)}s',
                      icon: Icons.access_time,
                      color: Colors.orange,
                      description: 'Per block',
                    ),
                  ),
                if (uniqueAddresses > 0)
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: StatsCard(
                      title: 'Active Users',
                      value: FormatterUtils.formatLargeNumber(uniqueAddresses),
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

  // Calculate total volume from transactions
  double _calculateTotalVolume(List<Map<String, dynamic>> transactions) {
    double totalVolume = 0;
    for (var tx in transactions) {
      double amount = 0.0;
      if (tx.containsKey('tokenValue')) {
        amount = tx['tokenValue'];
      } else if (tx['input'] != null &&
          tx['input'].toString().length >= 138 &&
          tx['input'].toString().startsWith('0xa9059cbb')) {
        try {
          final String valueHex = tx['input'].toString().substring(74);
          final BigInt tokenValueBigInt =
              FormatterUtils.parseBigInt("0x$valueHex");
          amount =
              tokenValueBigInt / BigInt.from(10).pow(6); // PYUSD has 6 decimals
        } catch (e) {
          print('Error parsing token value: $e');
        }
      }
      totalVolume += amount;
    }
    return totalVolume;
  }

  // PYUSD Activity Section
  Widget _buildPyusdActivitySection() {
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
            if (oldestBlockNumber != null && latestBlockNumber > 0) ...[
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
                        'Showing transactions from blocks ${FormatterUtils.formatBlockNumber(oldestBlockNumber)} to ${FormatterUtils.formatBlockNumber(latestBlockNumber)}',
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
            if (transactions.isEmpty)
              const Center(
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
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 400,
                child: ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    if (index > 0) {
                      return Column(
                        children: [
                          const Divider(height: 1),
                          TransactionListItem(
                            transaction: transaction,
                            onTap: () {},
                          ),
                        ],
                      );
                    }
                    return TransactionListItem(
                      transaction: transaction,
                      onTap: () {},
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
