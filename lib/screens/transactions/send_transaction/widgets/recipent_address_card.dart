import 'package:flutter/material.dart';
import '../../../homescreen/widgets/custom_textfield.dart';
import 'package:web3dart/web3dart.dart';

class RecipientAddressCard extends StatelessWidget {
  final TextEditingController addressController;
  final bool isValidAddress;
  final Function(String) onAddressChanged;
  final VoidCallback onScanQR;

  const RecipientAddressCard({
    Key? key,
    required this.addressController,
    required this.isValidAddress,
    required this.onAddressChanged,
    required this.onScanQR,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              'Recipient Details',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
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
                    suffixIcon: isValidAddress
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                _ScanQRButton(onTap: onScanQR),
              ],
            ),
            if (isValidAddress)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Valid address',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScanQRButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ScanQRButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.primaryContainer,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: const Icon(Icons.qr_code_scanner),
        tooltip: 'Scan QR Code',
        style: IconButton.styleFrom(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
