import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/snackbar_utils.dart';

class BalanceCard extends StatelessWidget {
  final double ethBalance;
  final double tokenBalance; // Add PYUSD token balance
  final String walletAddress;
  final bool isRefreshing;
  final Color primaryColor;
  final String networkName;
  final String? connectionType;

  const BalanceCard({
    Key? key,
    required this.ethBalance,
    required this.tokenBalance, // Add this parameter
    required this.walletAddress,
    required this.isRefreshing,
    required this.primaryColor,
    required this.networkName,
    this.connectionType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Define colors based on theme
    final cardColor = isDarkMode
        ? const Color(0xFF222447)
        : theme.colorScheme.primary.withOpacity(0.05);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final labelColor = isDarkMode ? Colors.white70 : Colors.black54;
    final dividerColor = isDarkMode ? Colors.white24 : Colors.black12;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Network indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  networkName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Connection type indicator (if provided)
          if (connectionType != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.6),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    connectionType!.contains('WalletConnect') ||
                            connectionType!.contains('Connected via')
                        ? Icons.link
                        : Icons.account_balance_wallet,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    connectionType!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PYUSD Token Balance Section
                Text(
                  'PYUSD Balance',
                  style: TextStyle(
                    fontSize: 14,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    isRefreshing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primaryColor),
                            ),
                          )
                        : Icon(
                            Icons.monetization_on,
                            color: primaryColor,
                            size: 24,
                          ),
                    const SizedBox(width: 12),
                    Text(
                      '${tokenBalance.toStringAsFixed(2)} PYUSD',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(color: dividerColor),
                const SizedBox(height: 16),

                // ETH Balance Section
                Text(
                  'ETH Balance',
                  style: TextStyle(
                    fontSize: 14,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    isRefreshing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primaryColor),
                            ),
                          )
                        : Icon(
                            Icons.currency_exchange,
                            color: primaryColor,
                            size: 24,
                          ),
                    const SizedBox(width: 12),
                    Text(
                      '${ethBalance.toStringAsFixed(5)} ETH',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: dividerColor),
                const SizedBox(height: 16),

                // Wallet Address Section
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wallet',
                            style: TextStyle(
                              fontSize: 14,
                              color: labelColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatAddress(walletAddress),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.copy,
                        color: primaryColor,
                        size: 20,
                      ),
                      onPressed: () {
                        _copyToClipboard(context, walletAddress);
                      },
                      tooltip: 'Copy Address',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      splashRadius: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(String address) {
    if (address.isEmpty) return 'No wallet connected';
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  void _copyToClipboard(BuildContext context, String text) {
    if (text.isEmpty) return;

    Clipboard.setData(ClipboardData(text: text));
    SnackbarUtil.showSnackbar(
      context: context,
      message: 'Address copied to clipboard',
    );
  }
}
