class TransactionModel {
  final String hash;
  final String from;
  final String to;
  final double amount;
  final DateTime timestamp;
  final bool isIncoming;
  final String status;
  final String fee;

  const TransactionModel({
    required this.hash,
    required this.from,
    required this.to,
    required this.amount,
    required this.timestamp,
    required this.isIncoming,
    this.status = 'Confirmed',
    this.fee = '0.0001',
  });

  // Factory constructor to create from a value string
  factory TransactionModel.fromValueString({
    required String hash,
    required String from,
    required String to,
    required String value,
    required DateTime timestamp,
    required bool isIncoming,
  }) {
    return TransactionModel(
      hash: hash,
      from: from,
      to: to,
      amount: double.tryParse(value) ?? 0.0,
      timestamp: timestamp,
      isIncoming: isIncoming,
    );
  }
}
