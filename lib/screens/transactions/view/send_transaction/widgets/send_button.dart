import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../common/widgets/pyusd_components.dart';
import '../../../../../providers/wallet_provider.dart';

class SendButton extends StatelessWidget {
  final String selectedAsset;
  final bool isValidAddress;
  final TextEditingController amountController;
  final bool isLoading;
  final bool isEstimatingGas;
  final double estimatedGasFee;
  final VoidCallback onPressed;

  const SendButton({
    super.key,
    required this.selectedAsset,
    required this.isValidAddress,
    required this.amountController,
    required this.isLoading,
    required this.isEstimatingGas,
    required this.estimatedGasFee,
    required this.onPressed,
  });

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

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: PyusdButton(
        onPressed: canSend ? () => onPressed() : null,
        text: 'Send $selectedAsset',
        isLoading: isLoading,
        icon: const Icon(Icons.send_rounded),
        backgroundColor:
            canSend ? colorScheme.primary : colorScheme.surfaceContainerHighest,
        foregroundColor: canSend ? Colors.white : colorScheme.onSurfaceVariant,
        elevation: canSend ? 4 : 0,
        borderRadius: 16,
        height: 56,
        isFullWidth: true,
      ),
    );
  }
}
