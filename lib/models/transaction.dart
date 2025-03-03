// models/transaction.dart
class TransactionModel {
  final String hash;
  final String from;
  final String to;
  final double amount;
  final String fee;
  final String status;
  final DateTime timestamp;

  TransactionModel({
    required this.hash,
    required this.from,
    required this.to,
    required this.amount,
    required this.fee,
    required this.status,
    required this.timestamp,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      hash: json['hash'] ?? '',
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      fee: json['fee'] ?? '0',
      status: json['status'] ?? 'Pending',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] * 1000)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'from': from,
      'to': to,
      'amount': amount,
      'fee': fee,
      'status': status,
      'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
    };
  }
}
