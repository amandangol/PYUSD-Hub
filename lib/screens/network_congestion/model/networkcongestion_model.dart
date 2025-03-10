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
  });

  // Helper method to update specific fields
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

    int total =
        (gasFactor + utilizationFactor + pendingFactor + latencyFactor).round();
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
}
