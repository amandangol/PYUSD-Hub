import 'package:flutter/material.dart';
import '../../../model/transaction_model.dart';
import 'common/transaction_common_widgets.dart';

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
    final txValueUsd =
        currentPrice > 0 ? transaction.amount * currentPrice : 0.0;
    final ethPrice = marketPrices['ETH'] ?? 0.0;
    final gasFeeUsd = ethPrice > 0 ? transaction.fee * ethPrice : 0.0;

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
            // Header with improved visual hierarchy
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics_outlined,
                        size: 22, color: primaryColor),
                    const SizedBox(width: 10),
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
                if (!isLoadingMarketData && marketPrices.isNotEmpty)
                  Text(
                    'Live Data',
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            const Divider(height: 30),

            // Market data section
            if (isLoadingMarketData)
              _buildLoadingIndicator()
            else if (marketPrices.isEmpty)
              _buildNoDataView()
            else
              _buildMarketDataSection(
                  tokenSymbol, currentPrice, txValueUsd, gasFeeUsd, context),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            color: subtitleColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            'Market data not available',
            style: TextStyle(
              color: subtitleColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            strokeWidth: 3,
          ),
          const SizedBox(height: 10),
          Text(
            'Loading market data...',
            style: TextStyle(
              color: subtitleColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketDataSection(String tokenSymbol, double currentPrice,
      double txValueUsd, double gasFeeUsd, BuildContext context) {
    final valueToFeeRatio = _calculateValueToFeeRatio();
    final ratioColor = _getValueToFeeRatioColor();
    final ratioDescription = _getValueToFeeRatioDescription();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current market info
        _buildDetailRow(
          icon: Icons.currency_exchange,
          title: '$tokenSymbol Price',
          value: '\$${currentPrice.toStringAsFixed(4)} USD',
          textColor: textColor,
          subtitleColor: subtitleColor,
          valueColor: primaryColor,
          infoMessage: 'Current market price of $tokenSymbol in USD',
        ),

        // Transaction value at current price (with change indicator if available)
        _buildDetailRow(
          icon: Icons.account_balance_wallet,
          title: 'Current Value',
          value: '\$${txValueUsd.toStringAsFixed(4)} USD',
          textColor: textColor,
          subtitleColor: subtitleColor,
          valueColor: primaryColor,
          infoMessage: 'Current USD value of the transaction amount',
        ),

        // Gas fee with better explanation
        _buildDetailRow(
          icon: Icons.local_gas_station,
          title: 'Network Fee',
          value: '\$${gasFeeUsd.toStringAsFixed(4)} USD',
          textColor: textColor,
          subtitleColor: subtitleColor,
          infoMessage: 'Current USD value of the network fee (gas)',
        ),

        const SizedBox(height: 10),
        const Divider(height: 10),
        const SizedBox(height: 10),

        // Transaction efficiency with explanation
        if (valueToFeeRatio != 'N/A')
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Efficiency metric with header
              TransactionSectionHeader(
                icon: Icons.speed,
                title: 'Transaction Efficiency',
                iconColor: ratioColor,
                textColor: textColor,
                infoMessage:
                    'Measures how efficiently the transaction value compares to its network fee. Higher ratios indicate better cost-effectiveness.',
              ),
              const SizedBox(height: 10),

              // Value/Fee visualization
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: ratioColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Value/Fee Ratio:',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          valueToFeeRatio,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ratioColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ratioDescription,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required Color textColor,
    required Color subtitleColor,
    Color? valueColor,
    String? infoMessage,
  }) {
    return TransactionDetailRow(
      icon: icon,
      title: title,
      value: value,
      infoMessage: infoMessage ?? '',
      textColor: textColor,
      subtitleColor: subtitleColor,
      valueColor: valueColor,
    );
  }

  /// Calculates the ratio between transaction value and network fee in USD terms.
  /// This ratio helps evaluate the efficiency of the transaction:
  /// - Higher ratios (e.g., >50x) indicate very efficient transactions
  /// - Lower ratios (e.g., <10x) suggest the fee might be high relative to the value
  /// - Ratios <1x indicate the fee exceeds the transaction value
  String _calculateValueToFeeRatio() {
    const double epsilon =
        0.000001; // Small value to prevent division by very small numbers
    final ethPrice = marketPrices['ETH'] ?? 0.0;

    if (ethPrice <= 0 || transaction.fee <= 0) return 'N/A';

    // For token transactions
    if (transaction.tokenSymbol != null) {
      final tokenPrice = marketPrices[transaction.tokenSymbol!] ?? 0.0;
      if (tokenPrice <= 0) return 'N/A';

      final txValueUsd = transaction.amount * tokenPrice;
      final feeValueUsd = transaction.fee * ethPrice;

      if (feeValueUsd <= epsilon) return 'N/A';

      final ratio = txValueUsd / feeValueUsd;
      // Use more precision for small ratios, less for large ones
      if (ratio < 1) {
        return '${ratio.toStringAsFixed(2)}x';
      } else if (ratio < 10) {
        return '${ratio.toStringAsFixed(1)}x';
      } else {
        return '${ratio.toStringAsFixed(0)}x';
      }
    }
    // For ETH transactions
    else {
      final txValueUsd = transaction.amount * ethPrice;
      final feeValueUsd = transaction.fee * ethPrice;

      if (feeValueUsd <= epsilon) return 'N/A';

      final ratio = txValueUsd / feeValueUsd;
      // Use more precision for small ratios, less for large ones
      if (ratio < 1) {
        return '${ratio.toStringAsFixed(2)}x';
      } else if (ratio < 10) {
        return '${ratio.toStringAsFixed(1)}x';
      } else {
        return '${ratio.toStringAsFixed(0)}x';
      }
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

  String _getValueToFeeRatioDescription() {
    try {
      final ratioText = _calculateValueToFeeRatio();
      if (ratioText == 'N/A') return 'Unable to calculate efficiency ratio';

      final ratio = double.parse(ratioText.replaceAll('x', ''));

      if (ratio < 1) {
        return 'The network fee exceeds the transaction value. This may not be cost-effective.';
      }
      if (ratio < 10) {
        return 'The transaction value is higher than the fee, but the ratio is relatively low.';
      }
      if (ratio < 50) {
        return 'Good efficiency ratio. The transaction value significantly exceeds the network fee.';
      }
      return 'Excellent efficiency ratio. The transaction value far outweighs the network fee.';
    } catch (_) {
      return 'Unable to calculate efficiency ratio';
    }
  }
}
