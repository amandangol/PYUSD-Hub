import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';
import '../../provider/network_congestion_provider.dart';
import '../widgets/transaction_trace_screen.dart';

class TracingTab extends StatefulWidget {
  final NetworkCongestionProvider provider;

  const TracingTab({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  State<TracingTab> createState() => _TracingTabState();
}

class _TracingTabState extends State<TracingTab> {
  final TextEditingController _txHashController = TextEditingController();
  final TextEditingController _blockNumberController = TextEditingController();

  bool _isLoadingTx = false;
  bool _isLoadingBlock = false;
  Map<String, dynamic>? _txTraceResult;
  Map<String, dynamic>? _blockTraceResult;
  String _txError = '';
  String _blockError = '';

  @override
  void dispose() {
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
      final result = await widget.provider.getTransactionTraceWithCache(txHash);

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
      final result = await widget.provider.getBlockTrace(blockNumber);

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
                    'Advanced Transaction Tracing',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This tool uses GCP\'s powerful trace_transaction and trace_block RPC methods to provide detailed insights into PYUSD transactions.',
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
                            'These methods are computationally expensive but are provided for free by GCP, unlike other RPC providers.',
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

          // Transaction tracing section
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
                    'Trace Transaction',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _txHashController,
                    decoration: InputDecoration(
                      labelText: 'Transaction Hash',
                      hintText: '0x...',
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
                  if (_txTraceResult != null &&
                      _txTraceResult!['success'] == true) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Trace Result',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
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
                          child: const Text('View Detailed Analysis'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      height: 200,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transaction: ${_txHashController.text.trim()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Trace Type: ${_txTraceResult!.containsKey('debugTrace') ? 'debug_traceTransaction + trace_transaction' : 'trace_transaction'}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Trace Steps: ${(_txTraceResult!['trace'] as List?)?.length ?? 0}',
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Sample of trace data:',
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
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Block tracing section
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
                    'Trace Block',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  if (_blockTraceResult != null &&
                      _blockTraceResult!['success'] == true) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Block #${_blockTraceResult!['blockNumber']} Trace Result',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Total Traces: ${(_blockTraceResult!['fullTrace'] as List?)?.length ?? 0}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PYUSD Traces: ${(_blockTraceResult!['pyusdTraces'] as List?)?.length ?? 0}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PYUSD traces list
                    if ((_blockTraceResult!['pyusdTraces'] as List?)
                            ?.isNotEmpty ??
                        false) ...[
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTracePreview(Map<String, dynamic> traceData) {
    try {
      final trace = traceData['trace'];
      if (trace is List && trace.isNotEmpty) {
        final firstItem = trace[0];
        return const JsonEncoder.withIndent('  ')
                .convert(firstItem)
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
