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

class TransactionTraceScreen extends StatefulWidget {
  final String txHash;
  final String? heroTag;

  const TransactionTraceScreen({
    super.key,
    required this.txHash,
    this.heroTag,
  });

  @override
  State<TransactionTraceScreen> createState() => _TransactionTraceScreenState();
}

class _TransactionTraceScreenState extends State<TransactionTraceScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _traceData = {};
  Map<String, dynamic> _analysisData = {};
  String _errorMessage = '';

  bool _isAiAnalysisLoading = false;
  Map<String, dynamic> _aiAnalysis = {};
  bool _showAiAnalysis = false;

  bool _isAnalyzing = false;
  Map<String, dynamic>? _mevAnalysisResult;

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

  Future<void> _getAiAnalysis() async {
    setState(() {
      _isAiAnalysisLoading = true;
      _showAiAnalysis = true;
    });

    try {
      final geminiProvider =
          Provider.of<GeminiProvider>(context, listen: false);
      final analysis = await geminiProvider.analyzeTransactionTraceStructured(
          _traceData,
          _analysisData['transaction'] ?? {},
          _analysisData['tokenDetails'] ?? {});

      if (!mounted) return;

      setState(() {
        _aiAnalysis = analysis;
        _isAiAnalysisLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiAnalysis = {
          "summary": "Error analyzing transaction",
          "error": true,
          "errorMessage": e.toString()
        };
        _isAiAnalysisLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return LoadingOverlay(
      isLoading: _isLoading,
      loadingText: 'Loading transaction trace data...',
      body: Scaffold(
        appBar: CustomAppBar(
          title: 'Transaction Trace',
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
        body: _errorMessage.isNotEmpty
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
                      TraceButton(
                        text: 'Retry',
                        onPressed: _loadTraceData,
                        backgroundColor: Colors.blue,
                        icon: Icons.refresh,
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
          // Transaction overview card
          _buildTransactionOverviewCard(),

          const SizedBox(height: 16),

          // Gas analysis card
          _buildGasAnalysisCard(),

          const SizedBox(height: 16),

          // MEV Analysis Card
          _buildMEVAnalysisCard(),

          const SizedBox(height: 16),

          // AI Analysis button
          _buildAiAnalysisCard(),

          const SizedBox(height: 16),

          // Trace visualization card
          _buildTraceVisualizationCard(),

          const SizedBox(height: 16),

          // Raw trace data card
          _buildRawTraceDataCard(),
        ],
      ),
    );
  }

  Widget _buildTransactionOverviewCard() {
    // Extract transaction data
    final txData = _analysisData['transaction'] ?? {};
    final txHash = txData['hash'] ?? widget.txHash;
    final from = txData['from'] ?? 'Unknown';
    final to = txData['to'] ?? 'Unknown';
    final blockNumber =
        FormatterUtils.parseHexSafely(txData['blockNumber']) ?? 0;

    // Extract token details
    final tokenDetails = _analysisData['tokenDetails'] ?? {};
    final tokenValue = tokenDetails['value'] ?? 0.0;
    final tokenRecipient = tokenDetails['recipient'] ?? to;

    // Extract gas analysis
    final gasAnalysis = _analysisData['gasAnalysis'] ?? {};
    final gasUsed = gasAnalysis['gasUsed'] ?? 0;
    final gasPrice = gasAnalysis['gasPrice'] ?? 0.0;
    final gasCostEth = gasAnalysis['gasCostEth'] ?? 0.0;
    final gasCostUsd = gasAnalysis['gasCostUsd'] ?? 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Transaction hash
            _buildInfoRow('Hash', txHash, true),
            const Divider(height: 12),

            // From address
            _buildInfoRow('From', from, true),
            const Divider(height: 12),

            // To address
            _buildInfoRow('To', to, true),
            const Divider(height: 12),

            // Block number
            _buildInfoRow('Block', blockNumber.toString(), false),
            const Divider(height: 12),

            // Token transfer details if available
            if (tokenValue > 0) ...[
              _buildInfoRow('Token Value',
                  '\$${tokenValue.toStringAsFixed(2)} PYUSD', false),
              const Divider(height: 12),
              _buildInfoRow('Token Recipient', tokenRecipient, true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGasAnalysisCard() {
    // Extract gas analysis
    final gasAnalysis = _analysisData['gasAnalysis'] ?? {};
    final gasUsed = gasAnalysis['gasUsed'] ?? 0;
    final gasPrice = gasAnalysis['gasPrice'] ?? 0.0;
    final gasCostEth = gasAnalysis['gasCostEth'] ?? 0.0;
    final gasCostUsd = gasAnalysis['gasCostUsd'] ?? 0.0;

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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Gas Used',
                    gasUsed.toString(),
                    Icons.local_gas_station,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Gas Price',
                    '${gasPrice.toStringAsFixed(2)} Gwei',
                    Icons.money,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Cost (ETH)',
                    '${gasCostEth.toStringAsFixed(6)} ETH',
                    Icons.currency_exchange_outlined,
                    Colors.indigo,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Cost (USD)',
                    '\$${gasCostUsd.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMEVAnalysisCard() {
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
                  child: const Icon(Icons.analytics,
                      color: Colors.orange, size: 28),
                ),
                const SizedBox(width: 12),
                const Text(
                  'MEV Analysis',
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
            _buildMEVAnalysisButtons(),
            if (_mevAnalysisResult != null) ...[
              const SizedBox(height: 16),
              _buildMEVAnalysisResult(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMEVAnalysisButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildMEVButton(
          'Frontrunning Analysis',
          Icons.speed,
          Colors.purple,
          () => _analyzeFrontrunning(),
        ),
        _buildMEVButton(
          'MEV Impact',
          Icons.trending_up,
          Colors.green,
          () => _analyzeMEVImpact(),
        ),
      ],
    );
  }

  Widget _buildMEVButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: _isAnalyzing ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
      ),
    );
  }

  Widget _buildMEVAnalysisResult() {
    final result = _mevAnalysisResult!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          result['type'] ?? 'Analysis Results',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (result['summary'] != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Text(
              result['summary'],
              style: TextStyle(
                color: textColor,
                height: 1.5,
              ),
            ),
          ),
        if (result['details'] != null) ...[
          const SizedBox(height: 16),
          ...List.generate(
            (result['details'] as List).length,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                result['details'][index],
                style: TextStyle(color: textColor),
              ),
            ),
          ),
        ],
        if (result['profit'] != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimated Profit:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${result['profit'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _analyzeFrontrunning() async {
    setState(() {
      _isAnalyzing = true;
      _mevAnalysisResult = null;
    });

    try {
      final provider = Provider.of<TraceProvider>(context, listen: false);
      final result = await provider.analyzeFrontrunning(widget.txHash);

      if (result['success']) {
        setState(() {
          _mevAnalysisResult = {
            'type': 'Frontrunning Analysis',
            'summary': 'Analysis of potential frontrunning activity',
            'details': result['frontrunners']
                .map((f) =>
                    'Transaction ${FormatterUtils.formatHash(f['transaction']['hash'])} with profit \$${f['profit'].toStringAsFixed(2)}')
                .toList(),
            'profit': result['frontrunners']
                .fold(0.0, (sum, f) => sum + (f['profit'] as double)),
          };
        });
      }
    } catch (e) {
      print('Error analyzing frontrunning: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _analyzeMEVImpact() async {
    setState(() {
      _isAnalyzing = true;
      _mevAnalysisResult = null;
    });

    try {
      final provider = Provider.of<TraceProvider>(context, listen: false);
      final blockNumber = FormatterUtils.parseHexSafely(
              _analysisData['transaction']['blockNumber']) ??
          0;

      // Get block data for context
      final blockData = await provider.getBlockWithTransactions(blockNumber);
      if (blockData['success']) {
        final block = blockData['block'];
        final transactions = block['transactions'] as List;
        final txIndex =
            transactions.indexWhere((tx) => tx['hash'] == widget.txHash);

        // Analyze MEV impact
        final impact = await _calculateMEVImpact(transactions, txIndex);
        setState(() {
          _mevAnalysisResult = {
            'type': 'MEV Impact Analysis',
            'summary': impact['summary'],
            'details': impact['details'],
            'profit': impact['profit'],
          };
        });
      }
    } catch (e) {
      print('Error analyzing MEV impact: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<Map<String, dynamic>> _calculateMEVImpact(
      List<dynamic> transactions, int txIndex) async {
    final details = <String>[];
    double totalProfit = 0.0;

    // Analyze transactions before and after the target transaction
    final beforeTx = txIndex > 0 ? transactions[txIndex - 1] : null;
    final afterTx =
        txIndex < transactions.length - 1 ? transactions[txIndex + 1] : null;

    if (beforeTx != null) {
      final gasPrice = int.parse(beforeTx['gasPrice'].toString()) / 1e9;
      details.add(
          'Previous transaction gas price: ${gasPrice.toStringAsFixed(2)} Gwei');
    }

    if (afterTx != null) {
      final gasPrice = int.parse(afterTx['gasPrice'].toString()) / 1e9;
      details.add(
          'Next transaction gas price: ${gasPrice.toStringAsFixed(2)} Gwei');
    }

    // Calculate potential MEV impact
    final currentGasPrice =
        int.parse(_analysisData['transaction']['gasPrice'].toString()) / 1e9;
    details.add(
        'Current transaction gas price: ${currentGasPrice.toStringAsFixed(2)} Gwei');

    // Simple MEV impact calculation (this could be more sophisticated)
    if (beforeTx != null && afterTx != null) {
      final avgGasPrice = (int.parse(beforeTx['gasPrice'].toString()) +
              int.parse(afterTx['gasPrice'].toString())) /
          2e9;
      final gasPriceDiff = currentGasPrice - avgGasPrice;
      totalProfit = gasPriceDiff *
          (int.parse(_analysisData['receipt']['gasUsed'].toString()) / 1e9) *
          2000;

      if (gasPriceDiff > 0) {
        details.add(
            'Transaction paid ${gasPriceDiff.toStringAsFixed(2)} Gwei more than average');
      }
    }

    return {
      'summary': 'Analysis of MEV impact on this transaction',
      'details': details,
      'profit': totalProfit.abs(),
    };
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
                  'AI Transaction Analysis',
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
                      'Get an AI-powered analysis of this transaction',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our AI will analyze the transaction trace and provide insights',
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
                      'Analyzing transaction...',
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
                      'Error analyzing transaction',
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
    final txType = _aiAnalysis['type'] ?? 'Unknown';
    final riskLevel = _aiAnalysis['riskLevel'] ?? 'Unknown';
    final riskFactors = _aiAnalysis['riskFactors'] ?? [];
    final gasAnalysis =
        _aiAnalysis['gasAnalysis'] ?? 'No gas analysis available';
    final contractInteractions = _aiAnalysis['contractInteractions'] ?? [];
    final technicalInsights =
        _aiAnalysis['technicalInsights'] ?? 'No technical insights available';
    final humanReadable =
        _aiAnalysis['humanReadable'] ?? 'No explanation available';

    // Determine risk color
    Color riskColor = Colors.grey;
    if (riskLevel == 'Low') {
      riskColor = Colors.green;
    } else if (riskLevel == 'Medium') {
      riskColor = Colors.orange;
    } else if (riskLevel == 'High') {
      riskColor = Colors.red;
    }

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
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      txType,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
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

        // Risk assessment
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: riskColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: riskColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.security, size: 18, color: riskColor),
                  const SizedBox(width: 8),
                  Text(
                    'Risk Assessment',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: riskColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      riskLevel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: riskColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (riskFactors.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...List.generate(
                  riskFactors.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 16,
                          color: riskColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            riskFactors[index],
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'No risk factors identified',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Expandable sections
        ExpansionTile(
          title: const Text('Technical Details'),
          leading: const Icon(Icons.code),
          childrenPadding: const EdgeInsets.all(16),
          children: [
            Text(
              technicalInsights,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: textColor,
              ),
            ),
          ],
        ),

        ExpansionTile(
          title: const Text('Gas Analysis'),
          leading: const Icon(Icons.local_gas_station),
          childrenPadding: const EdgeInsets.all(16),
          children: [
            Text(
              gasAnalysis,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: textColor,
              ),
            ),
          ],
        ),

        if (contractInteractions.isNotEmpty)
          ExpansionTile(
            title: const Text('Contract Interactions'),
            leading: const Icon(Icons.account_tree),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              ...List.generate(
                contractInteractions.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '• ${contractInteractions[index]}',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),

        const SizedBox(height: 16),

        // Human readable explanation
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Simplified Explanation',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                humanReadable,
                style: TextStyle(
                  fontSize: 14,
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
    // Extract trace data for visualization
    final traceData = _traceData['trace'];

    if (traceData == null || traceData is! List || traceData.isEmpty) {
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

            // Simple trace visualization
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: (traceData).length,
              itemBuilder: (context, index) {
                final trace = traceData[index];
                final action = trace['action'] ?? {};
                final callType = action['callType'] ?? 'call';
                final from = action['from'] ?? '';
                final to = action['to'] ?? '';
                final value = action['value'] ?? '0x0';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCallTypeColor(callType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _getCallTypeColor(callType).withOpacity(0.3)),
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
                              color: _getCallTypeColor(callType),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              callType.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatEthValue(value),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'From: ${FormatterUtils.formatAddress(from)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'To: ${FormatterUtils.formatAddress(to)}',
                        style: const TextStyle(fontSize: 14),
                      ),
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
                    TraceButton(
                      text: 'Copy JSON',
                      onPressed: () {
                        final jsonString =
                            FormatterUtils.formatJson(_traceData);
                        Clipboard.setData(ClipboardData(text: jsonString));
                        SnackbarUtil.showSnackbar(
                          context: context,
                          message: 'Raw trace data copied to clipboard',
                        );
                      },
                      icon: Icons.copy,
                      backgroundColor: Colors.blue,
                      horizontalPadding: 16,
                      verticalPadding: 8,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  height: 300,
                  child: SingleChildScrollView(
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
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool copyable) {
    return PyusdListTile(
      title: label,
      subtitle: value,
      trailing: copyable
          ? IconButton(
              icon: const Icon(Icons.copy, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                SnackbarUtil.showSnackbar(
                  context: context,
                  message: '$label copied to clipboard',
                );
              },
            )
          : null,
      contentPadding: EdgeInsets.zero,
      showDivider: false,
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
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
    return FormatterUtils.formatEthFromHex(hexValue);
  }
}
