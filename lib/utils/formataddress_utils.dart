class FormatterUtils {
  /// Formats an Ethereum address to a shorter, readable version
  static String formatAddress(String address) {
    if (address.length < 10) return address;

    String start = address.substring(0, 6);
    String end = address.substring(address.length - 4);

    return '$start....$end';
  }

  static String formatHash(String hash) {
    if (hash.length <= 16) return hash;
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 8)}';
  }
}
