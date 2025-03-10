import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class TransactionListItem extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionListItem({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract transaction data
    final String txHash = transaction['hash'] ?? '';
    final String from = transaction['from'] ?? '';

    // Safely parse hexadecimal value
    double value = 0.0;
    if (transaction['value'] != null &&
        transaction['value'].toString().startsWith('0x')) {
      try {
        value =
            int.parse(transaction['value'].toString().substring(2), radix: 16) /
                1e18;
      } catch (e) {
        // Handle parsing error
        value = 0.0;
      }
    }

    // Determine if pending or confirmed
    final isPending = transaction['blockNumber'] == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Row(
          children: [
            Expanded(
              child: Text(
                txHash.isNotEmpty
                    ? '${txHash.substring(0, min(10, txHash.length))}...${txHash.substring(max(0, txHash.length - 8))}'
                    : 'No Hash',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (txHash.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: txHash));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaction hash copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Icon(Icons.copy, size: 16),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              from.isNotEmpty
                  ? 'From: ${from.substring(0, min(8, from.length))}...${from.substring(max(0, from.length - 6))}'
                  : 'From: Unknown',
              style: const TextStyle(fontSize: 12),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (value > 0)
                  Text(
                    'Value: ${value.toStringAsFixed(4)} ETH',
                    style: const TextStyle(fontSize: 12),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPending ? Colors.orange : Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isPending ? 'Pending' : 'Confirmed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          // Navigate to transaction details or open in etherscan
          if (txHash.isNotEmpty) {
            final url = 'https://etherscan.io/tx/$txHash';
            launchUrl(Uri.parse(url));
          }
        },
      ),
    );
  }

  // Utility functions to safely handle substring operations
  int min(int a, int b) => a < b ? a : b;
  int max(int a, int b) => a > b ? a : b;
}
