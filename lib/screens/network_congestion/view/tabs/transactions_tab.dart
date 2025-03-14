import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pyusd_forensics/utils/snackbar_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../utils/formatter_utils.dart';
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

          // Recent PYUSD Transactions (expanded view)
          _buildPyusdActivitySection(expandedView: true),
        ],
      ),
    );
  }

  // Transaction Activity Overview
  Widget _buildTransactionOverview() {
    final data = widget.provider.congestionData;

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
                            onTap: () => _showTransactionDetails(transaction),
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

  // Transaction details dialog
  void _showTransactionDetails(dynamic transaction) {
    final hash = transaction['hash'] as String? ?? '';
    final from = transaction['from'] as String? ?? '';
    final to = transaction['to'] as String? ?? '';
    final value = transaction['value'] as double? ?? 0.0;
    final timestamp = transaction['timestamp'] as int? ?? 0;
    final gasUsed = transaction['gasUsed'] as int? ?? 0;
    final gasPrice = transaction['gasPrice'] as double? ?? 0.0;

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm:ss').format(date);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Hash', FormatterUtils.formatHash(hash)),
              const Divider(),
              _buildDetailItem('From', FormatterUtils.formatAddress(from)),
              const Divider(),
              _buildDetailItem('To', FormatterUtils.formatAddress(to)),
              const Divider(),
              _buildDetailItem('Value', '\$${value.toStringAsFixed(2)} PYUSD'),
              const Divider(),
              _buildDetailItem('Timestamp', formattedDate),
              const Divider(),
              _buildDetailItem('Gas Used', gasUsed.toString()),
              const Divider(),
              _buildDetailItem(
                  'Gas Price', '${gasPrice.toStringAsFixed(2)} Gwei'),
              const Divider(),
              _buildDetailItem('Transaction Fee',
                  '${(gasUsed * gasPrice / 1e9).toStringAsFixed(8)} ETH'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.launch, size: 16),
            label: const Text('View on Explorer'),
            onPressed: () {
              _launchExplorer(hash);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // Helper to build detail items in transaction details
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              if (label == 'Hash' || label == 'From' || label == 'To')
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () {
                    // Copy to clipboard functionality
                    final valueToCopy = label == 'Hash'
                        ? widget.provider.recentPyusdTransactions.firstWhere(
                            (tx) => tx['hash'] == value.replaceAll('...', ''),
                            orElse: () => {'hash': ''})['hash']
                        : value.replaceAll('...', '');

                    SnackbarUtil.showSnackbar(
                        context: context,
                        message: '$label copied to clipboard');
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Copy to clipboard',
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Launch blockchain explorer
  Future<void> _launchExplorer(String hash) async {
    final url = Uri.parse('https://etherscan.io/tx/$hash');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch explorer')),
      );
    }
  }
}
