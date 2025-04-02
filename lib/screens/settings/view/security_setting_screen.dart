import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import 'package:pyusd_hub/utils/snackbar_utils.dart';
import '../../../widgets/pyusd_components.dart';
import '../../authentication/provider/auth_provider.dart';
import '../../authentication/provider/security_setting_provider.dart';
import '../../authentication/provider/session_provider.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final TextEditingController _pinController = TextEditingController();
  late BuildContext _scaffoldContext;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldContext = context;
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  PinTheme _defaultPinTheme(BuildContext context) {
    final theme = Theme.of(context);
    return PinTheme(
      width: 46,
      height: 56,
      textStyle: TextStyle(
        fontSize: 20,
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor,
        ),
      ),
    );
  }

  // Method to show biometrics activation dialog
  void _showEnableBiometricsDialog() {
    final theme = Theme.of(context);
    final defaultPinTheme = _defaultPinTheme(context);
    final primaryColor = theme.colorScheme.primary;
    final securityProvider =
        Provider.of<SecuritySettingsProvider>(context, listen: false);

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primaryColor,
          width: 2,
        ),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primaryColor.withOpacity(0.5),
        ),
      ),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enable Biometrics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your PIN'),
            const SizedBox(height: 16),
            Pinput(
              controller: _pinController,
              length: 6,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: focusedPinTheme,
              submittedPinTheme: submittedPinTheme,
              obscureText: true,
              obscuringCharacter: '•',
              onCompleted: (pin) async {
                Navigator.of(dialogContext).pop();

                final success = await securityProvider.enableBiometrics(pin);
                if (success) {
                  // Directly update the state and notify listeners
                  securityProvider.setIsBiometricsEnabled(true);

                  if (mounted) {
                    SnackbarUtil.showSnackbar(
                      context: _scaffoldContext,
                      message: 'Biometrics enabled',
                    );
                  }
                } else {
                  if (mounted) {
                    SnackbarUtil.showSnackbar(
                      context: _scaffoldContext,
                      message: 'Failed to enable biometrics',
                      isError: true,
                    );
                  }
                }
                _pinController.clear();
              },
              keyboardType: TextInputType.number,
              crossAxisAlignment: CrossAxisAlignment.center,
              pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
              showCursor: true,
              cursor: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    width: 2,
                    height: 22,
                    color: primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _pinController.clear();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePINSection() {
    final theme = Theme.of(context);
    final defaultPinTheme = _defaultPinTheme(context);
    final primaryColor = theme.colorScheme.primary;
    final securityProvider = Provider.of<SecuritySettingsProvider>(context);
    final onBackground = theme.colorScheme.onSurface;

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primaryColor,
          width: 2,
        ),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primaryColor.withOpacity(0.5),
        ),
      ),
    );

    if (securityProvider.pinChangeStep == PinChangeStep.none) {
      return PyusdButton(
        onPressed: () {
          securityProvider.startPinChange();
        },
        text: 'Change PIN',
        icon: const Icon(Icons.lock_outline),
      );
    } else {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                securityProvider.pinChangeStep == PinChangeStep.enterCurrent
                    ? 'Enter Current PIN'
                    : 'Enter New PIN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: onBackground,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                securityProvider.pinChangeStep == PinChangeStep.enterCurrent
                    ? 'Verify your current PIN to proceed with changes'
                    : 'Choose a new 6-digit PIN for your wallet',
                style: TextStyle(
                  fontSize: 14,
                  color: onBackground.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Pinput(
                      controller: _pinController,
                      length: 6,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: submittedPinTheme,
                      obscureText: true,
                      obscuringCharacter: '•',
                      onCompleted: (pin) async {
                        if (securityProvider.pinChangeStep ==
                            PinChangeStep.enterCurrent) {
                          securityProvider.setCurrentPin(pin);
                          _pinController.clear();
                        } else {
                          final success = await securityProvider.changePin(pin);

                          if (mounted) {
                            if (success) {
                              SnackbarUtil.showSnackbar(
                                context: context,
                                message: 'PIN changed successfully',
                              );
                            } else {
                              SnackbarUtil.showSnackbar(
                                context: context,
                                message: securityProvider.error ??
                                    'Failed to change PIN',
                                isError: true,
                              );
                            }
                          }
                          _pinController.clear();
                        }
                      },
                      keyboardType: TextInputType.number,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                      showCursor: true,
                      cursor: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            width: 2,
                            height: 22,
                            color: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      securityProvider.resetPinChangeProcess();
                      _pinController.clear();
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final onBackground = Theme.of(context).colorScheme.onSurface;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return ChangeNotifierProxyProvider<AuthProvider, SecuritySettingsProvider>(
      create: (ctx) => SecuritySettingsProvider(
        Provider.of<AuthProvider>(ctx, listen: false),
      ),
      update: (ctx, auth, previous) =>
          previous ?? SecuritySettingsProvider(auth),
      child: Consumer<SecuritySettingsProvider>(
        builder: (ctx, securityProvider, _) {
          return Scaffold(
            backgroundColor: backgroundColor,
            appBar: PyusdAppBar(
              isDarkMode: isDarkMode,
              showLogo: false,
              title: "Security Settings",
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: securityProvider.isCheckingBiometrics
                    ? Center(
                        child: CircularProgressIndicator(color: primaryColor))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Security Info Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.security, color: primaryColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Security Options',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: onBackground,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Secure your wallet with multiple authentication methods',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: onBackground.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // PIN Section
                          Text(
                            'PIN Protection',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: onBackground,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your PIN is required to access your wallet and confirm transactions',
                            style: TextStyle(
                              fontSize: 14,
                              color: onBackground.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildChangePINSection(),

                          const SizedBox(height: 32),

                          // Biometrics Section
                          if (securityProvider.isBiometricsAvailable)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Biometric Authentication',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: onBackground,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Use fingerprint to quickly access your wallet',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: onBackground.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SwitchListTile(
                                  title: const Text('Enable Biometrics'),
                                  value: securityProvider.isBiometricsEnabled,
                                  onChanged: (value) async {
                                    if (value) {
                                      // Enable biometrics - show PIN dialog
                                      _showEnableBiometricsDialog();
                                    } else {
                                      // Disable biometrics directly
                                      final success = await securityProvider
                                          .disableBiometrics();

                                      // Force state update
                                      setState(() {
                                        securityProvider
                                            .setIsBiometricsEnabled(false);
                                      });

                                      if (mounted) {
                                        if (success) {
                                          SnackbarUtil.showSnackbar(
                                            context: _scaffoldContext,
                                            message: 'Biometrics disabled',
                                          );
                                        } else {
                                          SnackbarUtil.showSnackbar(
                                            context: _scaffoldContext,
                                            message:
                                                'Failed to disable biometrics',
                                            isError: true,
                                          );
                                        }
                                      }
                                    }
                                  },
                                  secondary: Icon(
                                    Icons.fingerprint,
                                    color: securityProvider.isBiometricsEnabled
                                        ? primaryColor
                                        : onBackground.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 32),

                          // Auto-Lock Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Auto-Lock',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: onBackground,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Automatically lock your wallet after a period of inactivity',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: onBackground.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Consumer<SessionProvider>(
                                builder: (context, sessionProvider, _) {
                                  return DropdownButtonFormField<int>(
                                    value: sessionProvider.autoLockDuration,
                                    decoration: InputDecoration(
                                      labelText: 'Auto-Lock Timer',
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      prefixIcon: Icon(Icons.timer,
                                          color: primaryColor),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 1, child: Text('1 minute')),
                                      DropdownMenuItem(
                                          value: 5, child: Text('5 minutes')),
                                      DropdownMenuItem(
                                          value: 15, child: Text('15 minutes')),
                                      DropdownMenuItem(
                                          value: 30, child: Text('30 minutes')),
                                      DropdownMenuItem(
                                          value: 60, child: Text('1 hour')),
                                      DropdownMenuItem(
                                          value: 0, child: Text('Never')),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        sessionProvider
                                            .setAutoLockDuration(value);
                                      }
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
