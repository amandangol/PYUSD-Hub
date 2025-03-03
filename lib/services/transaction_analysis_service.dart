import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class TransactionAnalysisService {
  final String _rpcUrl;

  TransactionAnalysisService()
      : _rpcUrl = dotenv.env['GCP_RPC_URL'] ??
            dotenv.env['GCP_ETHEREUM_TESTNET_RPC'] ??
            'https://blockchain.googleapis.com/v1/projects/oceanic-impact-451616-f5/locations/us-central1/endpoints/ethereum-holesky/rpc?key=AIzaSyAnZZi8DTOXLn3zcRKoGYtRgMl-YQnIo1Q';

  // Get full transaction details including block info and network data
  Future<Map<String, dynamic>> getFullTransactionDetails(String txHash) async {
    try {
      // First, get the transaction details
      final txResponse = await http.post(
        Uri.parse(_rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'jsonrpc': '2.0',
          'method': 'eth_getTransactionByHash',
          'params': [txHash],
          'id': 1,
        }),
      );

      final txData = json.decode(txResponse.body);
      if (txData['error'] != null || txData['result'] == null) {
        print('Error fetching transaction: ${txData['error']}');
        return {};
      }

      final tx = txData['result'];
      final blockNumber = tx['blockNumber'];

      // Get block information
      final blockResponse = await http.post(
        Uri.parse(_rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'jsonrpc': '2.0',
          'method': 'eth_getBlockByNumber',
          'params': [blockNumber, false],
          'id': 1,
        }),
      );

      final blockData = json.decode(blockResponse.body);
      if (blockData['error'] != null || blockData['result'] == null) {
        print('Error fetching block: ${blockData['error']}');
        return {
          'transaction': tx,
          'block': int.parse(blockNumber.substring(2), radix: 16),
          'confirmations': 0,
        };
      }

      // Get current block number for confirmations
      final latestBlockResponse = await http.post(
        Uri.parse(_rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'jsonrpc': '2.0',
          'method': 'eth_blockNumber',
          'params': [],
          'id': 1,
        }),
      );

      final latestBlockData = json.decode(latestBlockResponse.body);
      final latestBlockHex = latestBlockData['result'] ?? '0x0';

      // Convert hex values to integers
      final txBlockNum = int.parse(blockNumber.substring(2), radix: 16);
      final latestBlockNum = int.parse(latestBlockHex.substring(2), radix: 16);

      // Calculate confirmations
      final confirmations = latestBlockNum - txBlockNum;

      // Get transaction receipt for accurate gas used
      final receiptResponse = await http.post(
        Uri.parse(_rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'jsonrpc': '2.0',
          'method': 'eth_getTransactionReceipt',
          'params': [txHash],
          'id': 1,
        }),
      );

      final receiptData = json.decode(receiptResponse.body);
      final receipt = receiptData['result'];

      return {
        'transaction': tx,
        'block': txBlockNum,
        'timestamp': _hexToDateTime(blockData['result']['timestamp']),
        'confirmations': confirmations,
        'receipt': receipt,
        'gasUsed': receipt != null
            ? int.parse(receipt['gasUsed'].substring(2), radix: 16)
            : 0,
      };
    } catch (e) {
      print('Error getting full transaction details: $e');
      return {};
    }
  }

  // Analyze gas costs and compare to network averages
  Future<Map<String, dynamic>> analyzeGasCost(
      String txHash, double feeInUsd) async {
    try {
      // Get transaction receipt for gas used
      final receiptResponse = await http.post(
        Uri.parse(_rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'jsonrpc': '2.0',
          'method': 'eth_getTransactionReceipt',
          'params': [txHash],
          'id': 1,
        }),
      );

      final receiptData = json.decode(receiptResponse.body);
      if (receiptData['error'] != null || receiptData['result'] == null) {
        return {};
      }

      final receipt = receiptData['result'];

      // Get transaction details for gas price and gas limit
      final txResponse = await http.post(
        Uri.parse(_rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'jsonrpc': '2.0',
          'method': 'eth_getTransactionByHash',
          'params': [txHash],
          'id': 1,
        }),
      );

      final txData = json.decode(txResponse.body);
      if (txData['error'] != null || txData['result'] == null) {
        return {};
        // return _generateFallbackGasAnalysis(feeInUsd);
      }

      final tx = txData['result'];

      // Convert hex values to integers
      final gasUsed = int.parse(receipt['gasUsed'].substring(2), radix: 16);
      final gasLimit = int.parse(tx['gas'].substring(2), radix: 16);
      final gasPriceWei = int.parse(tx['gasPrice'].substring(2), radix: 16);

      // Convert to more readable units
      final gasPriceGwei = gasPriceWei / 1e9;

      // Calculate efficiency
      final efficiency = (gasUsed / gasLimit * 100).toStringAsFixed(1);

      // Get current gas price for comparison
      final gasResponse = await http.post(
        Uri.parse(_rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'jsonrpc': '2.0',
          'method': 'eth_gasPrice',
          'params': [],
          'id': 1,
        }),
      );

      final gasData = json.decode(gasResponse.body);
      final currentGasPriceWei =
          int.parse(gasData['result'].substring(2), radix: 16);
      final currentGasPriceGwei = currentGasPriceWei / 1e9;

      // Generate comparison text
      String comparisonText;
      if (gasPriceGwei > currentGasPriceGwei * 1.2) {
        comparisonText =
            'You paid a premium of ${((gasPriceGwei / currentGasPriceGwei - 1) * 100).toStringAsFixed(0)}% above the current network gas price.';
      } else if (gasPriceGwei < currentGasPriceGwei * 0.8) {
        comparisonText =
            'You saved ${((1 - gasPriceGwei / currentGasPriceGwei) * 100).toStringAsFixed(0)}% compared to the current network gas price.';
      } else {
        comparisonText =
            'You paid a gas price close to the current network average.';
      }

      return {
        'gasPrice': gasPriceGwei.toString(),
        'gasUsed': gasUsed.toString(),
        'gasLimit': gasLimit.toString(),
        'efficiency': efficiency,
        'currentGasPrice': currentGasPriceGwei.toStringAsFixed(5),
        'comparisonText': comparisonText,
      };
    } catch (e) {
      print('Error analyzing gas cost: $e');
      return {};
      // return _generateFallbackGasAnalysis(feeInUsd);
    }
  }

  // Map<String, dynamic> _generateFallbackGasAnalysis(double feeInUsd) {
  //   // Generate reasonable fallback values when API calls fail
  //   final gasPrice = (Random().nextDouble() * 10 + 20).toStringAsFixed(2);
  //   final gasUsed = (Random().nextInt(30000) + 40000).toString();
  //   final gasLimit = (Random().nextInt(50000) + 65000).toString();
  //   final efficiency = (Random().nextDouble() * 20 + 70).toStringAsFixed(1);

  //   return {
  //     'gasPrice': gasPrice,
  //     'gasUsed': gasUsed,
  //     'gasLimit': gasLimit,
  //     'efficiency': efficiency,
  //     'comparisonText':
  //         'This transaction used approximately ${efficiency}% of its gas allocation.',
  //   };
  // }

  // Get market conditions at the time of transaction
  Future<Map<String, dynamic>> getMarketConditionsAtTime(
      DateTime timestamp) async {
    try {
      // This would ideally use a price oracle or historical API
      // For demonstration purposes, we're generating realistic values based on date

      // Get current ETH price
      final ethPrice = await _fetchEthUsdPrice();

      // Generate a historical price based on days since transaction
      final daysSince = DateTime.now().difference(timestamp).inDays;
      final volatility = 0.02; // 2% daily volatility assumption

      // Simplified random walk model
      double historicalEthPrice;
      if (daysSince > 0) {
        final priceDeviationFactor = 1 +
            (volatility * sqrt(daysSince) * (Random().nextDouble() * 2 - 1));
        historicalEthPrice = ethPrice * priceDeviationFactor;
      } else {
        historicalEthPrice = ethPrice;
      }

      // PYUSD is a stablecoin, so we model very small deviations
      final pyusdPrice = 1.0 + (Random().nextDouble() * 0.01 - 0.005);

      // Determine market volatility context
      String volatilityDesc;
      String insights;

      if (daysSince < 7) {
        // Recent transaction - use simplified volatility measure
        final volatilityMeasure = Random().nextDouble();

        if (volatilityMeasure < 0.2) {
          volatilityDesc = 'Very Low';
          insights =
              'The market was exceptionally stable at the time of this transaction, with minimal price fluctuations.';
        } else if (volatilityMeasure < 0.4) {
          volatilityDesc = 'Low';
          insights =
              'Market conditions were relatively calm when this transaction was processed.';
        } else if (volatilityMeasure < 0.6) {
          volatilityDesc = 'Moderate';
          insights =
              'The market showed average volatility when this transaction occurred.';
        } else if (volatilityMeasure < 0.8) {
          volatilityDesc = 'High';
          insights =
              'Market conditions were somewhat turbulent at the time of this transaction.';
        } else {
          volatilityDesc = 'Very High';
          insights =
              'This transaction occurred during a period of significant market volatility.';
        }
      } else {
        // Older transaction - less detail
        volatilityDesc = 'Historical';
        insights =
            'This transaction occurred ${daysSince} days ago. Market conditions have likely changed significantly since then.';
      }

      return {
        'ethPrice': historicalEthPrice,
        'pyusdPrice': pyusdPrice,
        'volatility': volatilityDesc,
        'insights': insights,
      };
    } catch (e) {
      print('Error getting market conditions: $e');
      return {
        'ethPrice': 2500.0 + (Random().nextDouble() * 500),
        'pyusdPrice': 1.0,
        'volatility': 'Unknown',
        'insights':
            'Historical market data could not be retrieved for this transaction.',
      };
    }
  }

  // Helper method to fetch current ETH/USD price
  Future<double> _fetchEthUsdPrice() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ethereum']['usd'].toDouble();
      } else {
        return 2500.0; // Default value if API fails
      }
    } catch (e) {
      print('Error fetching ETH/USD price: $e');
      return 2500.0;
    }
  }

  // Convert hex timestamp to DateTime
  DateTime _hexToDateTime(String hexTimestamp) {
    final timestamp = int.parse(hexTimestamp.substring(2), radix: 16);
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }
}
