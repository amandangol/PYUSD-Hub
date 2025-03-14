import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/loading_overlay.dart';
import '../provider/auth_provider.dart';

class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({Key? key}) : super(key: key);

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  bool _isCreating = false;
  bool _walletCreated = false;
  bool _phraseVisible = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final primaryColor =
        isDarkMode ? theme.colorScheme.primary : const Color(0xFF3D56F0);
    final backgroundColor = isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;
    final cardColor = isDarkMode ? const Color(0xFF252543) : Colors.white;
    final surfaceColor =
        isDarkMode ? const Color(0xFF252543) : const Color(0xFFF5F7FF);

    return LoadingOverlay(
      isLoading: _isCreating,
      loadingText: 'Creating your wallet...',
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Create Wallet',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          iconTheme: IconThemeData(
            color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create a New PYUSD Wallet',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We will generate a secure wallet for you to store and manage your PYUSD.',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),

                // Security Information Card
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.shield_rounded,
                              color: primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Important Security Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SecurityInfoItem(
                        icon: Icons.key_rounded,
                        text:
                            'After creating your wallet, you will receive a recovery phrase',
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 12),
                      SecurityInfoItem(
                        icon: Icons.note_alt_outlined,
                        text: 'Write down this phrase and store it securely',
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 12),
                      SecurityInfoItem(
                        icon: Icons.people_alt_outlined,
                        text:
                            'Never share your recovery phrase or private key with anyone',
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 12),
                      SecurityInfoItem(
                        icon: Icons.warning_amber_rounded,
                        text: 'Lost recovery phrases cannot be recovered',
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                if (!_walletCreated)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isCreating
                          ? null
                          : () async {
                              setState(() {
                                _isCreating = true;
                              });

                              try {
                                await authProvider.createWallet();
                                if (mounted) {
                                  setState(() {
                                    _walletCreated = true;
                                    _isCreating = false;
                                  });
                                }
                              } catch (e) {
                                if (mounted) {
                                  SnackbarUtil.showSnackbar(
                                    context: context,
                                    message: "Error: ${e.toString()}",
                                  );

                                  setState(() {
                                    _isCreating = false;
                                  });
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: primaryColor.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Create Wallet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.key_rounded,
                                        color: primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Recovery Phrase',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? Colors.white
                                            : const Color(0xFF1A1A2E),
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(
                                    _phraseVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: primaryColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _phraseVisible = !_phraseVisible;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? const Color(0xFF1A1A2E)
                                    : const Color(0xFFF5F7FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: _phraseVisible
                                  ? Text(
                                      authProvider.wallet?.mnemonic ?? '',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: isDarkMode
                                            ? Colors.white
                                            : const Color(0xFF1A1A2E),
                                        height: 1.5,
                                      ),
                                    )
                                  : const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '• • • • • • • • • • • •',
                                            style: TextStyle(
                                              fontSize: 24,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                  text: authProvider.wallet?.mnemonic ?? '',
                                ));
                                SnackbarUtil.showSnackbar(
                                  context: context,
                                  message:
                                      'Recovery phrase copied to clipboard',
                                  isError: false,
                                  icon: Icons.check_circle,
                                );
                              },
                              icon: const Icon(Icons.copy_rounded),
                              label: const Text('Copy to Clipboard'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor:
                                    isDarkMode ? Colors.white : Colors.black87,
                                backgroundColor: isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                elevation: 0,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => const MainApp()),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: primaryColor.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'I\'ve Saved My Recovery Phrase',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SecurityInfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDarkMode;

  const SecurityInfoItem({
    Key? key,
    required this.icon,
    required this.text,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}
