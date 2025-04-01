import 'package:flutter/material.dart';
import '../screens/networkcongestion/model/networkcongestion_model.dart';
import '../services/gemini_service.dart';

class GeminiProvider with ChangeNotifier {
  final GeminiService _service = GeminiService();
  bool _isLoading = false;
  String? _lastError;
  String? _lastResponse;
  String? _conversationHistory;
  final List<Map<String, String>> _chatMessages = [];
  bool _isGeneratingInsights = false;
  String? _aiInsights;

  // Network information
  static const String _networkName = 'Ethereum Mainnet';
  static const String _networkSymbol = 'ETH';
  static const String _networkType = 'Layer 1';
  static const String _networkDescription =
      'Ethereum Mainnet is the primary blockchain network for PYUSD, providing the highest level of security and decentralization.';

  // Built-in messages for quick access
  final List<Map<String, String>> _builtInMessages = [
    {
      'role': 'assistant',
      'content':
          'Hi! I\'m your PYUSD assistant on $_networkName. I can help you with:\n\n'
              '1. Network Status & Gas Analysis\n'
              '2. Transaction History & Patterns\n'
              '3. Market Insights & Trends\n'
              '4. Technical Network Metrics\n'
              '5. PYUSD-Specific Analysis\n'
              '6. General Blockchain Questions\n\n'
              'What would you like to know?'
    },
    {
      'role': 'assistant',
      'content': 'Here are some quick commands you can use:\n\n'
          '• "gas" - Get detailed gas price analysis\n'
          '• "network" - Check network health and status\n'
          '• "transactions" - View PYUSD transaction patterns\n'
          '• "market" - Get market activity insights\n'
          '• "technical" - View technical network metrics\n'
          '• "about" - Learn about PYUSD and $_networkName\n'
          '• "help" - Show this help message'
    },
  ];

  bool get isLoading => _isLoading;
  bool get isGeneratingInsights => _isGeneratingInsights;
  String? get lastError => _lastError;
  String? get lastResponse => _lastResponse;
  String? get conversationHistory => _conversationHistory;
  List<Map<String, String>> get chatMessages => _chatMessages;
  String? get aiInsights => _aiInsights;
  List<Map<String, String>> get builtInMessages => _builtInMessages;

  Future<void> initialize() async {
    try {
      await _service.initialize();
      _lastError = null;
      // Add initial welcome message
      if (_chatMessages.isEmpty) {
        _chatMessages.addAll(_builtInMessages);
      }
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> generatePYUSDInsights({
    required Map<String, dynamic> networkData,
    String? userQuery,
  }) async {
    _isGeneratingInsights = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await _service.getPYUSDInsights(
        networkData: networkData,
        userQuery: userQuery,
      );
      _aiInsights = response;
      _lastError = null;
    } catch (e) {
      _lastError = e.toString();
      _aiInsights = null;
    } finally {
      _isGeneratingInsights = false;
      notifyListeners();
    }
  }

  Future<void> sendChatMessage({
    required String message,
    required Map<String, dynamic> networkData,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // Add user message to chat history
      _chatMessages.add({
        'role': 'user',
        'content': message,
      });

      // Handle built-in commands
      final lowerMessage = message.toLowerCase();
      if (lowerMessage == 'help') {
        _chatMessages.add(_builtInMessages[1]);
      } else if (lowerMessage == 'gas') {
        await _handleGasCommand(networkData);
      } else if (lowerMessage == 'network') {
        await _handleNetworkCommand(networkData);
      } else if (lowerMessage == 'transactions') {
        await _handleTransactionsCommand(networkData);
      } else if (lowerMessage == 'market') {
        await _handleMarketCommand(networkData);
      } else if (lowerMessage == 'technical') {
        await _handleTechnicalCommand(networkData);
      } else if (lowerMessage == 'about') {
        await _handleAboutCommand();
      } else {
        // Update conversation history
        _conversationHistory = _chatMessages
            .map((msg) => '${msg['role']}: ${msg['content']}')
            .join('\n');

        final response = await _service.chatAboutPYUSD(
          message: message,
          networkData: networkData,
          conversationHistory: _conversationHistory,
        );

        // Add AI response to chat history
        _chatMessages.add({
          'role': 'assistant',
          'content': response,
        });

        _lastResponse = response;
        _lastError = null;
      }
    } catch (e) {
      _lastError = e.toString();
      _lastResponse = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _handleGasCommand(Map<String, dynamic> networkData) async {
    final congestionData =
        networkData['congestionData'] as NetworkCongestionData;
    final currentGasPrice = congestionData.currentGasPrice;
    final averageGasPrice = congestionData.averageGasPrice;
    final gasUsagePercentage = congestionData.gasUsagePercentage;
    final historicalPrices = congestionData.historicalGasPrices;

    final response = '''
Network: $_networkName
Current Gas Analysis:

1. Current Metrics:
   • Gas Price: ${currentGasPrice.toStringAsFixed(2)} Gwei
   • Average Price: ${averageGasPrice.toStringAsFixed(2)} Gwei
   • Network Usage: ${gasUsagePercentage.toStringAsFixed(2)}%
   • Gas Limit: ${congestionData.gasLimit}

2. Historical Trends:
   • Last 20 Prices: ${historicalPrices.map((p) => p.toStringAsFixed(2)).join(', ')}
   • Price Change: ${((currentGasPrice - averageGasPrice) / averageGasPrice * 100).toStringAsFixed(2)}%
   • Volatility: ${_calculateVolatility(historicalPrices).toStringAsFixed(2)}%

3. Analysis:
   ${_getDetailedGasAnalysis(currentGasPrice, averageGasPrice, gasUsagePercentage, historicalPrices)}

4. Recommendations:
   ${_getGasRecommendations(currentGasPrice, averageGasPrice, gasUsagePercentage)}

Note: Gas prices on $_networkName are typically higher than Layer 2 solutions due to network demand.
''';

    _chatMessages.add({
      'role': 'assistant',
      'content': response,
    });
  }

  Future<void> _handleNetworkCommand(Map<String, dynamic> networkData) async {
    final congestionData =
        networkData['congestionData'] as NetworkCongestionData;
    final pendingTransactions = congestionData.pendingTransactions;
    final blockTime = congestionData.blockTime;
    final networkLatency = congestionData.networkLatency;
    final peerCount = congestionData.peerCount;

    final response = '''
Network: $_networkName
Health Status Report:

1. Network Status:
   • Active: ${congestionData.isNetworkListening ? 'Yes' : 'No'}
   • Version: ${congestionData.networkVersion}
   • Peers: $peerCount
   • Bad Blocks: ${congestionData.badBlocks.length}

2. Performance Metrics:
   • Block Time: ${blockTime.toStringAsFixed(2)} seconds
   • Network Latency: ${networkLatency.toStringAsFixed(2)}ms
   • Pending Transactions: $pendingTransactions
   • Congestion Level: ${_getCongestionLevel(pendingTransactions)}

3. Block Production:
   • Latest Block: ${congestionData.lastBlockNumber}
   • Blocks/Hour: ${congestionData.blocksPerHour}
   • Average Block Size: ${congestionData.averageBlockSize.toStringAsFixed(2)}
   • Transactions/Block: ${congestionData.averageTxPerBlock}

4. Analysis:
   ${_getDetailedNetworkAnalysis(pendingTransactions, blockTime, networkLatency, peerCount)}

$_networkDescription
''';

    _chatMessages.add({
      'role': 'assistant',
      'content': response,
    });
  }

  Future<void> _handleTransactionsCommand(
      Map<String, dynamic> networkData) async {
    final congestionData =
        networkData['congestionData'] as NetworkCongestionData;
    final pyusdTxCount = congestionData.pyusdTransactionCount;
    final confirmedTxCount = congestionData.confirmedPyusdTxCount;
    final pendingTxCount = congestionData.pendingPyusdTxCount;
    final avgConfirmationTime = congestionData.averagePyusdConfirmationTime;
    final avgFee = congestionData.averagePyusdTransactionFee;

    final response = '''
Network: $_networkName
PYUSD Transaction Analysis:

1. Transaction Volume:
   • Total Transactions: $pyusdTxCount
   • Confirmed: $confirmedTxCount
   • Pending: $pendingTxCount
   • Success Rate: ${((confirmedTxCount / pyusdTxCount) * 100).toStringAsFixed(2)}%

2. Performance Metrics:
   • Average Confirmation: ${avgConfirmationTime.toStringAsFixed(2)} minutes
   • Average Fee: ${avgFee.toStringAsFixed(2)} $_networkSymbol
   • Gas Usage %: ${congestionData.pyusdGasUsagePercentage.toStringAsFixed(2)}%

3. Queue Status:
   • Pending Queue: ${congestionData.pyusdPendingQueueSize}
   • Queue Time: ${_estimateQueueTime(pendingTxCount).toStringAsFixed(2)} minutes

4. Analysis:
   ${_getDetailedTransactionAnalysis(pyusdTxCount, confirmedTxCount, pendingTxCount, avgConfirmationTime)}

Note: Transactions on $_networkName may take longer to confirm and have higher fees compared to Layer 2 solutions.
''';

    _chatMessages.add({
      'role': 'assistant',
      'content': response,
    });
  }

  Future<void> _handleMarketCommand(Map<String, dynamic> networkData) async {
    final congestionData =
        networkData['congestionData'] as NetworkCongestionData;
    final blocksPerHour = congestionData.blocksPerHour;
    final averageTxPerBlock = congestionData.averageTxPerBlock;
    final gasLimit = congestionData.gasLimit;
    final currentGasPrice = congestionData.currentGasPrice;

    final response = '''
Network: $_networkName
Market Activity Report:

1. Block Production:
   • Blocks/Hour: $blocksPerHour
   • Transactions/Block: $averageTxPerBlock
   • Gas Limit: $gasLimit
   • Network Usage: ${congestionData.gasUsagePercentage.toStringAsFixed(2)}%

2. Gas Economics:
   • Current Price: ${currentGasPrice.toStringAsFixed(2)} Gwei
   • Average Price: ${congestionData.averageGasPrice.toStringAsFixed(2)} Gwei
   • Price Trend: ${_getGasPriceTrend(currentGasPrice, congestionData.averageGasPrice)}
   • Market Activity: ${_getMarketActivityLevel(blocksPerHour, averageTxPerBlock)}

3. PYUSD Activity:
   • Transaction Volume: ${congestionData.pyusdTransactionCount}
   • Average Fee: ${congestionData.averagePyusdTransactionFee.toStringAsFixed(2)} $_networkSymbol
   • Gas Usage: ${congestionData.pyusdGasUsagePercentage.toStringAsFixed(2)}%

4. Analysis:
   ${_getDetailedMarketAnalysis(blocksPerHour, averageTxPerBlock, gasLimit)}

Note: Market activity on $_networkName directly impacts gas prices and transaction costs.
''';

    _chatMessages.add({
      'role': 'assistant',
      'content': response,
    });
  }

  Future<void> _handleTechnicalCommand(Map<String, dynamic> networkData) async {
    final congestionData =
        networkData['congestionData'] as NetworkCongestionData;

    final response = '''
Network: $_networkName
Technical Metrics Report:

1. Network Infrastructure:
   • Version: ${congestionData.networkVersion}
   • Peer Count: ${congestionData.peerCount}
   • Network Status: ${congestionData.isNetworkListening ? 'Active' : 'Inactive'}
   • Bad Blocks: ${congestionData.badBlocks.length}

2. Block Production:
   • Latest Block: ${congestionData.lastBlockNumber}
   • Block Time: ${congestionData.blockTime.toStringAsFixed(2)} seconds
   • Average Block Time: ${congestionData.averageBlockTime.toStringAsFixed(2)} seconds
   • Blocks/Hour: ${congestionData.blocksPerHour}
   • Blocks/Minute: ${congestionData.blocksPerMinute.toStringAsFixed(2)}

3. Transaction Processing:
   • Gas Limit: ${congestionData.gasLimit}
   • Network Usage: ${congestionData.gasUsagePercentage.toStringAsFixed(2)}%
   • Average Block Size: ${congestionData.averageBlockSize.toStringAsFixed(2)}
   • Transactions/Block: ${congestionData.averageTxPerBlock}

4. Network Health:
   • Latency: ${congestionData.networkLatency.toStringAsFixed(2)}ms
   • Pending Queue: ${congestionData.pendingQueueSize}
   • Last Updated: ${congestionData.lastRefreshed}
   • Data Freshness: ${_getDataFreshness(congestionData.lastRefreshed)}

5. Analysis:
   ${_getTechnicalAnalysis(congestionData)}

Note: These metrics are based on real-time network data and historical trends.
''';

    _chatMessages.add({
      'role': 'assistant',
      'content': response,
    });
  }

  Future<void> _handleAboutCommand() async {
    const response = '''
About PYUSD on $_networkName:

1. Network Overview:
   • Type: $_networkType
   • Native Token: $_networkSymbol
   • Description: $_networkDescription

2. Key Features:
   • High Security: Primary blockchain network for PYUSD
   • Decentralized: Operates on Ethereum's main network
   • Global Access: Available to all Ethereum users
   • Maximum Security: Benefits from Ethereum's security model

3. Benefits:
   • Highest level of security and decentralization
   • Direct integration with Ethereum ecosystem
   • Access to all Ethereum DeFi protocols
   • Strong network reliability

4. Technical Details:
   • Layer 1 Solution: Native Ethereum network
   • Consensus: Proof of Stake (PoS)
   • Block Time: ~12 seconds
   • Gas Token: $_networkSymbol

Would you like to know more about any specific aspect of PYUSD or $_networkName?
''';

    _chatMessages.add({
      'role': 'assistant',
      'content': response,
    });
  }

  String _getDetailedGasAnalysis(
    double current,
    double average,
    double usage,
    List<double> historical,
  ) {
    final priceChange =
        ((current - average) / average * 100).toStringAsFixed(2);
    final volatility = _calculateVolatility(historical).toStringAsFixed(2);

    String analysis =
        'Current gas price is $priceChange% compared to average.\n';
    analysis += 'Price volatility is $volatility%.\n';

    if (current < average * 0.8) {
      analysis += 'Gas prices are currently low, good time for transactions.';
    } else if (current > average * 1.2) {
      analysis += 'Gas prices are high, consider waiting for lower prices.';
    } else if (usage > 80) {
      analysis +=
          'Network is congested, consider waiting for lower gas prices.';
    } else {
      analysis += 'Gas prices are at normal levels.';
    }

    return analysis;
  }

  String _getGasRecommendations(
    double current,
    double average,
    double usage,
  ) {
    final recommendations = <String>[];

    if (current < average * 0.8) {
      recommendations.add('• Good time to send transactions');
    } else if (current > average * 1.2) {
      recommendations.add('• Consider waiting for lower prices');
    }

    if (usage > 80) {
      recommendations.add('• Network is congested, wait if possible');
    }

    if (recommendations.isEmpty) {
      recommendations.add('• Current conditions are optimal for transactions');
    }

    return recommendations.join('\n');
  }

  String _getDetailedNetworkAnalysis(
    int pending,
    double blockTime,
    double latency,
    int peers,
  ) {
    final analysis = <String>[];

    if (pending > 10000) {
      analysis.add('• Network is highly congested');
    } else if (blockTime > 15) {
      analysis.add('• Block times are slower than usual');
    } else if (latency > 1000) {
      analysis.add('• Network latency is high');
    } else {
      analysis.add('• Network is operating normally');
    }

    if (peers < 10) {
      analysis.add('• Low peer count may affect network reliability');
    }

    return analysis.join('\n');
  }

  String _getDetailedTransactionAnalysis(
    int total,
    int confirmed,
    int pending,
    double confirmationTime,
  ) {
    final analysis = <String>[];

    if (pending > confirmed * 0.5) {
      analysis.add('• High number of pending transactions');
    } else if (total > 1000) {
      analysis.add('• High transaction volume');
    }

    if (confirmationTime > 5) {
      analysis.add('• Transaction confirmations are taking longer than usual');
    }

    return analysis.join('\n');
  }

  String _getDetailedMarketAnalysis(
    int blocksPerHour,
    int txPerBlock,
    int gasLimit,
  ) {
    final analysis = <String>[];

    if (blocksPerHour < 240) {
      analysis.add('• Block production is slower than usual');
    } else if (txPerBlock > 150) {
      analysis.add('• High transaction volume per block');
    }

    return analysis.join('\n');
  }

  String _getTechnicalAnalysis(NetworkCongestionData data) {
    final analysis = <String>[];

    if (data.blockTime > 3) {
      analysis.add('• Block production is slower than optimal');
    }

    if (data.networkLatency > 500) {
      analysis.add('• Network latency is affecting performance');
    }

    if (data.pendingQueueSize > 5000) {
      analysis.add('• Transaction queue is building up');
    }

    return analysis.join('\n');
  }

  String _getCongestionLevel(int pending) {
    if (pending > 10000) return 'High';
    if (pending > 5000) return 'Medium';
    return 'Low';
  }

  String _getGasPriceTrend(double current, double average) {
    if (current < average * 0.8) return 'Decreasing';
    if (current > average * 1.2) return 'Increasing';
    return 'Stable';
  }

  String _getMarketActivityLevel(int blocksPerHour, int txPerBlock) {
    if (blocksPerHour < 240) return 'Low';
    if (txPerBlock > 150) return 'High';
    return 'Normal';
  }

  String _getDataFreshness(DateTime lastRefreshed) {
    final difference = DateTime.now().difference(lastRefreshed);
    if (difference.inSeconds < 30) return 'Very Fresh';
    if (difference.inMinutes < 1) return 'Fresh';
    if (difference.inMinutes < 5) return 'Recent';
    return 'Stale';
  }

  double _calculateVolatility(List<double> prices) {
    if (prices.length < 2) return 0;

    double sum = 0;
    for (int i = 1; i < prices.length; i++) {
      sum += ((prices[i] - prices[i - 1]) / prices[i - 1]).abs();
    }
    return (sum / (prices.length - 1)) * 100;
  }

  double _estimateQueueTime(int pendingCount) {
    // Rough estimation based on network conditions
    return (pendingCount / 100) * 2; // 2 minutes per 100 transactions
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  void clearChat() {
    _chatMessages.clear();
    // Add back the welcome message after clearing
    _chatMessages.addAll(_builtInMessages);
    _conversationHistory = null;
    _lastResponse = null;
    notifyListeners();
  }

  void clearInsights() {
    _aiInsights = null;
    notifyListeners();
  }
}
