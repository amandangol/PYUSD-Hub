import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

import '../providers/wallet_provider.dart';
import '../utils/snackbar_utils.dart';
import 'homescreen/widgets/custom_textfield.dart';

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
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _validateAddress(String address) {
    try {
      // Validate Ethereum address format
      final ethAddress = EthereumAddress.fromHex(address);
      setState(() {
        _isValidAddress = true;
      });
    } catch (e) {
      setState(() {
        _isValidAddress = false;
      });
    }
  }

  Future<void> _estimateGasFee() async {
    if (!_isValidAddress || _amountController.text.isEmpty) return;

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    try {
      setState(() {
        _isLoading = true;
      });

      final amount = double.parse(_amountController.text);
      final gasFee = await walletProvider.estimateGasFee(
          _addressController.text.trim(), amount);

      setState(() {
        _estimatedGasFee = gasFee;
      });
    } catch (e) {
      SnackbarUtil.showSnackbar(
          context: context,
          message: 'Failed to estimate gas fee: $e',
          isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final address = _addressController.text.trim();
    final amount = double.parse(_amountController.text);

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
            Text('Amount: $amount PYUSD'),
            Text('Gas Fee: $_estimatedGasFee ETH'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
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
      final success = await walletProvider.sendPYUSD(
        to: address,
        amount: amount,
      );

      if (success) {
        SnackbarUtil.showSnackbar(
          context: context,
          message: 'Transaction sent successfully!',
        );
        Navigator.of(context).pop();
      } else {
        SnackbarUtil.showSnackbar(
            context: context,
            message: 'Transaction failed. Please try again.',
            isError: true);
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

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send PYUSD'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Balance Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Available Balance',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${walletProvider.balance.toStringAsFixed(2)} PYUSD',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Network: ${walletProvider.getCurrentNetworkName()}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recipient Address Input
            CustomTextField(
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
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
            const SizedBox(height: 16),

            // Amount Input
            CustomTextField(
              controller: _amountController,
              labelText: 'Amount',
              hintText: 'Enter PYUSD amount',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,6}$')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Invalid amount';
                }
                if (amount > walletProvider.balance) {
                  return 'Insufficient balance';
                }
                return null;
              },
              onChanged: (_) => _estimateGasFee(),
            ),
            const SizedBox(height: 16),

            // Gas Fee Estimation
            if (_estimatedGasFee > 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Gas Fee:'),
                      Text('${_estimatedGasFee.toStringAsFixed(6)} ETH'),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Send Button
            PrimaryButton(
              onPressed: _isValidAddress &&
                      _amountController.text.isNotEmpty &&
                      !_isLoading
                  ? _sendTransaction
                  : null,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send PYUSD'),
            ),
          ],
        ),
      ),
    );
  }
}
