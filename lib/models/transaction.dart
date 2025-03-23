enum TransactionType {
  send,
  receive,
  swap,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
}

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String fromAddress;
  final String toAddress;
  final DateTime timestamp;
  final TransactionStatus status;
  final String? fromToken;
  final String? toToken;
  final double? fromAmount;
  final double? toAmount;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.fromAddress,
    required this.toAddress,
    required this.timestamp,
    required this.status,
    this.fromToken,
    this.toToken,
    this.fromAmount,
    this.toAmount,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => TransactionType.send,
      ),
      amount: (json['amount'] as num).toDouble(),
      fromAddress: json['fromAddress'] as String,
      toAddress: json['toAddress'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      fromToken: json['fromToken'] as String?,
      toToken: json['toToken'] as String?,
      fromAmount: json['fromAmount'] != null
          ? (json['fromAmount'] as num).toDouble()
          : null,
      toAmount: json['toAmount'] != null
          ? (json['toAmount'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'amount': amount,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString(),
      'fromToken': fromToken,
      'toToken': toToken,
      'fromAmount': fromAmount,
      'toAmount': toAmount,
    };
  }
}
