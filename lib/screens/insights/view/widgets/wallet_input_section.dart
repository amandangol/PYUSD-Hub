import 'package:flutter/material.dart';
import '../../../../widgets/pyusd_components.dart';

class WalletInputSection extends StatelessWidget {
  final TextEditingController addressController;
  final VoidCallback onPaste;
  final VoidCallback onScanQR;

  const WalletInputSection({
    super.key,
    required this.addressController,
    required this.onPaste,
    required this.onScanQR,
  });

  @override
  Widget build(BuildContext context) {
    return PyusdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Wallet Address',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          PyusdTextField(
            controller: addressController,
            labelText: 'Enter Ethereum Address',
            hintText: '0x...',
            prefixIcon: const Icon(Icons.account_balance_wallet),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: onPaste,
                  tooltip: 'Paste from clipboard',
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: onScanQR,
                  tooltip: 'Scan QR code',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'We\'ll analyze the latest transactions and token holdings for this wallet',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
