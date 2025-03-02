import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/credentials.dart';

import '../providers/wallet_provider.dart';
import '../widgets/loading_overlay.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({Key? key}) : super(key: key);

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;
  bool _showScanner = false;

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture barcode) {
    final List<Barcode> barcodes = barcode.barcodes;
    if (barcodes.isNotEmpty) {
      final String? address = barcodes.first.rawValue;
      if (address != null && address.startsWith('0x')) {
        _addressController.text = address;
        setState(() {
          _showScanner = false;
        });
      }
    }
  }

  Future<void> _send(WalletProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    final address = _addressController.text.trim();
    final amount = double.parse(_amountController.text.trim());

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await provider.sendPYUSD(
        to: address,
        amount: amount,
      );

      if (mounted) {
        if (result) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction sent successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
      loadingText: 'Sending PYUSD...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Send PYUSD'),
        ),
        body: _showScanner ? _buildScanner() : _buildSendForm(walletProvider),
      ),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            onDetect: _onDetect,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _showScanner = false;
              });
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  Widget _buildSendForm(WalletProvider walletProvider) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Send PYUSD',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Recipient Address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        hintText: 'Enter wallet address',
                        border: OutlineInputBorder(),
                      ),
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
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showScanner = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Amount',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'Enter amount',
                  border: OutlineInputBorder(),
                  suffixText: 'PYUSD',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  try {
                    final amount = double.parse(value);
                    if (amount <= 0) {
                      return 'Amount must be greater than 0';
                    }
                    if (amount > walletProvider.balance) {
                      return 'Insufficient balance';
                    }
                    return null;
                  } catch (e) {
                    return 'Please enter a valid number';
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available: ${walletProvider.balance.toStringAsFixed(2)} PYUSD',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _amountController.text =
                          walletProvider.balance.toString();
                    },
                    child: const Text('MAX'),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _send(walletProvider),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Send PYUSD'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
