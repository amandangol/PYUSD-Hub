class NetworkActivityData {
  final DateTime timestamp;
  final int transactionCount;
  final double volume;
  final String fromAddress;
  final String toAddress;
  final String transactionHash;

  NetworkActivityData({
    required this.timestamp,
    required this.transactionCount,
    required this.volume,
    required this.fromAddress,
    required this.toAddress,
    required this.transactionHash,
  });

  factory NetworkActivityData.fromJson(Map<String, dynamic> json) {
    return NetworkActivityData(
      timestamp: DateTime.parse(json['timestamp']),
      transactionCount: json['transactionCount'],
      volume: json['volume'].toDouble(),
      fromAddress: json['fromAddress'],
      toAddress: json['toAddress'],
      transactionHash: json['transactionHash'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'transactionCount': transactionCount,
      'volume': volume,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'transactionHash': transactionHash,
    };
  }
}
