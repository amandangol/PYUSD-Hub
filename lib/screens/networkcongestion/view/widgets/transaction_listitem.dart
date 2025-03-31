import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../trace/view/transaction_trace_screen.dart';

class TransactionListItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onTap;

  const TransactionListItem({
    Key? key,
    required this.transaction,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String txHash = transaction['hash'] ?? 'Unknown';
    final String fromAddress = transaction['from'] ?? 'Unknown';
    final String toAddress = transaction['to'] ?? 'Unknown';
    final DateTime timestamp = transaction.containsKey('timeStamp')
        ? DateTime.fromMillisecondsSinceEpoch(
            int.parse(transaction['timeStamp']) * 1000)
        : DateTime.now();

    // Determine if this is a transfer transaction
    bool isTransfer = transaction['input'] != null &&
        transaction['input'].toString().startsWith('0xa9059cbb');

    // Get token value if available
    double tokenValue = 0.0;
    if (transaction.containsKey('tokenValue')) {
      tokenValue = transaction['tokenValue'];
    } else if (isTransfer) {
      try {
        final String valueHex = transaction['input'].toString().substring(74);
        final BigInt tokenValueBigInt =
            FormatterUtils.parseBigInt("0x$valueHex");
        tokenValue =
            tokenValueBigInt / BigInt.from(10).pow(6); // PYUSD has 6 decimals
      } catch (e) {
        print('Error parsing token value: $e');
      }
    }

    // Format token value
    String formattedValue = '${tokenValue.toStringAsFixed(2)} PYUSD';
    if (tokenValue >= 1000000) {
      formattedValue = '${(tokenValue / 1000000).toStringAsFixed(2)}M PYUSD';
    } else if (tokenValue >= 1000) {
      formattedValue = '${(tokenValue / 1000).toStringAsFixed(2)}K PYUSD';
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction Hash with Copy Button
              Row(
                children: [
                  Chip(
                    label: Text(
                      isTransfer ? 'Transfer' : 'Contract',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    backgroundColor: isTransfer ? Colors.green : Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Text(
                    formattedValue,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Transaction Hash with Copy Button
              Row(
                children: [
                  const Text(
                    'Tx: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatAddress(txHash),
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Copy transaction hash',
                    onPressed: () =>
                        _copyToClipboard(context, txHash, 'Transaction hash'),
                  ),
                ],
              ),

              // From Address with Copy Button
              Row(
                children: [
                  const Text(
                    'From: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatAddress(fromAddress),
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Copy from address',
                    onPressed: () =>
                        _copyToClipboard(context, fromAddress, 'From address'),
                  ),
                ],
              ),

              // To Address with Copy Button
              Row(
                children: [
                  const Text(
                    'To: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatAddress(toAddress),
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Copy to address',
                    onPressed: () =>
                        _copyToClipboard(context, toAddress, 'To address'),
                  ),
                ],
              ),

              // Action Buttons
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    context,
                    'View Trace',
                    Icons.account_tree_outlined,
                    Colors.orange,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TransactionTraceScreen(txHash: txHash),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    context,
                    'Etherscan',
                    Icons.open_in_new,
                    Colors.blue,
                    () => _launchEtherscan(context, txHash),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for action buttons
  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to format address for display
  String _formatAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  // Helper method to format timestamp
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      // Format with month and day
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }

  // Helper method to copy text to clipboard
  void _copyToClipboard(BuildContext context, String text, String description) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$description copied to clipboard'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    });
  }

  // Launch the transaction trace
  void _launchEtherscan(BuildContext context, String txHash) async {
    if (txHash.isEmpty) return;

    // Etherscan transaction trace URL
    final url = Uri.parse('https://etherscan.io/tx/$txHash');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch transaction trace'),
        ),
      );
    }
  }
}
