import 'package:flutter/material.dart';
import '../../../../../utils/datetime_utils.dart';
import '../../../model/transaction_model.dart';

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
    return Card(
      color: cardColor,
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(transaction.status),
                color: statusColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            // Transaction type and status
            Text(
              isIncoming ? 'Received' : 'Sent',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),

            // Status with confirmations
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      fontSize: 14,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount
            Text(
              _formatAmount(transaction),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isIncoming ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 12),

            // Fee and date
            Text(
              'Fee: ${transaction.fee.toStringAsFixed(10)} ETH',
              style: TextStyle(
                fontSize: 14,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateTimeUtils.formatDateTime(transaction.timestamp),
              style: TextStyle(
                fontSize: 14,
                color: subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.confirmed:
        return Icons.check_circle;
      case TransactionStatus.pending:
        return Icons.pending;
      case TransactionStatus.failed:
        return Icons.error;
    }
  }

  String _getStatusText() {
    switch (transaction.status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.confirmed:
        return 'Confirmed (${transaction.confirmations} confirmations)';
      case TransactionStatus.failed:
        return 'Failed';
    }
  }

  String _formatAmount(TransactionDetailModel tx) {
    if (tx.tokenSymbol != null) {
      return '${tx.amount.toStringAsFixed(2)} ${tx.tokenSymbol}';
    } else {
      return '${tx.amount.toStringAsFixed(6)} ETH';
    }
  }
}
