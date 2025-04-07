import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final provider = Provider.of<TraceProvider>(context);

    return LoadingOverlay(
      isLoading: provider.isLoading,
      loadingText: 'Loading advanced trace data...',
      body: Scaffold(
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
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
                          ElevatedButton.icon(
                            onPressed: _loadTraceData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
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
            ...widget.traceParams.entries
                .map((entry) => Padding(
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
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
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
                  child: Icon(
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
              Row(
                children: [
                  const Icon(Icons.summarize, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
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
              Text(
                summary,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: textColor,
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
              Row(
                children: [
                  const Icon(Icons.code, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
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
              Text(
                technicalDetails,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: textColor,
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
              Row(
                children: [
                  const Icon(Icons.lightbulb, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text(
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
              Text(
                insights,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: textColor,
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
              Row(
                children: [
                  const Icon(Icons.recommend, size: 18, color: Colors.purple),
                  const SizedBox(width: 8),
                  const Text(
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
              Text(
                recommendations,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: textColor,
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
    final traces = _traceData['trace'] ?? _traceData['traces'];
    if (traces == null) {
      return const Center(child: Text('No trace data available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Call Hierarchy',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildTraceTree(traces),
      ],
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
        Text(
          'Block: ${widget.traceParams['blockNumber']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Transactions: ${traces.length}'),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: traces.length > 5 ? 5 : traces.length,
          itemBuilder: (context, index) {
            final trace = traces[index];
            final txHash = trace['transactionHash'] ?? 'Unknown';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title:
                    Text('Transaction: ${FormatterUtils.formatHash(txHash)}'),
                subtitle: Text('Calls: ${_countCalls(trace)}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Show detailed trace
                  _showTraceDetailsDialog(trace);
                },
              ),
            );
          },
        ),
        if (traces.length > 5)
          Center(
            child: TextButton(
              onPressed: () {
                // Show all traces
                _showAllTracesDialog(traces);
              },
              child: Text('Show all ${traces.length} transactions'),
            ),
          ),
      ],
    );
  }

  int _countCalls(dynamic trace) {
    if (trace is! Map) return 0;

    int count = 0;
    if (trace['calls'] is List) {
      count += (trace['calls'] as List).length;
      for (var call in trace['calls']) {
        count += _countCalls(call);
      }
    }
    return count;
  }

  Widget _buildTraceTree(dynamic trace, {int depth = 0}) {
    if (trace is! Map) return const SizedBox.shrink();

    final callType = trace['type'] ?? 'call';
    final to = trace['to'] ?? 'Unknown';
    final gasUsed = trace['gasUsed'] ?? '0x0';

    final callTypeColor = _getCallTypeColor(callType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            // Show call details
            _showCallDetailsDialog(trace as Map<String, dynamic>);
          },
          child: Padding(
            padding: EdgeInsets.only(left: depth * 20.0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  color: callTypeColor,
                  margin: const EdgeInsets.only(right: 8),
                ),
                Expanded(
                  child: Text(
                    '$callType to ${FormatterUtils.formatHash(to)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: callTypeColor,
                    ),
                  ),
                ),
                Text(
                  'Gas: ${FormatterUtils.formatGas(gasUsed)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        if (trace['calls'] is List)
          ...List.generate((trace['calls'] as List).length, (index) {
            return _buildTraceTree(trace['calls'][index], depth: depth + 1);
          }),
      ],
    );
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
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                FormatterUtils.formatJson(_traceData),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyTraceData() {
    Clipboard.setData(ClipboardData(
      text: FormatterUtils.formatJson(_traceData),
    ));
    SnackbarUtil.showSnackbar(
      context: context,
      message: 'Trace data copied to clipboard',
      icon: Icons.check_circle,
    );
  }

  void _showCallDetailsDialog(Map<String, dynamic> call) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${call['type'] ?? 'Call'} Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('From', call['from'] ?? 'Unknown'),
              _buildDetailRow('To', call['to'] ?? 'Unknown'),
              _buildDetailRow('Value',
                  FormatterUtils.formatEthFromHex(call['value'] ?? '0x0')),
              _buildDetailRow(
                  'Gas', FormatterUtils.formatGas(call['gas'] ?? '0x0')),
              _buildDetailRow('Gas Used',
                  FormatterUtils.formatGas(call['gasUsed'] ?? '0x0')),
              if (call['input'] != null)
                _buildDetailRow('Input', call['input']),
              if (call['output'] != null)
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

  void _showTraceDetailsDialog(Map<String, dynamic> trace) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Transaction: ${FormatterUtils.formatHash(trace['transactionHash'] ?? 'Unknown')}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Block Hash', trace['blockHash'] ?? 'Unknown'),
                _buildDetailRow(
                    'Block Number', trace['blockNumber'] ?? 'Unknown'),
                _buildDetailRow('Transaction Index',
                    trace['transactionPosition'] ?? 'Unknown'),
                const Divider(thickness: 2),
                const SizedBox(height: 8),
                const Text(
                  'Call Hierarchy',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTraceTree(trace),
              ],
            ),
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

  void _showAllTracesDialog(List<dynamic> traces) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'All Transactions in Block ${widget.traceParams['blockNumber']}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: traces.length,
            itemBuilder: (context, index) {
              final trace = traces[index];
              final txHash = trace['transactionHash'] ?? 'Unknown';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(FormatterUtils.formatHash(txHash)),
                  subtitle: Text(
                      'From: ${FormatterUtils.formatHash(trace['from'] ?? 'Unknown')} To: ${FormatterUtils.formatHash(trace['to'] ?? 'Unknown')}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    _showTraceDetailsDialog(trace);
                  },
                ),
              );
            },
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
}
