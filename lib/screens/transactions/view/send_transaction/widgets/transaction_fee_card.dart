import 'package:flutter/material.dart';
import 'asset_selection_card.dart';

class TransactionFeeCard extends StatelessWidget {
  final String selectedAsset;
  final Function(String) onAssetSelected;
  final double estimatedGasFee;
  final double gasPrice;
  final Function(double) onGasPriceChanged;
  final bool isEstimatingGas;
  final double ethBalance;
  final double tokenBalance;

  const TransactionFeeCard({
    Key? key,
    required this.selectedAsset,
    required this.onAssetSelected,
    required this.estimatedGasFee,
    required this.gasPrice,
    required this.onGasPriceChanged,
    required this.isEstimatingGas,
    required this.ethBalance,
    required this.tokenBalance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Asset Selection
            Text(
              'Select Asset',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AssetSelectionCard(
                    assetName: 'PYUSD',
                    isSelected: selectedAsset == 'PYUSD',
                    balance: tokenBalance,
                    onTap: () => onAssetSelected('PYUSD'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AssetSelectionCard(
                    assetName: 'ETH',
                    isSelected: selectedAsset == 'ETH',
                    balance: ethBalance,
                    onTap: () => onAssetSelected('ETH'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Fee',
                  style: theme.textTheme.titleMedium,
                ),
                if (isEstimatingGas)
                  SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Fee estimation card with gradient background
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.surfaceVariant,
                    colorScheme.primaryContainer.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimated Fee:',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        estimatedGasFee > 0
                            ? '${estimatedGasFee.toStringAsFixed(6)} ETH'
                            : 'Enter details below',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Gas price with slider
            Text(
              'Gas Price:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Slow', style: theme.textTheme.bodySmall),
                Expanded(
                  child: Slider(
                    value: gasPrice.clamp(0.5, 20.0),
                    min: 0.5,
                    max: 20.0,
                    divisions: 40,
                    label: '${gasPrice.toStringAsFixed(1)} Gwei',
                    onChanged: onGasPriceChanged,
                  ),
                ),
                Text('Fast', style: theme.textTheme.bodySmall),
              ],
            ),

            // Current gas price display
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${gasPrice.toStringAsFixed(1)} Gwei',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Network information
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'Gas prices in Gwei (1 ETH = 10^9 Gwei)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
