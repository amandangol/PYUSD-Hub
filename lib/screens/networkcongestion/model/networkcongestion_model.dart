class GasPricePoint {
  final double price;
  final int timestamp;

  GasPricePoint({
    required this.price,
    required this.timestamp,
  });
}

class NetworkCongestionData {
  // General Network Metrics
  final double currentGasPrice;
  final double averageGasPrice;
  final int pendingTransactions;
  final double gasUsagePercentage;
  final List<double> historicalGasPrices;
  final double networkLatency;
  final double blockTime;
  final int lastBlockNumber;
  final int lastBlockTimestamp;
  final int pendingQueueSize;
  final double averageBlockSize;
  final DateTime lastRefreshed;
  final double averageBlockTime;
  final int blocksPerHour;
  final int averageTxPerBlock;
  final int gasLimit;

  // PYUSD-Specific Metrics
  final int pyusdTransactionCount;
  final int confirmedPyusdTxCount;
  final int pendingPyusdTxCount;
  final int pyusdPendingQueueSize;
  final double averagePyusdBlockSize;
  final double pyusdGasUsagePercentage;
  final double averagePyusdTransactionFee;
  final double averagePyusdConfirmationTime;
  final List<double> pyusdHistoricalGasPrices;

  final List<GasPricePoint> gasPriceHistory;
  final double currentGasPriceUSD;

  // New network-related fields
  final String networkVersion;
  final int peerCount;
  final bool isNetworkListening;
  final List<Map<String, dynamic>> badBlocks;
  final Map<String, dynamic> txPoolInspection;

  NetworkCongestionData({
    // General Network Metrics
    this.currentGasPrice = 0,
    this.averageGasPrice = 0,
    this.pendingTransactions = 0,
    this.gasUsagePercentage = 0,
    this.historicalGasPrices = const [],
    this.networkLatency = 0,
    this.blockTime = 0,
    this.lastBlockNumber = 0,
    this.lastBlockTimestamp = 0,
    this.pendingQueueSize = 0,
    this.averageBlockSize = 0,
    required this.lastRefreshed,
    this.averageBlockTime = 0,
    this.blocksPerHour = 0,
    this.averageTxPerBlock = 0,
    this.gasLimit = 0,

    // PYUSD-Specific Metrics
    this.pyusdTransactionCount = 0,
    this.confirmedPyusdTxCount = 0,
    this.pendingPyusdTxCount = 0,
    this.pyusdPendingQueueSize = 0,
    this.averagePyusdBlockSize = 0,
    this.pyusdGasUsagePercentage = 0,
    this.averagePyusdTransactionFee = 0,
    this.averagePyusdConfirmationTime = 0,
    this.pyusdHistoricalGasPrices = const [],
    this.gasPriceHistory = const [],
    this.currentGasPriceUSD = 0.0,

    // New network-related fields
    this.networkVersion = '',
    this.peerCount = 0,
    this.isNetworkListening = false,
    this.badBlocks = const [],
    this.txPoolInspection = const {},
  });

  NetworkCongestionData copyWith({
    double? currentGasPrice,
    double? averageGasPrice,
    int? pendingTransactions,
    double? gasUsagePercentage,
    List<double>? historicalGasPrices,
    double? networkLatency,
    double? blockTime,
    int? lastBlockNumber,
    int? lastBlockTimestamp,
    int? pendingQueueSize,
    double? averageBlockSize,
    DateTime? lastRefreshed,
    double? averageBlockTime,
    int? blocksPerHour,
    int? averageTxPerBlock,
    int? gasLimit,
    int? pyusdTransactionCount,
    int? confirmedPyusdTxCount,
    int? pendingPyusdTxCount,
    int? pyusdPendingQueueSize,
    double? averagePyusdBlockSize,
    double? pyusdGasUsagePercentage,
    double? averagePyusdTransactionFee,
    double? averagePyusdConfirmationTime,
    List<double>? pyusdHistoricalGasPrices,
    List<GasPricePoint>? gasPriceHistory,
    double? currentGasPriceUSD,
    String? networkVersion,
    int? peerCount,
    bool? isNetworkListening,
    List<Map<String, dynamic>>? badBlocks,
    Map<String, dynamic>? txPoolInspection,
  }) {
    return NetworkCongestionData(
      currentGasPrice: currentGasPrice ?? this.currentGasPrice,
      averageGasPrice: averageGasPrice ?? this.averageGasPrice,
      pendingTransactions: pendingTransactions ?? this.pendingTransactions,
      gasUsagePercentage: gasUsagePercentage ?? this.gasUsagePercentage,
      historicalGasPrices: historicalGasPrices ?? this.historicalGasPrices,
      networkLatency: networkLatency ?? this.networkLatency,
      blockTime: blockTime ?? this.blockTime,
      lastBlockNumber: lastBlockNumber ?? this.lastBlockNumber,
      lastBlockTimestamp: lastBlockTimestamp ?? this.lastBlockTimestamp,
      pendingQueueSize: pendingQueueSize ?? this.pendingQueueSize,
      averageBlockSize: averageBlockSize ?? this.averageBlockSize,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
      averageBlockTime: averageBlockTime ?? this.averageBlockTime,
      blocksPerHour: blocksPerHour ?? this.blocksPerHour,
      averageTxPerBlock: averageTxPerBlock ?? this.averageTxPerBlock,
      gasLimit: gasLimit ?? this.gasLimit,
      pyusdTransactionCount:
          pyusdTransactionCount ?? this.pyusdTransactionCount,
      confirmedPyusdTxCount:
          confirmedPyusdTxCount ?? this.confirmedPyusdTxCount,
      pendingPyusdTxCount: pendingPyusdTxCount ?? this.pendingPyusdTxCount,
      pyusdPendingQueueSize:
          pyusdPendingQueueSize ?? this.pyusdPendingQueueSize,
      averagePyusdBlockSize:
          averagePyusdBlockSize ?? this.averagePyusdBlockSize,
      pyusdGasUsagePercentage:
          pyusdGasUsagePercentage ?? this.pyusdGasUsagePercentage,
      averagePyusdTransactionFee:
          averagePyusdTransactionFee ?? this.averagePyusdTransactionFee,
      averagePyusdConfirmationTime:
          averagePyusdConfirmationTime ?? this.averagePyusdConfirmationTime,
      pyusdHistoricalGasPrices:
          pyusdHistoricalGasPrices ?? this.pyusdHistoricalGasPrices,
      gasPriceHistory: gasPriceHistory ?? this.gasPriceHistory,
      currentGasPriceUSD: currentGasPriceUSD ?? this.currentGasPriceUSD,
      networkVersion: networkVersion ?? this.networkVersion,
      peerCount: peerCount ?? this.peerCount,
      isNetworkListening: isNetworkListening ?? this.isNetworkListening,
      badBlocks: badBlocks ?? this.badBlocks,
      txPoolInspection: txPoolInspection ?? this.txPoolInspection,
    );
  }

  // Calculate network congestion level (0-100)
  int get congestionLevel {
    // Factors to consider:
    // 1. Gas price relative to average
    double gasFactor = currentGasPrice > averageGasPrice
        ? (currentGasPrice / averageGasPrice) * 20
        : 10;
    if (gasFactor > 40) gasFactor = 40;

    // 2. Block utilization
    double utilizationFactor = gasUsagePercentage * 0.3;
    if (utilizationFactor > 30) utilizationFactor = 30;

    // 3. Pending transactions
    double pendingFactor =
        (pendingTransactions > 5000) ? 20 : (pendingTransactions / 5000) * 20;

    // 4. Network latency
    double latencyFactor =
        (networkLatency > 1000) ? 10 : (networkLatency / 1000) * 10;

    // 5. Consider pending queue size
    double queueFactor =
        (pendingQueueSize > 2000) ? 10 : (pendingQueueSize / 2000) * 10;

    int total = (gasFactor +
            utilizationFactor +
            pendingFactor +
            latencyFactor +
            queueFactor)
        .round();
    return total > 100 ? 100 : total;
  }

  // Get congestion level description
  String get congestionDescription {
    final level = congestionLevel;
    if (level < 30) {
      return 'Low';
    } else if (level < 60) {
      return 'Moderate';
    } else if (level < 80) {
      return 'High';
    } else {
      return 'Extreme';
    }
  }

  // Get color based on congestion level
  String get congestionColor {
    final level = congestionLevel;
    if (level < 30) {
      return '#4CAF50'; // Green
    } else if (level < 60) {
      return '#FFC107'; // Yellow
    } else if (level < 80) {
      return '#FF9800'; // Orange
    } else {
      return '#F44336'; // Red
    }
  }

  // Get formatted time since last refresh
  String get refreshTimeAgo {
    final now = DateTime.now();
    final difference = now.difference(lastRefreshed);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  // Get formatted timestamp for the last block
  String get blockTimeFormatted {
    final date = DateTime.fromMillisecondsSinceEpoch(lastBlockTimestamp * 1000);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  // Get estimated transaction confirmation time in minutes based on congestion
  double get estimatedConfirmationMinutes {
    final level = congestionLevel;
    if (level < 30) {
      return 0.5; // 30 seconds
    } else if (level < 60) {
      return 2.0; // 2 minutes
    } else if (level < 80) {
      return 5.0; // 5 minutes
    } else {
      return 10.0; // 10 minutes
    }
  }

  // Get recommended gas price for fast confirmation (in Gwei)
  double get recommendedGasPrice {
    if (congestionLevel < 30) {
      return currentGasPrice * 1.1; // 10% above current
    } else if (congestionLevel < 60) {
      return currentGasPrice * 1.2; // 20% above current
    } else if (congestionLevel < 80) {
      return currentGasPrice * 1.5; // 50% above current
    } else {
      return currentGasPrice * 2.0; // Double the current
    }
  }
}
