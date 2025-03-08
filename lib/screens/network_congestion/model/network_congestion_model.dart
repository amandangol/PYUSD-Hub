import 'package:flutter/material.dart';

class NetworkCongestionData {
  final double gasPrice;
  final int pendingTransactions;
  final int pyusdTransactions;
  final double pyusdVolume;
  final double networkUtilization;
  final DateTime timestamp;
  final bool isEstimated;

  NetworkCongestionData({
    required this.gasPrice,
    required this.pendingTransactions,
    required this.pyusdTransactions,
    required this.pyusdVolume,
    required this.networkUtilization,
    DateTime? timestamp,
    this.isEstimated = false,
  }) : timestamp = timestamp ?? DateTime.now();

  // Create a copy with updated values
  NetworkCongestionData copyWith({
    double? gasPrice,
    int? pendingTransactions,
    int? pyusdTransactions,
    double? pyusdVolume,
    double? networkUtilization,
    DateTime? timestamp,
    bool? isEstimated,
  }) {
    return NetworkCongestionData(
      gasPrice: gasPrice ?? this.gasPrice,
      pendingTransactions: pendingTransactions ?? this.pendingTransactions,
      pyusdTransactions: pyusdTransactions ?? this.pyusdTransactions,
      pyusdVolume: pyusdVolume ?? this.pyusdVolume,
      networkUtilization: networkUtilization ?? this.networkUtilization,
      timestamp: timestamp ?? this.timestamp,
      isEstimated: isEstimated ?? this.isEstimated,
    );
  }
}

class NetworkStatus {
  final String level;
  final String description;
  final Color color;

  const NetworkStatus({
    required this.level,
    required this.description,
    required this.color,
  });

  static NetworkStatus fromUtilization(double utilization) {
    if (utilization < 30.0) {
      return const NetworkStatus(
        level: 'Low',
        description:
            'Network traffic is light. Transactions should process quickly with low fees.',
        color: Colors.green,
      );
    } else if (utilization < 70.0) {
      return const NetworkStatus(
        level: 'Medium',
        description:
            'Moderate network congestion. Expect average transaction times and fees.',
        color: Colors.orange,
      );
    } else {
      return const NetworkStatus(
        level: 'High',
        description:
            'Network is highly congested. Transactions may be delayed and fees elevated.',
        color: Colors.red,
      );
    }
  }
}

enum NetworkType {
  ethereumMainnet,
  sepoliaTestnet,
}
