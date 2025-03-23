import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pyusd_hub/utils/snackbar_utils.dart';
import '../../../../../common/widgets/pyusd_components.dart';
import '../../../../../utils/formatter_utils.dart';
import '../../../model/transaction_model.dart';

class TransactionDetailsWidget extends StatelessWidget {
  final TransactionDetailModel transaction;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final Color primaryColor;
  final VoidCallback onShowErrorDetails;
  final String currentAddress;

  const TransactionDetailsWidget({
    super.key,
    required this.transaction,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.primaryColor,
    required this.onShowErrorDetails,
    required this.currentAddress,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment_outlined, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Transaction Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              title: 'Transaction Hash',
              value: FormatterUtils.formatHash(transaction.hash),
              canCopy: true,
              data: transaction.hash,
              textColor: textColor,
              subtitleColor: subtitleColor,
              context: context,
            ),
            _buildDetailRow(
              title: 'Status',
              value: _getStatusTextWithConfirmations(),
              valueColor: _getStatusColor(transaction.status),
              textColor: textColor,
              subtitleColor: subtitleColor,
              context: context,
            ),
            _buildDetailRow(
              title: 'Block',
              value: transaction.blockNumber != 'Pending'
                  ? transaction.blockNumber
                  : 'Pending',
              textColor: textColor,
              subtitleColor: subtitleColor,
              context: context,
            ),
            _buildDetailRow(
              title: 'Block Hash',
              value: transaction.blockHash != 'Pending'
                  ? FormatterUtils.formatHash(transaction.blockHash)
                  : 'Pending',
              canCopy: transaction.blockHash != 'Pending',
              data: transaction.blockHash != 'Pending'
                  ? transaction.blockHash
                  : null,
              textColor: textColor,
              subtitleColor: subtitleColor,
              context: context,
            ),
            _buildDetailRow(
              title: 'From',
              value: FormatterUtils.formatHash(transaction.from),
              canCopy: true,
              data: transaction.from,
              valueColor:
                  transaction.from.toLowerCase() == currentAddress.toLowerCase()
                      ? primaryColor
                      : null,
              textColor: textColor,
              subtitleColor: subtitleColor,
              context: context,
            ),
            _buildDetailRow(
              title: 'To',
              value: FormatterUtils.formatHash(transaction.to),
              canCopy: true,
              data: transaction.to,
              valueColor:
                  transaction.to.toLowerCase() == currentAddress.toLowerCase()
                      ? primaryColor
                      : null,
              textColor: textColor,
              subtitleColor: subtitleColor,
              context: context,
            ),
            if (transaction.tokenContractAddress != null) ...[
              _buildDetailRow(
                title: 'Token',
                value: transaction.tokenSymbol ?? 'Unknown Token',
                textColor: textColor,
                subtitleColor: subtitleColor,
                context: context,
              ),
              if (transaction.tokenName != null)
                _buildDetailRow(
                  title: 'Token Name',
                  value: transaction.tokenName!,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  context: context,
                ),
              if (transaction.tokenDecimals != null)
                _buildDetailRow(
                  title: 'Token Decimals',
                  value: transaction.tokenDecimals.toString(),
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  context: context,
                ),
              _buildDetailRow(
                title: 'Token Contract',
                value: FormatterUtils.formatHash(
                    transaction.tokenContractAddress!),
                canCopy: true,
                data: transaction.tokenContractAddress!,
                textColor: textColor,
                subtitleColor: subtitleColor,
                context: context,
              ),
            ],
            _buildDetailRow(
              title: 'Nonce',
              value: transaction.nonce.toString(),
              textColor: textColor,
              subtitleColor: subtitleColor,
              context: context,
            ),
            if (transaction.isError && transaction.errorMessage != null)
              PyusdErrorMessage(
                message: transaction.errorMessage!,
                borderRadius: 12,
              ),
            if (transaction.data != null && transaction.data!.length > 2)
              _buildDetailRow(
                title: 'Transaction Data',
                value: FormatterUtils.formatHash(transaction.data!),
                canCopy: true,
                data: transaction.data,
                textColor: textColor,
                subtitleColor: subtitleColor,
                context: context,
              ),
            if (transaction.isError)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(
                  child: PyusdButton(
                    onPressed: onShowErrorDetails,
                    text: 'View Error Details',
                    icon: const Icon(Icons.error_outline),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String title,
    required String value,
    bool canCopy = false,
    String? data,
    Color? valueColor,
    required Color textColor,
    required Color subtitleColor,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? textColor,
              ),
            ),
          ),
          if (canCopy && data != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: data));
                  SnackbarUtil.showSnackbar(
                      context: context, message: 'Copied to clipboard');
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.copy_outlined,
                    size: 16,
                    color: subtitleColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getStatusTextWithConfirmations() {
    switch (transaction.status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.confirmed:
        return 'Confirmed (${transaction.confirmations} confirmations)';
      case TransactionStatus.failed:
        return 'Failed';
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.confirmed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
    }
  }
}
