import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';
import 'package:pyusd_hub/utils/snackbar_utils.dart';
import '../../../widgets/pyusd_components.dart';
import 'block_trace_screen.dart';
import '../provider/trace_provider.dart';
import 'transaction_trace_screen.dart';

class TraceScreen extends StatefulWidget {
  final int initialTabIndex;

  const TraceScreen({
    super.key,
    this.initialTabIndex = 0,
  });

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
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return DefaultTabController(
      length: 4,
      initialIndex: widget.initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PYUSD Tracer'),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: primaryColor,
            labelColor: primaryColor,
            unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.black54,
            tabs: const [
              Tab(text: 'Transaction'),
              Tab(text: 'Block'),
              Tab(text: 'Advanced'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
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

  Widget _buildTransactionTraceTab() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with explanation
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            const Icon(Icons.receipt_long, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Transaction Tracing',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Analyze the execution of any transaction on the Ethereum network. See internal calls, state changes, and PYUSD transfers.',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Transaction hash input with paste and clear buttons
          TextField(
            controller: _txHashController,
            decoration: InputDecoration(
              labelText: 'Transaction Hash',
              hintText: 'Enter transaction hash (0x...)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.tag),
              filled: true,
              fillColor:
                  isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.content_paste, size: 20),
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data != null && data.text != null) {
                        setState(() {
                          _txHashController.text = data.text!.trim();
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _txHashController.clear();
                        _txError = '';
                      });
                    },
                  ),
                ],
              ),
            ),
            autofocus: false,
          ),
          const SizedBox(height: 24),

          // Trace button
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Error message
          if (_txError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _txError,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Transaction trace result
          if (_txTraceResult != null) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            // Transaction trace result would be displayed here
          ],
        ],
      ),
    );
  }

  Widget _buildBlockTraceTab() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with explanation
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.storage, color: Colors.green),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Block Tracing',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Trace all transactions in a specific Ethereum block to analyze network activity.',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Block number input with paste and clear buttons
          TextField(
            controller: _blockNumberController,
            decoration: InputDecoration(
              labelText: 'Block Number',
              hintText: 'Enter block number (e.g., 18000000)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.numbers),
              filled: true,
              fillColor:
                  isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.content_paste, size: 20),
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data != null && data.text != null) {
                        setState(() {
                          _blockNumberController.text = data.text!.trim();
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _blockNumberController.clear();
                        _blockError = '';
                      });
                    },
                  ),
                ],
              ),
            ),
            keyboardType: TextInputType.number,
            autofocus: false,
          ),
          const SizedBox(height: 24),

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
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Error message
          if (_blockError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _blockError,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Block trace result
          if (_blockTraceResult != null) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            // Block trace result would be displayed here
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedTraceTab() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with explanation
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.science, color: Colors.purple),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Advanced Tracing',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Use specialized GCP tracing methods for detailed analysis of transactions and blocks.',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
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
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.science),
              filled: true,
              fillColor:
                  isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
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

          // Dynamic inputs based on selected method
          _buildAdvancedMethodInputs(),
          const SizedBox(height: 24),

          // Execute button
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
                  : const Icon(Icons.play_arrow),
              label:
                  Text(_isLoadingAdvanced ? 'Processing...' : 'Execute Trace'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Error message
          if (_advancedError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _advancedError,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Advanced trace result
          if (_advancedTraceResult != null) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildAdvancedTraceResult(),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedMethodInputs() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final inputFillColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50;

    switch (_selectedAdvancedMethod) {
      case 'Raw Transaction':
        return Column(
          children: [
            TextField(
              controller: _rawTxController,
              decoration: InputDecoration(
                labelText: 'Raw Transaction Data',
                hintText: 'Enter raw transaction data (0x...)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.code),
                filled: true,
                fillColor: inputFillColor,
              ),
              maxLines: 4,
              autofocus: false,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.paste, size: 16),
                  label: const Text('Paste'),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data != null && data.text != null) {
                      setState(() {
                        _rawTxController.text = data.text!.trim();
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                  onPressed: () {
                    setState(() {
                      _rawTxController.clear();
                    });
                  },
                ),
              ],
            ),
          ],
        );

      case 'Replay Block Transactions':
        return Column(
          children: [
            TextField(
              controller: _replayBlockController,
              decoration: InputDecoration(
                labelText: 'Block Number',
                hintText: 'Enter block number (e.g., 18500000)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.storage),
                filled: true,
                fillColor: inputFillColor,
              ),
              keyboardType: TextInputType.number,
              autofocus: false,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.paste, size: 16),
                  label: const Text('Paste'),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data != null && data.text != null) {
                      setState(() {
                        _replayBlockController.text = data.text!.trim();
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                  onPressed: () {
                    setState(() {
                      _replayBlockController.clear();
                    });
                  },
                ),
              ],
            ),
          ],
        );

      case 'Replay Transaction':
        return Column(
          children: [
            TextField(
              controller: _replayTxController,
              decoration: InputDecoration(
                labelText: 'Transaction Hash',
                hintText: 'Enter transaction hash (0x...)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.receipt_long),
                filled: true,
                fillColor: inputFillColor,
              ),
              autofocus: false,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.paste, size: 16),
                  label: const Text('Paste'),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data != null && data.text != null) {
                      setState(() {
                        _replayTxController.text = data.text!.trim();
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                  onPressed: () {
                    setState(() {
                      _replayTxController.clear();
                    });
                  },
                ),
              ],
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
                hintText: 'Enter contract address (0x...)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.account_balance),
                filled: true,
                fillColor: inputFillColor,
              ),
              autofocus: false,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _blockHashController,
              decoration: InputDecoration(
                labelText: 'Block Hash',
                hintText: 'Enter block hash (0x...)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.storage),
                filled: true,
                fillColor: inputFillColor,
              ),
              autofocus: false,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _txIndexController,
              decoration: InputDecoration(
                labelText: 'Transaction Index',
                hintText: 'Enter tx index (0 for first)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.format_list_numbered),
                filled: true,
                fillColor: inputFillColor,
              ),
              keyboardType: TextInputType.number,
              autofocus: false,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear All'),
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
              _advancedError =
                  'Please fill in all fields (contract address, block hash, and tx index)';
              _isLoadingAdvanced = false;
            });
            return;
          }

          final txIndex = int.tryParse(txIndexText);
          if (txIndex == null) {
            setState(() {
              _advancedError = 'Invalid transaction index format';
              _isLoadingAdvanced = false;
            });
            return;
          }

          final result = await provider.getStorageRangeAt(
              blockHash, txIndex, contractAddress, '0x0', 1000);
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
      if (mounted) {
        setState(() {
          _isLoadingAdvanced = false;
        });
      }
    }
  }

  Widget _buildAdvancedTraceResult() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_advancedTraceResult == null) {
      return const SizedBox.shrink();
    }

    final success = _advancedTraceResult!['success'] == true;
    final resultColor = success ? Colors.green : Colors.red;
    final resultIcon = success ? Icons.check_circle : Icons.error;
    final resultTitle =
        success ? 'Trace Completed Successfully' : 'Trace Failed';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: resultColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(resultIcon, color: resultColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    resultTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TraceButton(
                  text: 'View Full Trace',
                  onPressed: _showFullTraceDialog,
                  backgroundColor: Colors.purple,
                  icon: Icons.visibility,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Trace Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildTraceSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildTraceSummary() {
    if (_advancedTraceResult == null ||
        _advancedTraceResult!['success'] != true) {
      return const Text('No trace data available');
    }

    // Extract relevant data based on the trace method
    switch (_selectedAdvancedMethod) {
      case 'Raw Transaction':
        return _buildRawTransactionSummary();
      case 'Replay Block Transactions':
        return _buildReplayBlockSummary();
      case 'Replay Transaction':
        return _buildReplayTransactionSummary();
      case 'Storage Range':
        return _buildStorageRangeSummary();
      default:
        return const Text('No summary available for this trace type');
    }
  }

  Widget _buildRawTransactionSummary() {
    final trace = _advancedTraceResult!['trace'];
    if (trace == null) return const Text('No trace data available');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryItem('Gas Used', '${trace['gasUsed'] ?? 'N/A'}'),
        _buildSummaryItem(
            'Status', trace['failed'] == true ? 'Failed' : 'Success'),
        if (trace['returnValue'] != null)
          _buildSummaryItem('Return Value', trace['returnValue']),
        const SizedBox(height: 16),
        TraceButton(
          text: 'Copy Trace Data',
          onPressed: () {
            final jsonString =
                const JsonEncoder.withIndent('  ').convert(trace);
            Clipboard.setData(ClipboardData(text: jsonString));
            SnackbarUtil.showSnackbar(
              context: context,
              message: 'Trace data copied to clipboard',
            );
          },
          icon: Icons.copy,
          backgroundColor: Colors.grey.shade700,
          foregroundColor: Colors.white,
          horizontalPadding: 12,
          verticalPadding: 8,
        ),
      ],
    );
  }

  Widget _buildReplayBlockSummary() {
    final traces = _advancedTraceResult!['traces'];
    if (traces == null) return const Text('No trace data available');

    final blockNumber = _advancedTraceResult!['blockNumber'];
    final txCount = traces is List ? traces.length : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryItem('Block Number', '$blockNumber'),
        _buildSummaryItem('Transactions Traced', '$txCount'),
        const SizedBox(height: 16),
        TraceButton(
          text: 'Copy Trace Data',
          onPressed: () {
            final jsonString =
                const JsonEncoder.withIndent('  ').convert(traces);
            Clipboard.setData(ClipboardData(text: jsonString));
            SnackbarUtil.showSnackbar(
              context: context,
              message: 'Trace data copied to clipboard',
            );
          },
          icon: Icons.copy,
          backgroundColor: Colors.grey.shade700,
          foregroundColor: Colors.white,
          horizontalPadding: 12,
          verticalPadding: 8,
        ),
      ],
    );
  }

  Widget _buildReplayTransactionSummary() {
    final trace = _advancedTraceResult!['trace'];
    if (trace == null) return const Text('No trace data available');

    final txHash = _advancedTraceResult!['txHash'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryItem('Transaction Hash', txHash ?? 'N/A'),
        _buildSummaryItem(
            'Status', trace['failed'] == true ? 'Failed' : 'Success'),
        if (trace['returnValue'] != null)
          _buildSummaryItem('Return Value', trace['returnValue']),
        const SizedBox(height: 16),
        TraceButton(
          text: 'Copy Trace Data',
          onPressed: () {
            final jsonString =
                const JsonEncoder.withIndent('  ').convert(trace);
            Clipboard.setData(ClipboardData(text: jsonString));
            SnackbarUtil.showSnackbar(
              context: context,
              message: 'Trace data copied to clipboard',
            );
          },
          icon: Icons.copy,
          backgroundColor: Colors.grey.shade700,
          foregroundColor: Colors.white,
          horizontalPadding: 12,
          verticalPadding: 8,
        ),
      ],
    );
  }

  Widget _buildStorageRangeSummary() {
    final storage = _advancedTraceResult!['storage'];
    if (storage == null) return const Text('No storage data available');

    final contractAddress = _advancedTraceResult!['contractAddress'];
    final storageKeys =
        storage['storage'] != null ? storage['storage'].keys.length : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryItem('Contract Address', contractAddress ?? 'N/A'),
        _buildSummaryItem('Storage Keys', '$storageKeys'),
        _buildSummaryItem(
            'Complete', storage['complete'] == true ? 'Yes' : 'No'),
        const SizedBox(height: 16),
        TraceButton(
          text: 'Copy Storage Data',
          onPressed: () {
            final jsonString =
                const JsonEncoder.withIndent('  ').convert(storage);
            Clipboard.setData(ClipboardData(text: jsonString));
            SnackbarUtil.showSnackbar(
              context: context,
              message: 'Storage data copied to clipboard',
            );
          },
          icon: Icons.copy,
          backgroundColor: Colors.grey.shade700,
          foregroundColor: Colors.white,
          horizontalPadding: 12,
          verticalPadding: 8,
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: PyusdListTile(
        title: label,
        subtitle: value,
        contentPadding: EdgeInsets.zero,
        showDivider: false,
      ),
    );
  }

  Widget _buildHistoryTab() {
    final traceProvider = Provider.of<TraceProvider>(context);
    final recentTraces = List.from(traceProvider.recentTraces)
      ..sort((a, b) => (b['timestamp'] as int)
          .compareTo(a['timestamp'] as int)); // Sort by latest first
    final recentBlocks = List.from(traceProvider.recentBlocksTraced);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (recentTraces.isEmpty && recentBlocks.isEmpty) {
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
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your recent trace activities will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trace History',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TraceButton(
                text: 'Clear History',
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
                        TraceButton(
                          text: 'Clear',
                          onPressed: () {
                            traceProvider.clearHistory();
                            Navigator.pop(context);
                            SnackbarUtil.showSnackbar(
                              context: context,
                              message: 'History cleared',
                            );
                          },
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          horizontalPadding: 16,
                          verticalPadding: 8,
                        ),
                      ],
                    ),
                  );
                },
                icon: Icons.delete_outline,
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red,
                horizontalPadding: 12,
                verticalPadding: 8,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          if (recentTraces.isNotEmpty) ...[
            for (final trace in recentTraces)
              _buildTraceHistoryItem(trace, isDarkMode),
          ],
        ],
      ),
    );
  }

  Widget _buildTraceHistoryItem(Map<String, dynamic> trace, bool isDarkMode) {
    final type = trace['type'] as String;
    final timestamp =
        DateTime.fromMillisecondsSinceEpoch(trace['timestamp'] as int);

    String title;
    String subtitle;
    IconData icon;
    Color iconColor;

    if (type == 'transaction') {
      title = 'Transaction Trace';
      subtitle = 'Tx: ${FormatterUtils.formatHash(trace['hash'])}';
      icon = Icons.receipt_long;
      iconColor = Colors.blue;
    } else if (type == 'block') {
      title = 'Block Trace';
      subtitle = 'Block #${trace['blockNumber']}';
      icon = Icons.storage;
      iconColor = Colors.green;
    } else if (type == 'blockReplay') {
      title = 'Block Replay';
      subtitle = 'Block #${trace['blockNumber']}';
      icon = Icons.replay;
      iconColor = Colors.orange;
    } else if (type == 'txReplay') {
      title = 'Transaction Replay';
      subtitle = 'Tx: ${FormatterUtils.formatHash(trace['hash'])}';
      icon = Icons.replay;
      iconColor = Colors.purple;
    } else {
      title = 'Advanced Trace';
      subtitle = type;
      icon = Icons.science;
      iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.2),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            Text(
              FormatterUtils.formatRelativeTime(
                  timestamp.millisecondsSinceEpoch ~/ 1000),
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (type == 'transaction' || type == 'txReplay') {
            final hash = trace['hash'] as String;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionTraceScreen(txHash: hash),
              ),
            );
          } else if (type == 'block' || type == 'blockReplay') {
            final blockNumber = trace['blockNumber'] as int;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BlockTraceScreen(blockNumber: blockNumber),
              ),
            );
          } else {
            // Show a dialog with the trace details
            _showTraceDetailsDialog(trace);
          }
        },
      ),
    );
  }

  void _showTraceDetailsDialog(Map<String, dynamic> trace) {
    showDialog(
      context: context,
      builder: (context) => PyusdDialog(
        title: 'Trace Details',
        content: const JsonEncoder.withIndent('  ').convert(trace),
        confirmText: 'Close',
        cancelText: 'Copy',
        onCancel: () {
          Clipboard.setData(ClipboardData(
              text: const JsonEncoder.withIndent('  ').convert(trace)));
          SnackbarUtil.showSnackbar(
            context: context,
            message: 'Copied to clipboard',
          );
          Navigator.pop(context);
        },
        onConfirm: () => Navigator.pop(context),
        isDestructive: false,
      ),
    );
  }

  void _showFullTraceDialog() {
    final jsonString = FormatterUtils.formatJson(_advancedTraceResult);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Full Trace Data'),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonString,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TraceButton(
            text: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              SnackbarUtil.showSnackbar(
                context: context,
                message: 'Trace data copied to clipboard',
              );
            },
            icon: Icons.copy,
            backgroundColor: Colors.blue,
            horizontalPadding: 12,
            verticalPadding: 8,
          ),
          TraceButton(
            text: 'Close',
            onPressed: () => Navigator.pop(context),
            icon: Icons.close,
            backgroundColor: Colors.grey,
            horizontalPadding: 12,
            verticalPadding: 8,
          ),
        ],
      ),
    );
  }
}
