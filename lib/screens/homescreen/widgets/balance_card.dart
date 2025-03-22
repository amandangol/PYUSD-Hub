import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/snackbar_utils.dart';

class BalanceCard extends StatelessWidget {
  final double? ethBalance;
  final double? tokenBalance;
  final String walletAddress;
  final bool isRefreshing;
  final Color primaryColor;
  final String networkName;
  final NetworkStatus networkStatus;

  const BalanceCard({
    super.key,
    required this.ethBalance,
    required this.tokenBalance,
    required this.walletAddress,
    required this.isRefreshing,
    required this.primaryColor,
    required this.networkName,
    this.networkStatus = NetworkStatus.connected, // Default to connected
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Colors
    const paypalBlue = Color(0xFF142C8E);
    const paypalLightBlue = Color(0xFF253B80);

    // Extract card content to improve readability
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        decoration: _buildCardDecoration(isDarkMode),
        child: Stack(
          children: [
            // Decorative elements
            _buildDecorativeCircle(true, isDarkMode, paypalBlue),
            _buildDecorativeCircle(false, isDarkMode, paypalBlue),

            // Card content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader(isDarkMode, paypalBlue, paypalLightBlue),
                  const SizedBox(height: 24),
                  _buildBalanceSection(isDarkMode, paypalBlue),
                  const SizedBox(height: 24),
                  _buildDivider(isDarkMode),
                  const SizedBox(height: 16),
                  _buildWalletAddressSection(isDarkMode, paypalBlue, context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Extracted methods for better organization
  BoxDecoration _buildCardDecoration(bool isDarkMode) {
    return BoxDecoration(
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
    );
  }

  Widget _buildDecorativeCircle(bool isTop, bool isDarkMode, Color paypalBlue) {
    return Positioned(
      top: isTop ? -20 : null,
      right: isTop ? -20 : null,
      bottom: !isTop ? -15 : null,
      left: !isTop ? -15 : null,
      child: Container(
        height: isTop ? 100 : 80,
        width: isTop ? 100 : 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDarkMode
              ? Colors.white.withOpacity(isTop ? 0.03 : 0.02)
              : paypalBlue.withOpacity(isTop ? 0.05 : 0.03),
        ),
      ),
    );
  }

  Widget _buildCardHeader(
      bool isDarkMode, Color paypalBlue, Color paypalLightBlue) {
    return Row(
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
        _buildNetworkStatusBadge(isDarkMode, paypalBlue),
      ],
    );
  }

  Widget _buildNetworkStatusBadge(bool isDarkMode, Color paypalBlue) {
    // Network status colors
    final Color statusColor = _getNetworkStatusColor(isDarkMode);
    final Color backgroundColor = isDarkMode
        ? Colors.white.withOpacity(0.1)
        : paypalBlue.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.2)
              : paypalBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            networkName,
            style: TextStyle(
              color: isDarkMode ? Colors.white : paypalBlue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getNetworkStatusColor(bool isDarkMode) {
    switch (networkStatus) {
      case NetworkStatus.connected:
        return Colors.green;
      case NetworkStatus.connecting:
        return Colors.orange;
      case NetworkStatus.disconnected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBalanceSection(bool isDarkMode, Color paypalBlue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Balance',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildBalanceDisplay(isDarkMode, paypalBlue),
            const Spacer(),
            _buildEthBalanceChip(isDarkMode),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceDisplay(bool isDarkMode, Color paypalBlue) {
    return AnimatedSwitcher(
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
                    color: isDarkMode ? Colors.white : paypalBlue,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  (tokenBalance ?? 0).toStringAsFixed(2),
                  key: ValueKey(tokenBalance),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEthBalanceChip(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            color: isDarkMode ? Colors.white70 : Colors.black54,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            '${(ethBalance ?? 0).toStringAsFixed(4)} ETH',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Divider(
      color: isDarkMode
          ? Colors.white.withOpacity(0.1)
          : Colors.black.withOpacity(0.05),
      thickness: 1,
    );
  }

  Widget _buildWalletAddressSection(
      bool isDarkMode, Color paypalBlue, BuildContext context) {
    return Row(
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
                  color: isDarkMode ? Colors.white70 : Colors.black54,
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
                    color: isDarkMode ? Colors.white : Colors.black87,
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
            padding: const EdgeInsets.all(8),
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
    );
  }
}

// Network status enum for better type safety
enum NetworkStatus { connected, connecting, disconnected, unknown }
