class FormatterUtils {
  /// Formats an Ethereum address to a shorter, readable version (e.g., "0x1234...abcd")
  static String formatAddress(String address) {
    if (address.length < 10) return address;
    String start = address.substring(0, 6);
    String end = address.substring(address.length - 4);
    return '$start...$end'; // Use three dots for consistency
  }

  /// Formats a transaction hash to a shorter, readable version (e.g., "0x1234abcd...ef567890")
  static String formatHash(String hash) {
    if (hash.length <= 16) return hash;
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 8)}';
  }

  /// Parses a hex string safely into an integer (returns null on failure)
  static int? parseHexSafely(String? hexString) {
    if (hexString == null || hexString.isEmpty || !hexString.startsWith('0x')) {
      return null;
    }
    try {
      return int.parse(hexString.substring(2), radix: 16);
    } catch (e) {
      print('Error parsing hex: $hexString - $e');
      return null;
    }
  }

  /// Formats a BigInt value (in wei) to ETH with appropriate precision
  static String formatEther(String value) {
    try {
      // Convert hex string to BigInt if it starts with '0x'
      BigInt bigIntValue;
      if (value.startsWith('0x')) {
        bigIntValue = BigInt.parse(value.substring(2), radix: 16);
      } else {
        bigIntValue = BigInt.parse(value);
      }

      // Convert to ETH (1 ETH = 10^18 wei)
      final double ethValue = bigIntValue / BigInt.from(10).pow(18);

      // Format based on size
      if (ethValue < 0.00001) {
        return ethValue.toStringAsExponential(6);
      } else if (ethValue < 1) {
        return ethValue.toStringAsFixed(8);
      } else {
        return ethValue.toStringAsFixed(6);
      }
    } catch (e) {
      return value;
    }
  }

  /// Formats a large number with commas (e.g., 1000000 -> "1,000,000")
  static String formatLargeNumber(int? number) {
    if (number == null) return '0';
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  // --- HEX PARSING UTILITIES ---

  /// Parses a [String] hex value to [BigInt] safely.
  static BigInt parseBigInt(String? hex) {
    if (hex == null || hex.isEmpty || hex == '0x0' || hex == '0x') {
      return BigInt.zero;
    }
    try {
      return BigInt.parse(hex.startsWith('0x') ? hex.substring(2) : hex,
          radix: 16);
    } catch (_) {
      return BigInt.zero;
    }
  }

  /// Parses a [String] hex value to [int] safely, with an optional fallback.
  static int parseInt(String? hex, {int fallback = 0}) {
    try {
      return parseBigInt(hex).toInt();
    } catch (_) {
      return fallback;
    }
  }
}
