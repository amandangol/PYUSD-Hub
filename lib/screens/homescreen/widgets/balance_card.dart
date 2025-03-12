import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/snackbar_utils.dart';

class BalanceCard extends StatelessWidget {
  final double ethBalance;
  final double tokenBalance;
  final String walletAddress;
  final bool isRefreshing;
  final Color primaryColor;
  final String networkName;

  const BalanceCard({
    super.key,
    required this.ethBalance,
    required this.tokenBalance,
    required this.walletAddress,
    required this.isRefreshing,
    required this.primaryColor,
    required this.networkName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // PayPal colors
    const paypalBlue = Color(0xFF142C8E);
    const paypalLightBlue = Color(0xFF253B80);

    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? const [Color(0xFF142C8E), Color(0xFF253B80)]
                : const [Colors.white, Color(0xFFF5F7FA)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            // PayPal-style decorative elements
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.03)
                      : paypalBlue.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -15,
              left: -15,
              child: Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.02)
                      : paypalBlue.withOpacity(0.03),
                ),
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card header with logo-like element
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDarkMode ? paypalLightBlue : paypalBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PYUSD',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : paypalBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : paypalBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.2)
                                : paypalBlue.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          networkName,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : paypalBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Balance label
                  Text(
                    'Available Balance',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Main balance display
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: isRefreshing
                            ? SizedBox(
                                height: 32,
                                width: 32,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      isDarkMode ? Colors.white : paypalBlue),
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                children: [
                                  Text(
                                    '\$',
                                    key: const ValueKey('dollar'),
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : paypalBlue,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    tokenBalance.toStringAsFixed(2),
                                    key: ValueKey(tokenBalance),
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 38,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      const Spacer(),

                      // ETH balance pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.08)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.currency_exchange,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${ethBalance.toStringAsFixed(4)} ETH',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Divider like PayPal
                  Divider(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    thickness: 1,
                  ),

                  const SizedBox(height: 16),

                  // Wallet address section - PayPal style
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.08)
                              : paypalBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: isDarkMode ? Colors.white70 : paypalBlue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wallet Address',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              walletAddress.isEmpty
                                  ? 'No wallet connected'
                                  : '${walletAddress.substring(0, 10)}...${walletAddress.substring(walletAddress.length - 6)}',
                              style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1,
                                  fontFamily: "monospace"),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: walletAddress));
                          SnackbarUtil.showSnackbar(
                            context: context,
                            message: "Address copied to clipboard",
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.08)
                                : paypalBlue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.copy_rounded,
                            color: isDarkMode ? Colors.white70 : paypalBlue,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
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
