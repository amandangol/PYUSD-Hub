import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import '../widgets/loading_overlay.dart';
import 'home_screen.dart';

class ImportWalletScreen extends StatefulWidget {
  const ImportWalletScreen({Key? key}) : super(key: key);

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phraseController = TextEditingController();
  final TextEditingController _privateKeyController = TextEditingController();
  bool _isLoading = false;
  int _currentTab = 0;

  @override
  void dispose() {
    _phraseController.dispose();
    _privateKeyController.dispose();
    super.dispose();
  }

  Future<void> _importWallet(WalletProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_currentTab == 0) {
        // Import with mnemonic
        await provider.importWalletFromMnemonic(_phraseController.text.trim());
      } else {
        // Import with private key
        await provider
            .importWalletFromPrivateKey(_privateKeyController.text.trim());
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);

    return LoadingOverlay(
      isLoading: _isLoading,
      loadingText: 'Importing wallet...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Import Wallet'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Import Your PYUSD Wallet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Tab selection
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _currentTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _currentTab == 0
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            'Recovery Phrase',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _currentTab == 0
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _currentTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _currentTab == 1
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            'Private Key',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _currentTab == 1
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_currentTab == 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter your 12-word recovery phrase:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phraseController,
                        decoration: const InputDecoration(
                          hintText:
                              'Enter recovery phrase (12 words separated by spaces)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your recovery phrase';
                          }
                          final words = value.trim().split(' ');
                          if (words.length != 12) {
                            return 'Recovery phrase must contain exactly 12 words';
                          }
                          return null;
                        },
                      ),
                    ],
                  )
                // Private Key tab content
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter your private key:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _privateKeyController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your private key',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your private key';
                          }
                          final key = value.trim();
                          if (key.startsWith('0x')) {
                            if (key.length != 66) {
                              return 'Private key must be 64 characters (with 0x prefix)';
                            }
                          } else if (key.length != 64) {
                            return 'Private key must be 64 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),

                const Spacer(),
                ElevatedButton(
                  onPressed:
                      _isLoading ? null : () => _importWallet(walletProvider),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Import Wallet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
