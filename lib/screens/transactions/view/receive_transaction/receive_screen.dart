import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../widgets/pyusd_components.dart';
import '../../../authentication/provider/auth_provider.dart';
import '../../../../providers/network_provider.dart';
import '../../../../providers/walletstate_provider.dart';
import '../../../../utils/formatter_utils.dart';
import '../../../../utils/snackbar_utils.dart';

class ReceiveScreen extends StatelessWidget {
  const ReceiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletStateProvider>(context);
    final networkProvider = Provider.of<NetworkProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final address = authProvider.getCurrentAddress() ?? '';

    // Get the token balance
    final tokenBalance = walletProvider.tokenBalance;
    final isBalanceRefreshing = walletProvider.isBalanceRefreshing;
    final GlobalKey qrKey = GlobalKey();

    // Get theme information for styling
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardTheme.color;
    final textColor = theme.textTheme.bodyLarge?.color;
    final secondaryTextColor = theme.textTheme.bodySmall?.color;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PyusdAppBar(
        isDarkMode: isDarkMode,
        title: 'Receive PYUSD',
        showLogo: false,
        networkName: networkProvider.currentNetworkDisplayName,
        onRefreshPressed: () {
          walletProvider.refreshBalances(forceRefresh: true);
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Your Wallet Address',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share this address to receive PYUSD',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Balance info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Balance',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (isBalanceRefreshing)
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                primaryColor),
                                      ),
                                    )
                                  else
                                    Text(
                                      tokenBalance.toStringAsFixed(2),
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'PYUSD',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Network: ',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  Text(
                                    networkProvider.currentNetworkName,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // QR Code with border
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.dividerTheme.color ??
                                  Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: address.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(90.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : RepaintBoundary(
                                  key: qrKey,
                                  child: Container(
                                    color: Colors.white,
                                    child: QrImageView(
                                      data: address,
                                      version: QrVersions.auto,
                                      size: 200,
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      errorCorrectionLevel:
                                          QrErrorCorrectLevel.H,
                                    ),
                                  ),
                                ),
                        ),

                        const SizedBox(height: 24),

                        Text(
                          'Wallet Address',
                          style: theme.textTheme.bodySmall,
                        ),

                        const SizedBox(height: 8),

                        // Address with masked display
                        GestureDetector(
                          onTap: () {
                            if (address.isNotEmpty) {
                              Clipboard.setData(ClipboardData(text: address));
                              SnackbarUtil.showSnackbar(
                                context: context,
                                message: "Address copied to clipboard",
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.dividerTheme.color ??
                                    Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    address.isEmpty
                                        ? 'Loading...'
                                        : FormatterUtils.formatAddress(address),
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.copy_rounded,
                                  color: primaryColor,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Share button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: address.isEmpty
                                ? null
                                : () async {
                                    try {
                                      // Show loading indicator
                                      SnackbarUtil.showSnackbar(
                                        context: context,
                                        message: "Preparing to share...",
                                      );

                                      // Capture QR code as image
                                      final RenderRepaintBoundary boundary =
                                          qrKey.currentContext!
                                                  .findRenderObject()
                                              as RenderRepaintBoundary;
                                      final ui.Image image = await boundary
                                          .toImage(pixelRatio: 3.0);
                                      final ByteData? byteData =
                                          await image.toByteData(
                                              format: ui.ImageByteFormat.png);
                                      final Uint8List pngBytes =
                                          byteData!.buffer.asUint8List();

                                      // Save to temporary file
                                      final tempDir =
                                          await getTemporaryDirectory();
                                      final file = File(
                                          '${tempDir.path}/pyusd_qr_code.png');
                                      await file.writeAsBytes(pngBytes);

                                      // Share address and QR code
                                      await Share.shareXFiles(
                                        [XFile(file.path)],
                                        text:
                                            'My PYUSD wallet address: $address',
                                        subject: 'PYUSD Wallet Address',
                                      );
                                    } catch (e) {
                                      SnackbarUtil.showSnackbar(
                                        context: context,
                                        message:
                                            "Error sharing: ${e.toString()}",
                                        isError: true,
                                      );
                                    }
                                  },
                            icon:
                                Icon(Icons.share_rounded, color: primaryColor),
                            label: Text(
                              'Share Address',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Note about the wallet
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.error.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Only send PYUSD/ETH to this address. Sending other assets may result in permanent loss.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
