import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pyusd_hub/screens/trace/widgets/trace_widgets.dart';
import '../../../widgets/pyusd_components.dart';
import '../../../routes/app_routes.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';

class ShowMnemonicScreen extends StatefulWidget {
  final String mnemonic;
  final String pin;

  const ShowMnemonicScreen({
    super.key,
    required this.mnemonic,
    required this.pin,
  });

  @override
  State<ShowMnemonicScreen> createState() => _ShowMnemonicScreenState();
}

class _ShowMnemonicScreenState extends State<ShowMnemonicScreen> {
  bool _isMnemonicVisible = false;
  bool _hasCopied = false;
  List<String> _mnemonicWords = [];
  bool _hasConfirmedUnderstanding = false;

  @override
  void initState() {
    super.initState();
    _mnemonicWords = widget.mnemonic.split(' ');
  }

  void _toggleMnemonicVisibility() {
    setState(() {
      _isMnemonicVisible = !_isMnemonicVisible;
    });
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.mnemonic));
    setState(() {
      _hasCopied = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _hasCopied = false;
        });
      }
    });
  }

  void _proceedToVerification() {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.verifyMnemonic,
      arguments: {
        'mnemonic': widget.mnemonic,
        'pin': widget.pin,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: PyusdAppBar(
          showLogo: false,
          isDarkMode: isDarkMode,
          title: "Backup Recovery Phrase",
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Write Down Your Recovery Phrase',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Write down or copy these 12 words in the exact order shown. Anyone with this phrase can access your funds.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),

                // Recovery phrase display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recovery Phrase',
                            style: theme.textTheme.titleMedium,
                          ),
                          TextButton.icon(
                            onPressed: _toggleMnemonicVisibility,
                            icon: Icon(_isMnemonicVisible
                                ? Icons.visibility_off
                                : Icons.visibility),
                            label: Text(_isMnemonicVisible ? 'Hide' : 'Show'),
                          ),
                        ],
                      ),
                      if (_isMnemonicVisible)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _mnemonicWords.length,
                            itemBuilder: (context, index) {
                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.dividerColor),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _mnemonicWords[index],
                                        style: theme.textTheme.bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          height: 150,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.lock_outline,
                            size: 48,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: _copyToClipboard,
                        icon: Icon(_hasCopied ? Icons.check : Icons.copy),
                        label:
                            Text(_hasCopied ? 'Copied!' : 'Copy to clipboard'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Understanding confirmation
                CheckboxListTile(
                  value: _hasConfirmedUnderstanding,
                  onChanged: (value) {
                    setState(() {
                      _hasConfirmedUnderstanding = value ?? false;
                    });
                  },
                  title: Text(
                    'I understand that if I lose my recovery phrase, I will not be able to access my funds',
                    style: theme.textTheme.bodyMedium,
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                const SizedBox(height: 32),

                // Continue button
                ElevatedButton(
                  onPressed: _hasConfirmedUnderstanding && _isMnemonicVisible
                      ? _proceedToVerification
                      : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'I\'ve Written It Down',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Warning message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: theme.colorScheme.error.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Never share your recovery phrase with anyone and keep it in a safe place.',
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

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                const Text('Cancel Wallet Creation?'),
              ],
            ),
            content: const Text(
              'Going back will delete this wallet. You will need to create a new wallet and generate a new recovery phrase. Are you sure you want to proceed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No, Keep This Wallet'),
              ),
              TraceButton(
                icon: Icons.delete_forever_rounded,
                text: 'Yes, Go Back',
                backgroundColor: Colors.red,
                onPressed: () async {
                  // Delete the wallet and authentication data
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.deleteWallet(widget.pin);

                  if (mounted) {
                    Navigator.of(context).pop(true);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ) ??
        false;

    return shouldPop;
  }
}
