import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../../utils/formatter_utils.dart';

class QRCodeSection extends StatelessWidget {
  final GlobalKey qrKey;
  final String address;
  final ThemeData theme;
  final VoidCallback onTap;
  final bool isDarkMode;

  const QRCodeSection({
    required this.qrKey,
    required this.address,
    required this.theme,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Your Wallet Address',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Share this address to receive PYUSD',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // QR Code with shadow and border
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDarkMode ? Colors.black26 : Colors.black12,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: address.isEmpty
                ? Container(
                    width: 200,
                    height: 200,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary),
                      ),
                    ),
                  )
                : RepaintBoundary(
                    key: qrKey,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: QrImageView(
                        data: address,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                        embeddedImage:
                            const AssetImage('assets/images/pyusdlogo.png'),
                        embeddedImageStyle: const QrEmbeddedImageStyle(
                          size: Size(40, 40),
                        ),
                      ),
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 20),

        // Address display
        GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerTheme.color ?? Colors.transparent,
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.copy_rounded,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
