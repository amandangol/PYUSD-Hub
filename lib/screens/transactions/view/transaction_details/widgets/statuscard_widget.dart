import 'package:flutter/material.dart';
import '../../../../../utils/datetime_utils.dart';
import '../../../model/transaction_model.dart';
import 'common/transaction_common_widgets.dart';

class StatusCardWidget extends StatelessWidget {
  final TransactionDetailModel transaction;
  final bool isIncoming;
  final Color statusColor;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;

  const StatusCardWidget({
    super.key,
    required this.transaction,
    required this.isIncoming,
    required this.statusColor,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return TransactionCard(
      cardColor: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Transaction type
              Row(
                children: [
                  Icon(
                    isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isIncoming ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isIncoming ? 'Received' : 'Sent',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              // Status badge
              TransactionStatusBadge(
                status: transaction.status,
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Amount display
          Text(
            _formatAmount(transaction),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isIncoming ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 20),

          // Footer with timestamp and fee
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Timestamp
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: subtitleColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateTimeUtils.formatDateTime(transaction.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
              // Fee
              Row(
                children: [
                  Icon(
                    Icons.local_gas_station,
                    size: 14,
                    color: subtitleColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${transaction.fee.toStringAsFixed(9)} ETH',
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(TransactionDetailModel tx) {
    if (tx.tokenSymbol != null) {
      // PYUSD has 6 decimals, display the amount as is since it's already converted
      return '${tx.amount.toStringAsFixed(2)} ${tx.tokenSymbol}';
    } else {
      // ETH has 4 decimal places
      return '${tx.amount.toStringAsFixed(4)} ETH';
    }
  }
}
