import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import '../model/network_congestion_model.dart';

class NetworkCongestionProvider with ChangeNotifier {
  bool isLoading = false;
  String? error;
  NetworkCongestionData? currentData;
  List<NetworkCongestionData> historicalData = [];

  // API endpoints
  final Map<NetworkType, String> _httpEndpoints = {
    NetworkType.sepoliaTestnet:
        'https://blockchain.googleapis.com/v1/projects/oceanic-impact-451616-f5/locations/us-central1/endpoints/ethereum-sepolia/rpc?key=AIzaSyAnZZi8DTOXLn3zcRKoGYtRgMl-YQnIo1Q',
    NetworkType.ethereumMainnet:
        'https://blockchain.googleapis.com/v1/projects/t-bounty-433704-e4/locations/asia-east1/endpoints/ethereum-mainnet/rpc?key=AIzaSyB54i4uTgCx_T-mEnTssreiBTxZgsemXPc'
  };

  // PYUSD contract address (on Ethereum)
  final String pyusdContractAddress =
      '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8';

  // Current network
  NetworkType currentNetwork = NetworkType.ethereumMainnet;

  // Timer for periodic updates
  Timer? _updateTimer;

  // Maximum number of data points to keep in history
  final int maxHistoryPoints = 50;

  NetworkCongestionProvider() {
    startMonitoring();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> startMonitoring() async {
    if (_updateTimer != null) {
      _updateTimer!.cancel();
    }

    // Initial fetch
    await fetchNetworkData();

    // Setup periodic updates
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchNetworkData();
    });
  }

  Future<void> fetchNetworkData() async {
    try {
      isLoading = true;
      notifyListeners();

      final newData = await _fetchLiveNetworkData();

      // Add data to historical records
      historicalData.add(newData);

      // Keep only the last maxHistoryPoints records
      if (historicalData.length > maxHistoryPoints) {
        historicalData = historicalData.sublist(
          historicalData.length - maxHistoryPoints,
        );
      }

      currentData = newData;
      isLoading = false;
      error = null;
    } catch (e) {
      isLoading = false;
      error = e.toString();
      print('Error in fetchNetworkData: $e');

      // If there's an error, use the last valid data point if available
      // or create a new data point with a note that it's not from live data
      if (currentData == null && historicalData.isNotEmpty) {
        currentData = historicalData.last;
      } else if (currentData == null) {
        // Only as absolute last resort, create mock data but mark it clearly
        currentData = NetworkCongestionData(
          gasPrice: 30.0,
          pendingTransactions: 10000,
          pyusdTransactions: 500,
          pyusdVolume: 1000000.0,
          networkUtilization: 50.0,
          isEstimated: true,
        );
        historicalData.add(currentData!);
      }
    } finally {
      notifyListeners();
    }
  }

  Future<NetworkCongestionData> _fetchLiveNetworkData() async {
    final client = Web3Client(
      _httpEndpoints[currentNetwork]!,
      http.Client(),
    );

    try {
      // 1. Get current gas price using eth_gasPrice
      final gasPrice = await client.getGasPrice();
      final gasPriceGwei = gasPrice.getInWei / BigInt.from(1000000000);

      // 2. Get pending transactions using eth_getBlockByNumber for 'pending' block
      final pendingTxCount = await _getPendingTransactionCount(client);

      // 3. Get current block to calculate network activity
      final blockNumber = await client.getBlockNumber();

      // 4. Get PYUSD specific metrics by analyzing contract events
      // Only looking at the most recent blocks to avoid RPC timeouts/failures
      final pyusdMetrics = await _getPYUSDMetrics(client, blockNumber);

      // 5. Calculate network utilization based on the collected metrics
      final utilization = await _calculateNetworkUtilization(
        client,
        gasPriceGwei.toDouble(),
        pendingTxCount,
        blockNumber,
      );

      return NetworkCongestionData(
          gasPrice: gasPriceGwei.toDouble(),
          pendingTransactions: pendingTxCount,
          pyusdTransactions: pyusdMetrics['transactionCount'] as int,
          pyusdVolume: pyusdMetrics['volume'] as double,
          networkUtilization: utilization,
          isEstimated: false,
          timestamp: DateTime.now());
    } catch (e) {
      print('Error in _fetchLiveNetworkData: $e');
      throw Exception('Failed to fetch network data: $e');
    } finally {
      client.dispose();
    }
  }

  Future<int> _getPendingTransactionCount(Web3Client client) async {
    try {
      // Method 1: Get pending block and count transactions
      final response = await _makeRpcCall(
          client, 'eth_getBlockByNumber', ['pending', false]);

      // print('Method 1 response: $response'); // Debug log

      if (response != null && response['result'] != null) {
        final List<dynamic> transactions =
            response['result']['transactions'] as List<dynamic>;
        // print('Method 1 tx count: ${transactions.length}');
        return transactions.length;
      }

      // Method 2: Use txpool_status if available (not all nodes support this)
      final txpoolResponse = await _makeRpcCall(client, 'txpool_status', []);
      if (txpoolResponse != null &&
          txpoolResponse['result'] != null &&
          txpoolResponse['result']['pending'] != null) {
        // Convert hex to int
        final pendingHex = txpoolResponse['result']['pending'] as String;
        return int.parse(
            pendingHex.startsWith('0x') ? pendingHex.substring(2) : pendingHex,
            radix: 16);
      }

      // Fallback: Estimate based on mempool size
      final mempoolResponse = await _makeRpcCall(
          client, 'eth_getBlockTransactionCountByNumber', ['pending']);
      if (mempoolResponse != null && mempoolResponse['result'] != null) {
        final countHex = mempoolResponse['result'] as String;
        return int.parse(
            countHex.startsWith('0x') ? countHex.substring(2) : countHex,
            radix: 16);
      }

      throw Exception('Could not determine pending transaction count');
    } catch (e) {
      print('Error getting pending transactions: $e');
      throw Exception('Failed to fetch pending transaction count');
    }
  }

  Future<Map<String, dynamic>> _getPYUSDMetrics(
      Web3Client client, int currentBlockNumber) async {
    try {
      // print('Current block number: $currentBlockNumber');

      // Get the "finalized" block number which is more stable
      final finalizedBlockResponse = await _makeRpcCall(
          client, 'eth_getBlockByNumber', ['finalized', false]);

      int fromBlock;
      int toBlock;

      if (finalizedBlockResponse != null &&
          finalizedBlockResponse['result'] != null &&
          finalizedBlockResponse['result']['number'] != null) {
        final blockHex = finalizedBlockResponse['result']['number'] as String;
        final finalizedBlock = int.parse(
            blockHex.startsWith('0x') ? blockHex.substring(2) : blockHex,
            radix: 16);

        // print('Using finalized block: $finalizedBlock');

        // Look back 100 blocks from finalized block
        fromBlock = finalizedBlock - 1000 < 0 ? 0 : finalizedBlock - 1000;
        toBlock = finalizedBlock; // Use finalized block as toBlock
      } else {
        // Fallback to looking at last 100 blocks from current
        toBlock = currentBlockNumber;
        fromBlock = currentBlockNumber - 100 < 0 ? 0 : currentBlockNumber - 100;
      }

      // print('Analyzing PYUSD activity from block $fromBlock to $toBlock');

      // Topics for Transfer events (keccak256 hash of Transfer(address,address,uint256))
      const transferEventSignature =
          '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef';

      // Initialize metrics
      int transactionCount = 0;
      double totalVolume = 0.0;
      final Set<String> uniqueTxHashes = {};

      // Fetch logs in a single request (Alchemy supports larger block ranges)
      final params = {
        'address': pyusdContractAddress,
        'fromBlock': '0x${fromBlock.toRadixString(16)}',
        'toBlock': '0x${toBlock.toRadixString(16)}',
        'topics': [transferEventSignature],
      };

      // print('PYUSD log query params: $params');

      final response = await _makeRpcCall(client, 'eth_getLogs', [params]);

      if (response == null || response['result'] == null) {
        // print(
        //     'No PYUSD logs returned or error in response: ${response?['error']}');
        return {
          'transactionCount': 0,
          'volume': 0.0,
        };
      }

      final logs = response['result'] as List<dynamic>;
      // print('PYUSD logs fetched: ${logs.length}');

      // Process logs to calculate metrics
      for (var log in logs) {
        // Add transaction hash to set of unique transactions
        if (log['transactionHash'] != null) {
          uniqueTxHashes.add(log['transactionHash'] as String);
        }

        // Parse transfer amount from data field
        if (log['data'] != null) {
          final data = log['data'] as String;
          if (data.length >= 66) {
            // Valid data length for uint256
            // Convert hex value to BigInt and then to double
            final amountHex = data.substring(2); // Remove '0x' prefix
            final amount = BigInt.parse(amountHex, radix: 16);

            // PYUSD has 6 decimals
            final volumeAmount = amount.toDouble() / 1000000;
            totalVolume += volumeAmount;
          }
        }
      }

      transactionCount = uniqueTxHashes.length;
      // print(
      //     'Final metrics - Tx count: $transactionCount, Volume: $totalVolume');

      return {
        'transactionCount': transactionCount,
        'volume': totalVolume,
      };
    } catch (e) {
      // print('Error getting PYUSD metrics: $e');
      // Provide informed estimates based on typical PYUSD activity
      return {
        'transactionCount': 0,
        'volume': 0.0,
      };
    }
  }

  Future<void> _fetchLogsAndProcess(
      Web3Client client,
      Map<String, dynamic> params,
      Set<String> uniqueTxHashes,
      Function(double) onVolumeUpdate) async {
    try {
      final response = await _makeRpcCall(client, 'eth_getLogs', [params]);

      if (response == null || response['result'] == null) {
        print(
            'No PYUSD logs returned or error in response: ${response?['error']}');
        return;
      }

      final logs = response['result'] as List<dynamic>;
      print('PYUSD logs fetched: ${logs.length}');

      // Process logs to calculate metrics
      for (var log in logs) {
        // Add transaction hash to set of unique transactions
        if (log['transactionHash'] != null) {
          uniqueTxHashes.add(log['transactionHash'] as String);
        }

        // Parse transfer amount from data field
        if (log['data'] != null) {
          final data = log['data'] as String;
          if (data.length >= 66) {
            // Valid data length for uint256
            // Convert hex value to BigInt and then to double
            final amountHex = data.substring(2); // Remove '0x' prefix
            final amount = BigInt.parse(amountHex, radix: 16);

            // PYUSD has 6 decimals
            final volumeAmount = amount.toDouble() / 1000000;
            onVolumeUpdate(volumeAmount);
          }
        }
      }
    } catch (e) {
      print('Error fetching logs: $e');
    }
  }

  Future<double> _calculateNetworkUtilization(
    Web3Client client,
    double gasPrice,
    int pendingTransactions,
    int blockNumber,
  ) async {
    try {
      // Get latest block to analyze gas usage
      final latestBlockResponse =
          await _makeRpcCall(client, 'eth_getBlockByNumber', ['latest', true]);

      double blockUtilization = 0.0;
      if (latestBlockResponse != null &&
          latestBlockResponse['result'] != null) {
        final block = latestBlockResponse['result'];

        // Get gas used and gas limit
        String gasUsedHex = block['gasUsed'] as String;
        String gasLimitHex = block['gasLimit'] as String;

        // Convert hex to BigInt
        final gasUsed = BigInt.parse(
            gasUsedHex.startsWith('0x') ? gasUsedHex.substring(2) : gasUsedHex,
            radix: 16);
        final gasLimit = BigInt.parse(
            gasLimitHex.startsWith('0x')
                ? gasLimitHex.substring(2)
                : gasLimitHex,
            radix: 16);

        // Calculate block utilization percentage
        blockUtilization = (gasUsed.toDouble() / gasLimit.toDouble()) * 100;
      }

      // Normalize gas price (assuming 10-200 Gwei range for scaling)
      final normalizedGasPrice = (gasPrice - 10) / 190;
      final clampedGasPrice = normalizedGasPrice.clamp(0.0, 1.0);

      // Normalize pending transactions (assuming 1k-30k range)
      final normalizedPendingTx = (pendingTransactions - 1000) / 29000;
      final clampedPendingTx = normalizedPendingTx.clamp(0.0, 1.0);

      // Calculate overall utilization weighing different factors
      final utilization =
          (blockUtilization * 0.4 + // Block usage is a strong indicator
              clampedGasPrice * 0.4 + // Gas price reflects market demand
              clampedPendingTx * 0.2 // Pending tx count shows backlog
          );

      return utilization.clamp(0.0, 100.0);
    } catch (e) {
      print('Error calculating network utilization: $e');
      // Fallback to using a simple gas price based estimate
      return (gasPrice / 200 * 100).clamp(0.0, 100.0);
    }
  }

  // Helper method to make RPC calls
  Future<Map<String, dynamic>?> _makeRpcCall(
      Web3Client client, String method, List<dynamic> params) async {
    try {
      final response = await http.post(
        Uri.parse(_httpEndpoints[currentNetwork]!),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': method,
          'params': params,
        }),
      );

      if (response.statusCode == 200) {
        final decodedResponse =
            json.decode(response.body) as Map<String, dynamic>;
        return decodedResponse;
      }

      // print('RPC call for $method failed with status: ${response.statusCode}');
      // print('Response body: ${response.body}');
      return null;
    } catch (e) {
      print('RPC call error for $method: $e');
      return null;
    }
  }

  // Get network status based on current utilization
  NetworkStatus getNetworkStatus() {
    if (currentData == null) {
      return const NetworkStatus(
        level: 'Unknown',
        description: 'Network status currently unavailable.',
        color: Colors.grey,
      );
    }

    return NetworkStatus.fromUtilization(currentData!.networkUtilization);
  }

  // Change network type
  void switchNetwork(NetworkType network) {
    currentNetwork = network;
    historicalData.clear();
    currentData = null;
    startMonitoring();
  }
}
