import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../provider/authentication_provider.dart';
import '../../services/wallet_service.dart';
import '../../widgets/loading_overlay.dart';

class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({Key? key}) : super(key: key);

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  late WalletService _walletService;
  List<String> _mnemonic = [];
  bool _isLoading = true;
  bool _mnemonicConfirmed = false;
  bool _displayMnemonic = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _walletService = Provider.of<WalletService>(context, listen: false);
    _generateWallet();
  }

  Future<void> _generateWallet() async {
    setState(() => _isLoading = true);

    try {
      // Generate a new mnemonic
      _mnemonic = await _walletService.generateMnemonic();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to generate wallet: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _createWallet() async {
    setState(() => _isLoading = true);

    try {
      // Create wallet from mnemonic
      await _walletService.createWallet(_mnemonic.join(' '));

      // Navigate to the main app
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainApp()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to create wallet: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _mnemonic.join(' ')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recovery phrase copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor =
        isDarkMode ? theme.colorScheme.primary : const Color(0xFF3D56F0);
    final backgroundColor = isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;

    return LoadingOverlay(
      isLoading: _isLoading,
      loadingText: 'Generating wallet...',
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Create New Wallet',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: _mnemonicConfirmed
              ? _buildConfirmationScreen()
              : _buildMnemonicScreen(),
        ),
      ),
    );
  }

  Widget _buildMnemonicScreen() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor =
        isDarkMode ? theme.colorScheme.primary : const Color(0xFF3D56F0);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Recovery Phrase',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Write down these 12 words in order and keep them in a safe place. Anyone with this phrase can access your wallet.',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 24),

          // Recovery phrase display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF252543) : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? Colors.white24 : Colors.grey[300]!,
              ),
            ),
            child: _displayMnemonic
                ? _buildMnemonicGrid()
                : Center(
                    child: Text(
                      'Tap to reveal recovery phrase',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: primaryColor,
                    elevation: 0,
                    side: BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _displayMnemonic = !_displayMnemonic;
                    });
                  },
                  icon: Icon(_displayMnemonic
                      ? Icons.visibility_off
                      : Icons.visibility),
                  label: Text(_displayMnemonic ? 'Hide' : 'Show'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: primaryColor,
                    elevation: 0,
                    side: BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),

          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _mnemonicConfirmed = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('I\'ve saved my recovery phrase'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMnemonicGrid() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _mnemonic.length,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.black38 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode ? Colors.white24 : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Text(
                '${index + 1}.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white54 : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _mnemonic[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfirmationScreen() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor =
        isDarkMode ? theme.colorScheme.primary : const Color(0xFF3D56F0);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Important Security Note',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Before proceeding, please confirm you understand:',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 24),

          // Security confirmations
          _buildSecurityItem(
            icon: Icons.lock,
            title:
                'Your recovery phrase is the only way to restore your wallet',
            isDarkMode: isDarkMode,
          ),

          _buildSecurityItem(
            icon: Icons.shield,
            title:
                'Keep your recovery phrase offline and never share it with anyone',
            isDarkMode: isDarkMode,
          ),

          _buildSecurityItem(
            icon: Icons.warning_amber_rounded,
            title:
                'If you lose your recovery phrase, you will lose access to your funds',
            isDarkMode: isDarkMode,
          ),

          const Spacer(),

          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _mnemonicConfirmed = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Go Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _createWallet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Create Wallet'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem({
    required IconData icon,
    required String title,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white10 : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
