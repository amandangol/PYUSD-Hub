import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';
import 'package:pyusd_hub/utils/snackbar_utils.dart';
import '../../../widgets/pyusd_components.dart';
import '../widgets/trace_widgets.dart';
import 'block_trace_screen.dart';
import '../provider/trace_provider.dart';
import 'transaction_trace_screen.dart';
import 'advanced_trace_screen.dart';

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

  // Add these controllers for Trace Call
  final TextEditingController _traceCallToController = TextEditingController();
  final TextEditingController _traceCallDataController =
      TextEditingController();

  // Add this controller for Trace Call From Address
  final TextEditingController _traceCallFromController =
      TextEditingController();

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
  String _selectedAdvancedMethod = 'Replay Block Transactions';

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
    _traceCallToController.dispose();
    _traceCallDataController.dispose();
    _traceCallFromController.dispose();
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

  Future<void> _executeAdvancedTrace() async {
    // Validate inputs
    final validationError = _validateAdvancedTraceInputs();
    if (validationError != null) {
      setState(() {
        _advancedError = validationError;
      });
      return;
    }

    setState(() {
      _isLoadingAdvanced = true;
      _advancedError = '';
      _advancedTraceResult = null;
    });

    try {
      final provider = Provider.of<TraceProvider>(context, listen: false);
      Map<String, dynamic> result;
      Map<String, dynamic> traceParams = {};

      // Execute the appropriate trace method based on the selected method
      switch (_selectedAdvancedMethod) {
        case 'Replay Block Transactions':
          final blockNumber = int.parse(_replayBlockController.text.trim());
          result = await provider.replayBlockTransactions(blockNumber);
          traceParams = {'blockNumber': _replayBlockController.text.trim()};
          break;
        case 'Replay Transaction':
          final txHash = _replayTxController.text.trim();
          result = await provider.replayTransaction(txHash);
          traceParams = {'txHash': txHash};
          break;
        case 'Storage Range':
          final blockHash = _blockHashController.text.trim();
          final txIndex = int.parse(_txIndexController.text.trim());
          final contractAddress = _contractAddressController.text.trim();
          result = await provider.getStorageRangeAt(
            blockHash,
            txIndex,
            contractAddress,
            '0x0000000000000000000000000000000000000000000000000000000000000000',
            10,
          );
          traceParams = {
            'blockHash': blockHash,
            'txIndex': _txIndexController.text.trim(),
            'contractAddress': contractAddress,
            'startKey':
                '0x0000000000000000000000000000000000000000000000000000000000000000',
            'pageSize': '10',
          };
          break;
        case 'Trace Call':
          final toAddress = _traceCallToController.text.trim();
          final data = _traceCallDataController.text.trim();
          final fromAddress = _traceCallFromController.text.trim();

          if (toAddress.isEmpty) {
            return;
          }
          if (!toAddress.startsWith('0x')) {
            return;
          }
          if (toAddress.length != 42) {
            return;
          }

          if (data.isEmpty) {
            return;
          }
          if (!data.startsWith('0x')) {
            return;
          }

          result = await provider.traceCall(
              toAddress, data, fromAddress.isEmpty ? null : fromAddress);
          traceParams = {
            'toAddress': toAddress,
            'data': data,
            'fromAddress': fromAddress.isEmpty ? null : fromAddress,
          };
          break;
        default:
          result = {'success': false, 'error': 'Unknown trace method'};
      }

      if (!mounted) return;

      setState(() {
        _advancedTraceResult = result;
        _isLoadingAdvanced = false;
      });

      // Navigate to the advanced trace screen
      if (result['success'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdvancedTraceScreen(
              traceMethod: _selectedAdvancedMethod,
              traceParams: traceParams,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAdvanced = false;
        _advancedError = 'Error: $e';
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

  Widget _buildInfoSection(String title, String description, IconData icon) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode
        ? theme.colorScheme.surface.withOpacity(0.3)
        : theme.colorScheme.primary.withOpacity(0.05);
    final textColor = theme.colorScheme.primary;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTraceTab() {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            'Transaction Tracing',
            'Enter a transaction hash to trace its execution. This will show you all internal calls, state changes, and gas usage during the transaction.',
            Icons.info_outline,
          ),
          TraceInputField(
            controller: _txHashController,
            label: 'Transaction Hash',
            hintText: '0x...',
            prefixIcon: Icons.receipt,
            onPaste: () async {
              final data = await Clipboard.getData('text/plain');
              if (data != null && data.text != null) {
                setState(() {
                  _txHashController.text = data.text!.trim();
                });
              }
            },
          ),
          const SizedBox(height: 24),
          TraceButton(
            text: 'Trace Transaction',
            icon: Icons.search,
            onPressed: _traceTransaction,
            isLoading: _isLoadingTx,
            backgroundColor: theme.colorScheme.primary,
            textColor: theme.colorScheme.onPrimary,
          ),
          if (_txError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                _txError,
                style: TextStyle(color: errorColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBlockTraceTab() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            'Block Tracing',
            'Enter a block number to view all transactions in that block. You can then select individual transactions to trace their execution.',
            Icons.info_outline,
          ),
          TraceInputField(
            controller: _blockNumberController,
            label: 'Block Number',
            hintText: 'Enter block number (e.g., 12345678)',
            prefixIcon: Icons.view_module,
            isHexInput: false,
            onPaste: () async {
              final data = await Clipboard.getData('text/plain');
              if (data != null && data.text != null) {
                setState(() {
                  _blockNumberController.text = data.text!.trim();
                });
              }
            },
          ),
          const SizedBox(height: 24),
          TraceButton(
              text: 'Trace Block',
              icon: Icons.search,
              onPressed: _traceBlock,
              isLoading: _isLoadingBlock,
              backgroundColor: Colors.green),
          if (_blockError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                _blockError,
                style: const TextStyle(color: Colors.red),
              ),
            ),
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
          _buildInfoSection(
            'Advanced Tracing',
            'Use specialized tracing methods for deeper blockchain analysis. Select a method below to get started.',
            Icons.info_outline,
          ),
          TraceMethodSelector(
            selectedMethod: _selectedAdvancedMethod,
            onMethodChanged: (String newValue) {
              setState(() {
                _selectedAdvancedMethod = newValue;
                _advancedError = '';
                _advancedTraceResult = null;
              });
            },
            availableMethods: const [
              'Replay Block Transactions',
              'Replay Transaction',
              'Storage Range',
              'Trace Call',
            ],
          ),
          const SizedBox(height: 24),
          _buildAdvancedMethodInputs(),
          const SizedBox(height: 24),
          TraceButton(
            text: 'Execute Trace',
            icon: Icons.play_arrow,
            onPressed: _executeAdvancedTrace,
            isLoading: _isLoadingAdvanced,
            backgroundColor: Colors.purple,
          ),
          if (_advancedError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                _advancedError,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdvancedMethodInputs() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final inputFillColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;

    switch (_selectedAdvancedMethod) {
      case 'Replay Block Transactions':
        return TraceInputField(
          controller: _replayBlockController,
          label: 'Block Number',
          hintText: 'Enter block number (e.g., 12345678)',
          prefixIcon: Icons.view_module,
          isHexInput: false,
          onPaste: () async {
            final data = await Clipboard.getData('text/plain');
            if (data != null && data.text != null) {
              setState(() {
                _replayBlockController.text = data.text!.trim();
              });
            }
          },
        );

      case 'Replay Transaction':
        return TraceInputField(
          controller: _replayTxController,
          label: 'Transaction Hash',
          hintText: '0x...',
          prefixIcon: Icons.receipt,
          onPaste: () async {
            final data = await Clipboard.getData('text/plain');
            if (data != null && data.text != null) {
              setState(() {
                _replayTxController.text = data.text!.trim();
              });
            }
          },
        );

      case 'Storage Range':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TraceInputField(
              controller: _blockHashController,
              label: 'Block Hash',
              hintText: '0x...',
              prefixIcon: Icons.view_module,
              onPaste: () async {
                final data = await Clipboard.getData('text/plain');
                if (data != null && data.text != null) {
                  setState(() {
                    _blockHashController.text = data.text!.trim();
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TraceInputField(
              controller: _txIndexController,
              label: 'Transaction Index',
              hintText: 'Enter transaction index (e.g., 0)',
              prefixIcon: Icons.format_list_numbered,
              isHexInput: false,
              onPaste: () async {
                final data = await Clipboard.getData('text/plain');
                if (data != null && data.text != null) {
                  setState(() {
                    _txIndexController.text = data.text!.trim();
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TraceInputField(
              controller: _contractAddressController,
              label: 'Contract Address',
              hintText: '0x...',
              prefixIcon: Icons.account_balance,
              onPaste: () async {
                final data = await Clipboard.getData('text/plain');
                if (data != null && data.text != null) {
                  setState(() {
                    _contractAddressController.text = data.text!.trim();
                  });
                }
              },
              helperText: 'Enter the contract address to get storage for',
            ),
          ],
        );

      case 'Trace Call':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TraceInputField(
              controller: _traceCallFromController,
              label: 'From Address',
              hintText: '0x... (leave empty to use default)',
              prefixIcon: Icons.person,
              isRequired: false,
              onPaste: () async {
                final data = await Clipboard.getData('text/plain');
                if (data != null && data.text != null) {
                  setState(() {
                    _traceCallFromController.text = data.text!.trim();
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TraceInputField(
              controller: _traceCallToController,
              label: 'To Address',
              hintText: '0x...',
              prefixIcon: Icons.account_balance,
              onPaste: () async {
                final data = await Clipboard.getData('text/plain');
                if (data != null && data.text != null) {
                  setState(() {
                    _traceCallToController.text = data.text!.trim();
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TraceInputField(
              controller: _traceCallDataController,
              label: 'Call Data',
              hintText: '0x...',
              isMultiline: true,
              prefixIcon: Icons.code,
              onPaste: () async {
                final data = await Clipboard.getData('text/plain');
                if (data != null && data.text != null) {
                  setState(() {
                    _traceCallDataController.text = data.text!.trim();
                  });
                }
              },
              helperText:
                  'Enter the call data (function signature and parameters)',
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: This will execute a call without modifying state.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        );

      default:
        return const Text('Unknown trace method');
    }
  }

  Widget _buildHistoryTab() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<TraceProvider>(context);

    // Create a sorted copy of the recent traces (latest first)
    final recentTraces = List<Map<String, dynamic>>.from(provider.recentTraces)
      ..sort(
          (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildInfoSection(
            'Trace History',
            'View your recent trace operations. Click on any item to re-run the trace or view the results.',
            Icons.history,
          ),
        ),
        if (recentTraces.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.delete_sweep, size: 18),
                  label: const Text('Clear All'),
                  onPressed: () => _showClearHistoryDialog(provider),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        if (recentTraces.isEmpty)
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No trace history yet. Try tracing some transactions or blocks!',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: recentTraces.length,
              itemBuilder: (context, index) {
                final trace = recentTraces[index];
                final timestamp = DateTime.fromMillisecondsSinceEpoch(
                    trace['timestamp'] as int? ?? 0);
                final formattedTime =
                    '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';

                IconData icon;
                String title;
                String subtitle;

                switch (trace['type']) {
                  case 'transaction':
                    icon = Icons.receipt;
                    title = 'Transaction Trace';
                    subtitle =
                        'Hash: ${FormatterUtils.formatHash(trace['hash'] as String? ?? 'Unknown')}';
                    break;
                  case 'block':
                    icon = Icons.view_module;
                    title = 'Block Trace';
                    subtitle = 'Block: ${trace['blockNumber'] as int? ?? 0}';
                    break;
                  case 'blockReplay':
                    icon = Icons.replay;
                    title = 'Block Replay';
                    subtitle = 'Block: ${trace['blockNumber'] as int? ?? 0}';
                    break;
                  case 'txReplay':
                    icon = Icons.replay_circle_filled;
                    title = 'Transaction Replay';
                    subtitle =
                        'Hash: ${FormatterUtils.formatHash(trace['hash'] as String? ?? 'Unknown')}';
                    break;
                  case 'storageRange':
                    icon = Icons.storage;
                    title = 'Storage Range';
                    subtitle =
                        'Contract: ${FormatterUtils.formatHash(trace['contractAddress'] as String? ?? 'Unknown')}';
                    break;
                  case 'traceCall':
                    icon = Icons.call_made;
                    title = 'Trace Call';
                    subtitle =
                        'To: ${FormatterUtils.formatHash(trace['to'] as String? ?? 'Unknown')}';
                    break;
                  default:
                    icon = Icons.help_outline;
                    title = 'Unknown Trace';
                    subtitle = 'Type: ${trace['type'] as String? ?? 'Unknown'}';
                }

                return Dismissible(
                  key: Key('history_${trace['timestamp']}'),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await _showDeleteConfirmationDialog(context);
                  },
                  onDismissed: (direction) {
                    provider.removeTraceFromHistory(index);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red,
                        content: Text('$title removed from history'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            provider.restoreRemovedTrace();
                          },
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(0.2),
                        child:
                            Icon(icon, color: Theme.of(context).primaryColor),
                      ),
                      title: Text(title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(subtitle),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () async {
                              if (await _showDeleteConfirmationDialog(
                                  context)) {
                                provider.removeTraceFromHistory(index);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('$title removed from history'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () {
                                        provider.restoreRemovedTrace();
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                            tooltip: 'Delete',
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () => _navigateToTraceFromHistory(trace),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _navigateToTraceFromHistory(Map<String, dynamic> trace) {
    final type = trace['type'] as String? ?? '';

    switch (type) {
      case 'transaction':
        final txHash = trace['hash'] as String? ?? '';
        if (txHash.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionTraceScreen(txHash: txHash),
            ),
          );
        }
        break;

      case 'block':
        final blockNumber = trace['blockNumber'] as int? ?? 0;
        if (blockNumber > 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlockTraceScreen(blockNumber: blockNumber),
            ),
          );
        }
        break;

      case 'blockReplay':
        _selectedAdvancedMethod = 'Replay Block Transactions';
        _replayBlockController.text =
            (trace['blockNumber'] as int?)?.toString() ?? '';
        break;

      case 'txReplay':
        _selectedAdvancedMethod = 'Replay Transaction';
        _replayTxController.text = trace['hash'] as String? ?? '';
        break;

      case 'storageRange':
        _selectedAdvancedMethod = 'Storage Range';
        _blockHashController.text = trace['blockHash'] as String? ?? '';
        _txIndexController.text = (trace['txIndex'] as int?)?.toString() ?? '';
        _contractAddressController.text =
            trace['contractAddress'] as String? ?? '';
        break;

      case 'traceCall':
        _selectedAdvancedMethod = 'Trace Call';
        _traceCallToController.text = trace['to'] as String? ?? '';
        _traceCallDataController.text = trace['data'] as String? ?? '';
        if (trace['from'] != null) {
          _traceCallFromController.text = trace['from'] as String;
        }
        break;
    }

    // Execute the trace after a short delay to allow the UI to update
    Future.delayed(const Duration(milliseconds: 300), () {
      _executeAdvancedTrace();
    });
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

  String? _validateAdvancedTraceInputs() {
    // Validate inputs based on the selected method
    switch (_selectedAdvancedMethod) {
      case 'Replay Block Transactions':
        final blockNumber = _replayBlockController.text.trim();
        if (blockNumber.isEmpty) {
          return 'Block number is required';
        }
        try {
          final blockNum = int.parse(blockNumber);
          if (blockNum < 0) {
            return 'Block number must be positive';
          }
        } catch (e) {
          return 'Block number must be a valid integer';
        }
        break;

      case 'Replay Transaction':
        final txHash = _replayTxController.text.trim();
        if (txHash.isEmpty) {
          return 'Transaction hash is required';
        }
        if (!txHash.startsWith('0x')) {
          return 'Transaction hash must start with 0x';
        }
        if (txHash.length != 66) {
          return 'Transaction hash must be 66 characters long (including 0x)';
        }
        break;

      case 'Storage Range':
        final blockHash = _blockHashController.text.trim();
        final txIndex = _txIndexController.text.trim();
        final contractAddress = _contractAddressController.text.trim();

        if (blockHash.isEmpty) {
          return 'Block hash is required';
        }
        if (!blockHash.startsWith('0x')) {
          return 'Block hash must start with 0x';
        }
        if (blockHash.length != 66) {
          return 'Block hash must be 66 characters long (including 0x)';
        }

        if (txIndex.isEmpty) {
          return 'Transaction index is required';
        }
        try {
          final index = int.parse(txIndex);
          if (index < 0) {
            return 'Transaction index must be positive';
          }
        } catch (e) {
          return 'Transaction index must be a valid integer';
        }

        if (contractAddress.isEmpty) {
          return 'Contract address is required';
        }
        if (!contractAddress.startsWith('0x')) {
          return 'Contract address must start with 0x';
        }
        if (contractAddress.length != 42) {
          return 'Contract address must be 42 characters long (including 0x)';
        }
        break;

      case 'Trace Call':
        final toAddress = _traceCallToController.text.trim();
        final data = _traceCallDataController.text.trim();
        final fromAddress = _traceCallFromController.text.trim();

        if (toAddress.isEmpty) {
          return 'To address is required';
        }
        if (!toAddress.startsWith('0x')) {
          return 'To address must start with 0x';
        }
        if (toAddress.length != 42) {
          return 'To address must be 42 characters long (including 0x)';
        }

        if (data.isEmpty) {
          return 'Call data is required';
        }
        if (!data.startsWith('0x')) {
          return 'Call data must start with 0x';
        }

        // Only validate fromAddress if it's not empty
        if (fromAddress.isNotEmpty) {
          if (!fromAddress.startsWith('0x')) {
            return 'From address must start with 0x';
          }
          if (fromAddress.length != 42) {
            return 'From address must be 42 characters long (including 0x)';
          }
        }
        break;

      default:
        return 'Unknown trace method';
    }

    return null;
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Trace'),
              content: const Text(
                  'Are you sure you want to remove this trace from history?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showClearHistoryDialog(TraceProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear History'),
          content: const Text(
              'Are you sure you want to clear all trace history? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                provider.clearTraceHistory();
                Navigator.of(context).pop();
                SnackbarUtil.showSnackbar(
                    isError: true,
                    context: context,
                    message: 'Trace history cleared');
              },
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
