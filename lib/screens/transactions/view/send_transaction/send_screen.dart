import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';
import '../../../../providers/network_provider.dart';
import '../../../../providers/wallet_provider.dart';
import '../../../../utils/snackbar_utils.dart';
import '../../provider/transaction_provider.dart';
import 'widgets/amount_input_card.dart';
import 'widgets/balance_display_card.dart';
import 'widgets/recipent_card.dart';
import 'widgets/send_button.dart';
import 'widgets/transaction_fee_card.dart';

class SendTransactionScreen extends StatefulWidget {
  const SendTransactionScreen({super.key});

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
  bool _mounted = true; // Track if the widget is mounted

  @override
  void initState() {
    super.initState();
    _fetchGasPrice();
  }

  @override
  void dispose() {
    _mounted = false;
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Safe setState that checks if mounted first
  void _safeSetState(Function function) {
    if (_mounted) {
      setState(() {
        function();
      });
    }
  }

  Future<void> _fetchGasPrice() async {
    if (!_mounted) return;

    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);

    try {
      _safeSetState(() {
        _isLoading = true;
      });

      // Get current network gas price
      _gasPrice = await transactionProvider.getCurrentGasPrice();

      // If we have a valid address and amount, estimate gas
      if (_isValidAddress && _amountController.text.isNotEmpty) {
        await _estimateGasFee();
      }
    } catch (e) {
      // Use default gas price if fetch fails
      _safeSetState(() {
        _gasPrice = 20.0; // 20 Gwei default
      });
    } finally {
      _safeSetState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _estimateGasFee() async {
    if (!_mounted || !_isValidAddress || _amountController.text.isEmpty) {
      _safeSetState(() {
        _estimatedGasFee = 0.0;
        _estimatedGas = 0;
      });
      return;
    }

    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);
    double? amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      return;
    }

    try {
      _safeSetState(() {
        _isEstimatingGas = true;
      });

      final recipient = EthereumAddress.fromHex(_addressController.text);

      // Estimate gas based on selected asset
      int estimatedGas;

      if (_selectedAsset == 'PYUSD') {
        estimatedGas = await transactionProvider.estimateTokenTransferGas(
          recipient.hex,
          amount,
        );
      } else {
        estimatedGas = await transactionProvider.estimateEthTransferGas(
          recipient.hex,
          amount,
        );
      }

      if (!_mounted) return;

      // Calculate fee: gas units × gas price (in Gwei) × 10^-9 (to convert to ETH)
      final fee = estimatedGas * _gasPrice * 1e-9;

      _safeSetState(() {
        _estimatedGasFee = fee;
        _estimatedGas = estimatedGas;
      });
    } catch (e) {
      print('Gas estimation error: $e');
      // Set default values if estimation fails
      _safeSetState(() {
        if (_selectedAsset == 'PYUSD') {
          _estimatedGas = 100000; // Default for token transfers
        } else {
          _estimatedGas = 21000; // Default for ETH transfers
        }
        _estimatedGasFee = _estimatedGas * _gasPrice * 1e-9;
      });
    } finally {
      _safeSetState(() {
        _isEstimatingGas = false;
      });
    }
  }

  void _validateAddress(String address) {
    try {
      // Validate Ethereum address format - this is simplified, should use proper validation
      _safeSetState(() {
        _isValidAddress = true;
      });
      _estimateGasFee(); // Re-estimate when address changes
    } catch (e) {
      _safeSetState(() {
        _isValidAddress = false;
        _estimatedGasFee = 0.0;
        _estimatedGas = 0;
      });
    }
  }

  Future<bool?> _showConfirmationDialog(
    BuildContext context,
    String address,
    double amount,
  ) async {
    if (!_mounted) return false;

    return showDialog<bool>(
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
            onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTransaction() async {
    if (!_mounted || !_formKey.currentState!.validate()) return;

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);

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
    final confirmed = await _showConfirmationDialog(context, address, amount);

    if (confirmed != true || !_mounted) return;

    // Show loading indicator
    _safeSetState(() {
      _isLoading = true;
    });

    try {
      String txHash;

      // Execute the transaction and get the hash
      if (_selectedAsset == 'PYUSD') {
        txHash = await transactionProvider.sendPYUSD(
          address,
          amount,
          gasPrice: _gasPrice,
          gasLimit: _estimatedGas,
        );
      } else {
        txHash = await transactionProvider.sendETH(
          address,
          amount,
          gasPrice: _gasPrice,
          gasLimit: _estimatedGas,
        );
      }

      // Show a success message
      if (_mounted && context.mounted) {
        SnackbarUtil.showSnackbar(
          context: context,
          message: 'Transaction submitted: ${txHash.substring(0, 10)}...',
          isError: false,
        );
      }

      // Ensure we're using the correct navigation to return to the main screen
      if (_mounted && context.mounted) {
        // Make sure we're not popping too many screens
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Show error message
      if (_mounted && context.mounted) {
        SnackbarUtil.showSnackbar(
          context: context,
          message: 'Transaction failed: ${e.toString().substring(0, 50)}',
          isError: true,
        );
      }
    } finally {
      // Reset loading state
      if (_mounted) {
        _safeSetState(() {
          _isLoading = false;
        });
      }
    }
  }

// New method to handle the transaction in the background
  Future<void> _startTransactionInBackground(
      String address, double amount) async {
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);

    try {
      // Execute the transaction without blocking the UI
      if (_selectedAsset == 'PYUSD') {
        transactionProvider.sendPYUSD(
          address,
          amount,
          gasPrice: _gasPrice,
          gasLimit: _estimatedGas,
        );
      } else if (_selectedAsset == 'ETH') {
        transactionProvider.sendETH(
          address,
          amount,
          gasPrice: _gasPrice,
          gasLimit: _estimatedGas,
        );
      }
      // Note: We're not awaiting the result here, as we want to return to the main screen
      // immediately. The transaction will be processed in the background.
    } catch (e) {
      // We'll handle errors in the transaction provider
      print('Error initiating transaction: $e');
    }
  }

  Future<void> _scanQRCode() async {
    // This would normally use a QR code scanner plugin
    // For this example, we'll just simulate it by setting a value
    _safeSetState(() {
      _addressController.text = '0x71C7656EC7ab88b098defB751B7401B5f6d8976F';
      _validateAddress(_addressController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final networkProvider = Provider.of<NetworkProvider>(context);

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
              // Asset Selection and Transaction Fee
              TransactionFeeCard(
                selectedAsset: _selectedAsset,
                onAssetSelected: (asset) {
                  setState(() {
                    _selectedAsset = asset;
                    _estimateGasFee();
                  });
                },
                estimatedGasFee: _estimatedGasFee,
                gasPrice: _gasPrice,
                onGasPriceChanged: (value) {
                  setState(() {
                    _gasPrice = value;
                    if (_estimatedGas > 0) {
                      _estimatedGasFee = _estimatedGas * _gasPrice * 1e-9;
                    }
                  });
                },
                isEstimatingGas: _isEstimatingGas,
                ethBalance: walletProvider.ethBalance,
                tokenBalance: walletProvider.tokenBalance,
              ),

              // Balance Display
              BalanceDisplayCard(
                selectedAsset: _selectedAsset,
                availableBalance: availableBalance,
                maxSendableEth: maxSendableEth,
                estimatedGasFee: _estimatedGasFee,
                networkName: networkProvider.currentNetworkName,
              ),

              // Recipient Address Input
              RecipientCard(
                addressController: _addressController,
                isValidAddress: _isValidAddress,
                onAddressChanged: _validateAddress,
                onScanQRCode: _scanQRCode,
              ),

              // Amount Input
              AmountCard(
                amountController: _amountController,
                selectedAsset: _selectedAsset,
                availableBalance: availableBalance,
                maxSendableEth: maxSendableEth,
                onAmountChanged: (_) => _estimateGasFee(),
                onMaxPressed: () {
                  setState(() {
                    if (_selectedAsset == 'ETH' && _estimatedGasFee > 0) {
                      _amountController.text = maxSendableEth.toString();
                    } else {
                      _amountController.text = availableBalance.toString();
                    }
                  });
                  _estimateGasFee();
                },
                estimatedGasFee: _estimatedGasFee,
              ),

              const SizedBox(height: 24),

              // Send Button
              SendButton(
                selectedAsset: _selectedAsset,
                isValidAddress: _isValidAddress,
                amountController: _amountController,
                isLoading: _isLoading,
                isEstimatingGas: _isEstimatingGas,
                estimatedGasFee: _estimatedGasFee,
                // ethBalance: walletProvider.ethBalance,
                onPressed: _sendTransaction,
              ),

              // Note about gas fees
              const SizedBox(height: 16),
              Text(
                'Note: Transaction requires ETH for gas fees regardless of which asset you send.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
