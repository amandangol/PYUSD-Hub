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
    super.key,
    required this.selectedAsset,
    required this.onAssetSelected,
    required this.estimatedGasFee,
    required this.gasPrice,
    required this.onGasPriceChanged,
    required this.isEstimatingGas,
    required this.ethBalance,
    required this.tokenBalance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: theme.brightness == Brightness.light ? 1 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Asset Selection
            Text(
              'Select Asset',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
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

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Fee',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimated Fee:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        estimatedGasFee > 0
                            ? '${estimatedGasFee.toStringAsFixed(6)} ETH'
                            : 'Enter details below',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Gas price with slider
            Text(
              'Gas Price:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Slow',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                      activeTrackColor: colorScheme.primary,
                      inactiveTrackColor: colorScheme.surfaceVariant,
                      thumbColor: colorScheme.primary,
                      overlayColor: colorScheme.primary.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: gasPrice.clamp(0.5, 20.0),
                      min: 0.5,
                      max: 20.0,
                      divisions: 39,
                      label: '${gasPrice.toStringAsFixed(1)} Gwei',
                      onChanged: onGasPriceChanged,
                    ),
                  ),
                ),
                Text(
                  'Fast',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            // Current gas price display
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 4, bottom: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
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

            // Network information
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Gas prices in Gwei (1 ETH = 10^9 Gwei)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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
