// Main settings_screen.dart file
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../providers/theme_provider.dart';
import '../../providers/wallet_provider.dart';
import '../wallet_selection_screen.dart';
import 'widgets/about_section.dart';
import 'widgets/account_section.dart';
import 'widgets/appearance_section.dart';
import 'widgets/danger_section.dart';
import 'widgets/network_section.dart';
import 'widgets/security_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _appVersion = 'Unknown';
        _isLoading = false;
      });
    }
  }

  void _showLogoutDialog(BuildContext context, WalletProvider walletProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.logout,
              color: Colors.red,
            ),
            SizedBox(width: 8),
            Text('Log Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out? Make sure you have backed up your recovery phrase or private key before proceeding.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Ideally would call walletProvider.clearWallet()
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WalletSelectionScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletProvider = Provider.of<WalletProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Label Widget
                    SectionLabel(label: 'ACCOUNT', color: primaryColor),
                    const SizedBox(height: 8),
                    AccountSection(walletProvider: walletProvider),

                    SectionLabel(label: 'APPEARANCE', color: primaryColor),
                    const SizedBox(height: 8),
                    AppearanceSection(themeProvider: themeProvider),

                    SectionLabel(label: 'SECURITY', color: primaryColor),
                    const SizedBox(height: 8),
                    const SecuritySection(),

                    SectionLabel(label: 'NETWORK', color: primaryColor),
                    const SizedBox(height: 8),
                    NetworkSection(walletProvider: walletProvider),

                    SectionLabel(label: 'ABOUT', color: primaryColor),
                    const SizedBox(height: 8),
                    AboutSection(appVersion: _appVersion),

                    SectionLabel(
                      label: 'DANGER ZONE',
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 8),
                    DangerSection(
                      onLogoutTap: () =>
                          _showLogoutDialog(context, walletProvider),
                    ),

                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        '© 2025 PYUSD Wallet',
                        style: TextStyle(
                          color: textColor.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String label;
  final Color color;

  const SectionLabel({
    Key? key,
    required this.label,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}
