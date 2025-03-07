import 'package:flutter/material.dart';

class BalanceDisplayCard extends StatelessWidget {
  final String selectedAsset;
  final double availableBalance;
  final double maxSendableEth;
  final double estimatedGasFee;
  final String networkName;

  const BalanceDisplayCard({
    Key? key,
    required this.selectedAsset,
    required this.availableBalance,
    required this.maxSendableEth,
    required this.estimatedGasFee,
    required this.networkName,
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
          children: [
            Text(
              'Available Balance',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              selectedAsset == 'ETH'
                  ? '${availableBalance.toStringAsFixed(6)} ETH'
                  : '${availableBalance.toStringAsFixed(6)} PYUSD',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            if (selectedAsset == 'ETH' && estimatedGasFee > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Max sendable (after gas): ${maxSendableEth.toStringAsFixed(6)} ETH',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Network: $networkName',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
