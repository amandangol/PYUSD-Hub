import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../utils/snackbar_utils.dart';
import '../provider/walletscreen_provider.dart';
import 'shimmer/shimmer_effect.dart';

class BalanceCard extends StatelessWidget {
  final double? ethBalance;
  final double? tokenBalance;
  final String? walletAddress;
  final bool isRefreshing;
  final Color primaryColor;
  final bool showWalletAddress;

  // Cache common styles and colors
  static const _paypalBlue = Color(0xFF142C8E);
  static const _paypalLightBlue = Color(0xFF253B80);

  // Use const constructor
  const BalanceCard({
    super.key,
    required this.ethBalance,
    required this.tokenBalance,
    this.walletAddress,
    required this.isRefreshing,
    required this.primaryColor,
    this.showWalletAddress = true,
  });

  // Memoize common styles
  TextStyle _getBalanceTextStyle(bool isDarkMode) => TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: _buildCardDecoration(isDarkMode),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(context, isDarkMode),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isRefreshing
                  ? _buildBalanceLoadingSkeleton(isDarkMode)
                  : _buildBalanceSection(context, isDarkMode),
            ),
            if (showWalletAddress && walletAddress != null) ...[
              const SizedBox(height: 16),
              _buildWalletAddressSection(context, isDarkMode),
            ],
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration(bool isDarkMode) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDarkMode
            ? const [_paypalBlue, _paypalLightBlue]
            : const [Colors.white, Color(0xFFF5F7FA)],
      ),
      boxShadow: [
        BoxShadow(
          color: isDarkMode
              ? Colors.black.withOpacity(0.2)
              : const Color(0x0D000000),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ],
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
              child: Image.asset(
                "assets/images/pyusdlogo.png",
                height: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'PayPal USD',
              style: TextStyle(
                color: isDarkMode ? Colors.white : _paypalBlue,
                fontSize: 16,
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

  Widget _buildBalanceSection(BuildContext context, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PYUSD Balance',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              _buildPyusdBalanceDisplay(context, isDarkMode),
            ],
          ),
        ),
        Container(
          width: 1,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ETH Balance',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              _buildEthBalanceDisplay(context, isDarkMode),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPyusdBalanceDisplay(BuildContext context, bool isDarkMode) {
    final isBalanceVisible = context.select<WaletScreenProvider, bool>(
      (provider) => provider.isBalanceVisible,
    );

    return Row(
      children: [
        _buildCurrencySymbol(isDarkMode),
        Text(
          isBalanceVisible ? (tokenBalance ?? 0).toStringAsFixed(2) : '****',
          key: ValueKey(tokenBalance),
          style: _getBalanceTextStyle(isDarkMode),
        ),
      ],
    );
  }

  Widget _buildEthBalanceDisplay(BuildContext context, bool isDarkMode) {
    final isBalanceVisible = context.select<WaletScreenProvider, bool>(
      (provider) => provider.isBalanceVisible,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/svg/ethereum_logo.svg',
          height: 16,
          width: 16,
          colorFilter: ColorFilter.mode(
            isDarkMode ? Colors.white70 : Colors.black54,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isBalanceVisible
              ? '${(ethBalance ?? 0).toStringAsFixed(4)} ETH'
              : '**** ETH',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceLoadingSkeleton(bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSkeletonBox(
                isDarkMode,
                width: 100,
                height: 12,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildSkeletonBox(
                    isDarkMode,
                    width: 20,
                    height: 24,
                  ),
                  const SizedBox(width: 4),
                  _buildSkeletonBox(
                    isDarkMode,
                    width: 120,
                    height: 24,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 1,
          height: 40,
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSkeletonBox(
                isDarkMode,
                width: 100,
                height: 12,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildSkeletonBox(
                    isDarkMode,
                    width: 16,
                    height: 16,
                    isCircular: true,
                  ),
                  const SizedBox(width: 6),
                  _buildSkeletonBox(
                    isDarkMode,
                    width: 80,
                    height: 16,
                  ),
                ],
              ),
            ],
          ),
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
            color: isDarkMode
                ? Colors.white.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(isCircular ? height / 2 : 8),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencySymbol(bool isDarkMode) {
    return Text(
      '\$',
      key: const ValueKey('dollar'),
      style: TextStyle(
        color: isDarkMode ? Colors.white : _paypalBlue,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildWalletAddressSection(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet Address',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatWalletAddress(walletAddress ?? ''),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: IconButton(
              icon: Icon(
                Icons.copy,
                color: isDarkMode ? Colors.white70 : _paypalBlue,
                size: 18,
              ),
              onPressed: () => _copyWalletAddress(context),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  String _formatWalletAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 4)}';
  }

  void _copyWalletAddress(BuildContext context) {
    Clipboard.setData(ClipboardData(text: walletAddress ?? ''));
    SnackbarUtil.showSnackbar(
      context: context,
      message: 'Wallet address copied to clipboard',
    );
  }
}
