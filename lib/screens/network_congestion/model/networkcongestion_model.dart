class NetworkCongestionData {
  final double currentGasPrice;
  final double averageGasPrice;
  final int pendingTransactions;
  final double gasUsagePercentage;
  final List<double> historicalGasPrices;
  final int pyusdTransactionCount;
  final double networkLatency;
  final double blockTime;
  final int confirmedPyusdTxCount;
  final int pendingPyusdTxCount;
  final int lastBlockNumber;
  final int lastBlockTimestamp;
  final int pendingQueueSize;
  final double averageBlockSize;
  final DateTime lastRefreshed;
  final double averageBlockTime;
  final int blocksPerHour;
  final int averageTxPerBlock;
  final int gasLimit;

  // Update constructor by adding these parameters
  NetworkCongestionData({
    required this.currentGasPrice,
    required this.averageGasPrice,
    required this.pendingTransactions,
    required this.gasUsagePercentage,
    required this.historicalGasPrices,
    required this.pyusdTransactionCount,
    required this.networkLatency,
    required this.blockTime,
    required this.confirmedPyusdTxCount,
    required this.pendingPyusdTxCount,
    required this.lastBlockNumber,
    required this.lastBlockTimestamp,
    required this.pendingQueueSize,
    required this.averageBlockSize,
    required this.lastRefreshed,
    required this.averageBlockTime,
    required this.blocksPerHour,
    required this.averageTxPerBlock,
    required this.gasLimit,
  });

  // Update copyWith method by adding these parameters
  NetworkCongestionData copyWith({
    double? currentGasPrice,
    double? averageGasPrice,
    int? pendingTransactions,
    double? gasUsagePercentage,
    List<double>? historicalGasPrices,
    int? pyusdTransactionCount,
    double? networkLatency,
    double? blockTime,
    int? confirmedPyusdTxCount,
    int? pendingPyusdTxCount,
    int? lastBlockNumber,
    int? lastBlockTimestamp,
    int? pendingQueueSize,
    double? averageBlockSize,
    DateTime? lastRefreshed,
    double? averageBlockTime,
    int? blocksPerHour,
    int? averageTxPerBlock,
    int? gasLimit,
  }) {
    return NetworkCongestionData(
      currentGasPrice: currentGasPrice ?? this.currentGasPrice,
      averageGasPrice: averageGasPrice ?? this.averageGasPrice,
      pendingTransactions: pendingTransactions ?? this.pendingTransactions,
      gasUsagePercentage: gasUsagePercentage ?? this.gasUsagePercentage,
      historicalGasPrices: historicalGasPrices ?? this.historicalGasPrices,
      pyusdTransactionCount:
          pyusdTransactionCount ?? this.pyusdTransactionCount,
      networkLatency: networkLatency ?? this.networkLatency,
      blockTime: blockTime ?? this.blockTime,
      confirmedPyusdTxCount:
          confirmedPyusdTxCount ?? this.confirmedPyusdTxCount,
      pendingPyusdTxCount: pendingPyusdTxCount ?? this.pendingPyusdTxCount,
      lastBlockNumber: lastBlockNumber ?? this.lastBlockNumber,
      lastBlockTimestamp: lastBlockTimestamp ?? this.lastBlockTimestamp,
      pendingQueueSize: pendingQueueSize ?? this.pendingQueueSize,
      averageBlockSize: averageBlockSize ?? this.averageBlockSize,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
      averageBlockTime: averageBlockTime ?? this.averageBlockTime,
      blocksPerHour: blocksPerHour ?? this.blocksPerHour,
      averageTxPerBlock: averageTxPerBlock ?? this.averageTxPerBlock,
      gasLimit: gasLimit ?? this.gasLimit,
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
