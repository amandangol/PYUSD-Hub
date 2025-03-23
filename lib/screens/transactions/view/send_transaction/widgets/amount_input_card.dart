import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../common/widgets/pyusd_components.dart';
import 'custom_textfield.dart';

class AmountCard extends StatelessWidget {
  final TextEditingController amountController;
  final String selectedAsset;
  final double availableBalance;
  final double maxSendableEth;
  final double estimatedGasFee;
  final Function(String) onAmountChanged;
  final VoidCallback onMaxPressed;

  const AmountCard({
    super.key,
    required this.amountController,
    required this.selectedAsset,
    required this.availableBalance,
    required this.maxSendableEth,
    required this.onAmountChanged,
    required this.onMaxPressed,
    required this.estimatedGasFee,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PyusdCard(
      borderRadius: 12,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextField(
                  controller: amountController,
                  labelText: 'Amount',
                  hintText: 'Enter amount',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,6}$')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Invalid amount';
                    }

                    if (selectedAsset == 'ETH') {
                      // For ETH, check if amount + gas fee exceeds balance
                      if (amount > maxSendableEth) {
                        return 'Amount exceeds max sendable (gas fee included)';
                      }
                    } else {
                      // For PYUSD, just check token balance
                      if (amount > availableBalance) {
                        return 'Insufficient balance';
                      }
                    }
                    return null;
                  },
                  onChanged: onAmountChanged,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onMaxPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                ),
                child: const Text('MAX'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (selectedAsset == 'ETH' && estimatedGasFee > 0)
            Text(
              'Available: ${maxSendableEth.toStringAsFixed(6)} ETH (after gas fees)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            Text(
              'Balance: ${availableBalance.toStringAsFixed(4)} $selectedAsset',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
