import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'custom_textfield.dart';

class RecipientCard extends StatelessWidget {
  final TextEditingController addressController;
  final bool isValidAddress;
  final Function(String) onAddressChanged;
  final VoidCallback onScanQRCode;

  const RecipientCard({
    super.key,
    required this.addressController,
    required this.isValidAddress,
    required this.onAddressChanged,
    required this.onScanQRCode,
  });

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
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recipient Details',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: addressController,
                    labelText: 'Recipient Address',
                    hintText: '0x...',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a recipient address';
                      }
                      try {
                        EthereumAddress.fromHex(value);
                        return null;
                      } catch (e) {
                        return 'Invalid Ethereum address';
                      }
                    },
                    onChanged: onAddressChanged,
                    prefixIcon: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: isValidAddress
                          ? Colors.green
                          : colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    suffixIcon: isValidAddress
                        ? Container(
                            margin: const EdgeInsets.all(14),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: onScanQRCode,
                    icon: Icon(
                      Icons.qr_code_scanner,
                      color: colorScheme.primary,
                    ),
                    tooltip: 'Scan QR Code',
                  ),
                ),
              ],
            ),
            if (isValidAddress) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Valid Ethereum address',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
