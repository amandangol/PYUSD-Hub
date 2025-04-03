import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import 'package:pyusd_hub/utils/snackbar_utils.dart';
import '../../../widgets/pyusd_components.dart';
import '../../authentication/provider/auth_provider.dart';
import '../../authentication/provider/security_setting_provider.dart';
import '../../authentication/provider/session_provider.dart';
import '../../onboarding/provider/onboarding_provider.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final TextEditingController _pinController = TextEditingController();
  late BuildContext _scaffoldContext;
  String? _errorMessage;

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
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Enable Biometrics'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your PIN to enable biometric authentication'),
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
                      obscureText: !securityProvider.isPinVisible,
                      obscuringCharacter: '•',
                      onCompleted: (pin) async {
                        // Close dialog first
                        Navigator.of(dialogContext).pop();

                        // Process biometrics enabling
                        final success =
                            await securityProvider.enableBiometrics(pin);

                        if (mounted) {
                          if (success) {
                            // Update the provider state directly
                            securityProvider.setIsBiometricsEnabled(true);

                            // Show success message
                            SnackbarUtil.showSnackbar(
                              context: _scaffoldContext,
                              message: 'Biometrics enabled successfully',
                            );
                          } else {
                            // Show error message
                            SnackbarUtil.showSnackbar(
                              context: _scaffoldContext,
                              message: securityProvider.error ??
                                  'Failed to enable biometrics',
                              isError: true,
                            );
                          }
                        }
                        _pinController.clear();
                      },
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      securityProvider.isPinVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        securityProvider.togglePinVisibility();
                      });
                    },
                  ),
                ],
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
      ),
    );
  }

  // Add this new method to show disable confirmation dialog
  void _showDisableBiometricsDialog(SecuritySettingsProvider securityProvider) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Biometrics'),
        content: const Text(
          'Are you sure you want to disable biometric authentication? You will need to use your PIN to access your wallet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await securityProvider.disableBiometrics();
              if (mounted) {
                if (success) {
                  SnackbarUtil.showSnackbar(
                    context: _scaffoldContext,
                    message: 'Biometrics disabled',
                  );
                } else {
                  SnackbarUtil.showSnackbar(
                    context: _scaffoldContext,
                    message: securityProvider.error ??
                        'Failed to disable biometrics',
                    isError: true,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Disable'),
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
                      obscureText: securityProvider.pinChangeStep ==
                              PinChangeStep.enterCurrent
                          ? !securityProvider.isPinVisible
                          : !securityProvider.isNewPinVisible,
                      obscuringCharacter: '•',
                      onCompleted: (pin) async {
                        if (securityProvider.pinChangeStep ==
                            PinChangeStep.enterCurrent) {
                          final success =
                              await securityProvider.setCurrentPin(pin);
                          if (!success) {
                            // Clear the PIN input if validation fails
                            _pinController.clear();
                            // Show error message if any
                            if (mounted) {
                              SnackbarUtil.showSnackbar(
                                context: context,
                                message:
                                    securityProvider.error ?? 'Invalid PIN',
                                isError: true,
                              );
                            }
                          } else {
                            _pinController.clear();
                          }
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
                              _pinController.clear();
                            }
                          }
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
                  IconButton(
                    icon: Icon(
                      securityProvider.pinChangeStep ==
                              PinChangeStep.enterCurrent
                          ? (securityProvider.isPinVisible
                              ? Icons.visibility_off
                              : Icons.visibility)
                          : (securityProvider.isNewPinVisible
                              ? Icons.visibility_off
                              : Icons.visibility),
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () {
                      if (securityProvider.pinChangeStep ==
                          PinChangeStep.enterCurrent) {
                        securityProvider.togglePinVisibility();
                      } else {
                        securityProvider.toggleNewPinVisibility();
                      }
                    },
                  ),
                ],
              ),
              if (securityProvider.error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          securityProvider.error!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final onboardingProvider = Provider.of<OnboardingProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (onboardingProvider.isDemoMode || !authProvider.hasWallet) {
      return _buildDemoSecurityView(context);
    }

    return ChangeNotifierProxyProvider<AuthProvider, SecuritySettingsProvider>(
      create: (ctx) => SecuritySettingsProvider(
        Provider.of<AuthProvider>(ctx, listen: false),
      ),
      update: (ctx, auth, previous) =>
          previous ?? SecuritySettingsProvider(auth),
      child: Consumer<SecuritySettingsProvider>(
        builder: (ctx, securityProvider, _) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
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
                        child: CircularProgressIndicator(
                            color: theme.colorScheme.primary))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Security Info Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.security,
                                        color: theme.colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Security Options',
                                      style:
                                          theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Secure your wallet with multiple authentication methods',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // PIN Section
                          Text(
                            'PIN Protection',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your PIN is required to access your wallet and confirm transactions',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildChangePINSection(),

                          const SizedBox(height: 32),

                          // Biometrics Section
                          if (securityProvider.isBiometricsAvailable)
                            Consumer<SecuritySettingsProvider>(
                              builder: (context, provider, _) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Biometric Authentication',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Use fingerprint or face ID to quickly access your wallet',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SwitchListTile(
                                    title: const Text('Enable Biometrics'),
                                    value: provider.isBiometricsEnabled,
                                    onChanged: (value) async {
                                      if (value) {
                                        _showEnableBiometricsDialog();
                                      } else {
                                        _showDisableBiometricsDialog(provider);
                                      }
                                    },
                                    secondary: Icon(
                                      Icons.fingerprint,
                                      color: provider.isBiometricsEnabled
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface
                                              .withOpacity(0.5),
                                    ),
                                  ),
                                  if (provider.error != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.error
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 16,
                                            color: theme.colorScheme.error,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              provider.error!,
                                              style: TextStyle(
                                                color: theme.colorScheme.error,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                          const SizedBox(height: 32),

                          // Auto-Lock Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Auto-Lock',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Automatically lock your wallet after a period of inactivity',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
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
                                          color: theme.colorScheme.primary),
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

  Widget _buildDemoSecurityView(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PyusdAppBar(
        isDarkMode: isDarkMode,
        showLogo: true,
        title: "Security Settings",
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Security Features Unavailable in Demo Mode',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Create or import a wallet to access security features like:',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildFeatureItem(
                context,
                Icons.fingerprint,
                'Biometric Authentication',
                'Secure your wallet with fingerprint or face ID',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                Icons.pin,
                'PIN Management',
                'Change or reset your wallet PIN',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                Icons.lock_clock,
                'Auto-Lock Settings',
                'Configure automatic wallet locking',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Go back to settings
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Back to Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
