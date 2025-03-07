import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

import '../../../providers/wallet_provider.dart';
import '../../../utils/snackbar_utils.dart';
import '../../homescreen/widgets/custom_textfield.dart';

class SendTransactionScreen extends StatefulWidget {
  const SendTransactionScreen({Key? key}) : super(key: key);

  @override
  _SendTransactionScreenState createState() => _SendTransactionScreenState();
}

class _SendTransactionScreenState extends State<SendTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isValidAddress = false;
  double _estimatedGasFee = 0.0;
  double _gasPrice = 0.0;
  int _estimatedGas = 0;
  bool _isLoading = false;
  bool _isEstimatingGas = false;
  String _selectedAsset = 'PYUSD'; // Default to PYUSD

  // For QR scanner result
  String? _scanResult;

  @override
  void initState() {
    super.initState();
    _fetchGasPrice();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchGasPrice() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    try {
      _gasPrice = await walletProvider.getCurrentGasPrice();
      setState(() {});
    } catch (e) {
      // Use default gas price if fetch fails
      _gasPrice = 20.0; // 20 Gwei default
    }
  }

  void _validateAddress(String address) {
    try {
      // Validate Ethereum address format
      final ethAddress = EthereumAddress.fromHex(address);
      setState(() {
        _isValidAddress = true;
      });
      _estimateGasFee(); // Re-estimate when address changes
    } catch (e) {
      setState(() {
        _isValidAddress = false;
        _estimatedGasFee = 0.0;
        _estimatedGas = 0;
      });
    }
  }

  Future<void> _estimateGasFee() async {
    if (!_isValidAddress || _amountController.text.isEmpty) {
      setState(() {
        _estimatedGasFee = 0.0;
        _estimatedGas = 0;
      });
      return;
    }

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    try {
      setState(() {
        _isEstimatingGas = true;
      });

      double? amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) return;

      final recipient = EthereumAddress.fromHex(_addressController.text);

      // Estimate gas based on selected asset
      int estimatedGas;

      if (_selectedAsset == 'PYUSD') {
        estimatedGas = await walletProvider.estimateTokenTransferGas(
          recipient.hex,
          amount,
        );
      } else {
        estimatedGas = await walletProvider.estimateEthTransferGas(
          recipient.hex,
          amount,
        );
      }

      // Get current gas price if we don't have it yet
      if (_gasPrice <= 0) {
        _gasPrice = await walletProvider.getCurrentGasPrice();
      }

      // Calculate fee: gas units × gas price (in Gwei) × 10^-9 (to convert to ETH)
      _estimatedGasFee = estimatedGas * _gasPrice * 1e-9;
      _estimatedGas = estimatedGas;

      setState(() {});
    } catch (e) {
      print('Gas estimation error: $e');
      // Set default values if estimation fails
      setState(() {
        if (_selectedAsset == 'PYUSD') {
          _estimatedGas = 100000; // Default for token transfers
        } else {
          _estimatedGas = 21000; // Default for ETH transfers
        }
        _estimatedGasFee = _estimatedGas * _gasPrice * 1e-9;
      });
    } finally {
      setState(() {
        _isEstimatingGas = false;
      });
    }
  }

  Future<void> _sendTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final address = _addressController.text.trim();
    final amount = double.parse(_amountController.text);

    // Check balance before proceeding
    if (_selectedAsset == 'PYUSD' && amount > walletProvider.tokenBalance) {
      SnackbarUtil.showSnackbar(
        context: context,
        message: 'Insufficient PYUSD balance',
        isError: true,
      );
      return;
    } else if (_selectedAsset == 'ETH' && amount > walletProvider.ethBalance) {
      SnackbarUtil.showSnackbar(
        context: context,
        message: 'Insufficient ETH balance',
        isError: true,
      );
      return;
    }

    // For ETH transactions, make sure they have enough to cover amount + gas
    if (_selectedAsset == 'ETH' &&
        (amount + _estimatedGasFee) > walletProvider.ethBalance) {
      SnackbarUtil.showSnackbar(
        context: context,
        message:
            'Insufficient ETH to cover both transaction amount and gas fees',
        isError: true,
      );
      return;
    }

    // Check if there's enough ETH for gas when sending PYUSD
    if (_selectedAsset == 'PYUSD' &&
        _estimatedGasFee > walletProvider.ethBalance) {
      SnackbarUtil.showSnackbar(
        context: context,
        message: 'Insufficient ETH for gas fees',
        isError: true,
      );
      return;
    }

    // Confirm transaction details
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recipient: $address'),
            Text('Amount: $amount ${_selectedAsset}'),
            const SizedBox(height: 8),
            const Text('Gas Details:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Estimated Gas Units: $_estimatedGas'),
            Text('Gas Price: ${_gasPrice.toStringAsFixed(2)} Gwei'),
            Text('Total Gas Fee: ${_estimatedGasFee.toStringAsFixed(6)} ETH'),
            if (_selectedAsset == 'ETH')
              Text(
                  'Total Amount (with gas): ${(amount + _estimatedGasFee).toStringAsFixed(6)} ETH'),
            const SizedBox(height: 8),
            Text('Network: ${walletProvider.currentNetworkName}'),
            const SizedBox(height: 12),
            const Text('Please confirm this transaction details.',
                style:
                    TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String txHash;

      if (_selectedAsset == 'PYUSD') {
        txHash = await walletProvider.sendPYUSD(
          address,
          amount,
          gasPrice: _gasPrice, // Pass the gas price
          gasLimit: _estimatedGas, // Pass the gas limit
        );
      } else {
        txHash = await walletProvider.sendETH(
          address,
          amount,
          gasPrice: _gasPrice, // Pass the gas price
          gasLimit: _estimatedGas, // Pass the gas limit
        );
      }

      // Show success message
      if (mounted) {
        SnackbarUtil.showSnackbar(
          context: context,
          message: 'Transaction sent! Hash: ${txHash.substring(0, 10)}...',
          isError: false,
        );

        // Navigate back to the previous screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      SnackbarUtil.showSnackbar(
          context: context,
          message: 'Error sending transaction: $e',
          isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scanQRCode() async {
    // This would normally use a QR code scanner plugin
    // For this example, we'll just simulate it by setting a value
    setState(() {
      _addressController.text = '0x71C7656EC7ab88b098defB751B7401B5f6d8976F';
      _validateAddress(_addressController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine available balance based on selected asset
    final availableBalance = _selectedAsset == 'PYUSD'
        ? walletProvider.tokenBalance
        : walletProvider.ethBalance;

    // For ETH transfers, calculate the max amount that can be sent considering gas fees
    final maxSendableEth = _selectedAsset == 'ETH' && _estimatedGasFee > 0
        ? (walletProvider.ethBalance - _estimatedGasFee)
            .clamp(0.0, double.infinity)
        : walletProvider.ethBalance;

    return Scaffold(
      appBar: AppBar(
        title: Text('Send $_selectedAsset'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Asset Selection
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Asset',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _AssetSelectionCard(
                              assetName: 'PYUSD',
                              isSelected: _selectedAsset == 'PYUSD',
                              balance: walletProvider.tokenBalance,
                              onTap: () {
                                setState(() {
                                  _selectedAsset = 'PYUSD';
                                });
                                _estimateGasFee();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AssetSelectionCard(
                              assetName: 'ETH',
                              isSelected: _selectedAsset == 'ETH',
                              balance: walletProvider.ethBalance,
                              onTap: () {
                                setState(() {
                                  _selectedAsset = 'ETH';
                                });
                                _estimateGasFee();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Balance Display
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Available Balance',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedAsset == 'ETH'
                            ? '${availableBalance.toStringAsFixed(6)} ETH'
                            : '${availableBalance.toStringAsFixed(6)} PYUSD',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      if (_selectedAsset == 'ETH' && _estimatedGasFee > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Max sendable (after gas): ${maxSendableEth.toStringAsFixed(6)} ETH',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Network: ${walletProvider.currentNetworkName}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Recipient Address Input
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recipient Details',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _addressController,
                              labelText: 'Recipient Address',
                              hintText: '0x...',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a recipient address';
                                }
                                try {
                                  EthereumAddress.fromHex(value);
                                  return null;
                                } catch (e) {
                                  return 'Invalid Ethereum address';
                                }
                              },
                              onChanged: _validateAddress,
                              suffixIcon: _isValidAddress
                                  ? const Icon(Icons.check_circle,
                                      color: Colors.green)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _scanQRCode,
                            icon: const Icon(Icons.qr_code_scanner),
                            tooltip: 'Scan QR Code',
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  colorScheme.primary.withOpacity(0.1),
                              foregroundColor: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Amount Input
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _amountController,
                              labelText: 'Amount',
                              hintText: 'Enter amount',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,6}$')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an amount';
                                }
                                final amount = double.tryParse(value);
                                if (amount == null || amount <= 0) {
                                  return 'Invalid amount';
                                }

                                if (_selectedAsset == 'ETH') {
                                  // For ETH, check if amount + gas fee exceeds balance
                                  if (amount > maxSendableEth) {
                                    return 'Amount exceeds max sendable (gas fee included)';
                                  }
                                } else {
                                  // For PYUSD, just check token balance
                                  if (amount > availableBalance) {
                                    return 'Insufficient balance';
                                  }
                                }
                                return null;
                              },
                              onChanged: (_) => _estimateGasFee(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                if (_selectedAsset == 'ETH' &&
                                    _estimatedGasFee > 0) {
                                  _amountController.text =
                                      maxSendableEth.toString();
                                } else {
                                  _amountController.text =
                                      availableBalance.toString();
                                }
                              });
                              _estimateGasFee();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.onPrimaryContainer,
                            ),
                            child: const Text('MAX'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_selectedAsset == 'ETH' && _estimatedGasFee > 0)
                        Text(
                          'Available: ${maxSendableEth.toStringAsFixed(6)} ETH (after gas fees)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        Text(
                          'Balance: ${availableBalance.toStringAsFixed(6)} $_selectedAsset',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Gas Fee Estimation
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Transaction Fee',
                            style: theme.textTheme.titleMedium,
                          ),
                          if (_isEstimatingGas)
                            SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Gas Units:'),
                          Text(
                            _estimatedGas > 0
                                ? _estimatedGas.toString()
                                : 'Not estimated',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Gas Price:'),
                          Text(
                            '${_gasPrice.toStringAsFixed(9)} Gwei',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Fee:'),
                          Text(
                            _estimatedGasFee > 0
                                ? '${_estimatedGasFee.toStringAsFixed(15)} ETH'
                                : 'Enter details above',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_selectedAsset == 'PYUSD' &&
                          _estimatedGasFee > walletProvider.ethBalance &&
                          _estimatedGasFee > 0)
                        const Text(
                          'Warning: Insufficient ETH for gas fees',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Send Button
              ElevatedButton(
                onPressed: _isValidAddress &&
                        _amountController.text.isNotEmpty &&
                        !_isLoading &&
                        !_isEstimatingGas &&
                        !(_selectedAsset == 'PYUSD' &&
                            _estimatedGasFee > walletProvider.ethBalance &&
                            _estimatedGasFee > 0) &&
                        !(_selectedAsset == 'ETH' &&
                            double.tryParse(_amountController.text) != null &&
                            double.parse(_amountController.text) +
                                    _estimatedGasFee >
                                walletProvider.ethBalance)
                    ? _sendTransaction
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      )
                    : Text(
                        'Send $_selectedAsset',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              // Note about gas fees
              const SizedBox(height: 16),
              Text(
                'Note: Transaction requires ETH for gas fees regardless of which asset you send.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Asset selection card widget
class _AssetSelectionCard extends StatelessWidget {
  final String assetName;
  final bool isSelected;
  final double balance;
  final VoidCallback onTap;

  const _AssetSelectionCard({
    required this.assetName,
    required this.isSelected,
    required this.balance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.tertiary : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  assetName == 'PYUSD'
                      ? Icons.attach_money
                      : Icons.currency_exchange,
                  color: isSelected
                      ? colorScheme.inverseSurface
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  assetName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? colorScheme.inverseSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: colorScheme.inverseSurface,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${balance.toStringAsFixed(4)}',
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
