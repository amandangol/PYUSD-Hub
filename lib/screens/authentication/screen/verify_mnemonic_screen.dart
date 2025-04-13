import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/pyusd_components.dart';
import '../../../providers/navigation_provider.dart';
import '../../../routes/app_routes.dart';
import '../../onboarding/provider/onboarding_provider.dart';

class VerifyMnemonicScreen extends StatefulWidget {
  final String mnemonic;
  final String pin;

  const VerifyMnemonicScreen({
    super.key,
    required this.mnemonic,
    required this.pin,
  });

  @override
  State<VerifyMnemonicScreen> createState() => _VerifyMnemonicScreenState();
}

class _VerifyMnemonicScreenState extends State<VerifyMnemonicScreen> {
  bool _isConfirming = false;
  List<String> _mnemonicWords = [];
  List<int> _verificationIndices = [];
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, bool> _wordValidation = {};

  @override
  void initState() {
    super.initState();
    _mnemonicWords = widget.mnemonic.split(' ');
    _setupVerification();
  }

  void _setupVerification() {
    // Select 4 random words for verification
    final indices = List.generate(_mnemonicWords.length, (index) => index)
      ..shuffle();
    _verificationIndices = indices.take(3).toList()..sort();

    // Initialize controllers and validation state for each verification position
    for (var index in _verificationIndices) {
      _controllers[index] = TextEditingController();
      _wordValidation[index] = false;
    }
  }

  void _validateWord(String word, int position) {
    setState(() {
      _wordValidation[position] =
          word.trim().toLowerCase() == _mnemonicWords[position].toLowerCase();
    });
  }

  bool _areAllWordsCorrect() {
    return _verificationIndices
        .every((index) => _wordValidation[index] == true);
  }

  Future<void> _confirmMnemonic() async {
    if (!_areAllWordsCorrect()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all missing words correctly'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isConfirming = true;
    });

    try {
      // Complete onboarding
      final onboardingProvider =
          Provider.of<OnboardingProvider>(context, listen: false);
      await onboardingProvider.completeOnboarding();

      // Set the wallet screen before navigation
      if (mounted) {
        context.read<NavigationProvider>().setWalletScreen();

        // Navigate to main app and clear the navigation stack
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.main,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing setup: $e')),
        );
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: PyusdAppBar(
        showLogo: false,
        isDarkMode: isDarkMode,
        title: "Verify Recovery Phrase",
      ),
      body: SafeArea(
        child: _isConfirming
            ? _buildConfirmingView(theme)
            : _buildVerificationView(theme),
      ),
    );
  }

  Widget _buildConfirmingView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Setting up your wallet...',
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verify Your Recovery Phrase',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Fill in the missing words from your recovery phrase to verify you\'ve saved it correctly.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),

          // Recovery phrase grid with missing words
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Text(
                  'Recovery Phrase',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _mnemonicWords.length,
                  itemBuilder: (context, index) {
                    final isVerificationWord =
                        _verificationIndices.contains(index);
                    final controller = _controllers[index];
                    final isValid = _wordValidation[index];

                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isVerificationWord
                              ? theme.colorScheme.primary
                              : theme.dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
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
                            child: isVerificationWord
                                ? TextField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      hintText: 'Word #${index + 1}',
                                      border: InputBorder.none,
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                      suffixIcon: controller!.text.isNotEmpty
                                          ? Icon(
                                              isValid ?? false
                                                  ? Icons.check_circle
                                                  : Icons.error,
                                              color: isValid ?? false
                                                  ? Colors.green
                                                  : Colors.red,
                                              size: 16,
                                            )
                                          : null,
                                    ),
                                    style: theme.textTheme.bodyMedium,
                                    onChanged: (value) =>
                                        _validateWord(value, index),
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    textInputAction: TextInputAction.next,
                                  )
                                : Text(
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
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Confirm button
          ElevatedButton(
            onPressed: _verificationIndices
                    .every((index) => _controllers[index]!.text.isNotEmpty)
                ? _confirmMnemonic
                : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Confirm & Complete Setup',
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
              border:
                  Border.all(color: theme.colorScheme.error.withOpacity(0.5)),
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
                    'Make sure you\'re entering the exact words in their correct positions.',
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
    );
  }
}
