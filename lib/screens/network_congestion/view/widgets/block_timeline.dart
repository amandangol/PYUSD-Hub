import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../utils/formatter_utils.dart';

class BlockTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> blocks;

  const BlockTimeline({super.key, required this.blocks});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Block Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (blocks.isEmpty)
              const Center(
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
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemCount: blocks.length,
                itemBuilder: (context, index) {
                  final block = blocks[index];
                  final blockNumber =
                      FormatterUtils.parseHexSafely(block['number']);
                  final timestamp =
                      FormatterUtils.parseHexSafely(block['timestamp']);
                  final transactions = block['transactions'] as List? ?? [];
                  final gasUsed =
                      FormatterUtils.parseHexSafely(block['gasUsed']);
                  final gasLimit =
                      FormatterUtils.parseHexSafely(block['gasLimit']);

                  final utilization =
                      gasUsed != null && gasLimit != null && gasLimit > 0
                          ? (gasUsed / gasLimit) * 100
                          : 0.0;

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                          _formatTimestamp(timestamp),
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
                    subtitle: Column(
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
                              FormatterUtils.formatAddress('${block['miner']}'),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    borderRadius: BorderRadius.circular(3),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      utilization > 90
                                          ? Colors.red
                                          : utilization > 70
                                              ? Colors.orange
                                              : Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${utilization.toStringAsFixed(1)}% (${(gasUsed ?? 0) ~/ 1000000}M/${(gasLimit ?? 0) ~/ 1000000}M)',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new, size: 18),
                      onPressed: () async {
                        // Open block explorer to view block details
                        final url = Uri.parse(
                            'https://etherscan.io/block/$blockNumber');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return 'N/A';

    final now = DateTime.now();
    final blockTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final difference = now.difference(blockTime);

    if (difference.inMinutes < 1) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}
