import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pyusd_hub/utils/formatter_utils.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../config/rpc_endpoints.dart';
import '../../../services/notification_service.dart';
import '../model/networkcongestion_model.dart';
import '../../../services/rpc_call_service.dart';

class NetworkCongestionProvider with ChangeNotifier {
  static const int MAX_RECENT_BLOCKS = 10;
  static const int MAX_RECENT_TRANSACTIONS = 50;
  static const int MAX_HISTORICAL_GAS_PRICES = 20;
  static const int MAX_TRANSACTION_RECEIPT_CACHE_SIZE = 100;

  // RPC endpoints
  final String _httpRpcUrl = RpcEndpoints.mainnetHttpRpcUrl;
  final String _wsRpcUrl = RpcEndpoints.mainnetWssRpcUrl;

  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  Timer? _updateTimer;
  Timer? _slowUpdateTimer;
  int _requestId = 1;
  bool _isDisposed = false;
  bool _isFullyInitialized = false;
  bool _isInitializing = false;

  bool _isWebSocketConnected = false;
  String? _connectionError;

  // Add getters
  bool get isWebSocketConnected => _isWebSocketConnected;
  String? get connectionError => _connectionError;

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
    networkVersion: '',
    peerCount: 0,
    isNetworkListening: false,
    badBlocks: const [],
    txPoolInspection: const {},
  );

  NetworkCongestionData get congestionData => _congestionData;
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  late List<Map<String, dynamic>> _recentBlocks = [];
  List<Map<String, dynamic>> get recentBlocks => _recentBlocks;

  late List<Map<String, dynamic>> _recentPyusdTransactions = [];
  List<Map<String, dynamic>> get recentPyusdTransactions =>
      _recentPyusdTransactions;

  // Cache for transaction receipts to reduce RPC calls
  final Map<String, Map<String, dynamic>> _transactionReceiptCache = {};

  // Gas price notification settings
  double _gasPriceThreshold = 10.0;
  bool _gasPriceNotificationsEnabled = true;
  final NotificationService _notificationService = NotificationService();

  double get gasPriceThreshold => _gasPriceThreshold;
  bool get gasPriceNotificationsEnabled => _gasPriceNotificationsEnabled;

  final http.Client _httpClient = http.Client();
  final RpcCallService _rpcService = RpcCallService();

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool hasError = false;

  void setGasPriceThreshold(double threshold) {
    if (_isDisposed) return;
    _gasPriceThreshold = threshold;
    _safeNotifyListeners();
  }

  void toggleGasPriceNotifications(bool enabled) {
    if (_isDisposed) return;
    _gasPriceNotificationsEnabled = enabled;
    _safeNotifyListeners();
  }

  Future<dynamic> _makeRpcCall(String method, List<dynamic> params) async {
    try {
      final response =
          await _rpcService.makeRpcCall(_httpRpcUrl, method, params);

      if (response.containsKey('error') && response['error'] != null) {
        print('RPC error in NetworkCongestionProvider: ${response['error']}');
        return null;
      }

      return response['result'];
    } catch (e) {
      print('Error in _makeRpcCall: $e');
      return null;
    }
  }

  Future<void> refresh() async {
    if (_isDisposed) return;

    _isLoading = true;
    _safeNotifyListeners();

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

      if (_isDisposed) return;

      // Update last refreshed time
      _congestionData = _congestionData.copyWith(
        lastRefreshed: DateTime.now(),
      );

      // Clean up transaction receipt cache
      _cleanupTransactionReceiptCache();
    } catch (e) {
      print('Error during refresh: $e');
    }

    if (_isDisposed) return;
    _isLoading = false;
    _safeNotifyListeners();
  }

  Future<void> initialize() async {
    if (_isDisposed || _isInitializing) return;

    _isInitializing = true;
    _isLoading = true;
    _safeNotifyListeners();

    try {
      // First fetch only critical data for initial display
      await Future.wait([
        _fetchGasPrice(),
        _fetchLatestBlock(),
        _fetchPendingTransactions(),
        _fetchNetworkStatus(),
      ]);

      if (_isDisposed) return;

      // Connect WebSocket after initial data is loaded
      _setupWebSocket();

      // Immediately calculate block statistics to show avg block time and blocks/hour
      await _fetchInitialBlocks();
      await _calculateBlockStatistics();

      // Setup periodic updates with longer intervals
      _updateTimer?.cancel();
      _updateTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
        if (_isDisposed) {
          timer.cancel();
          return;
        }

        await _fetchNetworkStats();
        if (_isDisposed) return;

        await _fetchLatestBlocksUpdate();
        if (_isDisposed) return;

        await _fetchNetworkStatus();
        if (_isDisposed) return;

        // Update last refreshed timestamp
        _congestionData = _congestionData.copyWith(
          lastRefreshed: DateTime.now(),
        );

        // Fetch pending queue details every 45s
        if (timer.tick % 3 == 0) {
          await _fetchPendingQueueDetails();
        }

        // Periodically update PYUSD transaction data
        if (timer.tick % 4 == 0) {
          await _fetchPyusdTransactionActivity();
        }
      });

      // Start fetching additional data in the background
      _fetchPyusdTransactionActivity();

      if (_isDisposed) return;
      _isLoading = false;
      _safeNotifyListeners();
    } catch (e) {
      print('NetworkCongestionProvider: Initialization error: $e');
      if (_isDisposed) return;
      _isLoading = false;
      _safeNotifyListeners();
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _fetchLatestBlocksUpdate() async {
    try {
      final latestBlockResponse = await _makeRpcCall('eth_blockNumber', []);
      if (latestBlockResponse == null) {
        print('Failed to get latest block number: null response');
        return;
      }

      final latestBlockNumber =
          FormatterUtils.parseHexSafely(latestBlockResponse);

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
          : FormatterUtils.parseHexSafely(_recentBlocks[0]['number']);

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

        // Don't fetch more than 100 blocks at once to avoid overloading
        int blocksAvailable = latestBlockNumber - oldestBlockToFetch + 1;
        int numBlocksToFetch =
            blocksAvailable > 0 ? min(30, blocksAvailable) : 0;

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
          List<Map<String, dynamic>> newBlocks = [];
          for (var blockResponse in blockResponses) {
            if (blockResponse != null) {
              newBlocks.add(blockResponse);
            }
          }

          // Sort blocks by block number in descending order
          newBlocks.sort((a, b) {
            final blockNumberA =
                FormatterUtils.parseHexSafely(a['number']) ?? 0;
            final blockNumberB =
                FormatterUtils.parseHexSafely(b['number']) ?? 0;
            return blockNumberB.compareTo(blockNumberA);
          });

          // Add sorted blocks to the list
          for (var block in newBlocks) {
            // Insert at the beginning to maintain newest-first order
            _recentBlocks.insert(0, block);

            // Keep only the 30 most recent blocks
            if (_recentBlocks.length > 30) {
              _recentBlocks.removeLast();
            }

            // Check for PYUSD transactions in this block
            _countPyusdTransactionsInBlock(block);
          }

          // Recalculate block statistics after fetching new blocks
          await _calculateBlockStatistics();

          // Update block time if we have at least 2 blocks
          if (_recentBlocks.length >= 2) {
            final currentTimestamp =
                FormatterUtils.parseHexSafely(_recentBlocks[0]['timestamp']);
            final previousTimestamp =
                FormatterUtils.parseHexSafely(_recentBlocks[1]['timestamp']);

            if (currentTimestamp != null && previousTimestamp != null) {
              final blockTime = currentTimestamp - previousTimestamp;
              if (blockTime > 0) {
                // Only update if we have a valid block time
                _congestionData = _congestionData.copyWith(
                  blockTime: blockTime.toDouble(),
                  lastBlockTimestamp: currentTimestamp,
                );
              }
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
      // First try txpool_status which is more widely supported
      final txpoolStatusResponse = await _makeRpcCall('txpool_status', []);

      int pendingCount = 0;
      int queuedCount = 0;
      int pyusdPendingCount = 0;
      int pyusdQueuedCount = 0;
      double totalPyusdGasPrice = 0;
      int pyusdTxCount = 0;

      if (txpoolStatusResponse != null) {
        // Parse pending count
        if (txpoolStatusResponse.containsKey('pending')) {
          final pendingHex = txpoolStatusResponse['pending'];
          pendingCount = FormatterUtils.parseHexSafely(pendingHex) ?? 0;
        }

        // Parse queued count
        if (txpoolStatusResponse.containsKey('queued')) {
          final queuedHex = txpoolStatusResponse['queued'];
          queuedCount = FormatterUtils.parseHexSafely(queuedHex) ?? 0;
        }
      }

      // Then try to get detailed content if available
      try {
        final txpoolContentResponse = await _makeRpcCall('txpool_content', []);
        if (txpoolContentResponse != null) {
          // Process pending transactions
          if (txpoolContentResponse.containsKey('pending')) {
            final pendingMap =
                txpoolContentResponse['pending'] as Map<String, dynamic>;
            for (final address in pendingMap.keys) {
              final addressTxs = pendingMap[address] as Map<String, dynamic>;
              for (var tx in addressTxs.values) {
                if (tx['to']?.toString().toLowerCase() ==
                    _pyusdContractAddress.toLowerCase()) {
                  pyusdPendingCount++;
                  if (tx['gasPrice'] != null) {
                    totalPyusdGasPrice +=
                        FormatterUtils.parseHexSafely(tx['gasPrice']) ?? 0;
                    pyusdTxCount++;
                  }
                }
              }
            }
          }

          // Process queued transactions
          if (txpoolContentResponse.containsKey('queued')) {
            final queuedMap =
                txpoolContentResponse['queued'] as Map<String, dynamic>;
            for (final address in queuedMap.keys) {
              final addressTxs = queuedMap[address] as Map<String, dynamic>;
              for (var tx in addressTxs.values) {
                if (tx['to']?.toString().toLowerCase() ==
                    _pyusdContractAddress.toLowerCase()) {
                  pyusdQueuedCount++;
                }
              }
            }
          }
        }
      } catch (e) {
        // If txpool_content is not supported, estimate PYUSD transactions
        // based on the ratio of total transactions
        if (pendingCount > 0) {
          pyusdPendingCount =
              (pendingCount * 0.01).round(); // Estimate 1% are PYUSD
        }
        if (queuedCount > 0) {
          pyusdQueuedCount =
              (queuedCount * 0.1).round(); // Estimate 10% are PYUSD
        }
      }

      // Calculate average PYUSD transaction fee
      double averagePyusdFee =
          pyusdTxCount > 0 ? totalPyusdGasPrice / pyusdTxCount : 0;

      // Update congestion data with both total and PYUSD-specific queue sizes
      _congestionData = _congestionData.copyWith(
        pendingQueueSize: pendingCount + queuedCount,
        pyusdPendingQueueSize: pyusdPendingCount + pyusdQueuedCount,
        averagePyusdTransactionFee: averagePyusdFee,
        pendingPyusdTxCount: pyusdPendingCount, // Update pending count
      );

      // Log the results for debugging
      print('Pending Queue Status:');
      print('Total Pending: $pendingCount');
      print('Total Queued: $queuedCount');
      print('PYUSD Pending: $pyusdPendingCount');
      print('PYUSD Queued: $pyusdQueuedCount');
      print('Average PYUSD Fee: $averagePyusdFee Gwei');
    } catch (e) {
      print('Error fetching pending queue details: $e');
      // Set fallback values
      _congestionData = _congestionData.copyWith(
        pendingQueueSize: 0,
        pyusdPendingQueueSize: 0,
        averagePyusdTransactionFee: 0,
        pendingPyusdTxCount: 0,
      );
    }
  }

  Future<void> _calculateBlockStatistics() async {
    try {
      if (_recentBlocks.length < 2) return;

      // Create a copy of the list to avoid concurrent modification
      final blocksCopy = List<Map<String, dynamic>>.from(_recentBlocks);

      int totalSize = 0;
      int pyusdSize = 0;
      int totalTxs = 0;
      int pyusdTxs = 0;
      double totalPyusdGasUsed = 0;
      double totalPyusdGasPrice = 0;
      List<double> pyusdGasPrices = [];

      // Calculate block times and statistics
      List<double> blockTimes = [];
      for (int i = 0; i < blocksCopy.length - 1; i++) {
        final currentTimestamp =
            FormatterUtils.parseHexSafely(blocksCopy[i]['timestamp']);
        final previousTimestamp =
            FormatterUtils.parseHexSafely(blocksCopy[i + 1]['timestamp']);

        if (currentTimestamp != null && previousTimestamp != null) {
          final blockTime = currentTimestamp - previousTimestamp;
          if (blockTime > 0 && blockTime < 30) {
            // Only include reasonable block times (0-30 seconds)
            blockTimes.add(blockTime.toDouble());
          }
        }
      }

      // Calculate average block time with validation
      double averageBlockTime = 0;
      if (blockTimes.isNotEmpty) {
        // Remove outliers (blocks that took more than 2x the median)
        blockTimes.sort();
        final median = blockTimes[blockTimes.length ~/ 2];
        final filteredTimes =
            blockTimes.where((time) => time <= median * 2).toList();

        if (filteredTimes.isNotEmpty) {
          averageBlockTime =
              filteredTimes.reduce((a, b) => a + b) / filteredTimes.length;
        }
      }

      // Calculate blocks per hour with validation
      double blocksPerHour = 0;
      if (averageBlockTime > 0) {
        blocksPerHour = 3600 / averageBlockTime;
      }

      // Calculate blocks per minute
      double blocksPerMinute = 0;
      if (averageBlockTime > 0) {
        blocksPerMinute = 60 / averageBlockTime;
      }

      // Calculate other block statistics
      for (var block in blocksCopy) {
        if (block.containsKey('transactions') &&
            block['transactions'] is List) {
          final txs = block['transactions'] as List;
          totalTxs += txs.length;
          totalSize += txs.length * 250; // Approximate size

          // Calculate PYUSD-specific metrics
          for (var tx in txs) {
            if (tx['to']?.toString().toLowerCase() ==
                _pyusdContractAddress.toLowerCase()) {
              pyusdTxs++;
              pyusdSize += 250; // Approximate size

              // Get transaction receipt for gas metrics
              final receipt = await _getTransactionReceipt(tx['hash']);
              if (receipt != null) {
                final gasUsed =
                    FormatterUtils.parseHexSafely(receipt['gasUsed']) ?? 0;
                final gasPrice =
                    FormatterUtils.parseHexSafely(tx['gasPrice']) ?? 0;
                totalPyusdGasUsed += gasUsed;
                totalPyusdGasPrice += gasPrice;
                pyusdGasPrices.add(gasPrice / 1e9); // Convert to Gwei
              }
            }
          }
        }
      }

      if (blocksCopy.isNotEmpty) {
        final avgBlockSize = totalSize / blocksCopy.length;
        final avgPyusdBlockSize = pyusdSize / blocksCopy.length;
        final avgPyusdGasUsed = pyusdTxs > 0 ? totalPyusdGasUsed / pyusdTxs : 0;
        final avgPyusdGasPrice =
            pyusdTxs > 0 ? totalPyusdGasPrice / pyusdTxs : 0;
        final avgTxPerBlock = (totalTxs / blocksCopy.length).round();

        // Get gas limit from the latest block
        final gasLimit =
            FormatterUtils.parseHexSafely(blocksCopy[0]['gasLimit']) ?? 0;

        _congestionData = _congestionData.copyWith(
          averageBlockSize: avgBlockSize,
          averagePyusdBlockSize: avgPyusdBlockSize,
          pyusdGasUsagePercentage: avgPyusdGasUsed.toDouble(),
          averagePyusdTransactionFee: avgPyusdGasPrice.toDouble(),
          pyusdHistoricalGasPrices: pyusdGasPrices,
          averageBlockTime: averageBlockTime,
          blocksPerHour: blocksPerHour.round(),
          blocksPerMinute: blocksPerMinute,
          averageTxPerBlock: avgTxPerBlock,
          gasLimit: gasLimit,
        );
      }
    } catch (e) {
      print('Error calculating block statistics: $e');
    }
  }

  // Main method to fetch PYUSD transactions using RPC
  Future<void> _fetchPyusdTransactionActivity() async {
    try {
      // Get the latest block number
      final latestBlockResponse = await _makeRpcCall('eth_blockNumber', []);
      if (latestBlockResponse == null) {
        print(
            'Failed to get latest block number for PYUSD activity: null response');
        return;
      }

      final latestBlockNumber =
          FormatterUtils.parseHexSafely(latestBlockResponse);

      if (latestBlockNumber == null) {
        print('Could not get latest block number for PYUSD activity');
        return;
      }

      // Calculate the block range to search for PYUSD transactions
      // Look back about 10,000 blocks (approximately 1-2 days)
      final fromBlock = max(0, latestBlockNumber - 10000);
      final fromBlockHex = '0x${fromBlock.toRadixString(16)}';
      final toBlockHex = '0x${latestBlockNumber.toRadixString(16)}';

      // Get logs for PYUSD Transfer events
      final logsResponse = await _makeRpcCall('eth_getLogs', [
        {
          'fromBlock': fromBlockHex,
          'toBlock': toBlockHex,
          'address': _pyusdContractAddress,
          'topics': [_transferEventSignature],
        }
      ]);

      if (logsResponse == null) {
        print('Failed to get logs for PYUSD activity: null response');
        return;
      }

      if (!(logsResponse is List)) {
        print('Invalid logs response for PYUSD activity');
        return;
      }

      // Process the logs to extract transaction data
      final logs = logsResponse as List;
      int pyusdTxCount = 0;

      // Create a set of existing transaction hashes for quick lookup
      final existingTxHashes = _recentPyusdTransactions
          .map((tx) => tx['hash']?.toString().toLowerCase() ?? '')
          .toSet();

      for (var log in logs) {
        try {
          final String txHash = log['transactionHash'] ?? '';

          // Skip if we already have this transaction
          if (txHash.isEmpty ||
              existingTxHashes.contains(txHash.toLowerCase())) {
            continue;
          }

          // Get the full transaction details
          final txResponse =
              await _makeRpcCall('eth_getTransactionByHash', [txHash]);

          if (txResponse == null) continue;

          // Get the transaction receipt for status and other details
          final receiptResponse =
              await _makeRpcCall('eth_getTransactionReceipt', [txHash]);

          // Create an enriched transaction object
          Map<String, dynamic> enrichedTx =
              Map<String, dynamic>.from(txResponse);

          // Add receipt data if available
          if (receiptResponse != null) {
            enrichedTx['status'] = receiptResponse['status'];
            enrichedTx['gasUsed'] = receiptResponse['gasUsed'];
            enrichedTx['blockNumber'] = receiptResponse['blockNumber'];
          }

          // Extract PYUSD amount from input data
          if (txResponse['input'] != null &&
              txResponse['input'].toString().length >= 138 &&
              txResponse['input'].toString().startsWith('0xa9059cbb')) {
            try {
              // Extract recipient address (32 bytes after method ID)
              final String recipient =
                  '0x' + txResponse['input'].toString().substring(34, 74);

              // Extract value (32 bytes after recipient)
              final String valueHex =
                  txResponse['input'].toString().substring(74);
              final BigInt tokenValueBigInt =
                  FormatterUtils.parseBigInt("0x$valueHex");

              // Convert to PYUSD with 6 decimals
              final double tokenValue =
                  tokenValueBigInt / BigInt.from(10).pow(6);

              // Add these fields to the transaction
              enrichedTx['tokenValue'] = tokenValue;
              enrichedTx['tokenRecipient'] = recipient;
              enrichedTx['isTokenTransfer'] = true;
            } catch (e) {
              print('Error extracting PYUSD transfer data: $e');
              enrichedTx['tokenValue'] = 0.0;
              enrichedTx['isTokenTransfer'] = true;
            }
          } else {
            enrichedTx['tokenValue'] = 0.0;
            enrichedTx['isTokenTransfer'] = false;
          }

          // Get block timestamp
          if (enrichedTx['blockNumber'] != null) {
            final blockHex = enrichedTx['blockNumber'];
            final blockResponse =
                await _makeRpcCall('eth_getBlockByNumber', [blockHex, false]);

            if (blockResponse != null && blockResponse['timestamp'] != null) {
              enrichedTx['timestamp'] = blockResponse['timestamp'];
            }
          }

          // Add to recent transactions
          _recentPyusdTransactions.insert(0, enrichedTx);
          if (_recentPyusdTransactions.length > MAX_RECENT_TRANSACTIONS) {
            _recentPyusdTransactions.removeLast();
          }

          pyusdTxCount++;
        } catch (e) {
          print('Error processing PYUSD transaction log: $e');
        }
      }

      // Update PYUSD transaction count
      if (pyusdTxCount > 0) {
        _congestionData = _congestionData.copyWith(
          pyusdTransactionCount:
              _congestionData.pyusdTransactionCount + pyusdTxCount,
        );

        _safeNotifyListeners();
      }
    } catch (e) {
      print('Error fetching PYUSD transaction activity: $e');
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

      // Get the logs for this transaction to get the actual transfer amount
      final logs = await _makeRpcCall('eth_getTransactionReceipt', [txHash]);
      if (logs != null && logs['logs'] != null) {
        for (var log in logs['logs']) {
          if (log['address']?.toString().toLowerCase() ==
              _pyusdContractAddress.toLowerCase()) {
            // Use the data field from the log as it contains the actual transfer amount
            tx['value'] = log['data'];
            break;
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
        if (_transactionReceiptCache.length >
            MAX_TRANSACTION_RECEIPT_CACHE_SIZE) {
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
      print(
          'Extracting PYUSD transactions from ${_recentBlocks.length} blocks');

      if (pyusdTxCount > 0) {
        notifyListeners();
      }
    } catch (e) {
      print('Error extracting PYUSD transactions from recent blocks: $e');
    }
  }

  // OPTIMIZED: Fetch blocks in batch with reduced initial load
  Future<void> _fetchInitialBlocks() async {
    try {
      final latestBlockResponse = await _makeRpcCall('eth_blockNumber', []);
      final latestBlockNumber =
          FormatterUtils.parseHexSafely(latestBlockResponse);

      if (latestBlockNumber == null) {
        print('Could not get latest block number');
        return;
      }

      // Update last block number
      _congestionData = _congestionData.copyWith(
        lastBlockNumber: latestBlockNumber,
      );

      // Fetch the last 10 blocks
      final int numBlocksToFetch = 10;
      List<Future<Map<String, dynamic>?>> blockFutures = [];

      for (int i = 0; i < numBlocksToFetch; i++) {
        final blockNumber = latestBlockNumber - i;
        if (blockNumber < 0) break;

        final blockHex = '0x${blockNumber.toRadixString(16)}';
        blockFutures.add(_fetchBlock(blockHex));
      }

      final blockResponses = await Future.wait(blockFutures);

      // Process the blocks
      for (var blockResponse in blockResponses) {
        if (blockResponse != null) {
          // Insert at the beginning to maintain newest-first order
          _recentBlocks.insert(0, blockResponse);

          // Check for PYUSD transactions in this block
          _countPyusdTransactionsInBlock(blockResponse);
        }
      }

      // Sort blocks by block number in descending order
      _recentBlocks.sort((a, b) {
        final blockNumberA = FormatterUtils.parseHexSafely(a['number']) ?? 0;
        final blockNumberB = FormatterUtils.parseHexSafely(b['number']) ?? 0;
        return blockNumberB.compareTo(blockNumberA);
      });

      // Keep only the most recent blocks
      if (_recentBlocks.length > MAX_RECENT_BLOCKS) {
        _recentBlocks.length = MAX_RECENT_BLOCKS;
      }

      // Calculate block statistics after fetching blocks
      await _calculateBlockStatistics();

      _safeNotifyListeners();
    } catch (e) {
      print('Error fetching initial blocks: $e');
    }
  }

  // Helper function to fetch a single block
  Future<Map<String, dynamic>?> _fetchBlock(String blockHex) async {
    try {
      final result =
          await _makeRpcCall('eth_getBlockByNumber', [blockHex, true]);
      if (result == null) {
        print('Failed to fetch block $blockHex: null response');
        return null;
      }
      return result;
    } catch (e) {
      print('Error fetching block $blockHex: $e');
      return null;
    }
  }

  void _setupWebSocket() {
    if (_isDisposed) return;

    try {
      _wsChannel?.sink.close();
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

      _wsSubscription = _wsChannel!.stream.listen(
        (message) {
          if (_isDisposed) return;
          final data = json.decode(message);
          if (data['method'] == 'eth_subscription') {
            _handleSubscriptionUpdate(data['params']);
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          if (!_isDisposed) {
            _reconnectWebSocket();
          }
        },
        onDone: () {
          print('WebSocket connection closed');
          if (!_isDisposed) {
            _reconnectWebSocket();
          }
        },
      );
    } catch (e) {
      print('WebSocket connection error: $e');
      if (!_isDisposed) {
        _reconnectWebSocket();
      }
    }
  }

  void _reconnectWebSocket() {
    if (_isDisposed) return;

    _wsChannel?.sink.close();
    _wsChannel = null;
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isDisposed) {
        _setupWebSocket();
      }
    });
  }

  void _handleSubscriptionUpdate(Map<String, dynamic> params) {
    final result = params['result'];

    if (result.containsKey('hash')) {
      // This is a new transaction
      _checkIfPyusdTransaction(result['hash']);
    } else if (result.containsKey('number')) {
      // This is a new block
      final blockNumber = FormatterUtils.parseHexSafely(result['number']);
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
        if (_recentPyusdTransactions.length > MAX_RECENT_TRANSACTIONS) {
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
      if (gasPriceResponse == null) {
        print('Failed to get gas price: null response');
        return;
      }

      final gasPrice = FormatterUtils.parseHexSafely(gasPriceResponse);

      if (gasPrice != null) {
        final gasPriceGwei = gasPrice / 1e9;

        // Add to historical data
        List<double> updatedHistory =
            List.from(_congestionData.historicalGasPrices);
        updatedHistory.add(gasPriceGwei);
        if (updatedHistory.length > MAX_HISTORICAL_GAS_PRICES) {
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

        // Check for low gas price notification
        if (_gasPriceNotificationsEnabled &&
            gasPriceGwei < _gasPriceThreshold) {
          await _notificationService.showGasPriceNotification(
            currentGasPrice: gasPriceGwei,
            thresholdGasPrice: _gasPriceThreshold,
            averageGasPrice: avgGasPrice,
          );
        }
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
        final pendingTxCount = FormatterUtils.parseHexSafely(pendingHex);

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
        final gasLimit =
            FormatterUtils.parseHexSafely(latestBlockResponse['gasLimit']);
        final gasUsed =
            FormatterUtils.parseHexSafely(latestBlockResponse['gasUsed']);

        if (gasLimit != null && gasUsed != null) {
          final gasUsagePercentage = (gasUsed / gasLimit) * 100;
          _congestionData =
              _congestionData.copyWith(gasUsagePercentage: gasUsagePercentage);
        }

        // Extract timestamp from latest block
        final timestamp =
            FormatterUtils.parseHexSafely(latestBlockResponse['timestamp']);
        if (timestamp != null) {
          _congestionData = _congestionData.copyWith(
            lastBlockTimestamp: timestamp,
          );
        }

        // Extract block number
        final blockNumber =
            FormatterUtils.parseHexSafely(latestBlockResponse['number']);
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
        if (_recentBlocks.length > MAX_RECENT_BLOCKS) {
          _recentBlocks.removeLast();
        }

        // Calculate block time
        if (_recentBlocks.length >= 2) {
          final currentTimestamp =
              FormatterUtils.parseHexSafely(_recentBlocks[0]['timestamp']);
          final previousTimestamp =
              FormatterUtils.parseHexSafely(_recentBlocks[1]['timestamp']);

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

            // Process the transaction to extract PYUSD amount
            Map<String, dynamic> enrichedTx = Map<String, dynamic>.from(tx);

            // Extract PYUSD amount from input data if it's a token transfer
            if (tx['input'] != null &&
                tx['input'].toString().length >= 138 &&
                tx['input'].toString().startsWith('0xa9059cbb')) {
              try {
                // Extract recipient address (32 bytes after method ID)
                final String recipient =
                    '0x' + tx['input'].toString().substring(34, 74);

                // Extract value (32 bytes after recipient)
                final String valueHex = tx['input'].toString().substring(74);
                final BigInt tokenValueBigInt =
                    FormatterUtils.parseBigInt("0x$valueHex");

                // Convert to PYUSD with 6 decimals
                final double tokenValue =
                    tokenValueBigInt / BigInt.from(10).pow(6);

                // Add these fields to the transaction
                enrichedTx['tokenValue'] = tokenValue;
                enrichedTx['tokenRecipient'] = recipient;
                enrichedTx['isTokenTransfer'] = true;
              } catch (e) {
                print('Error extracting PYUSD transfer data: $e');
                enrichedTx['tokenValue'] = 0.0;
                enrichedTx['isTokenTransfer'] = true;
              }
            } else {
              enrichedTx['tokenValue'] = 0.0;
              enrichedTx['isTokenTransfer'] = false;
            }

            // Add timestamp from block
            if (block['timestamp'] != null) {
              enrichedTx['timestamp'] = block['timestamp'];
            }

            // Add to recent transactions if not already there
            if (!_recentPyusdTransactions.any((t) => t['hash'] == tx['hash'])) {
              _recentPyusdTransactions.insert(0, enrichedTx);
              if (_recentPyusdTransactions.length > MAX_RECENT_TRANSACTIONS) {
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
    print('NetworkCongestionProvider: dispose called');
    _isDisposed = true;
    _updateTimer?.cancel();
    _slowUpdateTimer?.cancel();
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
    _httpClient.close();
    super.dispose();
  }

  int min(int a, int b) => a < b ? a : b;

  Future<Map<String, dynamic>> analyzeNetworkHealth() async {
    try {
      Map<String, double> health = {
        'networkCongestion': 0,
        'gasEfficiency': 0,
        'transactionSuccessRate': 0,
        'averageConfirmationTime': 0,
      };

      // Calculate network congestion (0-1 scale)
      health['networkCongestion'] = _congestionData.gasUsagePercentage / 100;

      // Calculate gas efficiency
      if (_congestionData.averageBlockSize > 0) {
        health['gasEfficiency'] = _congestionData.averageTxPerBlock /
            (_congestionData.gasLimit /
                21000); // Assuming standard transfer gas
      }

      // Calculate transaction success rate
      int successfulTxs = 0;
      int totalTxs = 0;
      for (var tx in _recentPyusdTransactions) {
        if (tx['status'] != null) {
          totalTxs++;
          if (tx['status'] == '0x1') {
            successfulTxs++;
          }
        }
      }
      if (totalTxs > 0) {
        health['transactionSuccessRate'] = successfulTxs / totalTxs;
      }

      // Calculate average confirmation time
      if (_congestionData.blockTime > 0) {
        health['averageConfirmationTime'] = _congestionData.blockTime *
            12; // Assuming 12 blocks for confirmation
      }

      return health;
    } catch (e) {
      print('Error analyzing network health: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> predictGasPrice() async {
    try {
      Map<String, dynamic> prediction = {
        'shortTerm': 0,
        'mediumTerm': 0,
        'confidence': 0,
        'factors': <String, double>{},
      };

      // Calculate moving averages
      final shortTermWindow = 5;
      final mediumTermWindow = 20;

      if (_congestionData.historicalGasPrices.length >= shortTermWindow) {
        final shortTermAvg = _congestionData.historicalGasPrices
                .take(shortTermWindow)
                .reduce((a, b) => a + b) /
            shortTermWindow;

        prediction['shortTerm'] = shortTermAvg;
        prediction['factors']['recentAverage'] = shortTermAvg;
      }

      if (_congestionData.historicalGasPrices.length >= mediumTermWindow) {
        final mediumTermAvg = _congestionData.historicalGasPrices
                .take(mediumTermWindow)
                .reduce((a, b) => a + b) /
            mediumTermWindow;

        prediction['mediumTerm'] = mediumTermAvg;
        prediction['factors']['historicalAverage'] = mediumTermAvg;
      }

      // Consider network congestion
      prediction['factors']['networkCongestion'] =
          _congestionData.gasUsagePercentage / 100;

      // Consider pending transactions
      prediction['factors']['pendingLoad'] =
          _congestionData.pendingTransactions / 10000; // Normalize to 0-1

      // Calculate confidence based on data points
      prediction['confidence'] = _congestionData.historicalGasPrices.length /
          20; // Max confidence at 20 points

      return prediction;
    } catch (e) {
      print('Error predicting gas price: $e');
      return {};
    }
  }

  Future<void> _fetchNetworkStatus() async {
    try {
      // Get network version
      final version = await _makeRpcCall('net_version', []);

      // Get peer count
      final peerCount = await _makeRpcCall('net_peerCount', []);

      // Get network listening status
      final isListening = await _makeRpcCall('net_listening', []);

      // Get txpool status
      final txPoolStatus = await _makeRpcCall('txpool_status', []);

      if (_isDisposed) return;

      // Update congestion data with network status
      _congestionData = _congestionData.copyWith(
        networkVersion: version?.toString() ?? '',
        peerCount: FormatterUtils.parseHexSafely(peerCount) ?? 0,
        isNetworkListening: isListening ?? false,
      );

      _safeNotifyListeners();
    } catch (e) {
      print('Error fetching network status: $e');
    }
  }

  /// Documents the data sources and update frequency for each metric
  Map<String, String> getDataSourceInfo() {
    return {
      'Gas Price': 'Updated every 15 seconds via eth_gasPrice RPC call',
      'Block Data': 'Real-time via WebSocket newHeads subscription',
      'Network Status': 'Updated every 15 seconds via net_* RPC calls',
      'PYUSD Transactions': 'Monitored via Transfer event logs',
      'Block Time':
          'Calculated from timestamp difference between consecutive blocks',
      'Network Congestion':
          'Calculated from gasUsed/gasLimit ratio in latest blocks',
      'Peer Count': 'Updated every 15 seconds via net_peerCount',
      'Historical Data': 'Maintained for last 30 blocks',
      'Update Frequency': '''
- Real-time updates for new blocks
- 15-second intervals for gas prices and network stats
- 45-second intervals for pending queue details
      ''',
    };
  }

  /// Get the timestamp of the last data update for each metric
  Map<String, DateTime> getLastUpdateTimes() {
    return {
      'lastRefreshed': _congestionData.lastRefreshed,
      'lastBlock': DateTime.fromMillisecondsSinceEpoch(
          _congestionData.lastBlockTimestamp * 1000),
    };
  }

  /// Get the confidence level for each metric (0-1)
  Map<String, double> getMetricConfidence() {
    return {
      'gasPrice': _congestionData.historicalGasPrices.length / 20,
      'networkHealth': _recentBlocks.length / 30,
      'blockTime': _congestionData.averageBlockTime > 0 ? 1.0 : 0.0,
      'peerNetwork': _congestionData.isNetworkListening ? 1.0 : 0.0,
    };
  }

  // Helper method to safely notify listeners
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      print('NetworkCongestionProvider: Notifying listeners (safe)');
      notifyListeners();
    } else {
      print(
          'NetworkCongestionProvider: Skipping notifyListeners - provider disposed');
    }
  }

  Future<void> fastInitialize() async {
    try {
      // Only fetch essential data for initial display
      await _fetchGasPrice();
      await _fetchLatestBlock();

      // Set up WebSocket for real-time updates
      _setupWebSocket();

      // Set up periodic updates
      _setupPeriodicUpdates();

      _safeNotifyListeners();
    } catch (e) {
      print('Error in fast initialization: $e');
    }
  }

  Future<void> completeInitialization() async {
    if (_isFullyInitialized) return;

    try {
      // Fetch remaining data in parallel
      await Future.wait([
        _fetchNetworkStatus(),
        _fetchPendingTransactions(),
        _fetchRecentPyusdTransactions(),
      ]);

      _isFullyInitialized = true;
      _safeNotifyListeners();
    } catch (e) {
      print('Error in complete initialization: $e');
    }
  }

  Future<void> _setupPeriodicUpdates() {
    // Cancel existing timers
    _updateTimer?.cancel();
    _slowUpdateTimer?.cancel();

    // Fast updates (15 seconds)
    _updateTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      await _fetchGasPrice();
      _safeNotifyListeners();
    });

    // Slow updates (45 seconds)
    _slowUpdateTimer =
        Timer.periodic(const Duration(seconds: 45), (timer) async {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      // Use batch request for multiple calls
      await Future.wait([
        _fetchNetworkStatus(),
        _fetchPendingTransactions(),
      ]);

      _safeNotifyListeners();
    });

    return Future.value();
  }

  Future<void> _fetchRecentPyusdTransactions() async {
    // Implementation of _fetchRecentPyusdTransactions method
    // This method should be implemented to fetch recent PYUSD transactions
    // based on the current implementation.
    // For now, we'll keep this method empty as the original implementation
    // did not include this method.
  }

  // Add a method to clean up transaction receipt cache
  void _cleanupTransactionReceiptCache() {
    if (_transactionReceiptCache.length > MAX_TRANSACTION_RECEIPT_CACHE_SIZE) {
      // Remove oldest entries (first 20% of the cache)
      final keysToRemove = _transactionReceiptCache.keys
          .take((_transactionReceiptCache.length * 0.2).ceil());
      for (final key in keysToRemove) {
        _transactionReceiptCache.remove(key);
      }
    }
  }

  // Add methods to trim data when not needed
  void trimBlocksData() {
    // Keep only the most recent blocks when not on the blocks tab
    if (_recentBlocks.length > 5) {
      _recentBlocks = _recentBlocks.take(5).toList();
    }
  }

  void trimTransactionsData() {
    // Keep only the most recent transactions when not on the transactions tab
    if (_recentPyusdTransactions.length > 20) {
      _recentPyusdTransactions = _recentPyusdTransactions.take(20).toList();
    }

    // Clear transaction receipt cache
    if (_transactionReceiptCache.length > 20) {
      _transactionReceiptCache.clear();
    }
  }

  Future<void> reconnectWebSocket() async {
    try {
      _closeWebSocket();
      await _initializeWebSocket();
      hasError = false;
      notifyListeners();
    } catch (e) {
      hasError = true;
      notifyListeners();
      rethrow;
    }
  }

  void _closeWebSocket() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isWebSocketConnected = false;
  }

  Future<void> _initializeWebSocket() async {
    if (_isWebSocketConnected) return;

    try {
      final uri = Uri.parse(_wsRpcUrl);
      _wsChannel = WebSocketChannel.connect(uri);
      _isWebSocketConnected = true;

      _wsChannel!.stream.listen(
        (data) {
          // Handle incoming data
          _reconnectWebSocket();
        },
        onError: (error) {
          print('WebSocket error: $error');
          hasError = true;
          _handleConnectionError();
        },
        onDone: () {
          print('WebSocket connection closed');
          _isWebSocketConnected = false;
          _handleConnectionError();
        },
      );
    } catch (e) {
      print('WebSocket connection error: $e');
      hasError = true;
      _handleConnectionError();
    }
  }

  void _handleConnectionError() {
    _isWebSocketConnected = false;
    // Only attempt to reconnect if we haven't already scheduled a reconnection
    if (_reconnectTimer == null || !_reconnectTimer!.isActive) {
      _reconnectTimer = Timer(const Duration(seconds: 5), () {
        reconnectWebSocket();
      });
    }
    notifyListeners();
  }

  Future<void> refreshData() async {
    // Implement your data refresh logic here
    // This could include fetching new data from APIs
    try {
      // Refresh your data sources
      await Future.wait([
        _fetchGasPrice(),
        _fetchNetworkStatus(),
        _fetchPendingTransactions(),
        _fetchRecentPyusdTransactions(),
        _fetchLatestBlock(),
        _fetchGasPrice(),
      ]);
      hasError = false;
    } catch (e) {
      hasError = true;
      rethrow;
    } finally {
      notifyListeners();
    }
  }
}
