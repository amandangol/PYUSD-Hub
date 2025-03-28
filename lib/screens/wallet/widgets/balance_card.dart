import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../utils/snackbar_utils.dart';
import '../provider/walletscreen_provider.dart';
import 'shimmer/shimmer_effect.dart';

class BalanceCard extends StatelessWidget {
  final double? ethBalance;
  final double? tokenBalance;
  final String walletAddress;
  final bool isRefreshing;
  final Color primaryColor;

  // Cache common styles and colors
  static const _paypalBlue = Color(0xFF142C8E);
  static const _paypalLightBlue = Color(0xFF253B80);
  static const _animationDuration = Duration(milliseconds: 300);

  // Use const constructor
  const BalanceCard({
    super.key,
    required this.ethBalance,
    required this.tokenBalance,
    required this.walletAddress,
    required this.isRefreshing,
    required this.primaryColor,
  });

  // Memoize common styles
  TextStyle _getBalanceTextStyle(bool isDarkMode) => TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
        fontSize: 38,
        fontWeight: FontWeight.bold,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Colors
    const paypalBlue = Color(0xFF142C8E);

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
                  _buildCardHeader(context, isDarkMode),
                  const SizedBox(height: 24),
                  _buildBalanceSection(context, isDarkMode, paypalBlue),
                  const SizedBox(height: 24),
                  _buildDivider(isDarkMode),
                  const SizedBox(height: 16),
                  _buildWalletAddressSection(context, isDarkMode, paypalBlue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Optimize card decoration by reducing opacity calculations
  BoxDecoration _buildCardDecoration(bool isDarkMode) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDarkMode
            ? const [_paypalBlue, _paypalLightBlue]
            : const [Colors.white, Color(0xFFF5F7FA)],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000), // Pre-calculated opacity
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

  Widget _buildCardHeader(BuildContext context, bool isDarkMode) {
    final homeProvider = context.watch<WaletScreenProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDarkMode ? _paypalLightBlue : _paypalBlue,
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
                color: isDarkMode ? Colors.white : _paypalBlue,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            homeProvider.isBalanceVisible
                ? Icons.visibility
                : Icons.visibility_off,
            color: isDarkMode ? Colors.white70 : _paypalBlue,
            size: 20,
          ),
          onPressed: () => homeProvider.toggleBalanceVisibility(),
        ),
      ],
    );
  }

  Widget _buildBalanceSection(
      BuildContext context, bool isDarkMode, Color paypalBlue) {
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
        AnimatedSwitcher(
          duration: _animationDuration,
          child: isRefreshing
              ? _buildBalanceLoadingSkeleton(isDarkMode)
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child:
                          _buildBalanceDisplay(context, isDarkMode, paypalBlue),
                    ),
                    _buildEthBalanceChip(context, isDarkMode),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildBalanceLoadingSkeleton(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // PYUSD Balance Skeleton
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildSkeletonBox(
                    isDarkMode,
                    width: 20,
                    height: 38,
                  ), // $ symbol
                  const SizedBox(width: 4),
                  _buildSkeletonBox(
                    isDarkMode,
                    width: 120,
                    height: 38,
                  ), // Balance amount
                ],
              ),
            ),
            // ETH Balance Chip Skeleton
            Container(
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
                  _buildSkeletonBox(
                    isDarkMode,
                    width: 14,
                    height: 14,
                    isCircular: true,
                  ), // Icon
                  const SizedBox(width: 6),
                  _buildSkeletonBox(
                    isDarkMode,
                    width: 80,
                    height: 14,
                  ), // ETH amount
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonBox(
    bool isDarkMode, {
    required double width,
    required double height,
    bool isCircular = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isCircular ? height / 2 : 8),
      ),
      child: ShimmerEffect(
        isDarkMode: isDarkMode,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(isCircular ? height / 2 : 8),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceDisplay(
      BuildContext context, bool isDarkMode, Color paypalBlue) {
    final isBalanceVisible = context.select<WaletScreenProvider, bool>(
      (provider) => provider.isBalanceVisible,
    );

    return AnimatedSwitcher(
      duration: _animationDuration,
      child: Row(
        children: [
          _buildCurrencySymbol(isDarkMode),
          Text(
            isBalanceVisible ? (tokenBalance ?? 0).toStringAsFixed(2) : '****',
            key: ValueKey(tokenBalance),
            style: _getBalanceTextStyle(isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySymbol(bool isDarkMode) {
    return Text(
      '\$',
      key: const ValueKey('dollar'),
      style: TextStyle(
        color: isDarkMode ? Colors.white : _paypalBlue,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEthBalanceChip(BuildContext context, bool isDarkMode) {
    final isBalanceVisible = context.select<WaletScreenProvider, bool>(
      (provider) => provider.isBalanceVisible,
    );

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
            isBalanceVisible
                ? '${(ethBalance ?? 0).toStringAsFixed(4)} ETH'
                : '**** ETH',
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
    BuildContext context,
    bool isDarkMode,
    Color paypalBlue,
  ) {
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
