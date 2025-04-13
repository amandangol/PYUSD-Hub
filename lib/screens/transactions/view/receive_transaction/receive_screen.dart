import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../widgets/pyusd_components.dart';
import '../../../authentication/provider/auth_provider.dart';
import '../../../../providers/network_provider.dart';
import '../../../../providers/walletstate_provider.dart';
import '../../../../utils/snackbar_utils.dart';
import '../../../wallet/widgets/balance_card.dart';
import 'widgets/qr_code_section.dart';
import 'widgets/action_buttons.dart';
import 'widgets/warning_box.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _shareAddress(BuildContext context, String address) async {
    try {
      // Show loading indicator
      SnackbarUtil.showSnackbar(
        context: context,
        message: "Preparing to share...",
      );

      // Capture QR code as image
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/pyusd_qr_code.png');
      await file.writeAsBytes(pngBytes);

      // Share address and QR code
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My PYUSD wallet address: $address',
        subject: 'PYUSD Wallet Address',
      );
    } catch (e) {
      SnackbarUtil.showSnackbar(
        context: context,
        message: "Error sharing: ${e.toString()}",
        isError: true,
      );
    }
  }

  void _copyToClipboard(BuildContext context, String address) {
    if (address.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: address));
      HapticFeedback.lightImpact();
      SnackbarUtil.showSnackbar(
        context: context,
        message: "Address copied to clipboard",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletStateProvider>(context);
    final networkProvider = Provider.of<NetworkProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final address = authProvider.getCurrentAddress() ?? '';

    final tokenBalance = walletProvider.tokenBalance;
    final ethBalance = walletProvider.ethBalance;
    final isBalanceRefreshing = walletProvider.isBalanceRefreshing;

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PyusdAppBar(
        isDarkMode: isDarkMode,
        title: 'Receive PYUSD',
        showLogo: false,
        networkName: networkProvider.currentNetworkDisplayName,
        onRefreshPressed: () {
          // walletProvider.refreshBalances(forceRefresh: true);
        },
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 360;
              final horizontalPadding = isSmallScreen ? 16.0 : 24.0;

              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      BalanceCard(
                        ethBalance: ethBalance,
                        tokenBalance: tokenBalance,
                        isRefreshing: isBalanceRefreshing,
                        primaryColor: primaryColor,
                        showWalletAddress: false,
                      ),
                      const SizedBox(height: 24),
                      QRCodeSection(
                        qrKey: _qrKey,
                        address: address,
                        theme: theme,
                        onTap: () => _copyToClipboard(context, address),
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 24),
                      ActionButtons(
                        address: address,
                        primaryColor: primaryColor,
                        theme: theme,
                        onCopy: () => _copyToClipboard(context, address),
                        onShare: () => _shareAddress(context, address),
                      ),
                      const SizedBox(height: 24),
                      WarningBox(theme: theme),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
