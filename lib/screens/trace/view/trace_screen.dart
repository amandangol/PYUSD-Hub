import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';
import 'package:pyusd_hub/utils/snackbar_utils.dart';
import '../../networkcongestion/view/widgets/block_trace_screen.dart';
import '../provider/trace_provider.dart';
import 'transaction_trace_screen.dart';

class TraceScreen extends StatefulWidget {
  const TraceScreen({Key? key}) : super(key: key);

  @override
  State<TraceScreen> createState() => _TraceScreenState();
}

class _TraceScreenState extends State<TraceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _txHashController = TextEditingController();
  final TextEditingController _blockNumberController = TextEditingController();

  // Advanced tracing controllers
  final TextEditingController _rawTxController = TextEditingController();
  final TextEditingController _replayBlockController = TextEditingController();
  final TextEditingController _replayTxController = TextEditingController();
  final TextEditingController _contractAddressController =
      TextEditingController();
  final TextEditingController _blockHashController = TextEditingController();
  final TextEditingController _txIndexController = TextEditingController();

  bool _isLoadingTx = false;
  bool _isLoadingBlock = false;
  bool _isLoadingAdvanced = false;
  Map<String, dynamic>? _txTraceResult;
  Map<String, dynamic>? _blockTraceResult;
  Map<String, dynamic>? _advancedTraceResult;
  String _txError = '';
  String _blockError = '';
  String _advancedError = '';

  // Selected advanced trace method
  String _selectedAdvancedMethod = 'Raw Transaction';
  final List<String> _advancedMethods = [
    'Raw Transaction',
    'Replay Block Transactions',
    'Replay Transaction',
    'Storage Range'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _txHashController.dispose();
    _blockNumberController.dispose();
    _tabController.dispose();
    _txHashController.dispose();
    _blockNumberController.dispose();
    _rawTxController.dispose();
    _replayBlockController.dispose();
    _replayTxController.dispose();
    _contractAddressController.dispose();
    _blockHashController.dispose();
    _txIndexController.dispose();
    super.dispose();
  }

  Future<void> _traceTransaction() async {
    final txHash = _txHashController.text.trim();
    if (txHash.isEmpty) {
      setState(() {
        _txError = 'Please enter a transaction hash';
      });
      return;
    }

    setState(() {
      _isLoadingTx = true;
      _txError = '';
      _txTraceResult = null;
    });

    try {
      final provider = Provider.of<TraceProvider>(context, listen: false);
      final result = await provider.getTransactionTraceWithCache(txHash);

      if (!mounted) return;

      setState(() {
        _isLoadingTx = false;
        _txTraceResult = result;
        if (result['success'] != true) {
          _txError = result['error'] ?? 'Unknown error';
        } else {
          // Navigate to transaction trace screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionTraceScreen(txHash: txHash),
            ),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingTx = false;
        _txError = e.toString();
      });
    }
  }

  Future<void> _traceBlock() async {
    final blockNumberText = _blockNumberController.text.trim();
    if (blockNumberText.isEmpty) {
      setState(() {
        _blockError = 'Please enter a block number';
      });
      return;
    }

    int? blockNumber;
    if (blockNumberText.toLowerCase().startsWith('0x')) {
      blockNumber = FormatterUtils.parseHexSafely(blockNumberText);
    } else {
      blockNumber = int.tryParse(blockNumberText);
    }

    if (blockNumber == null) {
      setState(() {
        _blockError = 'Invalid block number format';
      });
      return;
    }

    setState(() {
      _isLoadingBlock = true;
      _blockError = '';
      _blockTraceResult = null;
    });

    try {
      // Navigate directly to block trace screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlockTraceScreen(blockNumber: blockNumber!),
        ),
      );

      setState(() {
        _isLoadingBlock = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingBlock = false;
        _blockError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PYUSD Tracer'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Transaction'),
              Tab(text: 'Block'),
              Tab(text: 'Advanced'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTransactionTraceTab(),
            _buildBlockTraceTab(),
            _buildAdvancedTraceTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedTraceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with explanation
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Advanced Tracing',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Use specialized Ethereum tracing methods for detailed analysis.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Method selector
          DropdownButtonFormField<String>(
            value: _selectedAdvancedMethod,
            decoration: InputDecoration(
              labelText: 'Trace Method',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.science),
            ),
            items: _advancedMethods.map((String method) {
              return DropdownMenuItem<String>(
                value: method,
                child: Text(method),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedAdvancedMethod = newValue;
                  _advancedTraceResult = null;
                  _advancedError = '';
                });
              }
            },
          ),
          const SizedBox(height: 24),

          // Dynamic input fields based on selected method
          _buildAdvancedMethodInputs(),

          if (_advancedError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _advancedError,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Trace button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoadingAdvanced ? null : _executeAdvancedTrace,
              icon: _isLoadingAdvanced
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2.0),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(Icons.science),
              label:
                  Text(_isLoadingAdvanced ? 'Processing...' : 'Execute Trace'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // Results section
          if (_advancedTraceResult != null) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildAdvancedTraceResults(),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedMethodInputs() {
    switch (_selectedAdvancedMethod) {
      case 'Raw Transaction':
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _rawTxController,
                    decoration: InputDecoration(
                      labelText: 'Raw Transaction Hex',
                      hintText: 'Enter raw transaction data (0x...)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.code),
                    ),
                    maxLines: 3,
                    autofocus: false,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear input',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                  ),
                  onPressed: () {
                    setState(() {
                      _rawTxController.clear();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.paste, size: 16),
                label: const Text('Paste from clipboard'),
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data != null && data.text != null) {
                    setState(() {
                      _rawTxController.text = data.text!.trim();
                    });
                  }
                },
              ),
            ),
          ],
        );

      case 'Replay Block Transactions':
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _replayBlockController,
                decoration: InputDecoration(
                  labelText: 'Block Number',
                  hintText: 'Enter block number to replay',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.storage),
                ),
                keyboardType: TextInputType.number,
                autofocus: false,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear input',
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
              ),
              onPressed: () {
                setState(() {
                  _replayBlockController.clear();
                });
              },
            ),
          ],
        );

      case 'Replay Transaction':
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _replayTxController,
                decoration: InputDecoration(
                  labelText: 'Transaction Hash',
                  hintText: 'Enter transaction hash to replay',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.receipt_long),
                ),
                autofocus: false,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear input',
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
              ),
              onPressed: () {
                setState(() {
                  _replayTxController.clear();
                });
              },
            ),
          ],
        );

      case 'Storage Range':
        return Column(
          children: [
            TextField(
              controller: _contractAddressController,
              decoration: InputDecoration(
                labelText: 'Contract Address',
                hintText: 'Enter contract address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.account_balance_wallet),
              ),
              autofocus: false,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _blockHashController,
              decoration: InputDecoration(
                labelText: 'Block Hash',
                hintText: 'Enter block hash',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.tag),
              ),
              autofocus: false,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _txIndexController,
                    decoration: InputDecoration(
                      labelText: 'Transaction Index',
                      hintText: 'Enter tx index (0 for first)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.format_list_numbered),
                    ),
                    keyboardType: TextInputType.number,
                    autofocus: false,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear all fields',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                  ),
                  onPressed: () {
                    setState(() {
                      _contractAddressController.clear();
                      _blockHashController.clear();
                      _txIndexController.clear();
                    });
                  },
                ),
              ],
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _executeAdvancedTrace() async {
    setState(() {
      _isLoadingAdvanced = true;
      _advancedError = '';
      _advancedTraceResult = null;
    });

    try {
      final provider = Provider.of<TraceProvider>(context, listen: false);

      switch (_selectedAdvancedMethod) {
        case 'Raw Transaction':
          final rawTx = _rawTxController.text.trim();
          if (rawTx.isEmpty) {
            setState(() {
              _advancedError = 'Please enter raw transaction data';
              _isLoadingAdvanced = false;
            });
            return;
          }

          final result = await provider.traceRawTransaction(rawTx);
          setState(() {
            _advancedTraceResult = result;
            if (result['success'] != true) {
              _advancedError =
                  result['error'] ?? 'Failed to trace raw transaction';
            }
          });
          break;

        case 'Replay Block Transactions':
          final blockNumberText = _replayBlockController.text.trim();
          if (blockNumberText.isEmpty) {
            setState(() {
              _advancedError = 'Please enter a block number';
              _isLoadingAdvanced = false;
            });
            return;
          }

          int? blockNumber;
          if (blockNumberText.toLowerCase().startsWith('0x')) {
            blockNumber = FormatterUtils.parseHexSafely(blockNumberText);
          } else {
            blockNumber = int.tryParse(blockNumberText);
          }

          if (blockNumber == null) {
            setState(() {
              _advancedError = 'Invalid block number format';
              _isLoadingAdvanced = false;
            });
            return;
          }

          final result = await provider.replayBlockTransactions(blockNumber);
          setState(() {
            _advancedTraceResult = result;
            if (result['success'] != true) {
              _advancedError =
                  result['error'] ?? 'Failed to replay block transactions';
            }
          });
          break;

        case 'Replay Transaction':
          final txHash = _replayTxController.text.trim();
          if (txHash.isEmpty) {
            setState(() {
              _advancedError = 'Please enter a transaction hash';
              _isLoadingAdvanced = false;
            });
            return;
          }

          final result = await provider.replayTransaction(txHash);
          setState(() {
            _advancedTraceResult = result;
            if (result['success'] != true) {
              _advancedError =
                  result['error'] ?? 'Failed to replay transaction';
            }
          });
          break;

        case 'Storage Range':
          final contractAddress = _contractAddressController.text.trim();
          final blockHash = _blockHashController.text.trim();
          final txIndexText = _txIndexController.text.trim();

          if (contractAddress.isEmpty ||
              blockHash.isEmpty ||
              txIndexText.isEmpty) {
            setState(() {
              _advancedError = 'Please fill in all required fields';
              _isLoadingAdvanced = false;
            });
            return;
          }

          final txIndex = int.tryParse(txIndexText) ?? 0;

          final result = await provider.getStorageRangeAt(
              blockHash,
              txIndex,
              contractAddress,
              '0x0', // Start from the beginning
              100 // Get up to 100 storage slots
              );

          setState(() {
            _advancedTraceResult = result;
            if (result['success'] != true) {
              _advancedError = result['error'] ?? 'Failed to get storage range';
            }
          });
          break;
      }
    } catch (e) {
      setState(() {
        _advancedError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingAdvanced = false;
      });
    }
  }

  Widget _buildAdvancedTraceResults() {
    if (_advancedTraceResult == null ||
        _advancedTraceResult!['success'] != true) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.teal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_selectedAdvancedMethod} Trace Results',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Result preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Result Preview',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getResultPreview(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Full Result'),
                  onPressed: () {
                    final jsonString = const JsonEncoder.withIndent('  ')
                        .convert(_advancedTraceResult);
                    Clipboard.setData(ClipboardData(text: jsonString));
                    SnackbarUtil.showSnackbar(
                      context: context,
                      message: 'Full trace result copied to clipboard',
                    );
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Details'),
                  onPressed: () {
                    _showFullTraceDialog();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getResultPreview() {
    try {
      final result = _advancedTraceResult;
      if (result == null) return 'No data';

      // Extract the most relevant part based on the method
      switch (_selectedAdvancedMethod) {
        case 'Raw Transaction':
          return const JsonEncoder.withIndent('  ').convert(result['trace']);

        case 'Replay Block Transactions':
          final traces = result['traces'];
          if (traces is List && traces.isNotEmpty) {
            return 'Found ${traces.length} transaction traces in block';
          }
          return const JsonEncoder.withIndent('  ')
                  .convert(traces)
                  .substring(0, 500) +
              '...';

        case 'Replay Transaction':
          return const JsonEncoder.withIndent('  ').convert(result['trace']);

        case 'Storage Range':
          final storage = result['storage'];
          return const JsonEncoder.withIndent('  ').convert(storage);

        default:
          return const JsonEncoder.withIndent('  ').convert(result);
      }
    } catch (e) {
      return 'Error generating preview: $e';
    }
  }

  void _showFullTraceDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text('${_selectedAdvancedMethod} Trace Details'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ')
                        .convert(_advancedTraceResult),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy All'),
                      onPressed: () {
                        final jsonString = const JsonEncoder.withIndent('  ')
                            .convert(_advancedTraceResult);
                        Clipboard.setData(ClipboardData(text: jsonString));
                        SnackbarUtil.showSnackbar(
                          context: context,
                          message: 'Full trace result copied to clipboard',
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      child: const Text('Close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTraceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with explanation
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transaction Tracing',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter a transaction hash to trace its execution and analyze PYUSD transfers.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Transaction hash input with reset button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _txHashController,
                  decoration: InputDecoration(
                    labelText: 'Transaction Hash',
                    hintText: 'Enter transaction hash (0x...)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.receipt_long),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.paste),
                      tooltip: 'Paste from clipboard',
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data != null && data.text != null) {
                          setState(() {
                            _txHashController.text = data.text!.trim();
                            _txError = '';
                            _txTraceResult =
                                null; // Clear previous results when pasting
                          });
                        }
                      },
                    ),
                  ),
                  // Remove autofocus
                  autofocus: false,
                  onChanged: (value) {
                    // Clear previous results when input changes
                    if (_txTraceResult != null) {
                      setState(() {
                        _txTraceResult = null;
                        _txError = '';
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.clear),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                ),
                onPressed: () {
                  setState(() {
                    _txHashController.clear();
                    _txTraceResult = null;
                    _txError = '';
                  });
                },
              ),
            ],
          ),
          if (_txError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _txError,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoadingTx ? null : _traceTransaction,
              icon: _isLoadingTx
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2.0),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(_isLoadingTx ? 'Tracing...' : 'Trace Transaction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // Transaction trace result
          if (_txTraceResult != null &&
              _txTraceResult!['success'] == true &&
              _txHashController.text.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.check_circle,
                              color: Colors.green),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Trace Completed Successfully',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransactionTraceScreen(
                                    txHash: _txHashController.text.trim()),
                              ),
                            );
                          },
                          child: const Text('View Details'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBlockTraceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with explanation
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Block Tracing',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter a block number to trace all transactions in that block and find PYUSD transactions.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.purple.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Block tracing can take longer for blocks with many transactions.',
                            style: TextStyle(
                              color: Colors.purple.shade700,
                              fontSize: 13,
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
          const SizedBox(height: 24),

          // Block number input with reset button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _blockNumberController,
                  decoration: InputDecoration(
                    labelText: 'Block Number',
                    hintText: 'Enter block number (e.g., 18500000)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.storage),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.paste),
                      tooltip: 'Paste from clipboard',
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data != null && data.text != null) {
                          setState(() {
                            _blockNumberController.text = data.text!.trim();
                            _blockError = '';
                          });
                        }
                      },
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  // Remove autofocus
                  autofocus: false,
                  onChanged: (value) {
                    // Clear error when input changes
                    if (_blockError.isNotEmpty) {
                      setState(() {
                        _blockError = '';
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear input',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.withOpacity(0.1),
                ),
                onPressed: () {
                  setState(() {
                    _blockNumberController.clear();
                    _blockError = '';
                  });
                },
              ),
            ],
          ),
          if (_blockError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _blockError,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Trace button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoadingBlock ? null : _traceBlock,
              icon: _isLoadingBlock
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2.0),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(_isLoadingBlock ? 'Tracing...' : 'Trace Block'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final traceProvider = Provider.of<TraceProvider>(context);
    final recentTraces = traceProvider.recentTraces;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Traces',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (recentTraces.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear History'),
                        content: const Text(
                            'Are you sure you want to clear all trace history?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              traceProvider.clearHistory();
                              Navigator.pop(context);
                              SnackbarUtil.showSnackbar(
                                context: context,
                                message: 'Trace history cleared',
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: recentTraces.isEmpty
                ? _buildEmptyHistoryMessage()
                : _buildHistoryList(recentTraces),
          ),
        ],
      ),
    );
  }

  // Custom reusable widgets

  Widget _buildHeaderCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    Widget? additionalWidget,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            if (additionalWidget != null) ...[
              const SizedBox(height: 8),
              additionalWidget,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color.withOpacity(0.7), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String error,
    required Function() onClear,
    required Function(String) onChanged,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(icon),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste),
                    tooltip: 'Paste from clipboard',
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data != null && data.text != null) {
                        controller.text = data.text!.trim();
                        onChanged(controller.text);
                      }
                    },
                  ),
                ),
                keyboardType: keyboardType,
                autofocus: false,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear input',
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
              ),
              onPressed: onClear,
            ),
          ],
        ),
        if (error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              error,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required String loadingLabel,
    required IconData icon,
    required bool isLoading,
    required Color color,
    required Function() onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(2.0),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Icon(icon),
        label: Text(isLoading ? loadingLabel : label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCard({
    required String message,
    required IconData icon,
    required Color color,
    required String buttonText,
    required Function() onButtonPressed,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: onButtonPressed,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No trace history yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Trace transactions or blocks to see them here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<dynamic> recentTraces) {
    return ListView.builder(
      itemCount: recentTraces.length,
      itemBuilder: (context, index) {
        final trace = recentTraces[recentTraces.length - 1 - index];
        final timestamp = DateTime.fromMillisecondsSinceEpoch(
            trace['timestamp'] as int? ?? 0);
        final formattedTime =
            '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';

        if (trace['type'] == 'transaction') {
          return _buildHistoryItem(
            icon: Icons.receipt_long,
            color: Colors.blue,
            title:
                'Transaction: ${FormatterUtils.formatHash(trace['hash'] as String? ?? '')}',
            timestamp: formattedTime,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionTraceScreen(
                      txHash: trace['hash'] as String? ?? ''),
                ),
              );
            },
          );
        } else if (trace['type'] == 'block') {
          final blockNumber = trace['blockNumber'] as int? ?? 0;
          return _buildHistoryItem(
            icon: Icons.storage,
            color: Colors.purple,
            title: 'Block: ${FormatterUtils.formatLargeNumber(blockNumber)}',
            timestamp: formattedTime,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BlockTraceScreen(blockNumber: blockNumber),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHistoryItem({
    required IconData icon,
    required Color color,
    required String title,
    required String timestamp,
    required Function() onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text('Traced on $timestamp'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
