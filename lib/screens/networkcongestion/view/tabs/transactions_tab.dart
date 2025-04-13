import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_hub/utils/snackbar_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';
import 'package:pyusd_hub/screens/trace/provider/trace_provider.dart';
import 'package:pyusd_hub/screens/trace/view/transaction_trace_screen.dart';
import '../../../../widgets/common/info_dialog.dart';
import '../../provider/network_congestion_provider.dart';
import '../widgets/stats_card.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction Activity Overview
          _buildTransactionOverview(colorScheme),

          const SizedBox(height: 16),

          // Recent PYUSD Transactions
          _buildPyusdActivitySection(colorScheme),
        ],
      ),
    );
  }

  // Transaction Activity Overview
  Widget _buildTransactionOverview(ColorScheme colorScheme) {
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

    final recentTxCount = transactions.length;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'PYUSD Transaction Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.info_outline,
                          color: colorScheme.onSurface.withOpacity(0.7),
                          size: 20,
                        ),
                        onPressed: () => InfoDialog.show(
                          context,
                          title: 'PYUSD Transaction Overview',
                          message:
                              'Overview of PYUSD transactions on the Ethereum network, including transaction count, volume, confirmation time, and active users.',
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  if (recentTxCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withOpacity(0.1),
                            Colors.green.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$recentTxCount txs',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  StatsCard(
                    title: 'Transactions',
                    value: FormatterUtils.formatLargeNumber(recentTxCount),
                    icon: Icons.swap_horiz,
                    color: Colors.blue,
                    description: 'Recent PYUSD txs',
                    isListView: true,
                  ),
                  const SizedBox(height: 12),
                  StatsCard(
                    title: 'Volume',
                    value: formattedVolume,
                    icon: Icons.attach_money,
                    color: Colors.green,
                    description: 'PYUSD transferred',
                    isListView: true,
                  ),
                  const SizedBox(height: 12),
                  // StatsCard(
                  //   title: 'Active Users',
                  //   value: FormatterUtils.formatLargeNumber(uniqueAddresses),
                  //   icon: Icons.people,
                  //   color: Colors.purple,
                  //   description: 'Unique wallets',
                  //   isListView: true,
                  // ),
                ],
              ),
            ],
          ),
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
  Widget _buildPyusdActivitySection(ColorScheme colorScheme) {
    final transactions = widget.provider.recentPyusdTransactions;
    final pendingTransactions =
        widget.provider.congestionData.pendingPyusdTxCount;
    final latestBlockNumber = widget.provider.congestionData.lastBlockNumber;
    final oldestBlockNumber = widget.provider.recentBlocks.isNotEmpty
        ? FormatterUtils.parseHexSafely(
            widget.provider.recentBlocks.last['number'])
        : null;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'PYUSD Transactions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (widget.provider.isLoading)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (!widget.provider.isLoading &&
                      (transactions.isNotEmpty || pendingTransactions > 0))
                    Text(
                      '${transactions.length} confirmed, $pendingTransactions pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              if (oldestBlockNumber != null &&
                  latestBlockNumber > 0 &&
                  !widget.provider.isLoading) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.1),
                        Colors.blue.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Showing transactions from blocks $oldestBlockNumber to $latestBlockNumber',
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
              if (widget.provider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading recent transactions...',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (transactions.isEmpty && pendingTransactions == 0)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No PYUSD transactions detected',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
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
                            Divider(
                              height: 1,
                              color:
                                  colorScheme.outlineVariant.withOpacity(0.2),
                            ),
                            _buildTransactionListItem(
                                context, transaction, colorScheme),
                          ],
                        );
                      }
                      return _buildTransactionListItem(
                          context, transaction, colorScheme);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionListItem(BuildContext context,
      Map<String, dynamic> transaction, ColorScheme colorScheme) {
    final from = transaction['from'] as String? ?? '';
    final to = transaction['to'] as String? ?? '';
    final hash = transaction['hash'] as String? ?? '';
    final gasPrice = transaction['gasPrice'] as String? ?? '0';
    final gasUsed = transaction['gasUsed'] as String? ?? '0';
    final timestamp = transaction['timestamp'] as String? ?? '0';
    final status = transaction['status'] as String? ?? '0x1';
    final tokenValue = transaction['tokenValue'] as double? ?? 0.0;

    // Parse gas price to Gwei
    final gasPriceGwei = int.tryParse(
            gasPrice.startsWith('0x') ? gasPrice.substring(2) : gasPrice,
            radix: gasPrice.startsWith('0x') ? 16 : 10) ??
        0;
    final gasPriceFormatted = (gasPriceGwei / 1e9).toStringAsFixed(1);

    // Format timestamp
    final blockTime =
        DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp) * 1000);
    final timeAgo = FormatterUtils.formatRelativeTime(int.parse(timestamp));

    return InkWell(
      onTap: () => _showTransactionOptions(context, transaction),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.1),
                            Colors.blue.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.swap_horiz, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tx: ${FormatterUtils.formatHash(hash)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withOpacity(0.1),
                            Colors.green.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${tokenValue.toStringAsFixed(2)} PYUSD',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTransactionDetailChip(
                  'From: ${FormatterUtils.formatAddress(from)}',
                  Icons.person_outline,
                  Colors.purple,
                ),
                _buildTransactionDetailChip(
                  'To: ${FormatterUtils.formatAddress(to)}',
                  Icons.person,
                  Colors.blue,
                ),
                _buildTransactionDetailChip(
                  'Gas: $gasPriceFormatted Gwei',
                  Icons.local_gas_station,
                  Colors.orange,
                ),
                _buildTransactionDetailChip(
                  'Status: ${status == '0x1' ? 'Confirmed' : 'Pending'}',
                  Icons.check_circle,
                  status == '0x1' ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetailChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionOptions(
      BuildContext context, Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.swap_horiz, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaction ${FormatterUtils.formatHash(transaction['hash'] ?? '')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Options',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.analytics, color: Colors.purple),
                title: const Text('Trace Transaction'),
                subtitle: const Text('View detailed execution trace'),
                onTap: () {
                  Navigator.pop(context);
                  _traceTransaction(context, transaction);
                },
              ),
              ListTile(
                leading: const Icon(Icons.content_copy, color: Colors.grey),
                title: const Text('Copy Transaction Hash'),
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: transaction['hash'] ?? ''));
                  Navigator.pop(context);
                  SnackbarUtil.showSnackbar(
                      context: context,
                      message: 'Transaction hash copied to clipboard');
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_in_new, color: Colors.green),
                title: const Text('View on Etherscan'),
                onTap: () async {
                  Navigator.pop(context);
                  final url = 'https://etherscan.io/tx/${transaction['hash']}';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open Etherscan'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _traceTransaction(
      BuildContext context, Map<String, dynamic> transaction) {
    final traceProvider = Provider.of<TraceProvider>(context, listen: false);
    final hash = transaction['hash'] as String? ?? '';
    if (hash.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionTraceScreen(txHash: hash),
        ),
      );
    }
  }
}
