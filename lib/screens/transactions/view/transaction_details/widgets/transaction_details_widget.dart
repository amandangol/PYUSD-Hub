import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pyusd_hub/utils/snackbar_utils.dart';
import '../../../../../widgets/pyusd_components.dart';
import '../../../../../utils/formatter_utils.dart';
import '../../../model/transaction_model.dart';
import 'common/transaction_common_widgets.dart';

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
    return TransactionCard(
      cardColor: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner at the top for high visibility
          _buildStatusBanner(),

          const SizedBox(height: 16),

          // Main section header
          TransactionSectionHeader(
            icon: Icons.receipt_long,
            title: 'Transaction Details',
            iconColor: primaryColor,
            textColor: textColor,
          ),
          const Divider(height: 30),

          // Transaction core information section
          TransactionSectionHeader(
            icon: Icons.description_outlined,
            title: 'Core Information',
            iconColor: textColor.withOpacity(0.7),
            textColor: textColor,
          ),
          _buildDetailRow(
            title: 'Transaction Hash',
            value: FormatterUtils.formatHash(transaction.hash),
            canCopy: true,
            data: transaction.hash,
            textColor: textColor,
            subtitleColor: subtitleColor,
            context: context,
            icon: Icons.tag,
            isImportant: true,
            infoMessage: 'Unique identifier for this transaction',
          ),
          _buildDetailRow(
            title: 'Block',
            value: transaction.blockNumber != 'Pending'
                ? '# ${transaction.blockNumber}'
                : 'Pending',
            textColor: textColor,
            subtitleColor: subtitleColor,
            context: context,
            icon: Icons.view_module_outlined,
            infoMessage: 'Block number where this transaction was included',
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
            icon: Icons.link,
            infoMessage: 'Hash of the block containing this transaction',
          ),
          _buildDetailRow(
            title: 'Nonce',
            value: transaction.nonce.toString(),
            textColor: textColor,
            subtitleColor: subtitleColor,
            context: context,
            icon: Icons.format_list_numbered,
            infoMessage:
                'Transaction sequence number for the sender\'s address',
          ),

          const SizedBox(height: 16),

          // Address section
          TransactionSectionHeader(
            icon: Icons.swap_horiz,
            title: 'Addresses',
            iconColor: textColor.withOpacity(0.7),
            textColor: textColor,
            infoMessage:
                'Sender and recipient addresses involved in this transaction',
          ),
          _buildAddressRow(
            context: context,
            title: 'From',
            address: transaction.from,
            isCurrentAddress:
                transaction.from.toLowerCase() == currentAddress.toLowerCase(),
            textColor: textColor,
            subtitleColor: subtitleColor,
            primaryColor: primaryColor,
          ),
          _buildAddressRow(
            context: context,
            title: 'To',
            address: transaction.to,
            isCurrentAddress:
                transaction.to.toLowerCase() == currentAddress.toLowerCase(),
            textColor: textColor,
            subtitleColor: subtitleColor,
            primaryColor: primaryColor,
          ),

          // Token information (if applicable)
          if (transaction.tokenContractAddress != null) ...[
            const SizedBox(height: 16),
            TransactionSectionHeader(
              icon: Icons.token,
              title: 'Token Information',
              iconColor: textColor.withOpacity(0.7),
              textColor: textColor,
              infoMessage:
                  'Details about the token involved in this transaction including contract address and decimals',
            ),
            _buildTokenInfoSection(context),
          ],

          // Transaction data (if available)
          if (transaction.data != null && transaction.data!.length > 2) ...[
            const SizedBox(height: 16),
            TransactionSectionHeader(
              icon: Icons.code,
              title: 'Technical Data',
              iconColor: textColor.withOpacity(0.7),
              textColor: textColor,
              infoMessage:
                  'Raw transaction data and contract interaction details',
            ),
            _buildDataSection(context),
          ],

          // Error section (if transaction failed)
          if (transaction.isError && transaction.errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorSection(context),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final statusColor = _getStatusColor(transaction.status);
    final statusText = _getStatusTextWithConfirmations();
    final statusIcon = _getStatusIcon(transaction.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
    IconData? icon,
    bool isImportant = false,
    String? infoMessage,
  }) {
    return TransactionDetailRow(
      icon: icon ?? Icons.info_outline,
      title: title,
      value: value,
      infoMessage: infoMessage ?? '',
      textColor: textColor,
      subtitleColor: subtitleColor,
      valueColor: valueColor,
      isHighlighted: isImportant,
      canCopy: canCopy,
      dataToCopy: data,
    );
  }

  Widget _buildAddressRow({
    required BuildContext context,
    required String title,
    required String address,
    required bool isCurrentAddress,
    required Color textColor,
    required Color subtitleColor,
    required Color primaryColor,
  }) {
    return TransactionDetailRow(
      icon: title == 'From' ? Icons.arrow_upward : Icons.arrow_downward,
      title: title,
      value: FormatterUtils.formatHash(address),
      infoMessage: '${title} address of the transaction',
      textColor: isCurrentAddress ? primaryColor : textColor,
      subtitleColor: subtitleColor,
      valueColor: isCurrentAddress ? primaryColor : null,
      isHighlighted: isCurrentAddress,
      canCopy: true,
      dataToCopy: address,
    );
  }

  Widget _buildTokenInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: subtitleColor.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.token_outlined,
                size: 18,
                color: primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                transaction.tokenSymbol ?? 'Unknown Token',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (transaction.tokenName != null)
            Text(
              transaction.tokenName!,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Contract:',
                style: TextStyle(
                  fontSize: 13,
                  color: subtitleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  FormatterUtils.formatHash(transaction.tokenContractAddress!),
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: transaction.tokenContractAddress!));
                    SnackbarUtil.showSnackbar(
                        context: context, message: 'Contract address copied');
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
          if (transaction.tokenDecimals != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Decimals:',
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  transaction.tokenDecimals.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: subtitleColor.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Transaction Input Data:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: transaction.data!));
                    SnackbarUtil.showSnackbar(
                        context: context, message: 'Data copied to clipboard');
                  },
                  child: Tooltip(
                    message: 'Copy full data',
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
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              FormatterUtils.formatHash(transaction.data!),
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: textColor.withOpacity(0.8),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '(This is encoded contract interaction data)',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: subtitleColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TransactionSectionHeader(
          icon: Icons.error_outline,
          title: 'Error Information',
          iconColor: Colors.red,
          textColor: Colors.red,
        ),
        PyusdErrorMessage(
          message: transaction.errorMessage!,
          borderRadius: 12,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Center(
            child: PyusdButton(
              onPressed: onShowErrorDetails,
              text: 'View Detailed Error Analysis',
              icon: const Icon(Icons.error_outline),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusTextWithConfirmations() {
    switch (transaction.status) {
      case TransactionStatus.pending:
        return 'Transaction Pending - Waiting for Confirmation';
      case TransactionStatus.confirmed:
        return 'Transaction Confirmed (${transaction.confirmations} confirmations)';
      case TransactionStatus.failed:
        return 'Transaction Failed - Error Detected';
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

  IconData _getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.confirmed:
        return Icons.check_circle;
      case TransactionStatus.pending:
        return Icons.pending_outlined;
      case TransactionStatus.failed:
        return Icons.error_outline;
    }
  }
}
