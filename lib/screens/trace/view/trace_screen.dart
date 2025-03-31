import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';
import '../provider/transaction_trace_provider.dart';
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

  bool _isLoadingTx = false;
  bool _isLoadingBlock = false;
  Map<String, dynamic>? _txTraceResult;
  Map<String, dynamic>? _blockTraceResult;
  String _txError = '';
  String _blockError = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _txHashController.dispose();
    _blockNumberController.dispose();
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
      final provider = Provider.of<TraceProvider>(context, listen: false);
      final result = await provider.getBlockTrace(blockNumber);

      if (!mounted) return;

      setState(() {
        _isLoadingBlock = false;
        _blockTraceResult = result;
        if (result['success'] != true) {
          _blockError = result['error'] ?? 'Unknown error';
        }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('PYUSD Transaction Tracer'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Trace Transaction'),
            Tab(text: 'Trace Block'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionTraceTab(),
          _buildBlockTraceTab(),
          _buildHistoryTab(),
        ],
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
                    'Enter a transaction hash to trace a PYUSD transaction using GCP\'s powerful trace_transaction RPC method.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This method provides detailed insights into transaction execution, including internal calls and state changes.',
                            style: TextStyle(
                              color: Colors.blue.shade700,
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

          // Transaction hash input
          TextField(
            controller: _txHashController,
            decoration: InputDecoration(
              labelText: 'Transaction Hash',
              hintText: 'Enter transaction hash (0x...)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste),
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) {
                    _txHashController.text = data!.text!;
                  }
                },
                tooltip: 'Paste from clipboard',
              ),
            ),
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
            child: ElevatedButton(
              onPressed: _isLoadingTx ? null : _traceTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoadingTx
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Trace Transaction'),
            ),
          ),

          // Transaction trace result
          if (_txTraceResult != null) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trace Result',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionTraceScreen(
                          txHash: _txHashController.text.trim(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_txTraceResult!['success'] == true) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trace Preview:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTracePreview(_txTraceResult!),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _txTraceResult!['error'] ?? 'Unknown error',
                        style: TextStyle(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                    'Enter a block number to trace all transactions in that block using GCP\'s trace_block RPC method.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This tool will automatically filter for PYUSD transactions in the block.',
                            style: TextStyle(
                              color: Colors.blue.shade700,
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

          // Block number input
          TextField(
            controller: _blockNumberController,
            decoration: InputDecoration(
              labelText: 'Block Number',
              hintText: 'Enter block number (e.g., 18000000)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste),
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) {
                    _blockNumberController.text = data!.text!;
                  }
                },
                tooltip: 'Paste from clipboard',
              ),
            ),
            keyboardType: TextInputType.number,
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoadingBlock ? null : _traceBlock,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoadingBlock
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Trace Block'),
            ),
          ),

          // Block trace result
          if (_blockTraceResult != null) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Block #${_blockTraceResult!['blockNumber']} Trace Result',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_blockTraceResult!['success'] == true) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Traces: ${(_blockTraceResult!['fullTrace'] as List?)?.length ?? 0}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PYUSD Traces: ${(_blockTraceResult!['pyusdTraces'] as List?)?.length ?? 0}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),

                    // PYUSD traces list
                    if ((_blockTraceResult!['pyusdTraces'] as List?)
                            ?.isNotEmpty ??
                        false) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'PYUSD Transactions in this Block:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        height: 200,
                        child: ListView.separated(
                          itemCount: (_blockTraceResult!['pyusdTraces'] as List)
                              .length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final trace = (_blockTraceResult!['pyusdTraces']
                                as List)[index];
                            final action = trace['action'] ?? {};
                            final from = action['from'] ?? '';
                            final to = action['to'] ?? '';
                            final value = action['value'] ?? '0x0';
                            final input = action['input'] ?? '';

                            return ListTile(
                              title: Text(
                                'From: ${FormatterUtils.formatAddress(from)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'To: ${FormatterUtils.formatAddress(to)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  if (input.length > 10)
                                    Text(
                                      'Input: ${input.length > 42 ? '${input.substring(0, 42)}...' : input}',
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              trailing: Text(
                                _formatEthValue(value),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              dense: true,
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _blockTraceResult!['error'] ?? 'Unknown error',
                        style: TextStyle(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<TraceProvider>(
      builder: (context, provider, child) {
        final recentTraces = provider.recentTraces;

        if (recentTraces.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey.shade400),
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

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    'Recent Trace History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      provider.clearHistory();
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: recentTraces.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final trace = recentTraces[recentTraces.length - 1 - index];
                  final isTransaction = trace['type'] == 'transaction';
                  final timestamp = DateTime.fromMillisecondsSinceEpoch(
                    trace['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
                  );

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isTransaction
                          ? Colors.blue.shade100
                          : Colors.green.shade100,
                      child: Icon(
                        isTransaction ? Icons.receipt_long : Icons.storage,
                        color: isTransaction ? Colors.blue : Colors.green,
                      ),
                    ),
                    title: Text(
                      isTransaction
                          ? 'Transaction: ${FormatterUtils.formatAddress(trace['hash'] ?? '')}'
                          : 'Block #${trace['blockNumber']}',
                    ),
                    subtitle: Text(
                      'Traced on ${timestamp.toString().substring(0, 19)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () {
                        if (isTransaction) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionTraceScreen(
                                txHash: trace['hash'] ?? '',
                              ),
                            ),
                          );
                        } else {
                          // Re-trace the block
                          _blockNumberController.text =
                              trace['blockNumber'].toString();
                          _tabController.animateTo(1); // Switch to block tab
                          _traceBlock();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTracePreview(Map<String, dynamic> traceData) {
    try {
      final trace = traceData['trace'];
      if (trace is List && trace.isNotEmpty) {
        return const JsonEncoder.withIndent('  ')
                .convert(trace[0])
                .substring(0, 300) +
            '...';
      }
      return 'No trace data available';
    } catch (e) {
      return 'Error formatting trace preview: $e';
    }
  }

  String _formatEthValue(String hexValue) {
    final value = FormatterUtils.parseHexSafely(hexValue) ?? 0;
    final ethValue = value / 1e18;

    if (ethValue == 0) {
      return '0 ETH';
    } else if (ethValue < 0.000001) {
      return '< 0.000001 ETH';
    } else {
      return '${ethValue.toStringAsFixed(6)} ETH';
    }
  }
}
