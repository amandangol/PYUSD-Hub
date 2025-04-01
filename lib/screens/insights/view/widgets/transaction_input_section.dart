import 'package:flutter/material.dart';
import '../../../../widgets/pyusd_components.dart';
import '../../../../providers/network_provider.dart';

class TransactionInputSection extends StatelessWidget {
  final TextEditingController txHashController;
  final TextEditingController addressController;
  final NetworkType? detectedNetwork;
  final VoidCallback onPasteTxHash;
  final VoidCallback onPasteAddress;

  const TransactionInputSection({
    super.key,
    required this.txHashController,
    required this.addressController,
    required this.detectedNetwork,
    required this.onPasteTxHash,
    required this.onPasteAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PyusdCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Transaction Hash',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PyusdTextField(
                controller: txHashController,
                labelText: 'Enter Transaction Hash',
                hintText: '0x...',
                prefixIcon: const Icon(Icons.receipt_long),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: onPasteTxHash,
                ),
              ),
              if (detectedNetwork != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Transaction found on:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: detectedNetwork == NetworkType.ethereumMainnet
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: detectedNetwork == NetworkType.ethereumMainnet
                              ? Colors.blue
                              : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            detectedNetwork == NetworkType.ethereumMainnet
                                ? Icons.public
                                : Icons.science,
                            size: 16,
                            color:
                                detectedNetwork == NetworkType.ethereumMainnet
                                    ? Colors.blue
                                    : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            detectedNetwork == NetworkType.ethereumMainnet
                                ? 'Mainnet'
                                : 'Sepolia',
                            style: TextStyle(
                              color:
                                  detectedNetwork == NetworkType.ethereumMainnet
                                      ? Colors.blue
                                      : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        PyusdCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Your Wallet (Optional)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PyusdTextField(
                controller: addressController,
                labelText: 'Enter Your Address',
                hintText: '0x...',
                prefixIcon: const Icon(Icons.account_balance_wallet),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: onPasteAddress,
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
                      'Enter your address to determine transaction direction',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
