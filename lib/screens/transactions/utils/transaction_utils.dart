// 📂utils/📜transaction_utils.dart

import '../model/transaction_model.dart';

class TransactionUtils {
  // Compare two Ethereum addresses (case-insensitive)
  static bool compareAddresses(String? address1, String? address2) {
    if (address1 == null || address2 == null) return false;
    return address1.toLowerCase() == address2.toLowerCase();
  }

  // Convert Wei to ETH
  static double weiToEth(BigInt wei) {
    return wei.toDouble() / 1e18;
  }

  // Convert Gwei to ETH
  static double gweiToEth(double gwei) {
    return gwei / 1e9;
  }

  // Convert token amount with proper decimals
  static double parseTokenAmount(String value, int decimals) {
    final rawAmount = BigInt.tryParse(value) ?? BigInt.zero;
    return rawAmount.toDouble() / BigInt.from(10).pow(decimals).toDouble();
  }

  // Determine transaction status from blockchain data
  static TransactionStatus determineTransactionStatus(
      Map<String, dynamic> txData) {
    if (txData['blockNumber'] == null || txData['blockNumber'] == '0') {
      return TransactionStatus.pending;
    } else if (int.parse(txData['isError'] ?? '0') == 1) {
      return TransactionStatus.failed;
    } else {
      return TransactionStatus.confirmed;
    }
  }

  // Determine transaction direction based on user address
  static TransactionDirection determineTransactionDirection(
      String txFrom, String userAddress) {
    return compareAddresses(txFrom, userAddress)
        ? TransactionDirection.outgoing
        : TransactionDirection.incoming;
  }

  // Calculate transaction fee
  static double calculateTransactionFee(double gasPrice, double gasUsed) {
    return gasPrice * gasUsed / 1e9; // Convert to ETH
  }

  // Get color for transaction status
  static int getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 0xFFFFA500; // Orange
      case TransactionStatus.confirmed:
        return 0xFF008000; // Green
      case TransactionStatus.failed:
        return 0xFFFF0000; // Red
    }
  }
}
