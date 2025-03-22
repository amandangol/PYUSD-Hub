import 'package:intl/intl.dart';
import 'package:web3dart/web3dart.dart';

class FormatterUtils {
  static final _numberFormat = NumberFormat('#,##0.####');
  static final _addressFormat = NumberFormat('0.000');

  /// Formats an Ethereum address to a shorter, readable version (e.g., "0x1234...abcd")
  static String formatAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
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
      if (hex.toLowerCase().startsWith('0x')) {
        return BigInt.parse(hex.substring(2), radix: 16);
      }
      return BigInt.parse(hex);
    } catch (e) {
      print('Error parsing BigInt: $e');
      return BigInt.zero;
    }
  }

  /// Parses a [String] hex value to [int] safely, with an optional fallback.
  static int parseInt(String? hex, {int fallback = 0}) {
    try {
      return parseBigInt(hex!).toInt();
    } catch (_) {
      return fallback;
    }
  }

  // Format number with thousands separator and optional decimal places
  static String formatNumber(dynamic number) {
    if (number == null) return '0';

    try {
      if (number is int || number is BigInt) {
        return _numberFormat.format(number);
      } else if (number is double) {
        return _numberFormat.format(number);
      } else if (number is String) {
        final parsed = double.tryParse(number);
        if (parsed != null) {
          return _numberFormat.format(parsed);
        }
      }
      return number.toString();
    } catch (e) {
      print('Error formatting number: $e');
      return '0';
    }
  }

  // Format ETH amount
  static String formatEthAmount(BigInt wei) {
    try {
      final ethAmount = EtherAmount.fromBigInt(EtherUnit.wei, wei)
          .getValueInUnit(EtherUnit.ether);
      return _addressFormat.format(ethAmount);
    } catch (e) {
      print('Error formatting ETH amount: $e');
      return '0.000';
    }
  }

  // Format token amount with decimals
  static String formatTokenAmount(BigInt amount, int decimals) {
    try {
      final value = amount / BigInt.from(10).pow(decimals);
      return _addressFormat.format(value);
    } catch (e) {
      print('Error formatting token amount: $e');
      return '0.000';
    }
  }
}
