import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';
import 'package:pyusd_hub/utils/snackbar_utils.dart';
import '../../provider/network_congestion_provider.dart';
import 'stats_card.dart';

class TransactionTraceScreen extends StatefulWidget {
  final String txHash;

  const TransactionTraceScreen({
    Key? key,
    required this.txHash,
  }) : super(key: key);

  @override
  State<TransactionTraceScreen> createState() => _TransactionTraceScreenState();
}

class _TransactionTraceScreenState extends State<TransactionTraceScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _traceData = {};
  Map<String, dynamic> _analysisData = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTraceData();
  }

  Future<void> _loadTraceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final provider =
          Provider.of<NetworkCongestionProvider>(context, listen: false);

      // Get transaction trace
      final traceData =
          await provider.getTransactionTraceWithCache(widget.txHash);

      // Get detailed analysis
      final analysisData =
          await provider.analyzePyusdTransaction(widget.txHash);

      if (!mounted) return;

      setState(() {
        _traceData = traceData;
        _analysisData = analysisData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading trace data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Trace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTraceData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_errorMessage, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadTraceData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildTraceContent(),
    );
  }

  Widget _buildTraceContent() {
    final bool success = _analysisData['success'] == true;

    if (!success) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                  'Could not analyze transaction: ${_analysisData['error'] ?? 'Unknown error'}'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadTraceData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final txData = _analysisData['transaction'] ?? {};
    final tokenDetails = _analysisData['tokenDetails'] ?? {};
    final gasAnalysis = _analysisData['gasAnalysis'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction overview card
          _buildTransactionOverviewCard(txData, tokenDetails),

          const SizedBox(height: 16),

          // Gas analysis card
          _buildGasAnalysisCard(gasAnalysis),

          const SizedBox(height: 16),

          // Trace visualization
          _buildTraceVisualizationCard(),

          const SizedBox(height: 16),

          // Raw trace data (collapsible)
          _buildRawTraceDataCard(),
        ],
      ),
    );
  }

  Widget _buildTransactionOverviewCard(
      Map<String, dynamic> txData, Map<String, dynamic> tokenDetails) {
    final String from = txData['from'] ?? '';
    final String to = txData['to'] ?? '';
    final String recipient = tokenDetails['recipient'] ?? to;
    final double value = tokenDetails['value'] ?? 0.0;
    final String formattedValue = tokenDetails['formattedValue'] ?? '\$0.00';

    // Get block number and timestamp
    final blockNumber =
        FormatterUtils.parseHexSafely(txData['blockNumber']) ?? 0;
    final timestamp = txData['timestamp'] != null
        ? FormatterUtils.parseHexSafely(txData['timestamp'])
        : null;

    final String dateTime = timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toString()
        : 'Pending';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaction Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.txHash));
                    SnackbarUtil.showSnackbar(
                        context: context,
                        message: 'Transaction hash copied to clipboard');
                  },
                  child: Row(
                    children: [
                      Text(
                        FormatterUtils.formatHash(widget.txHash),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy, size: 14),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Transaction details
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Amount',
                    value: formattedValue,
                    icon: Icons.attach_money,
                    color: Colors.green,
                    description: 'PYUSD',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatsCard(
                    title: 'Block',
                    value: blockNumber.toString(),
                    icon: Icons.layers,
                    color: Colors.blue,
                    description: dateTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // From/To addresses
            _buildAddressRow('From', from),
            const SizedBox(height: 12),
            _buildAddressRow('To', recipient),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow(String label, String address) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: address));
              SnackbarUtil.showSnackbar(
                  context: context,
                  message: '$label address copied to clipboard');
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.copy, size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGasAnalysisCard(Map<String, dynamic> gasAnalysis) {
    final int gasUsed = gasAnalysis['gasUsed'] ?? 0;
    final double gasPrice = gasAnalysis['gasPrice'] ?? 0;
    final double gasCostEth = gasAnalysis['gasCostEth'] ?? 0;
    final double gasCostUsd = gasAnalysis['gasCostUsd'] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gas Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Gas Used',
                    value: gasUsed.toString(),
                    icon: Icons.local_gas_station,
                    color: Colors.orange,
                    description: 'Units',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatsCard(
                    title: 'Gas Price',
                    value: '${gasPrice.toStringAsFixed(2)}',
                    icon: Icons.price_change,
                    color: Colors.purple,
                    description: 'Gwei',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Cost (ETH)',
                    value: '${gasCostEth.toStringAsFixed(6)}',
                    icon: Icons.currency_exchange,
                    color: Colors.indigo,
                    description: 'ETH',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatsCard(
                    title: 'Cost (USD)',
                    value: '\$${gasCostUsd.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    color: Colors.green,
                    description: 'USD',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraceVisualizationCard() {
    // Extract trace data for visualization
    final traceData = _traceData['trace'];

    if (traceData == null || !(traceData is List) || traceData.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trace Visualization',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Divider(),
              SizedBox(height: 16),
              Center(
                child: Text(
                  'No trace data available for visualization',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trace Visualization',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Build a visual representation of the trace
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: (traceData as List).length,
              itemBuilder: (context, index) {
                final trace = traceData[index];
                final action = trace['action'] ?? {};
                final result = trace['result'] ?? {};

                final String callType = action['callType'] ?? 'call';
                final String from = action['from'] ?? '';
                final String to = action['to'] ?? '';
                final String value = action['value'] ?? '0x0';
                final String gas = action['gas'] ?? '0x0';
                final String input = action['input'] ?? '0x';

                final Color callTypeColor = _getCallTypeColor(callType);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: callTypeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              callType.toUpperCase(),
                              style: TextStyle(
                                color: callTypeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Trace #${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // From -> To
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'From: ${FormatterUtils.formatAddress(from)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const Icon(Icons.arrow_forward, size: 16),
                          Expanded(
                            child: Text(
                              'To: ${FormatterUtils.formatAddress(to)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Value and Gas
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Value: ${_formatEthValue(value)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Gas: ${FormatterUtils.parseHexSafely(gas) ?? 0}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),

                      // Input data (truncated)
                      if (input.length > 2) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Input:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  input.length > 66
                                      ? '${input.substring(0, 66)}...'
                                      : input,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: input));
                                  SnackbarUtil.showSnackbar(
                                      context: context,
                                      message:
                                          'Input data copied to clipboard');
                                },
                                child: const Icon(Icons.copy, size: 16),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Result (if available)
                      if (result != null &&
                          result is Map &&
                          result.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Result:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            result.toString().length > 100
                                ? '${result.toString().substring(0, 100)}...'
                                : result.toString(),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRawTraceDataCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: const Text(
          'Raw Trace Data',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final jsonString = const JsonEncoder.withIndent('  ')
                            .convert(_traceData);
                        Clipboard.setData(ClipboardData(text: jsonString));
                        SnackbarUtil.showSnackbar(
                            context: context,
                            message: 'Raw trace data copied to clipboard');
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy JSON'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  height: 300,
                  child: SingleChildScrollView(
                    child: Text(
                      const JsonEncoder.withIndent('  ').convert(_traceData),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCallTypeColor(String callType) {
    switch (callType.toLowerCase()) {
      case 'call':
        return Colors.blue;
      case 'staticcall':
        return Colors.purple;
      case 'delegatecall':
        return Colors.orange;
      case 'create':
        return Colors.green;
      case 'create2':
        return Colors.teal;
      case 'selfdestruct':
        return Colors.red;
      default:
        return Colors.grey;
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
