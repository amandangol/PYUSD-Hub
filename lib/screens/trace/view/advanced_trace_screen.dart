import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';
import 'package:pyusd_hub/utils/snackbar_utils.dart';
import '../../../../widgets/loading_overlay.dart';

import '../../../widgets/pyusd_components.dart';
import '../provider/trace_provider.dart';
import '../../../providers/gemini_provider.dart';
import '../widgets/trace_widgets.dart';

class AdvancedTraceScreen extends StatefulWidget {
  final String traceMethod;
  final Map<String, dynamic> traceParams;
  final String? heroTag;

  const AdvancedTraceScreen({
    super.key,
    required this.traceMethod,
    required this.traceParams,
    this.heroTag,
  });

  @override
  State<AdvancedTraceScreen> createState() => _AdvancedTraceScreenState();
}

class _AdvancedTraceScreenState extends State<AdvancedTraceScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _traceData = {};
  String _errorMessage = '';

  bool _isAiAnalysisLoading = false;
  Map<String, dynamic> _aiAnalysis = {};
  bool _showAiAnalysis = false;

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
      final provider = Provider.of<TraceProvider>(context, listen: false);
      Map<String, dynamic> result;

      // Execute the appropriate trace method based on the method name
      switch (widget.traceMethod) {
        case 'Replay Block Transactions':
          final blockNumber =
              int.parse(widget.traceParams['blockNumber'] as String);
          result = await provider.replayBlockTransactions(blockNumber);
          break;
        case 'Replay Transaction':
          final txHash = widget.traceParams['txHash'] as String;
          result = await provider.replayTransaction(txHash);
          break;
        case 'Storage Range':
          final blockHash = widget.traceParams['blockHash'] as String;
          final txIndex = int.parse(widget.traceParams['txIndex'] as String);
          final contractAddress =
              widget.traceParams['contractAddress'] as String;
          final startKey = widget.traceParams['startKey'] as String;
          final pageSize = int.parse(widget.traceParams['pageSize'] as String);
          result = await provider.getStorageRangeAt(
              blockHash, txIndex, contractAddress, startKey, pageSize);
          break;
        default:
          result = {'success': false, 'error': 'Unknown trace method'};
      }

      if (!mounted) return;

      setState(() {
        _traceData = result;
        _isLoading = false;
        if (result['success'] != true) {
          _errorMessage = result['error'] ?? 'Unknown error';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading trace data: $e';
      });
    }
  }

  Future<void> _getAiAnalysis() async {
    setState(() {
      _isAiAnalysisLoading = true;
      _showAiAnalysis = true;
    });

    try {
      final geminiProvider =
          Provider.of<GeminiProvider>(context, listen: false);

      // Prepare data for analysis
      Map<String, dynamic> traceData = {
        'method': widget.traceMethod,
        'result': _traceData,
      };

      final analysis =
          await geminiProvider.analyzeAdvancedTraceStructured(traceData);

      if (!mounted) return;

      setState(() {
        _isAiAnalysisLoading = false;
        _aiAnalysis = analysis;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isAiAnalysisLoading = false;
        _aiAnalysis = {
          "summary": "Error generating AI analysis",
          "error": true,
          "errorMessage": e.toString()
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Advanced Trace: ${widget.traceMethod}',
        isDarkMode: isDarkMode,
        onBackPressed: () => Navigator.pop(context),
        onRefreshPressed: _loadTraceData,
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            tooltip: 'AI Analysis',
            onPressed: _isLoading ? null : _getAiAnalysis,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        loadingText: 'Loading advanced trace data...',
        body: _errorMessage.isNotEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      TraceButton(
                        text: 'Try Again',
                        horizontalPadding: 20,
                        onPressed: _loadTraceData,
                        icon: Icons.refresh,
                        backgroundColor: Colors.blue,
                        verticalPadding: 10,
                      ),
                    ],
                  ),
                ),
              )
            : _buildTraceContent(),
      ),
    );
  }

  Widget _buildTraceContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trace method info card
          _buildTraceMethodCard(),

          const SizedBox(height: 16),

          // AI Analysis card
          if (_showAiAnalysis) _buildAiAnalysisCard(),

          if (_showAiAnalysis) const SizedBox(height: 16),

          // Trace visualization card
          _buildTraceVisualizationCard(),

          const SizedBox(height: 16),

          // Raw trace data card
          _buildRawTraceDataCard(),
        ],
      ),
    );
  }

  Widget _buildTraceMethodCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.science,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.traceMethod,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Parameters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.traceParams.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key}: ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAnalysisCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    const accentColor = Colors.purple;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI Trace Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_showAiAnalysis)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isAiAnalysisLoading ? null : _getAiAnalysis,
                    tooltip: 'Refresh Analysis',
                  ),
              ],
            ),
            const Divider(height: 24),
            if (!_showAiAnalysis)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Image.asset(
                      'assets/images/geminilogo.png',
                      height: 48,
                      width: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Get an AI-powered analysis of this trace',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our AI will analyze the trace data and provide insights',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TraceButton(
                      text: 'Analyze with AI',
                      onPressed: _getAiAnalysis,
                      icon: Icons.auto_awesome,
                      backgroundColor: Colors.blue.withOpacity(0.8),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              )
            else if (_isAiAnalysisLoading)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Analyzing trace...',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'This may take a few moments',
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              )
            else if (_aiAnalysis.containsKey('error') &&
                _aiAnalysis['error'] == true)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error analyzing trace',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _aiAnalysis['errorMessage'] ?? 'Unknown error occurred',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textColor.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 20),
                    TraceButton(
                      text: 'Try Again',
                      onPressed: _getAiAnalysis,
                      icon: Icons.refresh,
                      backgroundColor: Colors.blue,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              )
            else
              _buildStructuredAnalysisContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildStructuredAnalysisContent() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    // Extract data from analysis
    final summary = _aiAnalysis['summary'] ?? 'No summary available';
    final technicalDetails =
        _aiAnalysis['technicalDetails'] ?? 'No technical details available';
    final insights = _aiAnalysis['insights'] ?? 'No insights available';
    final recommendations =
        _aiAnalysis['recommendations'] ?? 'No recommendations available';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.summarize, size: 18, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MarkdownBody(
                data: summary,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Technical Details section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.code, size: 18, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Technical Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MarkdownBody(
                data: technicalDetails,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Insights section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb, size: 18, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Insights',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MarkdownBody(
                data: insights,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Recommendations section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.recommend, size: 18, color: Colors.purple),
                  SizedBox(width: 8),
                  Text(
                    'Recommendations',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MarkdownBody(
                data: recommendations,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Powered by Gemini
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/geminilogo.png',
                height: 16,
                width: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Powered by Google Gemini',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: textColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTraceVisualizationCard() {
    Widget visualization;

    switch (widget.traceMethod) {
      case 'Storage Range':
        visualization = _buildStorageRangeVisualization();
        break;
      case 'Replay Block Transactions':
        visualization = _buildBlockTraceVisualization();
        break;
      case 'Replay Transaction':
        visualization = _buildTransactionTraceVisualization();
        break;
      default:
        visualization = const Center(
          child: Text('No visualization available for this trace type'),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_tree,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Trace Visualization',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            visualization,
          ],
        ),
      ),
    );
  }

  Widget _buildStorageRangeVisualization() {
    final storage = _traceData['storage'];
    if (storage == null) {
      return const Center(child: Text('No storage data available'));
    }

    final storageEntries = storage['storage'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contract: ${_traceData['contractAddress'] ?? 'Unknown'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text('Storage Entries: ${storageEntries.length}'),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: storageEntries.length,
          itemBuilder: (context, index) {
            final entry = storageEntries.entries.elementAt(index);
            final key = entry.key;
            final value = entry.value['value'] ?? 'null';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('Key: $key'),
                subtitle: Text('Value: $value'),
                dense: true,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTransactionTraceVisualization() {
    final traceData = _traceData['trace'];
    if (traceData == null) {
      return const Center(child: Text('No trace data available'));
    }

    final transaction = _traceData['transaction'] as Map<String, dynamic>?;
    final receipt = _traceData['receipt'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Transaction Overview Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transaction Overview',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              if (transaction != null) ...[
                _buildTransactionDetail(
                    'Hash', transaction['hash']?.toString()),
                _buildTransactionDetail(
                    'From', transaction['from']?.toString()),
                _buildTransactionDetail('To', transaction['to']?.toString()),
                _buildTransactionDetail(
                  'Value',
                  FormatterUtils.formatEthFromHex(
                      transaction['value']?.toString() ?? '0x0'),
                ),
                _buildTransactionDetail(
                  'Gas Price',
                  FormatterUtils.formatGasPrice(
                      int.parse(transaction['gasPrice']?.toString() ?? '0x0')),
                ),
              ],
              if (receipt != null) ...[
                _buildTransactionDetail(
                  'Status',
                  receipt['status'] == '0x1' ? 'Success' : 'Failed',
                  color: receipt['status'] == '0x1' ? Colors.green : Colors.red,
                ),
                _buildTransactionDetail(
                  'Gas Used',
                  FormatterUtils.formatGas(
                      receipt['gasUsed']?.toString() ?? '0x0'),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Call Hierarchy Section
        Text(
          'Call Hierarchy',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        _buildCallTree(traceData as Map<String, dynamic>?),

        const SizedBox(height: 24),

        // Trace Statistics
        if (traceData is Map<String, dynamic>) _buildTraceStatistics(traceData),
      ],
    );
  }

  Widget _buildTransactionDetail(String label, String? value,
      {String? suffix, Color? color}) {
    if (value == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              suffix != null ? '$value $suffix' : value,
              style: TextStyle(
                color: color,
                fontFamily: label == 'Hash' || label == 'From' || label == 'To'
                    ? 'monospace'
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraceStatistics(Map<String, dynamic> traceData) {
    final calls = _countCalls(traceData);
    final valueTransfers = _countValueTransfers(traceData);
    final errors = _countErrors(traceData);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trace Statistics',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatRow('Total Calls', calls),
          _buildStatRow('Value Transfers', valueTransfers),
          _buildStatRow('Errors', errors, isError: errors > 0),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isError && value > 0 ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  int _countCalls(Map<String, dynamic> trace) {
    int count = 1;
    final calls = trace['calls'] as List? ?? [];
    for (var call in calls) {
      if (call is Map<String, dynamic>) {
        count += _countCalls(call);
      }
    }
    return count;
  }

  int _countValueTransfers(Map<String, dynamic> trace) {
    int count = trace['value'] != null && trace['value'] != '0x0' ? 1 : 0;
    final calls = trace['calls'] as List? ?? [];
    for (var call in calls) {
      if (call is Map<String, dynamic>) {
        count += _countValueTransfers(call);
      }
    }
    return count;
  }

  int _countErrors(Map<String, dynamic> trace) {
    int count = trace['error'] != null ? 1 : 0;
    final calls = trace['calls'] as List? ?? [];
    for (var call in calls) {
      if (call is Map<String, dynamic>) {
        count += _countErrors(call);
      }
    }
    return count;
  }

  Widget _buildCallTree(Map<String, dynamic>? call, {int depth = 0}) {
    if (call == null || call.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No call data available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final type = call['type']?.toString().toUpperCase() ?? 'CALL';
    final to = call['to']?.toString() ?? 'Unknown';
    final from = call['from']?.toString() ?? 'Unknown';
    final value = call['value']?.toString() ?? '0x0';
    final input = call['input']?.toString() ?? '0x';
    final error = call['error']?.toString();
    final calls = call['calls'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showCallDetails(call),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: EdgeInsets.only(left: depth * 20.0),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: _getCallTypeColor(type),
                  width: 2,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getCallTypeColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          color: _getCallTypeColor(type),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (error != null)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ERROR',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'To: ${FormatterUtils.formatHash(to)}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (value != '0x0')
                  Text(
                    'Value: ${FormatterUtils.formatEthFromHex(value)} ETH',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
          ),
        ),
        ...calls.map((subcall) => _buildCallTree(
              subcall as Map<String, dynamic>?,
              depth: depth + 1,
            )),
      ],
    );
  }

  void _showCallDetails(Map<String, dynamic> call) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(call['type']?.toString().toUpperCase() ?? 'CALL'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('From', call['from']?.toString() ?? 'Unknown'),
              _buildDetailRow('To', call['to']?.toString() ?? 'Unknown'),
              _buildDetailRow(
                'Value',
                FormatterUtils.formatEthFromHex(
                    call['value']?.toString() ?? '0x0'),
              ),
              if (call['input'] != null && call['input'] != '0x')
                _buildDetailRow('Input', call['input']),
              if (call['output'] != null && call['output'] != '0x')
                _buildDetailRow('Output', call['output']),
              if (call['error'] != null)
                _buildDetailRow('Error', call['error'], isError: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isError ? Colors.red : null,
              fontFamily: 'monospace',
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  String _formatGasPrice(String hexGasPrice) {
    try {
      final gasPriceWei = BigInt.parse(hexGasPrice);
      final gasPriceGwei = gasPriceWei / BigInt.from(1e9);
      return '${gasPriceGwei.toStringAsFixed(2)} Gwei';
    } catch (e) {
      return '0 Gwei';
    }
  }

  Color _getCallTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'CALL':
        return Colors.blue;
      case 'STATICCALL':
        return Colors.purple;
      case 'DELEGATECALL':
        return Colors.orange;
      case 'CREATE':
        return Colors.green;
      case 'CREATE2':
        return Colors.teal;
      case 'SELFDESTRUCT':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRawTraceDataCard() {
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.code,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Raw Trace Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: _copyTraceData,
                  tooltip: 'Copy Raw Data',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  FormatterUtils.formatJson(_traceData),
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
    );
  }

  Widget _buildBlockTraceVisualization() {
    final traces = _traceData['traces'];
    if (traces == null || traces is! List) {
      return const Center(child: Text('No trace data available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Block Overview Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Block #${widget.traceParams['blockNumber']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Block Hash: ${FormatterUtils.formatHash(_traceData['blockHash'] ?? '')}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Transactions: ${traces.length}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Show first 5 transactions
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: traces.length > 5 ? 5 : traces.length,
          itemBuilder: (context, index) => _buildTransactionCard(traces[index]),
        ),

        // Show "View All" button if there are more than 5 transactions
        if (traces.length > 5)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: TextButton.icon(
                onPressed: () => _showAllTracesDialog(traces),
                icon: const Icon(Icons.list),
                label: Text('Show all ${traces.length} transactions'),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showAllTracesDialog(List<dynamic> traces) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            children: [
              // Dialog Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      'All ${traces.length} Transactions',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Scrollable Transaction List
              Expanded(
                child: ListView.builder(
                  itemCount: traces.length,
                  itemBuilder: (context, index) =>
                      _buildTransactionCard(traces[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> trace) {
    final tx = trace['transaction'] as Map<String, dynamic>;
    final receipt = trace['receipt'] as Map<String, dynamic>?;
    final traceData = trace['trace'] as Map<String, dynamic>?;

    // Determine transaction status
    final bool isSuccess = receipt != null &&
        (receipt['status'] == '0x1' || receipt['status'] == true);

    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              Icons.swap_horiz,
              size: 16,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                FormatterUtils.formatHash(tx['hash'] ?? ''),
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: (isSuccess ? Colors.green : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                receipt == null
                    ? 'Pending'
                    : (isSuccess ? 'Success' : 'Failed'),
                style: TextStyle(
                  fontSize: 12,
                  color: receipt == null
                      ? Colors.orange
                      : (isSuccess ? Colors.green : Colors.red),
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            _buildAddressRow('From', tx['from'] ?? ''),
            _buildAddressRow('To', tx['to'] ?? ''),
            if (tx['value'] != null && tx['value'] != '0x0')
              Text(
                'Value: ${FormatterUtils.formatEthFromHex(tx['value'])} ETH',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gas Information
                if (receipt != null) // Only show gas info if receipt exists
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildGasInfo(
                          'Gas Used',
                          FormatterUtils.formatGas(receipt['gasUsed'] ?? '0x0'),
                          Icons.local_gas_station,
                        ),
                        _buildGasInfo(
                          'Gas Price',
                          FormatterUtils.formatGasPrice(
                            int.parse(tx['gasPrice']?.toString() ?? '0x0'),
                          ),
                          Icons.price_change,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Call Trace',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                if (traceData != null)
                  _buildCallTree(traceData)
                else
                  const Text(
                    'No trace data available',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(String label, String address) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            FormatterUtils.formatHash(address),
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGasInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _copyTraceData() {
    Clipboard.setData(ClipboardData(
      text: FormatterUtils.formatJson(_traceData),
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trace data copied to clipboard')),
    );
  }
}
