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
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with type, time and value
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isTransfer ? Colors.green : Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isTransfer ? 'Transfer' : 'Contract',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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

              // From address
              Row(
                children: [
                  Text(
                    'From: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatAddress(fromAddress),
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () =>
                        _copyToClipboard(context, fromAddress, 'From address'),
                    child:
                        Icon(Icons.copy, size: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // To address
              Row(
                children: [
                  Text(
                    'To:     ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatAddress(toAddress),
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () =>
                        _copyToClipboard(context, toAddress, 'To address'),
                    child:
                        Icon(Icons.copy, size: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Bottom row with hash and action buttons
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'Tx: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _formatAddress(txHash),
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: Colors.grey.shade400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () => _copyToClipboard(
                              context, txHash, 'Transaction hash'),
                          child: Icon(Icons.copy,
                              size: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.account_tree_outlined, size: 20),
                        color: Colors.orange,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TransactionTraceScreen(txHash: txHash),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new, size: 20),
                        color: Colors.blue,
                        tooltip: 'View on Etherscan',
                        onPressed: () => _launchEtherscan(context, txHash),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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
          duration: const Duration(seconds: 1),
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
