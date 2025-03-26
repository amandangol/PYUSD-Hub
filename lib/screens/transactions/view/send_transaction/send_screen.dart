import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../providers/network_provider.dart';
import '../../../../providers/wallet_provider.dart';
import '../../../../utils/snackbar_utils.dart';
import '../../../../widgets/pyusd_components.dart';
import '../../provider/transaction_provider.dart';
import 'widgets/amount_input_card.dart';
import 'widgets/balance_display_card.dart';
import 'widgets/recipent_card.dart';
import 'widgets/send_button.dart';
import 'widgets/transaction_fee_card.dart';
import 'widgets/gas_selection_sheet.dart';

class SendTransactionScreen extends StatefulWidget {
  const SendTransactionScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SendTransactionScreenState createState() => _SendTransactionScreenState();
}

class _SendTransactionScreenState extends State<SendTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isValidAddress = false;
  double _estimatedGasFee = 0.0;
  double _gasPrice = 2.0;
  int _estimatedGas = 0;
  bool _isLoading = false;
  bool _isEstimatingGas = false;
  String _selectedAsset = 'PYUSD'; // Default to PYUSD
  bool _mounted = true; // Track if the widget is mounted
  GasOption? _selectedGasOption;
  Map<String, GasOption> _gasOptions = {};
  bool _isLoadingGasPrice = false;

  @override
  void initState() {
    super.initState();
    _loadGasOptions();
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

  Future<void> _loadGasOptions() async {
    if (!mounted) return;

    setState(() => _isLoadingGasPrice = true);

    try {
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);
      final options = await transactionProvider.getGasOptions();

      if (mounted) {
        setState(() {
          _gasOptions = options;
          _selectedGasOption = options['standard']; // Default to standard
          _gasPrice = _selectedGasOption!.price;
          _isLoadingGasPrice = false;
        });
      }
    } catch (e) {
      print('Error loading gas options: $e');
      setState(() => _isLoadingGasPrice = false);
    }
  }

  void _showGasOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GasSelectionSheet(
        gasOptions: _gasOptions,
        selectedOption: _selectedGasOption!,
        onOptionSelected: (option) {
          setState(() {
            _selectedGasOption = option;
            _gasPrice = option.price;
            _estimateGasFee();
          });
          Navigator.pop(context);
        },
      ),
    );
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recipient:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(address,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Amount:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('$amount $_selectedAsset'),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Gas Details:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimated Gas Units:'),
                  Text('$_estimatedGas'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Gas Price:'),
                  Text('${_gasPrice.toStringAsFixed(2)} Gwei'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Gas Fee:'),
                  Text('${_estimatedGasFee.toStringAsFixed(9)} ETH'),
                ],
              ),
              if (_selectedAsset == 'ETH') ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total (with gas):',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${(amount + _estimatedGasFee).toStringAsFixed(6)} ETH',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Please verify all transaction details before confirming.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
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

      // Navigate back with result indicating transaction was sent
      Navigator.of(context)
          .pop(true); // Pass true to indicate transaction was sent
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

  Future<void> _scanQRCode() async {
    // This would normally use a QR code scanner plugin
    // For this example, we'll just simulate it by setting a value
    _safeSetState(() {
      _addressController.text = '0x71C7656EC7ab88b098defB751B7401B5f6d8976F';
      _validateAddress(_addressController.text);
    });
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (_mounted) {
        SnackbarUtil.showSnackbar(
          context: context,
          message: 'Could not launch faucet URL',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final networkProvider = Provider.of<NetworkProvider>(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Determine available balance based on selected asset
    final availableBalance = _selectedAsset == 'PYUSD'
        ? walletProvider.tokenBalance
        : walletProvider.ethBalance;

    // For ETH transfers, calculate the max amount that can be sent considering gas fees
    final maxSendableEth = _selectedAsset == 'ETH' && _estimatedGasFee > 0
        ? (walletProvider.ethBalance - _estimatedGasFee)
            .clamp(0.0, double.infinity)
        : walletProvider.ethBalance;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context)
            .pop(false); // Pass false to indicate no transaction was sent
        return false;
      },
      child: Scaffold(
        appBar: PyusdAppBar(
          isDarkMode: isDarkMode,
          title: 'Send $_selectedAsset',
          networkName: networkProvider.currentNetwork.name,
          showLogo: false,
          onBackPressed: () {
            Navigator.of(context)
                .pop(false); // Pass false to indicate no transaction was sent
          },
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      selectedGasOption: _selectedGasOption,
                      isEstimatingGas: _isEstimatingGas,
                      ethBalance: walletProvider.ethBalance,
                      tokenBalance: walletProvider.tokenBalance,
                      onGasOptionsPressed: _showGasOptions,
                      isLoadingGasPrice: _isLoadingGasPrice,
                      networkName: networkProvider.currentNetwork.name,
                      maxSendableEth: maxSendableEth,
                    ),

                    const SizedBox(height: 16),

                    // Remove BalanceDisplayCard and directly show Recipient Card
                    RecipientCard(
                      addressController: _addressController,
                      isValidAddress: _isValidAddress,
                      onAddressChanged: _validateAddress,
                      onScanQRCode: _scanQRCode,
                    ),

                    const SizedBox(height: 16),

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
                            _amountController.text =
                                availableBalance.toString();
                          }
                        });
                        _estimateGasFee();
                      },
                      estimatedGasFee: _estimatedGasFee,
                    ),

                    const SizedBox(height: 16),

                    // Send Button
                    SendButton(
                      selectedAsset: _selectedAsset,
                      isValidAddress: _isValidAddress,
                      amountController: _amountController,
                      isLoading: _isLoading,
                      isEstimatingGas: _isEstimatingGas,
                      estimatedGasFee: _estimatedGasFee,
                      onPressed: _sendTransaction,
                    ),

                    // Note about gas fees
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF252543)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Transaction requires ETH for gas fees regardless of which asset you send.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Faucet Section - Only show on Sepolia testnet

                    const SizedBox(height: 8),
                    if (networkProvider.currentNetwork.name
                        .toLowerCase()
                        .contains('testnet'))
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF252543)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.water_drop,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Need tokens? Get them from the faucet:',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _launchURL(
                                  'https://cloud.google.com/application/web3/faucet/ethereum/sepolia'),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.link,
                                      color: isDarkMode
                                          ? Colors.blue[300]
                                          : Colors.blue,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Sepolia ETH Faucet',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: isDarkMode
                                            ? Colors.blue[300]
                                            : Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () =>
                                  _launchURL('https://faucet.paxos.com/'),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.link,
                                      color: isDarkMode
                                          ? Colors.blue[300]
                                          : Colors.blue,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'PYUSD Faucet',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: isDarkMode
                                            ? Colors.blue[300]
                                            : Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
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
        ),
      ),
    );
  }
}
