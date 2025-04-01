import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanning = true;
  bool _isTorchOn = false;

  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  void _onDetect(BarcodeCapture capture) {
    if (_isScanning && capture.barcodes.isNotEmpty) {
      final firstBarcode = capture.barcodes.first;
      setState(() {
        _isScanning = false;
      });

      // Validate Ethereum address
      if (_isValidEthereumAddress(firstBarcode.rawValue ?? '')) {
        Navigator.of(context).pop(firstBarcode.rawValue);
      } else {
        _showInvalidQRDialog();
      }
    }
  }

  bool _isValidEthereumAddress(String address) {
    final ethereumAddressRegex = RegExp(r'^0x[a-fA-F0-9]{40}$');
    return ethereumAddressRegex.hasMatch(address);
  }

  void _showInvalidQRDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalid QR Code'),
        content:
            const Text('The scanned QR code is not a valid Ethereum address.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isScanning = true;
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _toggleTorch() {
    setState(() {
      _isTorchOn = !_isTorchOn;
      _scannerController.toggleTorch();
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn
                  ? Colors.yellow
                  : (isDarkMode ? Colors.white : Colors.black),
            ),
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera View
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
            fit: BoxFit.cover,
          ),

          // Overlay with Scanning Frame
          IgnorePointer(
            child: CustomPaint(
              painter: QRScannerOverlayPainter(),
              child: Container(),
            ),
          ),

          // Instruction Text
          Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Align Ethereum QR Code within the frame',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// Custom Painter for QR Scanner Overlay
class QRScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Scanning frame dimensions
    const frameWidth = 250.0;
    const frameHeight = 250.0;
    final frameX = (size.width - frameWidth) / 2;
    final frameY = (size.height - frameHeight) / 2;

    // Create a hole in the overlay
    path.addRect(Rect.fromLTWH(frameX, frameY, frameWidth, frameHeight));

    canvas.drawPath(path, paint);

    // Draw frame border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawRect(
        Rect.fromLTWH(frameX, frameY, frameWidth, frameHeight), borderPaint);

    // Draw corner markers
    final cornerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    const cornerLength = 30.0;
    const cornerOffset = 4.0;

    // Top-left corners
    canvas.drawLine(
        Offset(frameX - cornerOffset, frameY - cornerOffset),
        Offset(frameX - cornerOffset + cornerLength, frameY - cornerOffset),
        cornerPaint);
    canvas.drawLine(
        Offset(frameX - cornerOffset, frameY - cornerOffset),
        Offset(frameX - cornerOffset, frameY - cornerOffset + cornerLength),
        cornerPaint);

    // Top-right corners
    canvas.drawLine(
        Offset(frameX + frameWidth + cornerOffset, frameY - cornerOffset),
        Offset(frameX + frameWidth + cornerOffset - cornerLength,
            frameY - cornerOffset),
        cornerPaint);
    canvas.drawLine(
        Offset(frameX + frameWidth + cornerOffset, frameY - cornerOffset),
        Offset(frameX + frameWidth + cornerOffset,
            frameY - cornerOffset + cornerLength),
        cornerPaint);

    // Bottom-left corners
    canvas.drawLine(
        Offset(frameX - cornerOffset, frameY + frameHeight + cornerOffset),
        Offset(frameX - cornerOffset + cornerLength,
            frameY + frameHeight + cornerOffset),
        cornerPaint);
    canvas.drawLine(
        Offset(frameX - cornerOffset, frameY + frameHeight + cornerOffset),
        Offset(frameX - cornerOffset,
            frameY + frameHeight + cornerOffset - cornerLength),
        cornerPaint);

    // Bottom-right corners
    canvas.drawLine(
        Offset(frameX + frameWidth + cornerOffset,
            frameY + frameHeight + cornerOffset),
        Offset(frameX + frameWidth + cornerOffset - cornerLength,
            frameY + frameHeight + cornerOffset),
        cornerPaint);
    canvas.drawLine(
        Offset(frameX + frameWidth + cornerOffset,
            frameY + frameHeight + cornerOffset),
        Offset(frameX + frameWidth + cornerOffset,
            frameY + frameHeight + cornerOffset - cornerLength),
        cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
