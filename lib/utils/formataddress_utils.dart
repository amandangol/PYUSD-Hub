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

  static int? parseHexSafely(String? hexString) {
    if (hexString == null) return null;

    try {
      if (hexString.startsWith('0x')) {
        return int.parse(hexString.substring(2), radix: 16);
      } else {
        return int.parse(hexString, radix: 16);
      }
    } catch (e) {
      print('Error parsing hex: $e');
      return null;
    }
  }

  // Format wei value to ETH with appropriate precision
  static String formatEther(BigInt? wei) {
    if (wei == null) return '0 ETH';
    final ether = wei / BigInt.from(1e18);
    return '${ether.toStringAsFixed(6)} ETH';
  }

  // Format large numbers with commas
  static String formatLargeNumber(int? number) {
    if (number == null) return '0';
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}
