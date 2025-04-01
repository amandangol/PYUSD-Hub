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
    if (hexString == null) return null;
    try {
      // Remove '0x' prefix if present
      final cleanHex = hexString.toLowerCase().startsWith('0x')
          ? hexString.substring(2)
          : hexString;
      return int.parse(cleanHex, radix: 16);
    } catch (e) {
      print('Error parsing hex string: $hexString');
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

  static String formatGas(String gasHex) {
    try {
      final gasValue = parseBigInt(gasHex);
      return gasValue.toString();
    } catch (e) {
      return '0';
    }
  }

  /// Format currency value with appropriate suffix (K, M, B)
  static String formatCurrencyWithSuffix(double value) {
    if (value >= 1000000000) {
      return '\$${(value / 1000000000).toStringAsFixed(2)}B';
    } else if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(2)}K';
    } else {
      return '\$${value.toStringAsFixed(2)}';
    }
  }

  /// Format a timestamp (in seconds) to a readable date/time
  static String formatTimestamp(int timestamp) {
    if (timestamp <= 0) return 'Unknown time';

    final DateTime dateTime =
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('MMM d, yyyy HH:mm').format(dateTime);
  }

  /// Format a timestamp (in seconds) to a relative time (e.g., "2 minutes ago")
  static String formatRelativeTime(int timestamp) {
    if (timestamp <= 0) return 'Unknown time';

    final DateTime dateTime =
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final Duration difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  /// Format ETH value from hex string
  static String formatEthFromHex(String hexValue) {
    final value = parseHexSafely(hexValue) ?? 0;
    final ethValue = value / 1e18;

    if (ethValue == 0) {
      return '0 ETH';
    } else if (ethValue < 0.000001) {
      return '< 0.000001 ETH';
    } else {
      return '${ethValue.toStringAsFixed(6)} ETH';
    }
  }

  /// Format a block number with commas
  static String formatBlockNumber(int blockNumber) {
    return formatLargeNumber(blockNumber);
  }

  /// Format gas price in Gwei
  static String formatGasPrice(int gasPriceWei) {
    final gweiValue = gasPriceWei / 1e9;
    if (gweiValue < 0.01) {
      return '< 0.01 Gwei';
    } else {
      return '${gweiValue.toStringAsFixed(2)} Gwei';
    }
  }
}
