import 'package:flutter/material.dart';
import 'package:pyusd_hub/screens/networkcongestion/view/widgets/transaction_trace_screen.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';
import 'package:intl/intl.dart';

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
    // Extract transaction data
    final String hash = transaction['hash'] ?? '';
    final String from = transaction['from'] ?? '';
    final String to = transaction['to'] ?? '';
    final String tokenRecipient = transaction['tokenRecipient'] ?? to;

    // Determine if transaction is incoming based on the token recipient
    // This logic needs fixing - incoming should be when the current user is receiving tokens
    final bool isIncoming = tokenRecipient.toLowerCase() == from.toLowerCase();

    // Get timestamp from transaction
    DateTime? timestamp;
    if (transaction['timestamp'] != null) {
      final int timestampValue =
          FormatterUtils.parseHexSafely(transaction['timestamp']) ?? 0;
      if (timestampValue > 0) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue * 1000);
      }
    }

    // Format timestamp
    final String timeString = timestamp != null
        ? DateFormat('MMM dd, HH:mm').format(timestamp)
        : 'Pending';

    // Calculate relative time
    final String relativeTime =
        timestamp != null ? _getRelativeTime(timestamp) : 'Pending';

    // Get PYUSD amount with improved error handling
    double amount = 0.0;
    if (transaction.containsKey('tokenValue') &&
        transaction['tokenValue'] != null) {
      // Try to parse as double first
      if (transaction['tokenValue'] is double) {
        amount = transaction['tokenValue'];
      } else if (transaction['tokenValue'] is int) {
        amount = transaction['tokenValue'].toDouble();
      } else if (transaction['tokenValue'] is String) {
        amount = double.tryParse(transaction['tokenValue']) ?? 0.0;
      }
    } else if (transaction['input'] != null &&
        transaction['input'].toString().length >= 138 &&
        transaction['input'].toString().startsWith('0xa9059cbb')) {
      try {
        final String valueHex = transaction['input'].toString().substring(74);
        final BigInt tokenValueBigInt =
            FormatterUtils.parseBigInt("0x$valueHex");
        amount =
            tokenValueBigInt / BigInt.from(10).pow(6); // PYUSD has 6 decimals
      } catch (e) {
        print('Error parsing token value: $e');
      }
    }

    // Format amount with commas for thousands
    final formattedAmount = NumberFormat('#,##0.00').format(amount);

    // Shorten addresses for display
    final String shortFrom = FormatterUtils.formatAddress(from);
    final String shortTo = FormatterUtils.formatAddress(tokenRecipient);

    final transactionStatus = timestamp != null ? 'Completed' : 'Pending';
    final statusColor =
        timestamp != null ? Colors.green.shade600 : Colors.orange.shade600;

    // Determine transaction type icon and color
    IconData transactionIcon;
    Color iconColor;
    Color iconBackgroundColor;

    if (isIncoming) {
      transactionIcon = Icons.call_received;
      iconColor = Colors.green.shade600;
      iconBackgroundColor = Colors.green.withOpacity(0.1);
    } else {
      transactionIcon = Icons.call_made;
      iconColor = Colors.blue.shade600;
      iconBackgroundColor = Colors.blue.withOpacity(0.1);
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Status, Hash and Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          transactionStatus,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          // Add functionality to copy hash to clipboard
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Transaction hash copied to clipboard'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              FormatterUtils.formatHash(hash),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.copy_outlined,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    relativeTime,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Middle row: Amount and direction icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      transactionIcon,
                      color: iconColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isIncoming ? 'Received' : 'Sent',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isIncoming
                                ? Colors.green.shade600
                                : Colors.blue.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeString,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$formattedAmount',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'PYUSD',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Bottom row: From/To addresses
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            // Add functionality to copy address to clipboard
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Address copied to clipboard'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                shortFrom,
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.copy_outlined,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            // Add functionality to copy address to clipboard
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Address copied to clipboard'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                shortTo,
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.copy_outlined,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Add a "View Trace" button
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TransactionTraceScreen(txHash: hash),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics, size: 16),
                  label: const Text('View Trace'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.blue.shade200),
                    ),
                    backgroundColor: Colors.blue.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // String _shortenAddress(String address) {
  //   if (address.isEmpty) return 'Unknown';
  //   if (address.length < 10) return address;
  //   return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  // }

  // String _shortenHash(String hash) {
  //   if (hash.isEmpty) return 'Unknown';
  //   if (hash.length < 10) return hash;
  //   return '${hash.substring(0, 6)}...${address.substring(hash.length - 4)}';
  // }

  String _getRelativeTime(DateTime timestamp) {
    final Duration difference = DateTime.now().difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(timestamp);
    }
  }
}
