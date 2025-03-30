import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../screens/networkcongestion/model/networkcongestion_model.dart';

class GeminiService {
  late final GenerativeModel _model;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null) {
        throw Exception('GEMINI_API_KEY not found in environment variables');
      }
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
      _isInitialized = true;
    }
  }

  String _formatNetworkData(Map<String, dynamic> networkData) {
    final congestionData =
        networkData['congestionData'] as NetworkCongestionData;

    return '''
Network Status:
• Network: ${networkData['networkName'] ?? 'Polygon Mainnet'}
• Version: ${congestionData.networkVersion}
• Peers: ${congestionData.peerCount}
• Network Status: ${congestionData.isNetworkListening ? 'Active' : 'Inactive'}

Gas Metrics:
• Current Gas Price: ${congestionData.currentGasPrice.toStringAsFixed(2)} Gwei
• Average Gas Price: ${congestionData.averageGasPrice.toStringAsFixed(2)} Gwei
• Network Gas Usage: ${congestionData.gasUsagePercentage.toStringAsFixed(2)}%
• Gas Limit: ${congestionData.gasLimit}
• Historical Gas Prices (last 20): ${congestionData.historicalGasPrices.map((p) => p.toStringAsFixed(2)).join(', ')}

Block Information:
• Latest Block: ${congestionData.lastBlockNumber}
• Block Time: ${congestionData.blockTime.toStringAsFixed(2)} seconds
• Average Block Time: ${congestionData.averageBlockTime.toStringAsFixed(2)} seconds
• Blocks per Hour: ${congestionData.blocksPerHour}
• Average Block Size: ${congestionData.averageBlockSize.toStringAsFixed(2)}
• Average Transactions per Block: ${congestionData.averageTxPerBlock}

PYUSD Activity:
• Total Transactions: ${congestionData.pyusdTransactionCount}
• Confirmed Transactions: ${congestionData.confirmedPyusdTxCount}
• Pending Transactions: ${congestionData.pendingPyusdTxCount}
• Average Confirmation Time: ${congestionData.averagePyusdConfirmationTime.toStringAsFixed(2)} minutes
• Average Transaction Fee: ${congestionData.averagePyusdTransactionFee.toStringAsFixed(2)} MATIC
• PYUSD Gas Usage %: ${congestionData.pyusdGasUsagePercentage.toStringAsFixed(2)}%

Network Health:
• Network Latency: ${congestionData.networkLatency.toStringAsFixed(2)}ms
• Pending Queue Size: ${congestionData.pendingQueueSize}
• PYUSD Pending Queue: ${congestionData.pyusdPendingQueueSize}
• Bad Blocks: ${congestionData.badBlocks.length}
• Last Updated: ${congestionData.lastRefreshed}

Transaction Pool:
• Total Pending: ${congestionData.pendingTransactions}
• PYUSD Pending: ${congestionData.pendingPyusdTxCount}
• Average Transaction Fee: ${congestionData.averagePyusdTransactionFee.toStringAsFixed(2)} MATIC
''';
  }

  Future<String> getPYUSDInsights({
    required Map<String, dynamic> networkData,
    String? userQuery,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final formattedData = _formatNetworkData(networkData);

    final prompt = '''
You are an expert on PYUSD (PayPal USD) and the Polygon blockchain network. Analyze the following network data and provide detailed insights.

Network Data:
$formattedData

${userQuery != null ? 'User Query: $userQuery' : ''}

Please provide a comprehensive analysis that includes:

1. Network Health Assessment:
   - Current network status and performance
   - Block production efficiency
   - Network congestion levels
   - Gas price trends and analysis

2. PYUSD Activity Analysis:
   - Transaction volume and patterns
   - Gas usage efficiency
   - Transaction confirmation times
   - Cost analysis

3. Technical Insights:
   - Block production metrics
   - Network latency impact
   - Transaction pool analysis
   - Historical trends

4. Recommendations:
   - Optimal transaction timing
   - Gas price optimization
   - Network usage patterns
   - Risk assessment

Keep your response clear, data-driven, and actionable. Focus on providing valuable insights based on the actual network data provided.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'No insights generated';
    } catch (e) {
      throw Exception('Failed to generate PYUSD insights: $e');
    }
  }

  Future<String> chatAboutPYUSD({
    required String message,
    required Map<String, dynamic> networkData,
    String? conversationHistory,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final formattedData = _formatNetworkData(networkData);

    final prompt = '''
You are an expert on PYUSD (PayPal USD) and the Polygon blockchain network. Respond to the user's question using the current network data.

Current Network Data:
$formattedData

${conversationHistory != null ? 'Previous Conversation:\n$conversationHistory' : ''}

User Question: $message

Please provide a response that:

1. Directly addresses the user's question
2. Uses current network data to support your answer
3. Explains technical concepts clearly
4. Provides actionable insights
5. Includes relevant metrics and trends
6. Offers practical recommendations

Topics you can cover:
- PYUSD market dynamics
- Network performance and health
- Transaction patterns and costs
- Gas price analysis
- Network congestion
- Technical metrics
- Security considerations
- Integration challenges
- Future developments

Keep your response concise but comprehensive, focusing on the specific aspects the user asked about. Always reference the actual network data when making statements or predictions.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'No response generated';
    } catch (e) {
      throw Exception('Failed to generate chat response: $e');
    }
  }
}
