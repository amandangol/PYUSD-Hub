import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../model/transaction_model.dart';

class GasDetailsWidget extends StatelessWidget {
  final TransactionDetailModel transaction;
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;

  const GasDetailsWidget({
    super.key,
    required this.transaction,
    required this.isDarkMode,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_gas_station_outlined,
                  size: 18,
                  color: isDarkMode ? Colors.orange : Colors.deepOrange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Gas Information',
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
              title: 'Gas Limit',
              value: '${transaction.gasUsed.toStringAsFixed(0)} units',
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildDetailRow(
              title: 'Gas Used',
              value: '${transaction.gasUsed.toStringAsFixed(0)} units',
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildDetailRow(
              title: 'Gas Price',
              value: '${transaction.gasPrice.toStringAsFixed(9)} Gwei',
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildDetailRow(
              title: 'Gas Efficiency',
              value: _calculateGasEfficiency(),
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildDetailRow(
              title: 'Transaction Fee',
              value: '${transaction.fee.toStringAsFixed(8)} ETH',
              valueColor: isDarkMode ? Colors.orange : Colors.deepOrange,
              textColor: textColor,
              subtitleColor: subtitleColor,
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
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   const SnackBar(content: Text('Copied to clipboard')),
                  // );
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

  String _calculateGasEfficiency() {
    // Check if gasPrice is not zero to avoid division by zero
    if (transaction.gasPrice <= 0) {
      return 'N/A';
    }

    // Calculate what percentage of the gas limit was actually used
    final double gasLimit =
        transaction.gasUsed; // Assuming gasUsed here is actually gas limit
    final double gasUsed = transaction.gasUsed;

    // If we have both values, calculate efficiency
    if (gasLimit > 0 && gasUsed > 0) {
      final double efficiency = (gasUsed / gasLimit) * 100;
      return '${efficiency.toStringAsFixed(1)}%';
    }

    return 'N/A';
  }
}
