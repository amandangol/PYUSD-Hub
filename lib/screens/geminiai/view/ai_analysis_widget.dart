import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AiAnalysisWidget extends StatelessWidget {
  final Map<String, dynamic> aiAnalysis;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onAnalyze;
  final bool showAiAnalysis;

  const AiAnalysisWidget({
    super.key,
    required this.aiAnalysis,
    required this.isLoading,
    required this.onRefresh,
    required this.onAnalyze,
    required this.showAiAnalysis,
  });

  @override
  Widget build(BuildContext context) {
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
            _buildHeader(accentColor, showAiAnalysis, onRefresh, isLoading),
            const Divider(height: 24),
            if (!showAiAnalysis)
              _buildInitialState(textColor, onAnalyze)
            else if (isLoading)
              _buildLoadingState(textColor)
            else if (aiAnalysis.containsKey('error') &&
                aiAnalysis['error'] == true)
              _buildErrorState(textColor, aiAnalysis, onAnalyze)
            else
              _buildAnalysisContent(context, aiAnalysis, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color accentColor, bool showAnalysis,
      VoidCallback onRefresh, bool isLoading) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.psychology, color: Colors.blue, size: 24),
        ),
        const SizedBox(width: 12),
        const Text(
          'AI Analysis',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (showAnalysis)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : onRefresh,
            tooltip: 'Refresh Analysis',
          ),
      ],
    );
  }

  Widget _buildInitialState(Color textColor, VoidCallback onAnalyze) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Image.asset('assets/images/geminilogo.png', height: 48, width: 48),
          const SizedBox(height: 16),
          const Text(
            'Get an AI-powered analysis',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Our AI will analyze the data and provide insights',
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAnalyze,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Analyze with AI'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.withOpacity(0.8),
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLoadingState(Color textColor) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text('Analyzing...', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          const CircularProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            'This may take a few moments',
            style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildErrorState(
      Color textColor, Map<String, dynamic> analysis, VoidCallback onRetry) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error analyzing data',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            analysis['errorMessage'] ?? 'Unknown error occurred',
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor.withOpacity(0.7)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAnalysisContent(
      BuildContext context, Map<String, dynamic> analysis, Color textColor) {
    // Extract data from analysis
    final summary = analysis['summary'] ?? 'No summary available';
    final txType = analysis['type'] ?? 'Analysis';
    final riskLevel = analysis['riskLevel'] ?? 'Unknown';
    final riskFactors = analysis['riskFactors'] as List? ?? [];
    final gasAnalysis = analysis['gasAnalysis'] ?? 'No gas analysis available';
    final contractInteractions =
        analysis['contractInteractions'] as List? ?? [];
    final technicalInsights =
        analysis['technicalInsights'] ?? 'No technical insights available';
    final humanReadable =
        analysis['humanReadable'] ?? 'No explanation available';

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
        _buildSummarySection(summary, txType, textColor),
        const SizedBox(height: 16),

        // Risk Assessment section
        _buildRiskSection(riskLevel, riskFactors, riskColor, textColor),
        const SizedBox(height: 16),

        // Expandable sections
        _buildExpandableSection(
          'Technical Details',
          technicalInsights,
          Icons.code,
          textColor,
        ),
        _buildExpandableSection(
          'Gas Analysis',
          gasAnalysis,
          Icons.local_gas_station,
          textColor,
        ),
        if (contractInteractions.isNotEmpty)
          _buildContractInteractionsSection(contractInteractions, textColor),

        const SizedBox(height: 16),

        // Human readable explanation
        _buildSimplifiedExplanation(humanReadable, textColor),
        const SizedBox(height: 16),

        _buildGeminiFooter(textColor),
      ],
    );
  }

  Widget _buildSummarySection(String summary, String txType, Color textColor) {
    return Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  txType,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MarkdownBody(
            data: summary,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(fontSize: 15, height: 1.5, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskSection(
      String riskLevel, List riskFactors, Color riskColor, Color textColor) {
    return Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            ...riskFactors.map((factor) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber, size: 16, color: riskColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          factor.toString(),
                          style: TextStyle(fontSize: 14, color: textColor),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandableSection(
      String title, String content, IconData icon, Color textColor) {
    return ExpansionTile(
      title: Text(title),
      leading: Icon(icon),
      childrenPadding: const EdgeInsets.all(16),
      children: [
        MarkdownBody(
          data: content,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(fontSize: 15, height: 1.5, color: textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildContractInteractionsSection(
      List contractInteractions, Color textColor) {
    return ExpansionTile(
      title: const Text('Contract Interactions'),
      leading: const Icon(Icons.account_tree),
      childrenPadding: const EdgeInsets.all(16),
      children: [
        ...contractInteractions.map((interaction) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '• $interaction',
                style: TextStyle(fontSize: 14, height: 1.5, color: textColor),
              ),
            )),
      ],
    );
  }

  Widget _buildSimplifiedExplanation(String explanation, Color textColor) {
    return Container(
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
          MarkdownBody(
            data: explanation,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(fontSize: 15, height: 1.5, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeminiFooter(Color textColor) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/geminilogo.png', height: 16, width: 16),
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
    );
  }
}
