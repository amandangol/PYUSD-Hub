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
    final theme = Theme.of(context);

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
          if (transaction.data != null) ...[
            const SizedBox(height: 16),
            TransactionSectionHeader(
              icon: Icons.code,
              title: 'Technical Data',
              iconColor: textColor.withOpacity(0.7),
              textColor: textColor,
              infoMessage:
                  'Transaction details including gas information and technical analysis',
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
      infoMessage: '$title address of the transaction',
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
    final bool isContractInteraction = transaction.data != null &&
        transaction.data!.length >= 10 &&
        transaction.data != '0x';

    final String methodId =
        isContractInteraction ? transaction.data!.substring(0, 10) : '';

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
          // Transaction Type
          Row(
            children: [
              Icon(
                isContractInteraction ? Icons.code : Icons.currency_exchange,
                size: 16,
                color: primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Transaction Type: ${isContractInteraction ? 'Contract Interaction' : 'ETH Transfer'}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Contract Standard Detection (only for contract interactions)
          if (isContractInteraction) ...[
            Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 16,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Contract Standard: ${_detectContractStandard()}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Method ID and Type (only for contract interactions)
          if (isContractInteraction) ...[
            Row(
              children: [
                Icon(
                  Icons.code,
                  size: 16,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Method ID: $methodId',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Type: ${_getTransactionType()}',
              style: TextStyle(
                fontSize: 14,
                color: subtitleColor,
              ),
            ),
            const Divider(height: 24),
          ],

          // Raw Input Data (only for contract interactions)
          if (isContractInteraction) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Input Data:',
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
                          context: context,
                          message: 'Data copied to clipboard');
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
                transaction.data ?? '0x',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: textColor.withOpacity(0.8),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            ),
          ],

          // Decoded Function (only for contract interactions)
          if (isContractInteraction) ...[
            const SizedBox(height: 16),
            Text(
              'Decoded Function:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDecodedFunction(),
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Technical Analysis (for all transactions)
          const SizedBox(height: 16),
          Text(
            'Technical Analysis:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildTechnicalAnalysis(),
            ),
          ),

          // Security Analysis (for all transactions)
          const SizedBox(height: 16),
          Text(
            'Security Analysis:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildSecurityAnalysis(),
            ),
          ),

          // Additional Info
          const SizedBox(height: 12),
          Text(
            isContractInteraction
                ? 'Note: This is encoded blockchain data. For security, always verify contract interactions.'
                : 'Note: This is a direct ETH transfer transaction.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  String _detectContractStandard() {
    if (transaction.data == null || transaction.data == '0x') {
      return 'N/A';
    }

    final methodId = transaction.data!.substring(0, 10).toLowerCase();

    // ERC20 Methods
    final erc20Methods = {
      '0xa9059cbb': 'transfer',
      '0x095ea7b3': 'approve',
      '0x23b872dd': 'transferFrom',
      '0x70a08231': 'balanceOf',
      '0x18160ddd': 'totalSupply',
      '0xdd62ed3e': 'allowance',
    };

    // ERC721 Methods
    final erc721Methods = {
      '0x42842e0e': 'safeTransferFrom',
      '0x23b872dd': 'transferFrom',
      '0x6352211e': 'ownerOf',
      '0x095ea7b3': 'approve',
      '0x081812fc': 'getApproved',
      '0xe985e9c5': 'isApprovedForAll',
    };

    // ERC1155 Methods
    final erc1155Methods = {
      '0xf242432a': 'safeTransferFrom',
      '0x2eb2c2d6': 'safeBatchTransferFrom',
      '0x00fdd58e': 'balanceOf',
      '0x4e1273f4': 'balanceOfBatch',
      '0xa22cb465': 'setApprovalForAll',
      '0xe985e9c5': 'isApprovedForAll',
    };

    if (erc20Methods.containsKey(methodId)) {
      return 'ERC20 Token Standard';
    } else if (erc721Methods.containsKey(methodId)) {
      return 'ERC721 NFT Standard';
    } else if (erc1155Methods.containsKey(methodId)) {
      return 'ERC1155 Multi Token Standard';
    }

    return 'Unknown Standard';
  }

  List<Widget> _buildSecurityAnalysis() {
    final List<Widget> analysis = [];
    final List<String> securityChecks = _getSecurityChecks();

    for (final check in securityChecks) {
      analysis.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            check,
            style: TextStyle(
              fontSize: 13,
              color: check.startsWith('⚠️') ? Colors.orange : textColor,
            ),
          ),
        ),
      );
    }

    if (analysis.isEmpty) {
      analysis.add(
        const Text(
          '✓ No security concerns detected',
          style: TextStyle(
            fontSize: 13,
            color: Colors.green,
          ),
        ),
      );
    }

    return analysis;
  }

  List<String> _getSecurityChecks() {
    final checks = <String>[];

    // Check if it's a contract creation
    if (transaction.to.isEmpty) {
      checks.add('⚠️ Contract Creation Transaction');
    }

    // Check for ETH transfer with contract interaction
    if (transaction.amount > 0 &&
        transaction.data != null &&
        transaction.data!.length > 2) {
      checks.add('⚠️ ETH Transfer with Contract Interaction');
    }

    // Check for high-value transaction
    if (transaction.amount > 1.0) {
      checks.add(
          '⚠️ High Value Transaction (>${transaction.amount.toStringAsFixed(2)} ETH)');
    }

    // Check gas efficiency
    final gasEfficiency = (transaction.gasUsed / transaction.gasLimit) * 100;
    if (gasEfficiency > 90) {
      checks.add(
          '⚠️ High Gas Usage (${gasEfficiency.toStringAsFixed(1)}% of limit)');
    }

    // Check for contract interaction
    if (transaction.data != null && transaction.data!.length > 10) {
      checks.add('• Contract Interaction Detected');

      // Check for known function signatures
      final methodId = transaction.data!.substring(0, 10);
      if (_isKnownMethod(methodId)) {
        checks.add('✓ Verified Function Signature');
      } else {
        checks.add('⚠️ Unknown Function Signature');
      }
    }

    return checks;
  }

  bool _isKnownMethod(String methodId) {
    final knownMethods = {
      '0xa9059cbb': 'ERC20 transfer',
      '0x095ea7b3': 'ERC20/721 approve',
      '0x23b872dd': 'ERC20/721 transferFrom',
      '0x42842e0e': 'ERC721 safeTransferFrom',
      '0x70a08231': 'ERC20 balanceOf',
      // Add more known methods as needed
    };

    return knownMethods.containsKey(methodId.toLowerCase());
  }

  List<Widget> _buildTechnicalAnalysis() {
    final List<Widget> analysis = [];

    // Data Size Analysis
    if (transaction.data != null) {
      analysis.add(
        Text(
          '• Data Size: ${(transaction.data!.length - 2) ~/ 2} bytes',
          style: TextStyle(
            fontSize: 13,
            color: textColor,
          ),
        ),
      );
    }

    // Gas Efficiency
    final gasEfficiency = (transaction.gasUsed / transaction.gasLimit) * 100;
    analysis.add(
      Text(
        '• Gas Efficiency: ${gasEfficiency.toStringAsFixed(1)}% of limit used',
        style: TextStyle(
          fontSize: 13,
          color: textColor,
        ),
      ),
    );

    // Gas Price Analysis
    analysis.add(
      Text(
        '• Gas Price: ${transaction.gasPrice.toStringAsFixed(4)} Gwei',
        style: TextStyle(
          fontSize: 13,
          color: textColor,
        ),
      ),
    );

    // Total Gas Cost
    final gasCostEth = (transaction.gasUsed * transaction.gasPrice) / 1e9;
    analysis.add(
      Text(
        '• Total Gas Cost: ${gasCostEth.toStringAsFixed(9)} ETH',
        style: TextStyle(
          fontSize: 13,
          color: textColor,
        ),
      ),
    );

    // Contract Interaction Check
    if (transaction.data != null && transaction.data!.length > 10) {
      analysis.add(
        Text(
          '• Contract Interaction: Yes (Method ID: ${transaction.data!.substring(0, 10)})',
          style: TextStyle(
            fontSize: 13,
            color: textColor,
          ),
        ),
      );
    }

    // Transaction Complexity
    analysis.add(
      Text(
        '• Complexity: ${_getTransactionComplexity()}',
        style: TextStyle(
          fontSize: 13,
          color: textColor,
        ),
      ),
    );

    // Nonce Information
    analysis.add(
      Text(
        '• Nonce: ${transaction.nonce}',
        style: TextStyle(
          fontSize: 13,
          color: textColor,
        ),
      ),
    );

    return analysis;
  }

  String _getTransactionType() {
    if (transaction.data == null || transaction.data == '0x') {
      return 'Simple Transfer';
    }

    final methodId = transaction.data!.substring(0, 10);

    // Common ERC20 method IDs
    switch (methodId) {
      case '0xa9059cbb':
        return 'ERC20 Token Transfer';
      case '0x095ea7b3':
        return 'ERC20 Token Approval';
      case '0x23b872dd':
        return 'ERC20 TransferFrom';
      case '0x70a08231':
        return 'ERC20 Balance Check';
      default:
        return 'Contract Interaction';
    }
  }

  String _getDecodedFunction() {
    if (transaction.data == null || transaction.data == '0x') {
      return 'No function data';
    }

    final methodId = transaction.data!.substring(0, 10);

    // Decode common ERC20 functions
    switch (methodId) {
      case '0xa9059cbb':
        final data = transaction.data!;
        if (data.length >= 138) {
          final address = '0x${data.substring(34, 74)}';
          final amount = BigInt.parse(data.substring(74), radix: 16);
          return 'transfer(\n  address: $address,\n  amount: $amount\n)';
        }
        break;
      case '0x095ea7b3':
        final data = transaction.data!;
        if (data.length >= 138) {
          final spender = '0x${data.substring(34, 74)}';
          final amount = BigInt.parse(data.substring(74), radix: 16);
          return 'approve(\n  spender: $spender,\n  amount: $amount\n)';
        }
        break;
    }

    return 'Unknown Function';
  }

  String _getTransactionComplexity() {
    if (transaction.data == null || transaction.data == '0x') {
      return 'Simple (Direct Transfer)';
    }

    final dataLength = transaction.data!.length;
    final gasUsed = transaction.gasUsed;

    if (dataLength <= 74 && gasUsed <= 30000) {
      return 'Low';
    } else if (dataLength <= 200 && gasUsed <= 100000) {
      return 'Medium';
    } else {
      return 'High';
    }
  }

  Widget _buildErrorSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TransactionSectionHeader(
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
