import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../model/transaction_model.dart';
import 'common/transaction_common_widgets.dart';

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
    final gasColor = isDarkMode ? Colors.orange : Colors.deepOrange;
    final efficiency = _calculateGasEfficiencyValue();
    final efficiencyColor = _getEfficiencyColor(efficiency);

    return TransactionCard(
      cardColor: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          TransactionSectionHeader(
            icon: Icons.local_gas_station_outlined,
            title: 'Gas Information',
            iconColor: gasColor,
            textColor: textColor,
            infoMessage:
                'Detailed information about gas usage, price, and efficiency of this transaction',
          ),
          const Divider(height: 30),

          // Gas visualization section
          _buildGasVisualizer(efficiency, efficiencyColor, gasColor),
          const SizedBox(height: 20),

          // Gas details section
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: subtitleColor.withOpacity(0.1), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gas limit and usage
                TransactionDetailRow(
                  icon: Icons.speed_outlined,
                  title: 'Gas Limit',
                  value: '${transaction.gasLimit.toStringAsFixed(0)} units',
                  infoMessage:
                      'Maximum amount of gas units allocated for this transaction. If exceeded, the transaction will fail.',
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                ),
                TransactionDetailRow(
                  icon: Icons.data_usage_outlined,
                  title: 'Gas Used',
                  value: '${transaction.gasUsed.toStringAsFixed(0)} units',
                  infoMessage:
                      'Actual gas units consumed by this transaction. This is what you pay for.',
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                ),

                // Gas price
                TransactionDetailRow(
                  icon: Icons.attach_money_outlined,
                  title: 'Gas Price',
                  value:
                      '${transaction.gasPrice.toStringAsFixed(4)} Gwei (${(transaction.gasPrice * 0.000000001).toStringAsFixed(9)} ETH)',
                  infoMessage:
                      'Price paid per unit of gas. Higher gas price means faster transaction processing but higher cost.',
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                ),

                // Transaction fee with calculation breakdown
                TransactionDetailRow(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Total Fee',
                  value: '${transaction.fee.toStringAsFixed(9)} ETH',
                  infoMessage:
                      'Total transaction fee calculated as Gas Used × Gas Price. This is the actual cost of the transaction.',
                  valueColor: gasColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  isHighlighted: true,
                ),
              ],
            ),
          ),

          // Fee calculation explanation
          const SizedBox(height: 16),
          Text(
            'Gas Fee Calculation',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gas Used (${transaction.gasUsed.toStringAsFixed(0)}) × Gas Price (${transaction.gasPrice.toStringAsFixed(2)} Gwei = ${(transaction.gasPrice * 0.000000001).toStringAsFixed(9)} ETH) = ${transaction.fee.toStringAsFixed(8)} ETH',
            style: TextStyle(
              fontSize: 13,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGasVisualizer(
      double efficiency, Color efficiencyColor, Color gasColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gas Efficiency',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: efficiencyColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${efficiency.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: efficiencyColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Gas usage progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: efficiency / 100,
            backgroundColor: subtitleColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(efficiencyColor),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getEfficiencyDescription(efficiency),
          style: TextStyle(
            fontSize: 13,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }

  double _calculateGasEfficiencyValue() {
    // Check if gasLimit is not zero to avoid division by zero
    if (transaction.gasLimit <= 0) {
      return 0;
    }

    // Calculate what percentage of the gas limit was actually used
    return (transaction.gasUsed / transaction.gasLimit) * 100;
  }

  Color _getEfficiencyColor(double efficiency) {
    if (efficiency < 60) {
      return Colors.red; // Poor efficiency
    } else if (efficiency < 80) {
      return Colors.orange; // Moderate efficiency
    } else if (efficiency < 95) {
      return Colors.green; // Good efficiency
    } else {
      return Colors.red; // Too close to limit (risky)
    }
  }

  String _getEfficiencyDescription(double efficiency) {
    if (efficiency < 60) {
      return 'Low gas utilization. You allocated more gas than needed, which doesnt cost extra but could be optimized in future transactions.';
    } else if (efficiency < 80) {
      return 'Moderate gas utilization. A reasonable buffer was included between gas used and gas limit.';
    } else if (efficiency < 95) {
      return 'Efficient gas utilization. Gas allocation was close to actual usage with a safe margin.';
    } else {
      return 'Transaction used almost all allocated gas. This could be risky as it might have failed if more gas was needed.';
    }
  }
}
