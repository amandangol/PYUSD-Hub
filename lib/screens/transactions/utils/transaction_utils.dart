// lib/features/transactions/utils/transaction_utils.dart

class TransactionUtils {
  // Helper method to compare addresses (case-insensitive)
  static bool compareAddresses(String? address1, String? address2) {
    if (address1 == null || address2 == null) return false;
    return address1.toLowerCase() == address2.toLowerCase();
  }
}
