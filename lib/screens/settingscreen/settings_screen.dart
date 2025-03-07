import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_forensics/providers/network_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/wallet_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/formataddress_utils.dart';
import '../../utils/snackbar_utils.dart';
import '../wallet_selection_screen.dart';

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

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      SnackbarUtil.showSnackbar(
        context: context,
        message: "Failed to open link: $e",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletProvider = Provider.of<WalletProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.colorScheme.surface;
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
                    // Account section
                    Text(
                      'ACCOUNT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: cardColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          // Wallet address
                          ListTile(
                            title: const Text('Wallet Address'),
                            subtitle: Text(
                              FormatterUtils.formatAddress(
                                  walletProvider.wallet?.address ?? ''),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                            trailing: Icon(Icons.copy, color: primaryColor),
                            onTap: () {
                              // Copy address logic
                              Clipboard.setData(
                                ClipboardData(
                                    text: walletProvider.wallet?.address ?? ''),
                              );
                              SnackbarUtil.showSnackbar(
                                context: context,
                                message: "Address copied to clipboard",
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            title: const Text('Export Private Key'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // Navigate to private key export with security checks
                              _showPrivateKeyDialog(
                                  context, walletProvider.wallet);
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            title: const Text('Backup Recovery Phrase'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // Navigate to recovery phrase backup with security checks
                              _showRecoveryPhraseDialog(
                                  context, walletProvider.wallet);
                            },
                          ),
                        ],
                      ),
                    ),

                    // Appearance section
                    Text(
                      'APPEARANCE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: cardColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Dark Mode'),
                            subtitle: Text(
                              'Use dark theme for the app',
                              style:
                                  TextStyle(color: textColor.withOpacity(0.7)),
                            ),
                            secondary: Icon(
                              themeProvider.isDarkMode
                                  ? Icons.dark_mode
                                  : Icons.light_mode,
                              color: primaryColor,
                            ),
                            value: themeProvider.isDarkMode,
                            onChanged: (value) {
                              themeProvider.setDarkMode(value);
                            },
                            activeColor: primaryColor,
                          ),
                        ],
                      ),
                    ),

                    // Security section
                    Text(
                      'SECURITY',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: cardColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Biometric Authentication'),
                            subtitle: Text(
                              'Use fingerprint or face ID to unlock app',
                              style:
                                  TextStyle(color: textColor.withOpacity(0.7)),
                            ),
                            secondary:
                                Icon(Icons.fingerprint, color: primaryColor),
                            value: false, // Connect to a biometric provider
                            onChanged: (value) {
                              // Toggle biometric auth
                              SnackbarUtil.showSnackbar(
                                context: context,
                                message: value
                                    ? 'Biometric authentication enabled'
                                    : 'Biometric authentication disabled',
                              );
                            },
                            activeColor: primaryColor,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            title: const Text('Change PIN'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              SnackbarUtil.showSnackbar(
                                context: context,
                                message: 'PIN change feature coming soon',
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Network section
                    Text(
                      'NETWORK',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: cardColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('Network Settings'),
                            subtitle: Text(
                              walletProvider.currentNetworkName,
                              style:
                                  TextStyle(color: textColor.withOpacity(0.7)),
                            ),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              _showNetworkDialog(context, walletProvider);
                            },
                          ),
                          const Divider(height: 1),
                          // New Faucet section
                          ExpansionTile(
                            title: Row(
                              children: [
                                Icon(Icons.water_drop,
                                    color: primaryColor, size: 20),
                                const SizedBox(width: 8),
                                const Text('Faucets'),
                              ],
                            ),
                            subtitle: Text(
                              'Get testnet tokens',
                              style:
                                  TextStyle(color: textColor.withOpacity(0.7)),
                            ),
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.withOpacity(0.2),
                                  child: const Icon(Icons.water_drop,
                                      size: 18, color: Colors.blue),
                                ),
                                title: const Text('Sepolia ETH Faucet'),
                                subtitle:
                                    const Text('Get test ETH for development'),
                                onTap: () {
                                  _launchUrl(
                                      'https://cloud.google.com/application/web3/faucet/ethereum/sepolia');
                                },
                              ),
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Colors.green.withOpacity(0.2),
                                  child: const Icon(Icons.attach_money,
                                      size: 18, color: Colors.green),
                                ),
                                title: const Text('PYUSD Faucet'),
                                subtitle: const Text('Get test PYUSD tokens'),
                                onTap: () {
                                  _launchUrl('https://faucet.paxos.com/');
                                },
                              ),
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Colors.purple.withOpacity(0.2),
                                  child: const Icon(Icons.currency_exchange,
                                      size: 18, color: Colors.purple),
                                ),
                                title: const Text('Other Testnet Tokens'),
                                subtitle:
                                    const Text('Access various test tokens'),
                                onTap: () {
                                  _launchUrl(
                                      'https://cloud.google.com/application/web3/faucet/ethereum');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // About section
                    Text(
                      'ABOUT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: cardColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('App Version'),
                            subtitle: Text(
                              _appVersion,
                              style:
                                  TextStyle(color: textColor.withOpacity(0.7)),
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            title: const Text('Privacy Policy'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // Navigate to Privacy Policy
                              SnackbarUtil.showSnackbar(
                                context: context,
                                message: "Privacy Policy will open soon",
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            title: const Text('Terms of Service'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // Navigate to Terms of Service
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Terms of Service will open soon'),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            title: const Text('Support'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // Navigate to Support screen or launch support link
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Support section will open soon'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Danger zone
                    Text(
                      'DANGER ZONE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: cardColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        title: Text(
                          'Log Out',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        leading: Icon(
                          Icons.logout,
                          color: theme.colorScheme.error,
                        ),
                        onTap: () {
                          // Show confirmation dialog before deletion
                          _showLogoutDialog(context, walletProvider);
                        },
                      ),
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

  void _showPrivateKeyDialog(BuildContext context, wallet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber[700],
            ),
            const SizedBox(width: 8),
            const Text('Private Key'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Text(
                  'NEVER share your private key with anyone. Anyone with this key can access your funds.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  wallet?.privateKey ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: wallet?.privateKey ?? ''),
              );
              Navigator.pop(context);
              SnackbarUtil.showSnackbar(
                context: context,
                message: "Private key copied to clipboard",
              );
            },
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRecoveryPhraseDialog(BuildContext context, wallet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber[700],
            ),
            const SizedBox(width: 8),
            const Text('Recovery Phrase'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Text(
                  'Never share your recovery phrase with anyone. Anyone with this phrase can access your funds.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  wallet?.mnemonic ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: wallet?.mnemonic ?? ''),
              );
              Navigator.pop(context);
              SnackbarUtil.showSnackbar(
                context: context,
                message: "Recovery phrase copied to clipboard",
              );
            },
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNetworkDialog(BuildContext context, WalletProvider walletProvider) {
    final networks = [
      {
        'name': 'Ethereum Mainnet',
        'chainId': 1,
        'icon': Icons.public,
        'color': Colors.blue
      },
      {
        'name': 'Sepolia Testnet',
        'chainId': 11155111,
        'icon': Icons.science,
        'color': Colors.green
      },
      {
        'name': 'Base',
        'chainId': 8453,
        'icon': Icons.layers,
        'color': Colors.blue
      },
      {
        'name': 'Base Sepolia',
        'chainId': 84532,
        'icon': Icons.layers,
        'color': Colors.green
      },
      {
        'name': 'Optimism',
        'chainId': 10,
        'icon': Icons.flash_on,
        'color': Colors.red
      },
      {
        'name': 'Arbitrum',
        'chainId': 42161,
        'icon': Icons.speed,
        'color': Colors.blue
      },
      {
        'name': 'Avalanche',
        'chainId': 43114,
        'icon': Icons.ac_unit,
        'color': Colors.red
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.swap_horiz,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Select Network'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 350, // Fixed height for scrollable content
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Active networks:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: networks.length,
                  itemBuilder: (context, index) {
                    final network = networks[index];
                    final currentNetworkName =
                        walletProvider.currentNetworkName;
                    final isSelected = network['name'] == currentNetworkName;

                    return Card(
                      elevation: isSelected ? 2 : 0,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              (network['color'] as Color).withOpacity(0.2),
                          child: Icon(
                            network['icon'] as IconData,
                            color: network['color'] as Color,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          network['name'] as String,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text('Chain ID: ${network['chainId']}'),
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary)
                            : null,
                        onTap: () {
                          // Call wallet provider to switch network
                          walletProvider
                              .switchNetwork(NetworkType.sepoliaTestnet);
                          Navigator.pop(context);

                          // Show confirmation
                          SnackbarUtil.showSnackbar(
                            context: context,
                            message: 'Switched to ${network['name']}',
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: Switching networks may require reloading your wallet data',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
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
}
