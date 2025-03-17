import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../providers/wallet_provider.dart';

class SendButton extends StatelessWidget {
  final String selectedAsset;
  final bool isValidAddress;
  final TextEditingController amountController;
  final bool isLoading;
  final bool isEstimatingGas;
  final double estimatedGasFee;
  final Function onPressed;

  const SendButton({
    Key? key,
    required this.selectedAsset,
    required this.isValidAddress,
    required this.amountController,
    required this.isLoading,
    required this.isEstimatingGas,
    required this.estimatedGasFee,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool canSend = isValidAddress &&
        amountController.text.isNotEmpty &&
        !isEstimatingGas &&
        !(selectedAsset == 'PYUSD' &&
            estimatedGasFee > walletProvider.ethBalance &&
            estimatedGasFee > 0) &&
        !(selectedAsset == 'ETH' &&
            double.tryParse(amountController.text) != null &&
            double.parse(amountController.text) + estimatedGasFee >
                walletProvider.ethBalance);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canSend ? () => onPressed() : null,
        style: ElevatedButton.styleFrom(
          elevation: canSend ? 4 : 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colorScheme.surfaceVariant,
          disabledForegroundColor: colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: canSend
                ? LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary
                          .withBlue(colorScheme.primary.blue + 20)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.send_rounded,
                  color: canSend ? Colors.white : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Send $selectedAsset',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        canSend ? Colors.white : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
