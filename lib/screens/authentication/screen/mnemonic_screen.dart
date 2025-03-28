import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pyusd_hub/widgets/pyusd_components.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../../providers/navigation_provider.dart';

class MnemonicConfirmationScreen extends StatefulWidget {
  final String mnemonic;
  final String pin;

  const MnemonicConfirmationScreen({
    super.key,
    required this.mnemonic,
    required this.pin,
  });

  @override
  State<MnemonicConfirmationScreen> createState() =>
      _MnemonicConfirmationScreenState();
}

class _MnemonicConfirmationScreenState
    extends State<MnemonicConfirmationScreen> {
  bool _isConfirming = false;
  bool _isMnemonicVisible = false;
  bool _hasCopied = false;
  List<String> _mnemonicWords = [];
  final List<String> _selectedWords = [];
  List<String> _verificationWords = [];
  List<int> _verificationIndices = [];

  @override
  void initState() {
    super.initState();
    _mnemonicWords = widget.mnemonic.split(' ');

    // Choose random indices for verification
    _setupVerification();
  }

  void _setupVerification() {
    // Select 3 random words for verification
    final indices = List.generate(_mnemonicWords.length, (index) => index)
      ..shuffle();
    _verificationIndices = indices.take(3).toList()..sort();

    // Create list of words for verification including the correct ones
    _verificationWords =
        _verificationIndices.map((i) => _mnemonicWords[i]).toList();

    // Add some decoy words
    const decoyWords = [
      'apple',
      'banana',
      'orange',
      'grape',
      'melon',
      'book',
      'chair',
      'table',
      'pencil',
      'phone'
    ];

    // Add only decoy words that aren't in the mnemonic
    final filteredDecoys =
        decoyWords.where((word) => !_mnemonicWords.contains(word)).toList();
    _verificationWords.addAll(filteredDecoys.take(3));

    // Shuffle the verification words
    _verificationWords.shuffle();
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

    // Reset copy status after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _hasCopied = false;
        });
      }
    });
  }

  void _selectWord(String word) {
    setState(() {
      if (_selectedWords.contains(word)) {
        _selectedWords.remove(word);
      } else {
        _selectedWords.add(word);
      }
    });
  }

  bool _isCorrectWordSelected(int index) {
    final correctWord = _mnemonicWords[_verificationIndices[index]];
    return _selectedWords.contains(correctWord);
  }

  bool _areAllCorrectWordsSelected() {
    return _verificationIndices
        .every((index) => _selectedWords.contains(_mnemonicWords[index]));
  }

  Future<void> _confirmMnemonic() async {
    setState(() {
      _isConfirming = true;
    });

    // Simulate a slight delay for a better UX
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      // Set the wallet screen before navigation
      context.read<NavigationProvider>().setWalletScreen();
      // Navigate to main app and clear the navigation stack
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/main',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: PyusdAppBar(
        showLogo: false,
        isDarkMode: isDarkMode,
        title: "Backup Recovery Phrase",
      ),
      body: SafeArea(
        child: _isConfirming
            ? _buildConfirmingView(theme)
            : _buildContentView(theme),
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

  Widget _buildContentView(ThemeData theme) {
    return SingleChildScrollView(
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
              border:
                  Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                // Show/hide button
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

                // Mnemonic grid
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

                // Copy button
                OutlinedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: Icon(_hasCopied ? Icons.check : Icons.copy),
                  label: Text(_hasCopied ? 'Copied!' : 'Copy to clipboard'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Verification section
          // Verification section
          Text(
            'Verify Your Recovery Phrase',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Select the words that appear at positions ${_verificationIndices.map((i) => i + 1).join(', ')} in your recovery phrase.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),

          // Word selection grid
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: _verificationWords.map((word) {
              final isSelected = _selectedWords.contains(word);
              return GestureDetector(
                onTap: () => _selectWord(word),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    word,
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Status indicators
          ...List.generate(3, (index) {
            final isCorrect = _isCorrectWordSelected(index);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.circle_outlined,
                    color: isCorrect ? Colors.green : theme.disabledColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Word at position ${_verificationIndices[index] + 1}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 32),

          // Confirm button
          ElevatedButton(
            onPressed: _areAllCorrectWordsSelected() ? _confirmMnemonic : null,
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
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber[800],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Never share your recovery phrase with anyone and keep it in a safe place.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.amber[800],
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
