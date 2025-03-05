import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction.dart';
import '../../../screens/transaction_detail_screen.dart';

class TransactionListItem extends StatelessWidget {
  final TransactionModel transaction;
  final String currentAddress;
  final bool isDarkMode;
  final Color cardColor;

  const TransactionListItem({
    Key? key,
    required this.transaction,
    required this.currentAddress,
    required this.cardColor,
    required this.isDarkMode,
  }) : super(key: key);

  String _formatAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isIncoming =
        transaction.to.toLowerCase() == currentAddress.toLowerCase();
    final String addressToShow = isIncoming ? transaction.from : transaction.to;

    // Determine transaction status text and color
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (transaction.status == 'Pending') {
      statusColor = Colors.orange;
      statusText = 'Pending';
      statusIcon = Icons.pending_outlined;
    } else {
      if (isIncoming) {
        statusColor = Colors.green;
        statusText = 'Received';
        statusIcon = Icons.arrow_downward;
      } else {
        statusColor = Colors.red;
        statusText = 'Sent';
        statusIcon = Icons.arrow_upward;
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(
              transaction: transaction,
              currentAddress: currentAddress,
              isDarkMode: isDarkMode,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isIncoming ? 'Received PYUSD' : 'Sent PYUSD',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatAddress(addressToShow),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.status == 'Pending'
                          ? 'Processing...'
                          : DateFormat.yMMMd()
                              .add_Hm()
                              .format(transaction.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: transaction.status == 'Pending'
                            ? statusColor
                            : (isDarkMode ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncoming ? '+' : '-'} \$${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fee: \$${transaction.fee}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
