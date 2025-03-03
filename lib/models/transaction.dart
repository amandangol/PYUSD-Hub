class TransactionModel {
  final String hash;
  final String? hashLink;
  final String from;
  final String to;
  final double amount;
  final DateTime timestamp;
  final String status;
  final String fee;
  final String? networkName;

  TransactionModel({
    required this.hash,
    this.hashLink,
    required this.from,
    required this.to,
    required this.amount,
    required this.timestamp,
    required this.status,
    required this.fee,
    this.networkName,
  });

  // Helper to check if this transaction is a send or receive relative to an address
  bool isSend(String address) {
    return from.toLowerCase() == address.toLowerCase();
  }
}
