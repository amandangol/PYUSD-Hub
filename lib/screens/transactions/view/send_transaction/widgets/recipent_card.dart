import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pyusd_hub/widgets/pyusd_components.dart';
import 'package:web3dart/web3dart.dart';
import 'custom_textfield.dart';

class RecipientCard extends StatefulWidget {
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
  State<RecipientCard> createState() => _RecipientCardState();
}

class _RecipientCardState extends State<RecipientCard> {
  // Function to handle paste from clipboard
  Future<void> _pasteFromClipboard() async {
    final ClipboardData? clipboardData =
        await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      final pastedText = clipboardData.text!.trim();
      widget.addressController.text = pastedText;
      widget.onAddressChanged(pastedText);
    }
  }

  // Helper method to check if an address is valid
  bool _validateEthereumAddress(String address) {
    if (address.isEmpty) return false;

    // Check if the address starts with '0x' and has the correct length
    if (!address.startsWith('0x') || address.length != 42) return false;

    // Check if the address contains only valid hexadecimal characters
    final validHexPattern = RegExp(r'^0x[0-9a-fA-F]{40}$');
    if (!validHexPattern.hasMatch(address)) return false;

    try {
      EthereumAddress.fromHex(address);
      return true;
    } catch (e) {
      return false;
    }
  }

  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a recipient address';
    }
    if (!value.startsWith('0x')) {
      return 'Address must start with 0x';
    }
    if (value.length != 42) {
      return 'Address must be 42 characters long';
    }
    if (!_validateEthereumAddress(value)) {
      return 'Invalid Ethereum address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PyusdCard(
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
                  controller: widget.addressController,
                  labelText: 'Recipient Address',
                  hintText: '0x...',
                  validator: _validateAddress,
                  onChanged: (value) {
                    widget.onAddressChanged(value);
                  },
                  prefixIcon: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: widget.isValidAddress
                        ? Colors.green
                        : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isValidAddress)
                        Container(
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
                        ),
                      // Paste button
                      IconButton(
                        icon: Icon(
                          Icons.content_paste,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: _pasteFromClipboard,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        splashRadius: 20,
                      ),
                    ],
                  ),
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
                  onPressed: widget.onScanQRCode,
                  icon: Icon(
                    Icons.qr_code_scanner,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          // // // Only show validation message when we have a complete and valid address
          // // if (widget.addressController.text.length == 42 &&
          // //     widget.isValidAddress) ...[
          // //   const SizedBox(height: 8),
          // //   Container(
          // //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          // //     decoration: BoxDecoration(
          // //       color: Colors.green.withOpacity(0.1),
          // //       borderRadius: BorderRadius.circular(8),
          // //     ),
          // //     child: Row(
          // //       children: [
          // //         const Icon(
          // //           Icons.check_circle_outline,
          // //           color: Colors.green,
          // //           size: 16,
          // //         ),
          // //         const SizedBox(width: 8),
          // //         Expanded(
          // //           child: Text(
          // //             'Valid Ethereum address',
          // //             style: theme.textTheme.bodySmall?.copyWith(
          // //               color: Colors.green,
          // //             ),
          // //           ),
          // //         ),
          // //       ],
          // //     ),
          // //   ),
          // ],
        ],
      ),
    );
  }
}
