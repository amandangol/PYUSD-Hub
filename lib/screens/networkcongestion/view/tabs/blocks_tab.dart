import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../utils/formatter_utils.dart';
import '../../../../utils/snackbar_utils.dart';
import '../../../../widgets/common/info_dialog.dart';
import '../../../trace/provider/trace_provider.dart';
import '../../../trace/view/transaction_trace_screen.dart';
import '../../provider/network_congestion_provider.dart';
import '../widgets/block_trace_screen.dart';

class BlocksTab extends StatefulWidget {
  final NetworkCongestionProvider provider;

  const BlocksTab({
    super.key,
    required this.provider,
  });

  @override
  State<BlocksTab> createState() => _BlocksTabState();
}

class _BlocksTabState extends State<BlocksTab> {
  final Map<String, bool> _expandedTraces = {};
  final Map<String, Map<String, dynamic>> _traceCache = {};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Block Information Overview
          _buildBlockInfoOverview(context),

          const SizedBox(height: 16),

          // Recent Blocks List (expanded with more details)
          _buildRecentBlocksSection(expandedView: true),
        ],
      ),
    );
  }

  // Block Information Overview Card
  Widget _buildBlockInfoOverview(BuildContext context) {
    // Get the latest block if available
    final latestBlock = widget.provider.recentBlocks.isNotEmpty
        ? widget.provider.recentBlocks[0]
        : null;

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                    const Text(
                      'Block Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => InfoDialog.show(
                        context,
                        title: 'Block Information',
                        message:
                            'Overview of the latest block on the Ethereum network, including block number, time, size, and gas usage statistics.',
                      ),
                    ),
                  ],
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
                  context,
                  'Avg Block Time',
                  widget.provider.congestionData.averageBlockTime > 0
                      ? '${widget.provider.congestionData.averageBlockTime.toStringAsFixed(1)} sec'
                      : 'Loading...',
                  Icons.timer,
                  Colors.blue,
                  'Average time between new blocks being added to the blockchain. Target is around 12-15 seconds.',
                ),
                _buildBlockStatCard(
                  context,
                  'Blocks/Hour',
                  widget.provider.congestionData.blocksPerHour > 0
                      ? '~${widget.provider.congestionData.blocksPerHour}'
                      : 'Loading...',
                  Icons.av_timer,
                  Colors.green,
                  'Estimated number of blocks being mined per hour on the Ethereum network.',
                ),
                _buildBlockStatCard(
                  context,
                  'Avg Tx/Block',
                  widget.provider.congestionData.averageTxPerBlock > 0
                      ? '${widget.provider.congestionData.averageTxPerBlock}'
                      : 'Loading...',
                  Icons.sync_alt,
                  Colors.purple,
                  'Average number of transactions included in each block. Higher numbers indicate increased network activity.',
                ),
                _buildBlockStatCard(
                  context,
                  'Gas Limit',
                  widget.provider.congestionData.gasLimit > 0
                      ? '${(widget.provider.congestionData.gasLimit / 1000000).toStringAsFixed(1)}M'
                      : 'Loading...',
                  Icons.local_gas_station,
                  Colors.orange,
                  'Maximum amount of gas that can be used in a single block. This is a network parameter that can be adjusted.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Block Statistics Card
  Widget _buildBlockStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String infoMessage,
  ) {
    return GestureDetector(
      onTap: () => InfoDialog.show(
        context,
        title: title,
        message: infoMessage,
      ),
      child: Container(
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
                  Row(
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
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.info_outline,
                        size: 12,
                        color: Colors.grey,
                      ),
                    ],
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
      ),
    );
  }

  // Recent Blocks List
  Widget _buildRecentBlocksSection({bool expandedView = false}) {
    final blocks = widget.provider.recentBlocks;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Blocks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (blocks.isNotEmpty)
                  Text(
                    'Showing ${blocks.length} blocks',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (blocks.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading recent blocks...',
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
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemCount: blocks.length,
                itemBuilder: (context, index) {
                  final block = blocks[index];
                  return _buildBlockListItem(context, block, expandedView);
                },
              ),
          ],
        ),
      ),
    );
  }

  // Block List Item
  Widget _buildBlockListItem(
      BuildContext context, Map<String, dynamic> block, bool expandedView) {
    // Parse block data
    final blockNumber = FormatterUtils.parseHexSafely(block['number']) ?? 0;
    final timestamp = FormatterUtils.parseHexSafely(block['timestamp']) ?? 0;
    final gasUsed = FormatterUtils.parseHexSafely(block['gasUsed']) ?? 0;
    final gasLimit = FormatterUtils.parseHexSafely(block['gasLimit']) ?? 0;
    final txCount = block['transactions'] != null
        ? (block['transactions'] as List).length
        : 0;
    final miner = block['miner'] as String? ?? '';
    final size = FormatterUtils.parseHexSafely(block['size']) ?? 0;

    // Calculate gas usage percentage
    final gasUsagePercentage =
        gasLimit > 0 ? (gasUsed / gasLimit * 100).toStringAsFixed(1) : '0';

    // Format timestamp
    final DateTime blockTime =
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final String timeAgo = FormatterUtils.formatRelativeTime(timestamp);

    return InkWell(
      onTap: () => _showBlockOptions(context, block, blockNumber),
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
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.storage, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Block #${(blockNumber)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
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
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$txCount txs',
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
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ],
            ),
            if (expandedView) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildBlockDetailChip(
                    'Gas: $gasUsagePercentage%',
                    Icons.local_gas_station,
                    Colors.orange,
                  ),
                  _buildBlockDetailChip(
                    'Size: ${(size / 1024).toStringAsFixed(1)} KB',
                    Icons.data_usage,
                    Colors.purple,
                  ),
                  _buildBlockDetailChip(
                    'Miner: ${FormatterUtils.formatAddress(miner)}',
                    Icons.account_balance,
                    Colors.blue,
                  ),
                  _buildBlockDetailChip(
                    DateFormat('MMM d, HH:mm:ss').format(blockTime),
                    Icons.access_time,
                    Colors.green,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Block Detail Chip
  Widget _buildBlockDetailChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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

  // Show Block Options Dialog
  void _showBlockOptions(
      BuildContext context, Map<String, dynamic> block, int blockNumber) {
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
                      child: const Icon(Icons.storage, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Block #${FormatterUtils.formatLargeNumber(blockNumber)}',
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
                title: const Text('Trace Block'),
                subtitle:
                    const Text('View detailed execution trace of this block'),
                onTap: () {
                  Navigator.pop(context);
                  _traceBlock(context, blockNumber);
                },
              ),
              ListTile(
                leading: const Icon(Icons.search, color: Colors.blue),
                title: const Text('Find PYUSD Transactions'),
                subtitle:
                    const Text('Search for PYUSD transactions in this block'),
                onTap: () {
                  Navigator.pop(context);
                  _findPyusdTransactions(context, blockNumber);
                },
              ),
              ListTile(
                leading: const Icon(Icons.content_copy, color: Colors.grey),
                title: const Text('Copy Block Number'),
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: blockNumber.toString()));
                  Navigator.pop(context);
                  SnackbarUtil.showSnackbar(
                    context: context,
                    message: 'Block number copied to clipboard',
                    icon: Icons.check_circle,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_in_new, color: Colors.green),
                title: const Text('View on Etherscan'),
                onTap: () async {
                  Navigator.pop(context);
                  final url = 'https://etherscan.io/block/$blockNumber';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  } else {
                    if (context.mounted) {
                      SnackbarUtil.showSnackbar(
                        context: context,
                        message: 'Could not open Etherscan',
                        icon: Icons.error,
                        isError: true,
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

  // Trace Block
  void _traceBlock(BuildContext context, int blockNumber) {
    final traceProvider = Provider.of<TraceProvider>(context, listen: false);

    // Navigate to block trace screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlockTraceScreen(blockNumber: blockNumber),
      ),
    );
  }

  // Find PYUSD Transactions in Block
  void _findPyusdTransactions(BuildContext context, int blockNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PYUSD Transactions'),
        content: FutureBuilder<List<Map<String, dynamic>>>(
          future: _getPyusdTransactionsInBlock(blockNumber),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (snapshot.hasError) {
              return SizedBox(
                height: 100,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 40),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, color: Colors.grey, size: 40),
                      SizedBox(height: 16),
                      Text(
                        'No PYUSD transactions found in this block',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            } else {
              final transactions = snapshot.data!;
              return SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final from = tx['from'] as String? ?? '';
                    final to = tx['to'] as String? ?? '';
                    final hash = tx['hash'] as String? ?? '';

                    return ListTile(
                      title: Text(
                        'Tx: ${FormatterUtils.formatHash(hash)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('From: ${FormatterUtils.formatAddress(from)}'),
                          Text('To: ${FormatterUtils.formatAddress(to)}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () async {
                          final url = 'https://etherscan.io/tx/$hash';
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          }
                        },
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showTransactionDetails(context, tx);
                      },
                    );
                  },
                ),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Get PYUSD Transactions in Block
  Future<List<Map<String, dynamic>>> _getPyusdTransactionsInBlock(
      int blockNumber) async {
    try {
      // This would typically call your provider method to get PYUSD transactions
      // For now, we'll simulate this with a delay
      await Future.delayed(const Duration(seconds: 1));

      // Get transactions from the block
      final block = widget.provider.recentBlocks.firstWhere(
        (b) => FormatterUtils.parseHexSafely(b['number']) == blockNumber,
        orElse: () => <String, dynamic>{},
      );

      if (block.isEmpty) {
        return [];
      }

      final transactions = block['transactions'] as List<dynamic>? ?? [];

      // Filter for PYUSD transactions (this is simplified)
      // In a real implementation, you would check for transactions to/from the PYUSD contract
      // or transactions with specific method signatures
      final pyusdContractAddress =
          '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8'.toLowerCase();

      final pyusdTransactions = transactions.where((tx) {
        if (tx is Map<String, dynamic>) {
          final to = (tx['to'] as String? ?? '').toLowerCase();
          return to == pyusdContractAddress;
        }
        return false;
      }).toList();

      return pyusdTransactions.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting PYUSD transactions: $e');
      return [];
    }
  }

  // Show Transaction Details
  void _showTransactionDetails(
      BuildContext context, Map<String, dynamic> transaction) {
    // This would navigate to a transaction detail screen
    // For now, we'll just show a dialog with basic info
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hash: ${transaction['hash'] ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('From: ${transaction['from'] ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('To: ${transaction['to'] ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text(
                'Value: ${FormatterUtils.formatEthFromHex(transaction['value'] ?? '0x0')}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to transaction trace screen
              final traceProvider =
                  Provider.of<TraceProvider>(context, listen: false);
              final hash = transaction['hash'] as String? ?? '';
              if (hash.isNotEmpty) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TransactionTraceScreen(
                        txHash: transaction['hash'] ?? '',
                      ),
                    ));
              }
            },
            child: const Text('Trace Transaction'),
          ),
        ],
      ),
    );
  }

  // Format block timestamp
  String _formatBlockTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      final timestampInt = FormatterUtils.parseHexSafely(timestamp) ?? 0;
      if (timestampInt == 0) return 'Unknown';

      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestampInt * 1000);
      return DateFormat('MMM d, yyyy HH:mm:ss').format(dateTime);
    } catch (e) {
      return 'Invalid timestamp';
    }
  }

  // Format gas used percentage
  String _formatGasUsedPercentage(String? gasUsed, String? gasLimit) {
    if (gasUsed == null || gasLimit == null) return '0%';

    try {
      final used = FormatterUtils.parseHexSafely(gasUsed) ?? 0;
      final limit = FormatterUtils.parseHexSafely(gasLimit) ?? 1;

      if (limit == 0) return '0%';

      final percentage = (used / limit) * 100;
      return '${percentage.toStringAsFixed(1)}%';
    } catch (e) {
      return '0%';
    }
  }

  // Get block difficulty
  String _formatBlockDifficulty(String? difficulty) {
    if (difficulty == null) return 'N/A';

    try {
      final difficultyInt = FormatterUtils.parseHexSafely(difficulty) ?? 0;
      if (difficultyInt == 0) return 'N/A';

      if (difficultyInt > 1000000000000) {
        return '${(difficultyInt / 1000000000000).toStringAsFixed(2)} T';
      } else if (difficultyInt > 1000000000) {
        return '${(difficultyInt / 1000000000).toStringAsFixed(2)} G';
      } else if (difficultyInt > 1000000) {
        return '${(difficultyInt / 1000000).toStringAsFixed(2)} M';
      } else {
        return difficultyInt.toString();
      }
    } catch (e) {
      return 'N/A';
    }
  }

  // Format transaction count
  String _formatTransactionCount(dynamic transactions) {
    if (transactions == null) return '0';

    try {
      if (transactions is String) {
        final count = FormatterUtils.parseHexSafely(transactions) ?? 0;
        return count.toString();
      } else if (transactions is List) {
        return transactions.length.toString();
      }
      return '0';
    } catch (e) {
      return '0';
    }
  }
}
