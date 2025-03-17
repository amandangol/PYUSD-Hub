import 'package:flutter/material.dart';
import '../../../model/transaction_model.dart';

class MarketAnalysisWidget extends StatelessWidget {
  final TransactionDetailModel transaction;
  final Map<String, double> marketPrices;
  final bool isLoadingMarketData;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final Color primaryColor;

  const MarketAnalysisWidget({
    super.key,
    required this.transaction,
    required this.marketPrices,
    required this.isLoadingMarketData,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokenSymbol = transaction.tokenSymbol ?? 'ETH';
    final currentPrice = marketPrices[tokenSymbol] ?? 0.0;

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
                Icon(Icons.trending_up, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Market Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current market value
            _buildDetailRow(
              title: 'Current Price',
              value: isLoadingMarketData
                  ? 'Loading...'
                  : '\$${currentPrice.toStringAsFixed(6)} USD',
              textColor: textColor,
              subtitleColor: subtitleColor,
              valueColor: primaryColor,
            ),

            // Transaction value at current price
            _buildDetailRow(
              title: 'Value Now',
              value: currentPrice <= 0 || isLoadingMarketData
                  ? 'Loading...'
                  : '\$${(transaction.amount * currentPrice).toStringAsFixed(6)} USD',
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),

            // Gas fee in USD
            _buildDetailRow(
              title: 'Gas Fee (USD)',
              value: marketPrices['ETH'] == null || isLoadingMarketData
                  ? 'Loading...'
                  : '\$${(transaction.fee * marketPrices['ETH']!).toStringAsFixed(6)} USD',
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),

            // Transaction efficiency (value to fee ratio)
            if (!isLoadingMarketData &&
                marketPrices['ETH'] != null &&
                marketPrices['ETH']! > 0)
              _buildDetailRow(
                title: 'Value/Fee Ratio',
                value: _calculateValueToFeeRatio(),
                textColor: textColor,
                subtitleColor: subtitleColor,
                valueColor: _getValueToFeeRatioColor(),
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
            InkWell(
              onTap: () {},
              child: Icon(
                Icons.copy_outlined,
                size: 16,
                color: subtitleColor,
              ),
            ),
        ],
      ),
    );
  }

  String _calculateValueToFeeRatio() {
    final ethPrice = marketPrices['ETH'] ?? 0.0;

    if (ethPrice <= 0 || transaction.fee <= 0) return 'N/A';

    // For token transactions
    if (transaction.tokenSymbol != null) {
      final tokenPrice = marketPrices[transaction.tokenSymbol!] ?? 0.0;
      if (tokenPrice <= 0) return 'N/A';

      final txValueUsd = transaction.amount * tokenPrice;
      final feeValueUsd = transaction.fee * ethPrice;

      if (feeValueUsd <= 0) return 'N/A';

      final ratio = txValueUsd / feeValueUsd;
      return ratio.toStringAsFixed(1) + 'x';
    }
    // For ETH transactions
    else {
      final txValueUsd = transaction.amount * ethPrice;
      final feeValueUsd = transaction.fee * ethPrice;

      if (feeValueUsd <= 0) return 'N/A';

      final ratio = txValueUsd / feeValueUsd;
      return ratio.toStringAsFixed(1) + 'x';
    }
  }

  Color _getValueToFeeRatioColor() {
    try {
      final ratioText = _calculateValueToFeeRatio();
      if (ratioText == 'N/A') return Colors.grey;

      final ratio = double.parse(ratioText.replaceAll('x', ''));

      if (ratio < 1) return Colors.red;
      if (ratio < 10) return Colors.orange;
      if (ratio < 50) return Colors.green;
      return Colors.blue;
    } catch (_) {
      return Colors.grey;
    }
  }
}
