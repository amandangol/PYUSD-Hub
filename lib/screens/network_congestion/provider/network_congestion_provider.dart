import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../config/rpc_endpoints.dart';
import '../model/networkcongestion_model.dart';

class NetworkCongestionProvider with ChangeNotifier {
  // RPC endpoints
  final String _httpRpcUrl = RpcEndpoints.mainnetHttpRpcUrl;
  final String _wsRpcUrl = RpcEndpoints.mainnetWssRpcUrl;

  WebSocketChannel? _wsChannel;
  Timer? _updateTimer;
  int _requestId = 1;

  // PYUSD Contract address on Ethereum mainnet
  final String _pyusdContractAddress =
      '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8';

  // Event signature for ERC-20 Transfer events
  final String _transferEventSignature =
      '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef';

  NetworkCongestionData _congestionData = NetworkCongestionData(
    currentGasPrice: 0,
    averageGasPrice: 0,
    pendingTransactions: 0,
    gasUsagePercentage: 0,
    historicalGasPrices: [],
    pyusdTransactionCount: 0,
    networkLatency: 0,
    blockTime: 0,
    confirmedPyusdTxCount: 0,
    pendingPyusdTxCount: 0,
    lastBlockNumber: 0,
    lastBlockTimestamp: 0,
    pendingQueueSize: 0,
    averageBlockSize: 0,
    lastRefreshed: DateTime.now(),
    averageBlockTime: 0,
    blocksPerHour: 0,
    averageTxPerBlock: 0,
    gasLimit: 0,
  );

  NetworkCongestionData get congestionData => _congestionData;
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  final List<Map<String, dynamic>> _recentBlocks = [];
  List<Map<String, dynamic>> get recentBlocks => _recentBlocks;

  final List<Map<String, dynamic>> _recentPyusdTransactions = [];
  List<Map<String, dynamic>> get recentPyusdTransactions =>
      _recentPyusdTransactions;

  // Cache for transaction receipts to reduce RPC calls
  final Map<String, Map<String, dynamic>> _transactionReceiptCache = {};

  Future<dynamic> _makeRpcCall(String method, List<dynamic> params) async {
    try {
      final response = await http.post(
        Uri.parse(_httpRpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'jsonrpc': '2.0',
          'id': _requestId++,
          'method': method,
          'params': params
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('error')) {
          print('RPC error: ${data['error']}');
          return null;
        }
        return data['result'];
      } else {
        // print('HTTP error: ${response.statusCode}, Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('RPC call error: $e');
      return null;
    }
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    // Clear existing data
    _recentBlocks.clear();
    _recentPyusdTransactions.clear();
    _transactionReceiptCache.clear();

    try {
      // Fetch all critical data in parallel
      await Future.wait([
        _fetchNetworkStats(),
        _fetchInitialBlocks(),
        _fetchPyusdTransactionActivity(),
        _fetchPendingQueueDetails(),
      ]);

      // Update last refreshed time
      _congestionData = _congestionData.copyWith(
        lastRefreshed: DateTime.now(),
      );
    } catch (e) {
      print('Error during refresh: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch critical data in parallel
      await Future.wait([
        _fetchNetworkStats(),
        _fetchInitialBlocks(),
        _fetchPyusdTransactionActivity(),
        _fetchPendingQueueDetails(),
      ]);

      // Connect WebSocket after initial data is loaded
      _connectWebSocket();

      // Setup periodic updates at a more reasonable interval (30 seconds)
      _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
        await _fetchNetworkStats();

        // Add automatic block refresh here
        await _fetchLatestBlocksUpdate();

        // Update last refreshed timestamp
        _congestionData = _congestionData.copyWith(
          lastRefreshed: DateTime.now(),
        );

        // Fetch pending queue details every 60s
        if (timer.tick % 2 == 0) {
          await _fetchPendingQueueDetails();
        }

        // Periodically update PYUSD transaction data
        if (timer.tick % 4 == 0) {
          // Every 2 minutes (30s * 4)
          await _fetchPyusdTransactionActivity();
        }
      });
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Initialization error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchLatestBlocksUpdate() async {
    try {
      final latestBlockResponse = await _makeRpcCall('eth_blockNumber', []);
      final latestBlockNumber = _parseHexSafely(latestBlockResponse);

      if (latestBlockNumber == null) {
        print('Could not get latest block number');
        return;
      }

      // Update last block number
      _congestionData = _congestionData.copyWith(
        lastBlockNumber: latestBlockNumber,
      );

      int? newestBlockInCache = _recentBlocks.isEmpty
          ? null
          : _parseHexSafely(_recentBlocks[0]['number']);

      // Only fetch new blocks if latest block is newer than the one we have
      if (_recentBlocks.isEmpty ||
          (newestBlockInCache != null &&
              latestBlockNumber > newestBlockInCache)) {
        // Only fetch the necessary number of new blocks
        int oldestBlockToFetch = latestBlockNumber;

        // If we already have recent blocks, just fetch the new ones
        if (newestBlockInCache != null) {
          oldestBlockToFetch = newestBlockInCache + 1;
        }

        // Don't fetch more than 5 blocks at once to avoid overloading
        int blocksAvailable = latestBlockNumber - oldestBlockToFetch + 1;
        int numBlocksToFetch =
            blocksAvailable > 0 ? min(5, blocksAvailable) : 0;

        if (numBlocksToFetch > 0) {
          // Create a list of futures to fetch blocks in parallel
          List<Future<Map<String, dynamic>?>> blockFutures = [];

          for (int i = 0; i < numBlocksToFetch; i++) {
            final blockNumber = latestBlockNumber - i;
            // Skip blocks we already have
            if (newestBlockInCache != null &&
                blockNumber <= newestBlockInCache) {
              continue;
            }

            final blockHex = '0x${blockNumber.toRadixString(16)}';
            blockFutures.add(_fetchBlock(blockHex));
          }

          // Wait for all block fetches to complete
          final blockResponses = await Future.wait(blockFutures);

          // Process the blocks
          for (var blockResponse in blockResponses) {
            if (blockResponse != null) {
              // Insert at the beginning to maintain newest-first order
              _recentBlocks.insert(0, blockResponse);

              // Keep only the 10 most recent blocks
              if (_recentBlocks.length > 10) {
                _recentBlocks.removeLast();
              }

              // Check for PYUSD transactions in this block
              _countPyusdTransactionsInBlock(blockResponse);
            }
          }

          // Recalculate block statistics after fetching new blocks
          await _calculateBlockStatistics();

          // Update block time if possible
          if (_recentBlocks.length >= 2) {
            final currentTimestamp =
                _parseHexSafely(_recentBlocks[0]['timestamp']);
            final previousTimestamp =
                _parseHexSafely(_recentBlocks[1]['timestamp']);

            if (currentTimestamp != null && previousTimestamp != null) {
              final blockTime = currentTimestamp - previousTimestamp;
              _congestionData =
                  _congestionData.copyWith(blockTime: blockTime.toDouble());

              // Update last block timestamp
              _congestionData = _congestionData.copyWith(
                lastBlockTimestamp: currentTimestamp,
              );
            }
          }
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error fetching latest blocks update: $e');
    }
  }

  Future<void> _fetchPendingQueueDetails() async {
    try {
      // Get txpool content for more detailed analysis
      final txpoolContentResponse = await _makeRpcCall('txpool_content', []);

      if (txpoolContentResponse != null) {
        // Calculate total pending queue size (includes both pending and queued transactions)
        int pendingCount = 0;
        if (txpoolContentResponse.containsKey('pending')) {
          final pendingMap =
              txpoolContentResponse['pending'] as Map<String, dynamic>;
          for (final address in pendingMap.keys) {
            final addressTxs = pendingMap[address] as Map<String, dynamic>;
            pendingCount += addressTxs.length;
          }
        }

        int queuedCount = 0;
        if (txpoolContentResponse.containsKey('queued')) {
          final queuedMap =
              txpoolContentResponse['queued'] as Map<String, dynamic>;
          for (final address in queuedMap.keys) {
            final addressTxs = queuedMap[address] as Map<String, dynamic>;
            queuedCount += addressTxs.length;
          }
        }

        // Update pending queue size
        _congestionData = _congestionData.copyWith(
          pendingQueueSize: pendingCount + queuedCount,
        );

        notifyListeners();
      }
    } catch (e) {
      print('Error fetching pending queue details: $e');
    }
  }

  Future<void> _calculateBlockStatistics() async {
    try {
      // We need at least 10 blocks to calculate meaningful statistics
      if (_recentBlocks.length < 2) {
        return;
      }

      // Calculate average block time from recent blocks
      double totalBlockTime = 0;
      int blockCount = 0;
      int totalTransactions = 0;
      int latestGasLimit = 0;

      // Get latest gas limit
      if (_recentBlocks.isNotEmpty &&
          _recentBlocks[0].containsKey('gasLimit')) {
        latestGasLimit = _parseHexSafely(_recentBlocks[0]['gasLimit']) ?? 0;
      }

      // Calculate average block time and transaction count
      for (int i = 0; i < _recentBlocks.length - 1; i++) {
        final currentTimestamp = _parseHexSafely(_recentBlocks[i]['timestamp']);
        final previousTimestamp =
            _parseHexSafely(_recentBlocks[i + 1]['timestamp']);

        if (currentTimestamp != null && previousTimestamp != null) {
          totalBlockTime += (currentTimestamp - previousTimestamp);
          blockCount++;
        }

        // Count transactions in block
        if (_recentBlocks[i].containsKey('transactions') &&
            _recentBlocks[i]['transactions'] is List) {
          totalTransactions +=
              (_recentBlocks[i]['transactions'] as List).length;
        }
      }

      // Calculate the statistics
      double avgBlockTime = blockCount > 0 ? totalBlockTime / blockCount : 0;
      int blocksPerHour = avgBlockTime > 0 ? (3600 / avgBlockTime).round() : 0;
      int avgTxPerBlock =
          blockCount > 0 ? (totalTransactions / blockCount).round() : 0;

      // Update the congestion data
      _congestionData = _congestionData.copyWith(
        averageBlockTime: avgBlockTime,
        blocksPerHour: blocksPerHour,
        averageTxPerBlock: avgTxPerBlock,
        gasLimit: latestGasLimit,
      );

      notifyListeners();
    } catch (e) {
      print('Error calculating block statistics: $e');
    }
  }

  // Main method to fetch PYUSD transactions using RPC
  Future<void> _fetchPyusdTransactionActivity() async {
    try {
      // First, get the latest block number
      final latestBlockResponse = await _makeRpcCall('eth_blockNumber', []);
      final latestBlockNumber = _parseHexSafely(latestBlockResponse);

      if (latestBlockNumber == null) {
        print('Could not get latest block number');
        return;
      }

      // We'll search for PYUSD transactions in the last 10,000 blocks
      // This is approximately 1-2 days of blocks
      const int blocksToSearch = 10000;

      // Calculate start block
      int startBlock = latestBlockNumber - blocksToSearch;
      if (startBlock < 0) startBlock = 0;

      // Convert block numbers to hex
      final fromBlockHex = '0x${startBlock.toRadixString(16)}';
      final toBlockHex = '0x${latestBlockNumber.toRadixString(16)}';

      // Use eth_getLogs to find all Transfer events related to PYUSD contract
      final logsResponse = await _makeRpcCall('eth_getLogs', [
        {
          'address': _pyusdContractAddress,
          'topics': [_transferEventSignature],
          'fromBlock': fromBlockHex,
          'toBlock': toBlockHex
        }
      ]);

      if (logsResponse == null || logsResponse is! List) {
        print('Invalid logs response: $logsResponse');
        return;
      }

      // Update total PYUSD transaction count
      _congestionData = _congestionData.copyWith(
          pyusdTransactionCount: logsResponse.length,
          confirmedPyusdTxCount: logsResponse.length);

      // Process recent logs to extract transactions
      await _processRecentLogs(logsResponse);

      notifyListeners();
    } catch (e) {
      print('Error fetching PYUSD transaction activity: $e');

      // Fallback: try to get some recent transactions from recent blocks we already have
      _extractPyusdTransactionsFromRecentBlocks();
    }
  }

  // Process log entries to extract transaction details
  Future<void> _processRecentLogs(List<dynamic> logs) async {
    try {
      // Sort logs by block number (descending) to get the most recent first
      logs.sort((a, b) {
        final blockNumberA = _parseHexSafely(a['blockNumber']) ?? 0;
        final blockNumberB = _parseHexSafely(b['blockNumber']) ?? 0;
        return blockNumberB.compareTo(blockNumberA);
      });

      // Take the 50 most recent logs
      final recentLogs = logs.take(50).toList();

      // Clear existing transactions list
      _recentPyusdTransactions.clear();

      // Create a set of transaction hashes we've already processed
      final Set<String> processedTxHashes = {};

      // Process each log to get transaction details
      for (var log in recentLogs) {
        final txHash = log['transactionHash'];

        // Skip if we've already processed this transaction
        if (processedTxHashes.contains(txHash)) continue;
        processedTxHashes.add(txHash);

        // Get full transaction details
        final tx = await _getTransactionDetails(txHash);
        if (tx != null) {
          _recentPyusdTransactions.add(tx);

          // Limit list size to 20
          if (_recentPyusdTransactions.length >= 20) break;
        }
      }
    } catch (e) {
      print('Error processing recent logs: $e');
    }
  }

  // Get transaction details from hash
  Future<Map<String, dynamic>?> _getTransactionDetails(String txHash) async {
    try {
      // Get transaction
      final tx = await _makeRpcCall('eth_getTransactionByHash', [txHash]);
      if (tx == null) return null;

      // Get transaction receipt to include status
      final receipt = await _getTransactionReceipt(txHash);
      if (receipt != null) {
        // Combine transaction with receipt data
        tx['status'] = receipt['status'];
        tx['gasUsed'] = receipt['gasUsed'];

        // Add transaction timestamp from block
        final blockNumber = tx['blockNumber'];
        if (blockNumber != null) {
          final block =
              await _makeRpcCall('eth_getBlockByNumber', [blockNumber, false]);
          if (block != null && block.containsKey('timestamp')) {
            tx['timestamp'] = block['timestamp'];
          }
        }
      }

      return tx;
    } catch (e) {
      print('Error getting transaction details: $e');
      return null;
    }
  }

  // Get transaction receipt with caching
  Future<Map<String, dynamic>?> _getTransactionReceipt(String txHash) async {
    try {
      // Check cache first
      if (_transactionReceiptCache.containsKey(txHash)) {
        return _transactionReceiptCache[txHash];
      }

      // Fetch receipt
      final receipt = await _makeRpcCall('eth_getTransactionReceipt', [txHash]);

      // Cache the result
      if (receipt != null) {
        _transactionReceiptCache[txHash] = receipt;

        // Limit cache size to reduce memory usage
        if (_transactionReceiptCache.length > 100) {
          final oldestKey = _transactionReceiptCache.keys.first;
          _transactionReceiptCache.remove(oldestKey);
        }
      }

      return receipt;
    } catch (e) {
      print('Error getting transaction receipt: $e');
      return null;
    }
  }

  // Extract PYUSD transactions from blocks we've already fetched
  void _extractPyusdTransactionsFromRecentBlocks() {
    try {
      if (_recentBlocks.isEmpty) return;

      int pyusdTxCount = 0;

      for (var block in _recentBlocks) {
        if (block.containsKey('transactions') &&
            block['transactions'] is List) {
          for (var tx in block['transactions']) {
            if (tx['to'] != null &&
                tx['to'].toString().toLowerCase() ==
                    _pyusdContractAddress.toLowerCase()) {
              // Only add if not already present
              if (!_recentPyusdTransactions
                  .any((t) => t['hash'] == tx['hash'])) {
                _recentPyusdTransactions.add(tx);
                pyusdTxCount++;
              }
            }
          }
        }
      }

      if (pyusdTxCount > 0) {
        notifyListeners();
      }
    } catch (e) {
      print('Error extracting PYUSD transactions from recent blocks: $e');
    }
  }

  // OPTIMIZED: Fetch blocks in batch
  Future<void> _fetchInitialBlocks() async {
    try {
      final latestBlockResponse = await _makeRpcCall('eth_blockNumber', []);
      final latestBlockNumber = _parseHexSafely(latestBlockResponse);

      if (latestBlockNumber == null) {
        print('Could not get latest block number');
        return;
      }

      // Update last block number
      _congestionData = _congestionData.copyWith(
        lastBlockNumber: latestBlockNumber,
      );

      // Create a list of futures to fetch blocks in parallel
      List<Future<Map<String, dynamic>?>> blockFutures = [];

      // Fetch the last 10 blocks
      for (int i = 0; i < 10; i++) {
        final blockNumber = latestBlockNumber - i;
        final blockHex = '0x${blockNumber.toRadixString(16)}';
        blockFutures.add(_fetchBlock(blockHex));
      }

      // Wait for all block fetches to complete
      final blockResponses = await Future.wait(blockFutures);

      // Process the blocks
      int pyusdTxCount = 0;
      int totalSize = 0;

      for (var blockResponse in blockResponses) {
        if (blockResponse != null) {
          _recentBlocks.add(blockResponse);

          // Calculate block size by summing transaction data sizes
          if (blockResponse.containsKey('transactions') &&
              blockResponse['transactions'] is List) {
            final txs = blockResponse['transactions'] as List;

            // Add to total size calculation (rough approximation)
            totalSize +=
                txs.length * 250; // Assume average tx size of ~250 bytes

            for (var tx in txs) {
              if (tx['to'] != null &&
                  tx['to'].toString().toLowerCase() ==
                      _pyusdContractAddress.toLowerCase()) {
                _recentPyusdTransactions.add(tx);
                pyusdTxCount++;
              }
            }
          }
        }
      }
      // Calculate average block size
      if (_recentBlocks.isNotEmpty) {
        final avgBlockSize = totalSize / _recentBlocks.length;
        _congestionData = _congestionData.copyWith(
          averageBlockSize: avgBlockSize,
        );
      }

      // Calculate block time if possible
      if (_recentBlocks.length >= 2) {
        final currentTimestamp = _parseHexSafely(_recentBlocks[0]['timestamp']);
        final previousTimestamp =
            _parseHexSafely(_recentBlocks[1]['timestamp']);

        if (currentTimestamp != null && previousTimestamp != null) {
          final blockTime = currentTimestamp - previousTimestamp;
          _congestionData =
              _congestionData.copyWith(blockTime: blockTime.toDouble());

          // Update last block timestamp
          _congestionData = _congestionData.copyWith(
            lastBlockTimestamp: currentTimestamp,
          );
        }
      }
      await _calculateBlockStatistics();

      // Update PYUSD transaction counts
      _congestionData =
          _congestionData.copyWith(confirmedPyusdTxCount: pyusdTxCount);

      // Update last refreshed time
      _congestionData = _congestionData.copyWith(
        lastRefreshed: DateTime.now(),
      );
    } catch (e) {
      print('Error fetching initial blocks: $e');
    }
  }

  // Helper function to fetch a single block
  Future<Map<String, dynamic>?> _fetchBlock(String blockHex) async {
    try {
      return await _makeRpcCall('eth_getBlockByNumber', [blockHex, true]);
    } catch (e) {
      print('Error fetching block $blockHex: $e');
      return null;
    }
  }

  void _connectWebSocket() {
    try {
      _wsChannel = WebSocketChannel.connect(Uri.parse(_wsRpcUrl));

      // Subscribe to new blocks
      _wsChannel!.sink.add(json.encode({
        "jsonrpc": "2.0",
        "id": _requestId++,
        "method": "eth_subscribe",
        "params": ["newHeads"]
      }));

      // Subscribe to pending transactions
      _wsChannel!.sink.add(json.encode({
        "jsonrpc": "2.0",
        "id": _requestId++,
        "method": "eth_subscribe",
        "params": ["pendingTransactions"]
      }));

      _wsChannel!.stream.listen((message) {
        final data = json.decode(message);
        if (data['method'] == 'eth_subscription') {
          _handleSubscriptionUpdate(data['params']);
        }
      }, onError: (error) {
        print('WebSocket error: $error');
        _reconnectWebSocket();
      }, onDone: () {
        print('WebSocket connection closed');
        _reconnectWebSocket();
      });
    } catch (e) {
      print('WebSocket connection error: $e');
      // Try to reconnect after a delay
      Future.delayed(const Duration(seconds: 5), _reconnectWebSocket);
    }
  }

  void _reconnectWebSocket() {
    _wsChannel?.sink.close();
    _wsChannel = null;
    Future.delayed(const Duration(seconds: 5), _connectWebSocket);
  }

  void _handleSubscriptionUpdate(Map<String, dynamic> params) {
    final result = params['result'];

    if (result.containsKey('hash')) {
      // This is a new transaction
      _checkIfPyusdTransaction(result['hash']);
    } else if (result.containsKey('number')) {
      // This is a new block
      final blockNumber = _parseHexSafely(result['number']);
      if (blockNumber != null) {
        // Update last block number
        _congestionData = _congestionData.copyWith(
          lastBlockNumber: blockNumber,
        );

        // Update last refreshed time whenever a new block arrives
        _congestionData = _congestionData.copyWith(
          lastRefreshed: DateTime.now(),
        );

        _fetchBlockInfo(blockNumber);
      }
    }
  }

  Future<void> _checkIfPyusdTransaction(String txHash) async {
    try {
      final response = await _makeRpcCall('eth_getTransactionByHash', [txHash]);
      if (response != null &&
          response.containsKey('to') &&
          response['to'] != null &&
          response['to'].toString().toLowerCase() ==
              _pyusdContractAddress.toLowerCase()) {
        // This is a PYUSD transaction
        _recentPyusdTransactions.insert(0, response);
        if (_recentPyusdTransactions.length > 20) {
          _recentPyusdTransactions.removeLast();
        }

        _congestionData = _congestionData.copyWith(
            pendingPyusdTxCount: _congestionData.pendingPyusdTxCount + 1);

        notifyListeners();
      }
    } catch (e) {
      print('Error checking transaction: $e');
    }
  }

  //More efficient network stats fetching
  Future<void> _fetchNetworkStats() async {
    try {
      // Create a list of promises for parallel execution
      final futures = <Future>[];

      // Get gas price
      futures.add(_fetchGasPrice());

      // Get pending transactions count
      futures.add(_fetchPendingTransactions());

      // Get latest block
      futures.add(_fetchLatestBlock());

      // Wait for all requests to complete
      await Future.wait(futures);

      // Update last refreshed time
      _congestionData = _congestionData.copyWith(
        lastRefreshed: DateTime.now(),
      );

      notifyListeners();
    } catch (e) {
      print('Error fetching network stats: $e');
    }
  }

  Future<void> _fetchGasPrice() async {
    try {
      final gasPriceResponse = await _makeRpcCall('eth_gasPrice', []);
      final gasPrice = _parseHexSafely(gasPriceResponse);

      if (gasPrice != null) {
        final gasPriceGwei = gasPrice / 1e9;

        // Add to historical data
        List<double> updatedHistory =
            List.from(_congestionData.historicalGasPrices);
        updatedHistory.add(gasPriceGwei);
        if (updatedHistory.length > 20) {
          updatedHistory.removeAt(0);
        }

        // Calculate average gas price
        double avgGasPrice = updatedHistory.isEmpty
            ? gasPriceGwei
            : updatedHistory.reduce((a, b) => a + b) / updatedHistory.length;

        _congestionData = _congestionData.copyWith(
            currentGasPrice: gasPriceGwei,
            averageGasPrice: avgGasPrice,
            historicalGasPrices: updatedHistory);
      }
    } catch (e) {
      print('Error fetching gas price: $e');
    }
  }

  Future<void> _fetchPendingTransactions() async {
    try {
      final txpoolStatusResponse = await _makeRpcCall('txpool_status', []);
      if (txpoolStatusResponse != null &&
          txpoolStatusResponse.containsKey('pending')) {
        final pendingHex = txpoolStatusResponse['pending'];
        final pendingTxCount = _parseHexSafely(pendingHex);

        if (pendingTxCount != null) {
          _congestionData =
              _congestionData.copyWith(pendingTransactions: pendingTxCount);
        }
      }
    } catch (e) {
      print('Error fetching pending transactions: $e');
    }
  }

  Future<void> _fetchLatestBlock() async {
    try {
      // Measure network latency
      final startTime = DateTime.now();

      final latestBlockResponse =
          await _makeRpcCall('eth_getBlockByNumber', ['latest', false]);

      final endTime = DateTime.now();
      final latencyMs = endTime.difference(startTime).inMilliseconds;
      _congestionData =
          _congestionData.copyWith(networkLatency: latencyMs.toDouble());

      if (latestBlockResponse != null) {
        // Gas limit and gas used
        final gasLimit = _parseHexSafely(latestBlockResponse['gasLimit']);
        final gasUsed = _parseHexSafely(latestBlockResponse['gasUsed']);

        if (gasLimit != null && gasUsed != null) {
          final gasUsagePercentage = (gasUsed / gasLimit) * 100;
          _congestionData =
              _congestionData.copyWith(gasUsagePercentage: gasUsagePercentage);
        }

        // Extract timestamp from latest block
        final timestamp = _parseHexSafely(latestBlockResponse['timestamp']);
        if (timestamp != null) {
          _congestionData = _congestionData.copyWith(
            lastBlockTimestamp: timestamp,
          );
        }

        // Extract block number
        final blockNumber = _parseHexSafely(latestBlockResponse['number']);
        if (blockNumber != null) {
          _congestionData = _congestionData.copyWith(
            lastBlockNumber: blockNumber,
          );
        }
      }
    } catch (e) {
      print('Error fetching latest block: $e');
    }
  }

  Future<void> _fetchBlockInfo(int blockNumber) async {
    try {
      final blockHex = '0x${blockNumber.toRadixString(16)}';
      final response =
          await _makeRpcCall('eth_getBlockByNumber', [blockHex, true]);

      if (response != null) {
        // Add to recent blocks
        _recentBlocks.insert(0, response);
        if (_recentBlocks.length > 10) {
          _recentBlocks.removeLast();
        }

        // Calculate block time
        if (_recentBlocks.length >= 2) {
          final currentTimestamp =
              _parseHexSafely(_recentBlocks[0]['timestamp']);
          final previousTimestamp =
              _parseHexSafely(_recentBlocks[1]['timestamp']);

          if (currentTimestamp != null && previousTimestamp != null) {
            final blockTime = currentTimestamp - previousTimestamp;
            _congestionData =
                _congestionData.copyWith(blockTime: blockTime.toDouble());

            // Update last block timestamp
            _congestionData = _congestionData.copyWith(
              lastBlockTimestamp: currentTimestamp,
            );
          }
        }

        // Recalculate average block size
        int totalSize = 0;
        for (var block in _recentBlocks) {
          if (block.containsKey('transactions') &&
              block['transactions'] is List) {
            final txs = block['transactions'] as List;
            totalSize += txs.length * 250; // Approximate size
          }
        }

        if (_recentBlocks.isNotEmpty) {
          final avgBlockSize = totalSize / _recentBlocks.length;
          _congestionData = _congestionData.copyWith(
            averageBlockSize: avgBlockSize,
          );
        }

        // Check for PYUSD transactions in this block
        await _calculateBlockStatistics();

        _countPyusdTransactionsInBlock(response);

        notifyListeners();
      }
    } catch (e) {
      print('Error fetching block info: $e');
    }
  }

  void _countPyusdTransactionsInBlock(Map<String, dynamic> block) {
    try {
      int pyusdTxCount = 0;
      if (block.containsKey('transactions') && block['transactions'] is List) {
        for (var tx in block['transactions']) {
          if (tx['to'] != null &&
              tx['to'].toString().toLowerCase() ==
                  _pyusdContractAddress.toLowerCase()) {
            pyusdTxCount++;

            // Add to recent transactions if not already there
            if (!_recentPyusdTransactions.any((t) => t['hash'] == tx['hash'])) {
              _recentPyusdTransactions.insert(0, tx);
              if (_recentPyusdTransactions.length > 20) {
                _recentPyusdTransactions.removeLast();
              }
            }
          }
        }
      }

      if (pyusdTxCount > 0) {
        _congestionData = _congestionData.copyWith(
            confirmedPyusdTxCount:
                _congestionData.confirmedPyusdTxCount + pyusdTxCount,
            pendingPyusdTxCount:
                _congestionData.pendingPyusdTxCount - pyusdTxCount < 0
                    ? 0
                    : _congestionData.pendingPyusdTxCount - pyusdTxCount);

        notifyListeners();
      }
    } catch (e) {
      print('Error counting PYUSD transactions in block: $e');
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _wsChannel?.sink.close();
    super.dispose();
  }

  int min(int a, int b) => a < b ? a : b;

  int? _parseHexSafely(dynamic hexValue) {
    try {
      if (hexValue == null ||
          hexValue is! String ||
          !hexValue.startsWith('0x')) {
        print('Invalid hex value: $hexValue');
        return null;
      }
      return int.tryParse(hexValue.substring(2), radix: 16);
    } catch (e) {
      print('Error parsing hex value: $hexValue, error: $e');
      return null;
    }
  }
}
