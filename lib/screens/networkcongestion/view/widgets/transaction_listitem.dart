import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../utils/formatter_utils.dart';
import '../../../../utils/snackbar_utils.dart';

class TransactionListItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback? onTap;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
  });

  // Helper method to safely parse hex values
  BigInt? _parseHexValue(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    try {
      // Remove '0x' prefix if present and any whitespace
      final cleanValue = value.trim().toLowerCase();
      final hexValue =
          cleanValue.startsWith('0x') ? cleanValue.substring(2) : cleanValue;

      // Handle special case for "0x0" or "0"
      if (hexValue == '0' || hexValue.isEmpty) {
        // print('Zero value detected');
        return BigInt.zero;
      }

      // Ensure the hex value is properly formatted
      final formattedHex =
          hexValue.padLeft(hexValue.length + (hexValue.length % 2), '0');
      // print('Formatted hex: $formattedHex');

      final result = BigInt.parse(formattedHex, radix: 16);
      // print('Parsed result: $result');
      return result;
    } catch (e) {
      print('Error parsing hex value: $e for input: $value');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract transaction data
    final String txHash = transaction['hash'] ?? '';
    final String from = transaction['from'] ?? '';
    final String to = transaction['to'] ?? '';
    final String? blockNumber = transaction['blockNumber'];
    final String? gasPrice = transaction['gasPrice'];

    // Determine if pending or confirmed
    final isPending = blockNumber == null;

    final gasPriceBigInt = _parseHexValue(gasPrice);
    final formattedGasPrice = gasPriceBigInt != null
        ? '${(gasPriceBigInt / BigInt.from(1e9)).toStringAsFixed(2)} Gwei'
        : 'N/A';

    // Format block number with proper hex parsing
    final blockNumberBigInt = _parseHexValue(blockNumber);
    final formattedBlockNumber =
        blockNumberBigInt != null ? blockNumberBigInt.toString() : 'Pending';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPending
              ? Colors.orange.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with transaction hash and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Transaction hash with copy button
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            FormatterUtils.formatHash(txHash),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: txHash));
                            SnackbarUtil.showSnackbar(
                                context: context,
                                message: "Transaction hash copied");
                          },
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPending
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPending ? Icons.pending : Icons.check_circle,
                          size: 12,
                          color: isPending ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPending ? 'Pending' : 'Confirmed',
                          style: TextStyle(
                            fontSize: 12,
                            color: isPending ? Colors.orange : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Transaction details
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // From/To addresses
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAddressRow('From', from),
                        const SizedBox(height: 4),
                        _buildAddressRow('To', to),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Gas info
                  Text(
                    'Gas: $formattedGasPrice',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Block info and timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (blockNumber != null)
                    Text(
                      'Block: $formattedBlockNumber',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () async {
                      final url = Uri.parse('https://etherscan.io/tx/$txHash');
                      try {
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      } catch (e) {
                        SnackbarUtil.showSnackbar(
                            context: context,
                            message: "Could not launch explorer");
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('View on Etherscan'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressRow(String label, String address) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            FormatterUtils.formatHash(address),
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
