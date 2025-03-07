import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_forensics/utils/formataddress_utils.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../providers/wallet_provider.dart';
import '../../../utils/snackbar_utils.dart';

class ReceiveScreen extends StatelessWidget {
  const ReceiveScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final address = walletProvider.getCurrentAddress() ?? '';

    // Get the token balance
    final tokenBalance = walletProvider.tokenBalance;
    final isBalanceRefreshing = walletProvider.isBalanceRefreshing;
    final GlobalKey qrKey = GlobalKey();

    // Get theme information for styling
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Define colors based on theme
    final primaryColor =
        isDarkMode ? theme.colorScheme.primary : const Color(0xFF3D56F0);
    final backgroundColor = isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;
    final cardColor = isDarkMode ? const Color(0xFF252543) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1A2E);
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Receive PYUSD',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        iconTheme: IconThemeData(
          color: textColor,
        ),
        actions: [
          // Add refresh button
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: textColor,
            ),
            onPressed: () {
              walletProvider.refreshWalletData(forceRefresh: true);
            },
          ),
        ],
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
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share this address to receive PYUSD',
                  style: TextStyle(
                    fontSize: 16,
                    color: secondaryTextColor,
                  ),
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
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.1),
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
                            color: isDarkMode
                                ? const Color(0xFF1A1A2E)
                                : const Color(0xFFF5F7FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Balance',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: secondaryTextColor,
                                ),
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
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'PYUSD',
                                    style: TextStyle(
                                      fontSize: 16,
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
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  Text(
                                    walletProvider.currentNetworkName,
                                    style: TextStyle(
                                      fontSize: 12,
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
                              color:
                                  isDarkMode ? Colors.white24 : Colors.black12,
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
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
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
                              color: isDarkMode
                                  ? const Color(0xFF1A1A2E)
                                  : const Color(0xFFF5F7FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.white24
                                    : Colors.black12,
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
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
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
                    color: isDarkMode
                        ? Colors.amber.shade800.withOpacity(0.2)
                        : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.amber.shade700
                          : Colors.amber.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDarkMode
                            ? Colors.amber.shade400
                            : Colors.amber.shade800,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Only send PYUSD to this address. Sending other assets may result in permanent loss.',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.amber.shade400
                                : Colors.amber.shade800,
                            fontSize: 14,
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
