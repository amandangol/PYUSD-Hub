import 'package:flutter/material.dart';
import '../../../../widgets/pyusd_components.dart';
import '../../../../providers/network_provider.dart';
import '../../../../screens/transactions/model/transaction_model.dart'
    as tx_model;

// Helper extension to convert model status to display text
extension TransactionStatusDisplay on tx_model.TransactionStatus {
  String toDisplayText() {
    switch (this) {
      case tx_model.TransactionStatus.pending:
        return 'Pending';
      case tx_model.TransactionStatus.confirmed:
        return 'Success';
      case tx_model.TransactionStatus.failed:
        return 'Failed';
    }
  }

  Color toColor() {
    switch (this) {
      case tx_model.TransactionStatus.pending:
        return Colors.orange;
      case tx_model.TransactionStatus.confirmed:
        return Colors.green;
      case tx_model.TransactionStatus.failed:
        return Colors.red;
    }
  }
}

// Helper extension to convert model direction to display text
extension TransactionDirectionDisplay on tx_model.TransactionDirection {
  String toDisplayText() {
    switch (this) {
      case tx_model.TransactionDirection.incoming:
        return 'INCOMING';
      case tx_model.TransactionDirection.outgoing:
        return 'OUTGOING';
    }
  }
}

class TransactionDetailsCard extends StatelessWidget {
  final tx_model.TransactionDetailModel txDetails;
  final Map<String, dynamic>? tokenDetails;

  const TransactionDetailsCard({
    super.key,
    required this.txDetails,
    this.tokenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMainnet = txDetails.network == NetworkType.ethereumMainnet;

    // Calculate total gas cost in ETH
    final gasUsedBigInt = BigInt.from(txDetails.gasUsed);
    final gasPriceWei =
        BigInt.from(txDetails.gasPrice).pow(9); // Convert Gwei to Wei
    final gasCostWei = gasUsedBigInt * gasPriceWei;
    final gasCostEth =
        (gasCostWei.toDouble() / BigInt.from(10).pow(18).toDouble())
            .toStringAsFixed(8);

    return PyusdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Transaction Details',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isMainnet
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isMainnet ? Colors.blue : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMainnet ? Icons.public : Icons.science,
                      size: 16,
                      color: isMainnet ? Colors.blue : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isMainnet ? 'Mainnet' : 'Sepolia',
                      style: TextStyle(
                        color: isMainnet ? Colors.blue : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildDetailRow(context, 'Hash', txDetails.hash, copyable: true),
          _buildDetailRow(context, 'Status', txDetails.status.toDisplayText(),
              status: txDetails.status),
          _buildDetailRow(context, 'From', txDetails.from, copyable: true),
          _buildDetailRow(context, 'To', txDetails.to, copyable: true),
          if (txDetails.tokenSymbol != null) ...[
            _buildDetailRow(context, 'Token',
                '${txDetails.tokenSymbol}${txDetails.tokenName != null ? ' (${txDetails.tokenName})' : ''}'),
            if (tokenDetails != null) ...[
              _buildDetailRow(
                  context, 'Token Contract', tokenDetails!['address'],
                  copyable: true),
              _buildDetailRow(
                  context, 'Decimals', tokenDetails!['decimals'].toString()),
              _buildDetailRow(
                  context, 'Total Supply', tokenDetails!['totalSupply']),
            ],
          ],
          _buildDetailRow(context, 'Amount',
              '${txDetails.amount} ${txDetails.tokenSymbol ?? 'ETH'}'),
          _buildDetailRow(context, 'Gas Used', '${txDetails.gasUsed} units'),
          _buildDetailRow(context, 'Gas Price', '${txDetails.gasPrice} Gwei'),
          _buildDetailRow(context, 'Total Gas Cost', '$gasCostEth ETH'),
          _buildDetailRow(context, 'Block', '#${txDetails.blockNumber}'),
          _buildDetailRow(
              context, 'Timestamp', txDetails.timestamp.toLocal().toString()),
          _buildDetailRow(
              context, 'Direction', txDetails.direction.toDisplayText()),
          if (txDetails.isError) ...[
            const SizedBox(height: 8),
            PyusdErrorMessage(
              message: txDetails.errorMessage ?? 'Transaction failed',
              padding: const EdgeInsets.all(12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value,
      {bool copyable = false, tx_model.TransactionStatus? status}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(value),
                ),
                if (copyable)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      // TODO: Implement copy functionality
                    },
                  ),
                if (status != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: status.toColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toDisplayText(),
                      style: TextStyle(
                        color: status.toColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
