import 'package:flutter/material.dart';

class AssetSelectionCard extends StatelessWidget {
  final String selectedAsset;
  final double tokenBalance;
  final double ethBalance;
  final Function(String) onAssetSelected;

  const AssetSelectionCard({
    Key? key,
    required this.selectedAsset,
    required this.tokenBalance,
    required this.ethBalance,
    required this.onAssetSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Asset',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AssetOption(
                    assetName: 'PYUSD',
                    isSelected: selectedAsset == 'PYUSD',
                    balance: tokenBalance,
                    onTap: () => onAssetSelected('PYUSD'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AssetOption(
                    assetName: 'ETH',
                    isSelected: selectedAsset == 'ETH',
                    balance: ethBalance,
                    onTap: () => onAssetSelected('ETH'),
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

class _AssetOption extends StatelessWidget {
  final String assetName;
  final bool isSelected;
  final double balance;
  final VoidCallback onTap;

  const _AssetOption({
    required this.assetName,
    required this.isSelected,
    required this.balance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      assetName == 'PYUSD'
                          ? Icons.attach_money
                          : Icons.currency_exchange,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      assetName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${balance.toStringAsFixed(4)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
