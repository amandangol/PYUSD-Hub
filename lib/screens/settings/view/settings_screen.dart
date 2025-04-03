import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/pyusd_components.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/walletstate_provider.dart';
import '../../authentication/provider/auth_provider.dart';
import '../../authentication/model/wallet.dart';
import '../../authentication/widget/pin_input_widget.dart.dart';
import '../../../utils/snackbar_utils.dart';
import '../../insights/view/news_explore_screen.dart';
import 'notification_settings_screen.dart';
import '../../../routes/app_routes.dart';
import 'pyusd_info_screen.dart';
import 'security_setting_screen.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/formatter_utils.dart';
import '../../onboarding/provider/onboarding_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final String _appVersion = '';

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
    final walletProvider = Provider.of<WalletStateProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final onboardingProvider = Provider.of<OnboardingProvider>(context);

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;
    final dividerColor = theme.dividerTheme.color ?? theme.dividerColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PyusdAppBar(
        showLogo: true,
        isDarkMode: isDarkMode,
        title: "Settings",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account section
              if (!onboardingProvider.isDemoMode && authProvider.hasWallet)
                Text(
                  'ACCOUNT',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              if (!onboardingProvider.isDemoMode && authProvider.hasWallet)
                const SizedBox(height: 8),
              if (!onboardingProvider.isDemoMode && authProvider.hasWallet)
                Card(
                  color: cardColor,
                  elevation: theme.cardTheme.elevation ?? 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      // Wallet address
                      if (!onboardingProvider.isDemoMode &&
                          authProvider.hasWallet)
                        ListTile(
                          title: Text('Wallet Address',
                              style: theme.textTheme.titleMedium),
                          subtitle: Text(
                            FormatterUtils.formatAddress(
                                authProvider.wallet?.address ?? ''),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                          trailing: Icon(Icons.copy, color: primaryColor),
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(
                                  text: authProvider.wallet?.address ?? ''),
                            );
                            SnackbarUtil.showSnackbar(
                              context: context,
                              message: "Address copied to clipboard",
                            );
                          },
                        ),
                      if (!onboardingProvider.isDemoMode &&
                          authProvider.hasWallet)
                        Divider(height: 1, color: dividerColor),
                      if (!onboardingProvider.isDemoMode &&
                          authProvider.hasWallet)
                        ListTile(
                          title: Text('Export Private Key',
                              style: theme.textTheme.titleMedium),
                          trailing: Icon(Icons.arrow_forward_ios,
                              size: 16, color: textColor.withOpacity(0.5)),
                          onTap: () {
                            _showPrivateKeyDialog(context, authProvider.wallet);
                          },
                        ),
                      if (!onboardingProvider.isDemoMode &&
                          authProvider.hasWallet)
                        Divider(height: 1, color: dividerColor),
                      if (!onboardingProvider.isDemoMode &&
                          authProvider.hasWallet)
                        ListTile(
                          title: Text('Backup Recovery Phrase',
                              style: theme.textTheme.titleMedium),
                          trailing: Icon(Icons.arrow_forward_ios,
                              size: 16, color: textColor.withOpacity(0.5)),
                          onTap: () {
                            _showRecoveryPhraseDialog(
                                context, authProvider.wallet);
                          },
                        ),
                    ],
                  ),
                ),

              // Appearance section
              Text(
                'APPEARANCE',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: cardColor,
                elevation: theme.cardTheme.elevation ?? 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title:
                          Text('Dark Mode', style: theme.textTheme.titleMedium),
                      subtitle: Text(
                        'Use dark theme for the app',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                      secondary: Icon(
                        themeProvider.isDarkMode
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: primaryColor,
                      ),
                      value: themeProvider.isDarkMode,
                      onChanged: (bool value) {
                        themeProvider.toggleTheme();
                        setState(() {});
                      },
                      activeColor: primaryColor,
                      inactiveTrackColor: theme.disabledColor.withOpacity(0.3),
                    ),
                  ],
                ),
              ),

              // Security section
              Text(
                'SECURITY',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: cardColor,
                elevation: theme.cardTheme.elevation ?? 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    ListTile(
                      title: Text('Security Settings',
                          style: theme.textTheme.titleMedium),
                      trailing: Icon(Icons.arrow_forward_ios,
                          size: 16, color: textColor.withOpacity(0.5)),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SecuritySettingsScreen(),
                            ));
                      },
                    ),
                  ],
                ),
              ),

              // Notifications section
              Text(
                'NOTIFICATIONS',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: cardColor,
                elevation: theme.cardTheme.elevation ?? 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    ListTile(
                      title: Text('Notification Settings',
                          style: theme.textTheme.titleMedium),
                      subtitle: Text(
                        'Configure gas price alerts and other notifications',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios,
                          size: 16, color: textColor.withOpacity(0.5)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const NotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Network section
              Text(
                'FAUCET',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: cardColor,
                elevation: theme.cardTheme.elevation ?? 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    // New Faucet section
                    ExpansionTile(
                      title: Row(
                        children: [
                          Icon(Icons.water_drop, color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text('Faucets', style: theme.textTheme.titleMedium),
                        ],
                      ),
                      subtitle: Text(
                        'Get testnet tokens',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.withOpacity(0.2),
                            child: const Icon(Icons.water_drop,
                                size: 18, color: Colors.blue),
                          ),
                          title: const Text('Sepolia ETH Faucet'),
                          subtitle: const Text('Get test ETH for development'),
                          onTap: () {
                            _launchUrl(
                                'https://cloud.google.com/application/web3/faucet/ethereum/sepolia');
                          },
                        ),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.withOpacity(0.2),
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
                            backgroundColor: Colors.purple.withOpacity(0.2),
                            child: const Icon(Icons.currency_exchange,
                                size: 18, color: Colors.purple),
                          ),
                          title: const Text('Other Testnet Tokens'),
                          subtitle: const Text('Access various test tokens'),
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
              // News & Updates section
              Text(
                'NEWS & UPDATES',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: cardColor,
                elevation: theme.cardTheme.elevation ?? 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.newspaper, color: primaryColor),
                      title: Text('PYUSD News',
                          style: theme.textTheme.titleMedium),
                      subtitle:
                          Text('Latest updates about PYUSD and crypto markets',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: textColor.withOpacity(0.7),
                              )),
                      trailing: Icon(Icons.arrow_forward_ios,
                          size: 16, color: textColor.withOpacity(0.5)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NewsExploreScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // About section
              Text(
                'ABOUT',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: cardColor,
                elevation: theme.cardTheme.elevation ?? 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.question_answer, color: primaryColor),
                      title: Text('PYUSD Information',
                          style: theme.textTheme.titleMedium),
                      subtitle: Text('Learn about PYUSD performance & adoption',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: textColor.withOpacity(0.7),
                          )),
                      trailing: Icon(Icons.arrow_forward_ios,
                          size: 16, color: textColor.withOpacity(0.5)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PyusdInfoScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: dividerColor),
                    ListTile(
                      title: Text('Privacy Policy',
                          style: theme.textTheme.titleMedium),
                      trailing: Icon(Icons.arrow_forward_ios,
                          size: 16, color: textColor.withOpacity(0.5)),
                      onTap: () {
                        // Navigate to Privacy Policy
                        SnackbarUtil.showSnackbar(
                          context: context,
                          message: "Privacy Policy will open soon",
                        );
                      },
                    ),
                    Divider(height: 1, color: dividerColor),
                    ListTile(
                      title: Text('Terms of Service',
                          style: theme.textTheme.titleMedium),
                      trailing: Icon(Icons.arrow_forward_ios,
                          size: 16, color: textColor.withOpacity(0.5)),
                      onTap: () {
                        // Navigate to Terms of Service
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Terms of Service will open soon'),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: dividerColor),
                    ListTile(
                      title:
                          Text('Support', style: theme.textTheme.titleMedium),
                      trailing: Icon(Icons.arrow_forward_ios,
                          size: 16, color: textColor.withOpacity(0.5)),
                      onTap: () {
                        // Navigate to Support screen or launch support link
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Support section will open soon'),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: dividerColor),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text('About this app',
                          style: theme.textTheme.titleMedium),
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),
              ),

              // Danger zone
              Text(
                'DANGER ZONE',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: cardColor,
                elevation: theme.cardTheme.elevation ?? 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  title: Text(
                    onboardingProvider.isDemoMode
                        ? 'Exit Demo Mode'
                        : 'Log Out',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  leading: Icon(
                    onboardingProvider.isDemoMode
                        ? Icons.exit_to_app
                        : Icons.logout,
                    color: theme.colorScheme.error,
                  ),
                  onTap: () {
                    if (onboardingProvider.isDemoMode) {
                      _showExitDemoDialog(context);
                    } else {
                      _showLogoutDialog(context);
                    }
                  },
                ),
              ),

              const SizedBox(height: 32),
              Center(
                child: Text(
                  '© 2025 PYUSD Wallet',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor.withOpacity(0.5),
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

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'PYUSD Hub',
      applicationVersion: _appVersion,
      applicationIcon: Image.asset(
        "assets/images/pyusdlogo.png",
        height: 30,
      ),
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text('This is a crypto wallet app built with Flutter.'),
        ),
      ],
    );
  }

// Helper method to show PIN authentication dialog using Pinput
  Future<bool> _showPINDialog(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final pinController = TextEditingController();
    bool result = false;
    bool pinError = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enter PIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'Enter your PIN to view sensitive wallet information'),
                  const SizedBox(height: 20),
                  PinInput(
                    controller: pinController,
                    pinLength: 6,
                    onCompleted: (pin) async {
                      result = await authProvider.authenticateWithPIN(pin);
                      if (result) {
                        Navigator.of(context).pop();
                      } else {
                        setState(() {
                          pinError = true;
                          pinController.clear();
                        });

                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Incorrect PIN. Please try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                  if (pinError) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Incorrect PIN. Please try again.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (pinController.text.length < 6) {
                      setState(() {
                        pinError = true;
                      });
                      return;
                    }

                    result = await authProvider
                        .authenticateWithPIN(pinController.text);
                    if (result) {
                      Navigator.of(context).pop();
                    } else {
                      setState(() {
                        pinError = true;
                        pinController.clear();
                      });
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  void _showPrivateKeyDialog(BuildContext context, WalletModel? wallet) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if the wallet exists
    if (wallet == null) {
      _showErrorDialog(context, 'No wallet available');
      return;
    }

    bool authenticated = await _showPINDialog(context);
    if (!authenticated) {
      return; // User canceled or failed authentication
    }

    wallet = authProvider.wallet;
    if (wallet == null || wallet.privateKey.isEmpty) {
      _showErrorDialog(context, 'Failed to load private key');
      return;
    }

    // Now show the private key
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
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
                child: SelectableText(
                  wallet!.privateKey,
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
                ClipboardData(text: wallet!.privateKey),
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

  void _showRecoveryPhraseDialog(
      BuildContext context, WalletModel? wallet) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if the wallet exists
    if (wallet == null) {
      _showErrorDialog(context, 'No wallet available');
      return;
    }

    // Always require PIN authentication for viewing recovery phrase
    bool authenticated = await _showPINDialog(context);
    if (!authenticated) {
      return; // User canceled or failed authentication
    }

    // Now the wallet should be fully loaded with mnemonic
    wallet = authProvider.wallet;
    if (wallet == null || wallet.mnemonic.isEmpty) {
      _showErrorDialog(context, 'Failed to load recovery phrase');
      return;
    }

    // Now show the recovery phrase
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
                child: SelectableText(
                  wallet!.mnemonic,
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
                ClipboardData(text: wallet!.mnemonic),
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

// Helper method to show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final onboardingProvider =
        Provider.of<OnboardingProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              // Reset onboarding state when logging out
              await onboardingProvider.resetOnboarding();
              await authProvider.logout();

              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.walletSelection,
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                )),
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitDemoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Demo Mode'),
        content: const Text(
          'Are you sure you want to exit demo mode? You will need to create or import a wallet to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                )),
            onPressed: () async {
              final onboardingProvider =
                  Provider.of<OnboardingProvider>(context, listen: false);
              await onboardingProvider.exitDemoMode();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.walletSelection,
                  (route) => false,
                );
              }
            },
            child: const Text('Exit Demo Mode'),
          ),
        ],
      ),
    );
  }
}
