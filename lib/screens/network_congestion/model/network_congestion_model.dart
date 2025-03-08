// lib/model/network_congestion_model.dart
import 'package:flutter/material.dart';

class NetworkCongestionData {
  final String timestamp;
  final double gasPrice;
  final int pendingTransactions;
  final int pyusdTransactions;
  final double pyusdVolume;
  final double networkUtilization;

  // Additional fields for enhanced monitoring
  final int blockGasUsed;
  final int blockGasLimit;
  final double baseFee;
  final Map<String, dynamic>? pyusdPendingData;
  final Map<String, dynamic>? crossChainData;

  NetworkCongestionData({
    required this.timestamp,
    required this.gasPrice,
    required this.pendingTransactions,
    required this.pyusdTransactions,
    required this.pyusdVolume,
    required this.networkUtilization,
    this.blockGasUsed = 0,
    this.blockGasLimit = 0,
    this.baseFee = 0,
    this.pyusdPendingData,
    this.crossChainData,
  });

  // Helper method to calculate PYUSD's impact on network
  double getPyusdNetworkImpact() {
    if (pendingTransactions == 0) return 0;
    return (pyusdTransactions / pendingTransactions) * 100;
  }

  // Calculate block utilization percentage
  double getBlockUtilization() {
    if (blockGasLimit == 0) return 0;
    return (blockGasUsed / blockGasLimit) * 100;
  }
}

class NetworkStatus {
  final String level;
  final String description;
  final Color color;

  NetworkStatus({
    required this.level,
    required this.description,
    required this.color,
  });
}

// Model for cross-chain data
class CrossChainPYUSDData {
  final String chainName;
  final String contractAddress;
  final int transactionCount;
  final double volume;
  final double gasPrice;
  final double networkUtilization;

  CrossChainPYUSDData({
    required this.chainName,
    required this.contractAddress,
    required this.transactionCount,
    required this.volume,
    required this.gasPrice,
    required this.networkUtilization,
  });
}
