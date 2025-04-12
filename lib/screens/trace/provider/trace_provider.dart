import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pyusd_hub/config/rpc_endpoints.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';

class TraceProvider with ChangeNotifier {
  // RPC endpoints
  final String _httpRpcUrl = RpcEndpoints.mainnetHttpRpcUrl;

  // PYUSD Contract address on Ethereum mainnet
  final String _pyusdContractAddress =
      '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8';

  int _requestId = 1;
  bool _isDisposed = false;

  // Cache for transaction traces to reduce RPC calls
  final Map<String, Map<String, dynamic>> _transactionTraceCache = {};

  // Cache for block traces
  final Map<int, Map<String, dynamic>> _blockTraceCache = {};

  // Recent traces history
  List<Map<String, dynamic>> _recentTraces = [];
  List<Map<String, dynamic>> get recentTraces => _recentTraces;

  // Recent blocks traced
  List<int> _recentBlocksTraced = [];
  List<int> get recentBlocksTraced => _recentBlocksTraced;

  // Add these variables to support undo functionality
  Map<String, dynamic>? _lastRemovedTrace;
  int? _lastRemovedIndex;

  // MEV Analysis Data
  Map<String, dynamic> _mevAnalysis = {};
  Map<String, dynamic> get mevAnalysis => _mevAnalysis;

  // MEV Event History
  List<Map<String, dynamic>> _mevEvents = [];
  List<Map<String, dynamic>> get mevEvents => _mevEvents;

  bool _isLoading = false;
  Map<String, dynamic> _traceData = {};
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  Map<String, dynamic> get traceData => _traceData;
  String get errorMessage => _errorMessage;

  TraceProvider() {
    _loadHistoryFromPrefs();
  }

  // Load history from SharedPreferences
  Future<void> _loadHistoryFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tracesJson = prefs.getString('recent_traces');
      final blocksJson = prefs.getString('recent_blocks_traced');

      if (tracesJson != null) {
        final List<dynamic> decoded = jsonDecode(tracesJson);
        _recentTraces =
            decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      if (blocksJson != null) {
        final List<dynamic> decoded = jsonDecode(blocksJson);
        _recentBlocksTraced = decoded.map((e) => e as int).toList();
      }

      // Also load cached traces
      final txTracesJson = prefs.getString('tx_trace_cache');
      if (txTracesJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(txTracesJson);
        decoded.forEach((key, value) {
          _transactionTraceCache[key] = Map<String, dynamic>.from(value);
        });
      }

      _safeNotifyListeners();
    } catch (e) {
      print('Error loading history from prefs: $e');
    }
  }

  // Save history to SharedPreferences
  Future<void> _saveHistoryToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save recent traces (limit to 20)
      if (_recentTraces.length > 20) {
        _recentTraces = _recentTraces.sublist(_recentTraces.length - 20);
      }
      await prefs.setString('recent_traces', jsonEncode(_recentTraces));

      // Save recent blocks traced (limit to 10)
      if (_recentBlocksTraced.length > 10) {
        _recentBlocksTraced =
            _recentBlocksTraced.sublist(_recentBlocksTraced.length - 10);
      }
      await prefs.setString(
          'recent_blocks_traced', jsonEncode(_recentBlocksTraced));

      // Save transaction trace cache (limit to 20 most recent)
      final Map<String, dynamic> cacheToSave = {};
      final cacheKeys = _transactionTraceCache.keys.toList();
      if (cacheKeys.length > 20) {
        cacheKeys.removeRange(0, cacheKeys.length - 20);
      }

      for (final key in cacheKeys) {
        cacheToSave[key] = _transactionTraceCache[key]!;
      }

      await prefs.setString('tx_trace_cache', jsonEncode(cacheToSave));
    } catch (e) {
      print('Error saving history to prefs: $e');
    }
  }

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
        print('HTTP error: ${response.statusCode}, Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('RPC call error: $e');
      return null;
    }
  }

  // Batch RPC calls to improve performance
  Future<List<dynamic>> _makeBatchRpcCalls(
      List<Map<String, dynamic>> calls) async {
    try {
      final List<Map<String, dynamic>> batch = calls
          .map((call) => {
                'jsonrpc': '2.0',
                'id': _requestId++,
                'method': call['method'],
                'params': call['params'],
              })
          .toList();

      final response = await http.post(
        Uri.parse(_httpRpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(batch),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        return results.map((data) {
          if (data.containsKey('error')) {
            print('RPC error: ${data['error']}');
            return null;
          }
          return data['result'];
        }).toList();
      } else {
        print('HTTP error: ${response.statusCode}, Body: ${response.body}');
        return List.filled(calls.length, null);
      }
    } catch (e) {
      print('Batch RPC call error: $e');
      return List.filled(calls.length, null);
    }
  }

  Future<Map<String, dynamic>> getTransactionDetails(String txHash) async {
    try {
      // Get transaction and receipt in parallel
      final results = await _makeBatchRpcCalls([
        {
          'method': 'eth_getTransactionByHash',
          'params': [txHash]
        },
        {
          'method': 'eth_getTransactionReceipt',
          'params': [txHash]
        },
      ]);

      final txData = results[0];
      final receiptData = results[1];

      if (txData == null) {
        return {'success': false, 'error': 'Transaction not found'};
      }

      return {
        'success': true,
        'transaction': txData,
        'receipt': receiptData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      print('Error getting transaction details: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getDetailedTransactionTrace(
      String txHash) async {
    try {
      // First try trace_transaction which is more widely supported by GCP
      final traceResult = await _makeRpcCall('trace_transaction', [txHash]);

      if (traceResult != null) {
        // Also get debug_traceTransaction for more detailed info
        final debugTraceResult = await _makeRpcCall('debug_traceTransaction', [
          txHash,
          {"tracer": "callTracer", "timeout": "30s"}
        ]);

        // Add to recent traces
        _addToRecentTraces({
          'type': 'transaction',
          'hash': txHash,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        return {
          'trace': traceResult,
          'debugTrace': debugTraceResult,
          'success': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
      }
      return {'success': false, 'error': 'No trace data available'};
    } catch (e) {
      print('Error getting transaction trace: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBlockWithTransactions(int blockNumber) async {
    try {
      // Convert block number to hex
      final blockHex = '0x${blockNumber.toRadixString(16)}';

      // Get block with transactions
      final blockData =
          await _makeRpcCall('eth_getBlockByNumber', [blockHex, true]);

      if (blockData == null) {
        return {'success': false, 'error': 'Block not found'};
      }

      return {
        'success': true,
        'block': blockData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      print('Error getting block with transactions: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBlockTrace(int blockNumber) async {
    try {
      // Check cache first
      if (_blockTraceCache.containsKey(blockNumber)) {
        return _blockTraceCache[blockNumber]!;
      }

      // Convert block number to hex
      final blockHex = '0x${blockNumber.toRadixString(16)}';

      // First get the block with transactions
      final blockData = await getBlockWithTransactions(blockNumber);
      if (blockData['success'] != true) {
        return {'success': false, 'error': 'Failed to get block data'};
      }

      // Use trace_block RPC method
      final traceResult = await _makeRpcCall('trace_block', [blockHex]);

      if (traceResult != null) {
        // Filter for PYUSD transactions
        final pyusdTraces = (traceResult as List).where((trace) {
          final to = trace['action']?['to']?.toString().toLowerCase();
          return to == _pyusdContractAddress.toLowerCase();
        }).toList();

        final result = {
          'fullTrace': traceResult,
          'pyusdTraces': pyusdTraces,
          'success': true,
          'blockNumber': blockNumber,
          'block': blockData['block'],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        // Cache the result
        _blockTraceCache[blockNumber] = result;

        // Add to recent blocks traced
        if (!_recentBlocksTraced.contains(blockNumber)) {
          _recentBlocksTraced.add(blockNumber);
          if (_recentBlocksTraced.length > 10) {
            _recentBlocksTraced.removeAt(0);
          }
        }

        // Add to recent traces
        _addToRecentTraces({
          'type': 'block',
          'blockNumber': blockNumber,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        _saveHistoryToPrefs();
        _safeNotifyListeners();
        return result;
      }
      return {'success': false, 'error': 'No block trace data available'};
    } catch (e) {
      print('Error getting block trace: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> analyzePyusdTransaction(String txHash) async {
    try {
      // Get transaction details
      final txDetails = await getTransactionDetails(txHash);
      if (txDetails['success'] != true) {
        return {'success': false, 'error': 'Transaction not found'};
      }

      final txData = txDetails['transaction'];

      // Get detailed trace
      final traceData = await getTransactionTraceWithCache(txHash);

      // Extract token transfer details
      Map<String, dynamic> tokenDetails = {};
      if (txData['input'] != null &&
          txData['input'].toString().startsWith('0xa9059cbb')) {
        try {
          // Extract recipient address (32 bytes after method ID)
          final String recipient =
              '0x${txData['input'].toString().substring(34, 74)}';

          // Extract value (32 bytes after recipient)
          final String valueHex = txData['input'].toString().substring(74);
          final BigInt tokenValueBigInt =
              FormatterUtils.parseBigInt("0x$valueHex");

          // Convert to PYUSD with 6 decimals
          final double tokenValue = tokenValueBigInt / BigInt.from(10).pow(6);

          tokenDetails = {
            'recipient': recipient,
            'value': tokenValue,
            'formattedValue': '\$${tokenValue.toStringAsFixed(2)}',
          };
        } catch (e) {
          print('Error extracting token details: $e');
        }
      }

      // Get gas usage details
      final gasUsed =
          FormatterUtils.parseHexSafely(txDetails['receipt']?['gasUsed']) ?? 0;
      final gasPrice = FormatterUtils.parseHexSafely(txData['gasPrice']) ?? 0;
      final gasCost = (gasUsed * gasPrice) / 1e18; // Convert to ETH

      return {
        'success': true,
        'transaction': txData,
        'receipt': txDetails['receipt'],
        'trace': traceData,
        'tokenDetails': tokenDetails,
        'gasAnalysis': {
          'gasUsed': gasUsed,
          'gasPrice': gasPrice / 1e9, // Convert to Gwei
          'gasCostEth': gasCost,
          'gasCostUsd': gasCost * 2000, // Approximate ETH price in USD
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      print('Error analyzing PYUSD transaction: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get transaction trace with caching
  Future<Map<String, dynamic>> getTransactionTraceWithCache(
      String txHash) async {
    try {
      // Validate transaction hash format
      if (txHash.isEmpty || !txHash.startsWith('0x') || txHash.length != 66) {
        return {'success': false, 'error': 'Invalid transaction hash format'};
      }

      // Check cache first
      if (_transactionTraceCache.containsKey(txHash)) {
        return _transactionTraceCache[txHash]!;
      }

      // Fetch trace
      final trace = await getDetailedTransactionTrace(txHash);

      // Cache the result
      if (trace['success'] == true) {
        _transactionTraceCache[txHash] = trace;

        // Limit cache size to reduce memory usage
        if (_transactionTraceCache.length > 50) {
          final oldestKey = _transactionTraceCache.keys.first;
          _transactionTraceCache.remove(oldestKey);
        }

        // Save to SharedPreferences
        _saveHistoryToPrefs();
      }

      return trace;
    } catch (e) {
      print('Error getting transaction trace with cache: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  void _addToRecentTraces(Map<String, dynamic> trace) {
    _recentTraces.add(trace);
    if (_recentTraces.length > 20) {
      _recentTraces.removeAt(0);
    }
    _saveHistoryToPrefs();
    _safeNotifyListeners();
  }

  void clearHistory() {
    _recentTraces.clear();
    _recentBlocksTraced.clear();
    _saveHistoryToPrefs();
    _safeNotifyListeners();
  }

  // Helper method to safely notify listeners
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // Trace a specific call using trace_call
  Future<Map<String, dynamic>> traceCall(String toAddress, String data,
      [String? fromAddress]) async {
    try {
      final callObject = {
        'to': toAddress,
        'data': data,
      };

      // Add from address if provided
      if (fromAddress != null && fromAddress.isNotEmpty) {
        callObject['from'] = fromAddress;
      }

      final params = [
        callObject,
        ['trace'],
        'latest',
      ];

      final result = await _makeRpcCall('debug_traceCall', params);

      if (result == null) {
        return {'success': false, 'error': 'No trace data available'};
      }

      // Add to recent traces
      _recentTraces.insert(0, {
        'type': 'traceCall',
        'to': toAddress,
        'data': data,
        'from': fromAddress,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Trim history if needed
      if (_recentTraces.length > 20) {
        _recentTraces = _recentTraces.sublist(0, 20);
      }

      _saveHistoryToPrefs();
      _safeNotifyListeners();

      return {
        'success': true,
        'trace': result,
        'to': toAddress,
        'data': data,
        'from': fromAddress,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      print('Error executing trace call: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Replay a block's transactions using trace_replayBlockTransactions
  Future<Map<String, dynamic>> replayBlockTransactions(int blockNumber) async {
    try {
      final blockHex = '0x${blockNumber.toRadixString(16)}';

      final result = await _makeRpcCall('trace_replayBlockTransactions', [
        blockHex,
        ['trace']
      ]);

      if (result == null) {
        return {'success': false, 'error': 'No replay data available'};
      }

      // Add to recent blocks traced
      if (!_recentBlocksTraced.contains(blockNumber)) {
        _recentBlocksTraced.add(blockNumber);
        if (_recentBlocksTraced.length > 10) {
          _recentBlocksTraced.removeAt(0);
        }
      }

      // Add to recent traces
      _addToRecentTraces({
        'type': 'blockReplay',
        'blockNumber': blockNumber,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      _saveHistoryToPrefs();
      _safeNotifyListeners();

      return {
        'success': true,
        'traces': result,
        'blockNumber': blockNumber,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      print('Error replaying block transactions: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Replay a transaction using trace_replayTransaction
  Future<Map<String, dynamic>> replayTransaction(String txHash) async {
    try {
      final result = await _makeRpcCall('trace_replayTransaction', [
        txHash,
        ['trace']
      ]);

      if (result == null) {
        return {'success': false, 'error': 'No replay data available'};
      }

      // Add to recent traces
      _addToRecentTraces({
        'type': 'txReplay',
        'hash': txHash,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      _saveHistoryToPrefs();
      _safeNotifyListeners();

      return {
        'success': true,
        'trace': result,
        'txHash': txHash,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      print('Error replaying transaction: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get storage at a specific range using debug_storageRangeAt
  Future<Map<String, dynamic>> getStorageRangeAt(String blockHash, int txIndex,
      String contractAddress, String startKey, int pageSize) async {
    try {
      final result = await _makeRpcCall('debug_storageRangeAt',
          [blockHash, txIndex, contractAddress, startKey, pageSize]);

      if (result == null) {
        return {'success': false, 'error': 'No storage data available'};
      }

      return {
        'success': true,
        'storage': result,
        'contractAddress': contractAddress,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      print('Error getting storage range: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Add these methods for history management

  void removeTraceFromHistory(int index) {
    if (index >= 0 && index < _recentTraces.length) {
      _lastRemovedTrace = _recentTraces[index];
      _lastRemovedIndex = index;
      _recentTraces.removeAt(index);
      _saveHistoryToPrefs();
      notifyListeners();
    }
  }

  void restoreRemovedTrace() {
    if (_lastRemovedTrace != null && _lastRemovedIndex != null) {
      if (_lastRemovedIndex! > _recentTraces.length) {
        _recentTraces.add(_lastRemovedTrace!);
      } else {
        _recentTraces.insert(_lastRemovedIndex!, _lastRemovedTrace!);
      }
      _lastRemovedTrace = null;
      _lastRemovedIndex = null;
      _saveHistoryToPrefs();
      notifyListeners();
    }
  }

  void clearTraceHistory() {
    _recentTraces.clear();
    _lastRemovedTrace = null;
    _lastRemovedIndex = null;
    _saveHistoryToPrefs();
    notifyListeners();
  }

  Future<void> fetchTraceData(String txHash) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch trace data implementation
      _traceData = {};
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error fetching trace data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // MEV Analysis Methods

  Future<Map<String, dynamic>> analyzeSandwichAttacks(String blockHash) async {
    try {
      _isLoading = true;
      _safeNotifyListeners();

      // Get block transactions
      final blockData =
          await _makeRpcCall('eth_getBlockByHash', [blockHash, true]);
      if (blockData == null) {
        return {'success': false, 'error': 'Block not found'};
      }

      final transactions = blockData['transactions'] as List;
      final sandwichAttacks = <Map<String, dynamic>>[];

      // Analyze transactions for sandwich patterns
      for (int i = 0; i < transactions.length - 2; i++) {
        final potentialFrontrun = transactions[i];
        final potentialVictim = transactions[i + 1];
        final potentialBackrun = transactions[i + 2];

        if (await _isSandwichAttack(
            potentialFrontrun, potentialVictim, potentialBackrun)) {
          final profit = await _calculateMEVProfit(
            potentialFrontrun,
            potentialVictim,
            potentialBackrun,
          );

          sandwichAttacks.add({
            'frontrun': potentialFrontrun,
            'victim': potentialVictim,
            'backrun': potentialBackrun,
            'profit': profit,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }

      _isLoading = false;
      _safeNotifyListeners();

      return {
        'success': true,
        'sandwichAttacks': sandwichAttacks,
        'blockHash': blockHash,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      _isLoading = false;
      _safeNotifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> _isSandwichAttack(
    Map<String, dynamic> frontrun,
    Map<String, dynamic> victim,
    Map<String, dynamic> backrun,
  ) async {
    try {
      // Check if transactions involve PYUSD
      if (!_involvesToken(frontrun, _pyusdContractAddress) ||
          !_involvesToken(victim, _pyusdContractAddress) ||
          !_involvesToken(backrun, _pyusdContractAddress)) {
        return false;
      }

      // Check if transactions are from different addresses
      final frontrunFrom = frontrun['from'].toString().toLowerCase();
      final victimFrom = victim['from'].toString().toLowerCase();
      final backrunFrom = backrun['from'].toString().toLowerCase();

      if (victimFrom == frontrunFrom || victimFrom == backrunFrom) {
        return false;
      }

      // Check if frontrun and backrun are from the same address (MEV bot)
      if (frontrunFrom != backrunFrom) {
        return false;
      }

      // Check gas prices
      final frontrunGasPrice = int.parse(frontrun['gasPrice'].toString());
      final victimGasPrice = int.parse(victim['gasPrice'].toString());
      final backrunGasPrice = int.parse(backrun['gasPrice'].toString());

      // Typical sandwich attack pattern: frontrun > victim, backrun > victim
      return frontrunGasPrice > victimGasPrice &&
          backrunGasPrice > victimGasPrice;
    } catch (e) {
      print('Error checking sandwich attack: $e');
      return false;
    }
  }

  bool _involvesToken(Map<String, dynamic> tx, String tokenAddress) {
    final to = tx['to']?.toString().toLowerCase();
    return to == tokenAddress.toLowerCase();
  }

  Future<Map<String, dynamic>> analyzeFrontrunning(String txHash) async {
    try {
      _isLoading = true;
      _safeNotifyListeners();

      // Get transaction and its block
      final tx = await _makeRpcCall('eth_getTransactionByHash', [txHash]);
      if (tx == null) {
        _isLoading = false;
        _safeNotifyListeners();
        return {'success': false, 'error': 'Transaction not found'};
      }

      final blockHash = tx['blockHash'];
      final blockData =
          await _makeRpcCall('eth_getBlockByHash', [blockHash, true]);
      if (blockData == null) {
        _isLoading = false;
        _safeNotifyListeners();
        return {'success': false, 'error': 'Block not found'};
      }

      final transactions = blockData['transactions'] as List;
      final txIndex = transactions.indexWhere((t) => t['hash'] == txHash);
      if (txIndex == -1 || txIndex == 0) {
        _isLoading = false;
        _safeNotifyListeners();
        return {'success': false, 'error': 'Transaction not found in block'};
      }

      // Check previous transaction for frontrunning
      final prevTx = transactions[txIndex - 1];
      if (!_involvesToken(prevTx, _pyusdContractAddress)) {
        _isLoading = false;
        _safeNotifyListeners();
        return {'success': false, 'message': 'No frontrunning detected'};
      }

      // Get transaction receipts
      final receipts = await _makeBatchRpcCalls([
        {
          'method': 'eth_getTransactionReceipt',
          'params': [prevTx['hash']]
        },
        {
          'method': 'eth_getTransactionReceipt',
          'params': [txHash]
        },
      ]);

      // Calculate profit
      final frontrunProfit = await _calculateProfit(prevTx, receipts[0]);

      final frontrunEvent = {
        'frontrun': {
          'hash': prevTx['hash'],
          'profit': frontrunProfit,
        },
        'victim': {
          'hash': txHash,
        },
        'blockNumber': int.parse(blockData['number'].toString()),
        'timestamp': int.parse(blockData['timestamp'].toString()),
      };

      // Update MEV events
      if (frontrunProfit > 0) {
        _mevEvents.add({
          'type': 'frontrun',
          'data': frontrunEvent,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        _saveHistoryToPrefs();
      }

      _isLoading = false;
      _safeNotifyListeners();

      return {
        'success': true,
        'frontrunning': frontrunEvent,
      };
    } catch (e) {
      print('Error analyzing frontrunning: $e');
      _isLoading = false;
      _safeNotifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> analyzeMEVImpact(String txHash) async {
    try {
      final tx = await _makeRpcCall('eth_getTransactionByHash', [txHash]);
      if (tx == null) {
        return {
          'summary': 'Transaction not found',
          'details': [],
          'impact': 0.0,
        };
      }

      final receipt = await _makeRpcCall('eth_getTransactionReceipt', [txHash]);
      if (receipt == null) {
        return {
          'summary': 'Transaction receipt not found',
          'details': [],
          'impact': 0.0,
        };
      }

      final blockNumber = int.parse(tx['blockNumber'].toString());
      final block = await _makeRpcCall(
          'eth_getBlockByNumber', ['0x${blockNumber.toRadixString(16)}', true]);

      final transactions = block['transactions'] as List;
      final txIndex = transactions.indexWhere((t) => t['hash'] == txHash);

      final details = <String>[];
      double totalImpact = 0.0;

      // Analyze gas prices
      final currentGasPrice = int.parse(tx['gasPrice'].toString()) / 1e9;
      final gasUsed = int.parse(receipt['gasUsed'].toString());

      details.add('Gas used: $gasUsed');
      details.add('Gas price: ${currentGasPrice.toStringAsFixed(2)} Gwei');

      // Compare with surrounding transactions
      if (txIndex > 0) {
        final prevTx = transactions[txIndex - 1];
        final prevGasPrice = int.parse(prevTx['gasPrice'].toString()) / 1e9;
        details.add(
            'Previous tx gas price: ${prevGasPrice.toStringAsFixed(2)} Gwei');
      }

      if (txIndex < transactions.length - 1) {
        final nextTx = transactions[txIndex + 1];
        final nextGasPrice = int.parse(nextTx['gasPrice'].toString()) / 1e9;
        details
            .add('Next tx gas price: ${nextGasPrice.toStringAsFixed(2)} Gwei');
      }

      // Calculate MEV impact
      final avgBlockGasPrice = transactions.fold(
              0.0, (sum, t) => sum + int.parse(t['gasPrice'].toString())) /
          (transactions.length * 1e9);

      final gasPricePremium = currentGasPrice - avgBlockGasPrice;
      totalImpact = (gasPricePremium * gasUsed / 1e9) *
          2000; // Assuming ETH price of $2000

      details.add(
          'Block average gas price: ${avgBlockGasPrice.toStringAsFixed(2)} Gwei');
      details
          .add('Gas price premium: ${gasPricePremium.toStringAsFixed(2)} Gwei');

      return {
        'summary': totalImpact > 0
            ? 'Transaction paid a premium for priority'
            : 'Transaction had no significant MEV impact',
        'details': details,
        'impact': totalImpact.abs(),
      };
    } catch (e) {
      print('Error in analyzeMEVImpact: $e');
      return {
        'summary': 'Error analyzing MEV impact',
        'details': [e.toString()],
        'impact': 0.0,
      };
    }
  }

  Future<bool> _isFrontrunning(Map<String, dynamic> potentialFrontrunner,
      Map<String, dynamic> targetTx) async {
    // Compare gas prices
    final frontrunGasPrice =
        int.parse(potentialFrontrunner['gasPrice'].toString());
    final targetGasPrice = int.parse(targetTx['gasPrice'].toString());

    // Basic heuristic: frontrunner typically pays higher gas price
    if (frontrunGasPrice <= targetGasPrice) {
      return false;
    }

    // Compare input data to see if they're interacting with the same contract/method
    final frontrunInput = potentialFrontrunner['input'].toString();
    final targetInput = targetTx['input'].toString();

    // Check if they're calling the same contract method (first 4 bytes of input)
    if (frontrunInput.length >= 10 && targetInput.length >= 10) {
      return frontrunInput.substring(0, 10) == targetInput.substring(0, 10);
    }

    return false;
  }

  Future<double> _calculateFrontrunProfit(Map<String, dynamic> tx) async {
    try {
      // Get transaction receipt for actual gas used
      final receipt =
          await _makeRpcCall('eth_getTransactionReceipt', [tx['hash']]);
      if (receipt == null) return 0.0;

      // Calculate gas cost
      final gasUsed = int.parse(receipt['gasUsed'].toString());
      final gasPrice = int.parse(tx['gasPrice'].toString());
      final gasCost = (gasUsed * gasPrice) / 1e18; // Convert to ETH

      // Analyze logs for token transfers
      final logs = receipt['logs'] as List;
      double estimatedProfit = 0.0;

      // Look for Transfer events (common in token transactions)
      for (final log in logs) {
        if (log['topics'].length > 0 &&
            log['topics'][0] ==
                '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef') {
          // This is a Transfer event
          final amount = int.parse(log['data'].toString()) / 1e18;
          estimatedProfit += amount;
        }
      }

      // Subtract gas cost (assuming ETH price of $2000)
      return (estimatedProfit * 2000) - (gasCost * 2000);
    } catch (e) {
      print('Error calculating frontrun profit: $e');
      return 0.0;
    }
  }

  Future<double> _calculateMEVProfit(
    Map<String, dynamic> frontrunTx,
    Map<String, dynamic> victimTx,
    Map<String, dynamic> backrunTx,
  ) async {
    try {
      // Calculate profits from frontrun and backrun transactions
      final frontrunProfit = await _calculateArbitrageProfit(frontrunTx);
      final backrunProfit = await _calculateArbitrageProfit(backrunTx);

      // Total profit is the sum of both transactions
      return frontrunProfit + backrunProfit;
    } catch (e) {
      print('Error calculating MEV profit: $e');
      return 0.0;
    }
  }

  Future<double> _calculateArbitrageProfit(Map<String, dynamic> tx) async {
    try {
      // Get transaction receipt for actual gas used
      final receipt =
          await _makeRpcCall('eth_getTransactionReceipt', [tx['hash']]);
      if (receipt == null) return 0.0;

      // Calculate gas cost
      final gasUsed = int.parse(receipt['gasUsed'].toString());
      final gasPrice = int.parse(tx['gasPrice'].toString());
      final gasCost = (gasUsed * gasPrice) / 1e18; // Convert to ETH

      // For this example, we'll use a simplified profit calculation
      // In a real implementation, you would analyze token transfers and price impacts
      final profit = await _calculateTokenTransferProfit(receipt['logs']);

      return profit - (gasCost * 2000); // Assuming ETH price of $2000
    } catch (e) {
      print('Error calculating arbitrage profit: $e');
      return 0.0;
    }
  }

  Future<double> _calculateTokenTransferProfit(List<dynamic> logs) async {
    double profit = 0.0;

    for (final log in logs) {
      if (log['address'].toString().toLowerCase() ==
          _pyusdContractAddress.toLowerCase()) {
        // Parse Transfer event
        if (log['topics'][0] ==
            '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef') {
          final amount = BigInt.parse(log['data'].toString());
          profit += amount.toDouble() / 1e6; // Convert from PYUSD decimals
        }
      }
    }

    return profit;
  }

  Future<double> _calculateProfit(
      Map<String, dynamic> tx, Map<String, dynamic> receipt) async {
    try {
      // Calculate gas cost
      final gasUsed = int.parse(receipt['gasUsed'].toString());
      final gasPrice = int.parse(tx['gasPrice'].toString());
      final gasCost = (gasUsed * gasPrice) / 1e18; // Convert to ETH

      // Calculate profit from token transfers
      final logs = receipt['logs'] as List;
      final tokenProfit = await _calculateTokenTransferProfit(logs);

      // Subtract gas cost (assuming ETH price of $2000)
      final netProfit = tokenProfit - (gasCost * 2000);

      return netProfit > 0 ? netProfit : 0.0;
    } catch (e) {
      print('Error calculating profit: $e');
      return 0.0;
    }
  }

  Future<List<Map<String, dynamic>>> _findLiquidationOpportunities(
      List<dynamic> transactions) async {
    final opportunities = <Map<String, dynamic>>[];

    for (final tx in transactions) {
      try {
        // Check if transaction is interacting with lending protocols
        if (await _isLiquidationCall(tx)) {
          final liquidationDetails = await _analyzeLiquidation(tx);
          if (liquidationDetails != null) {
            opportunities.add({
              'type': 'liquidation',
              'transaction': tx,
              'details': liquidationDetails,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });
          }
        }
      } catch (e) {
        print('Error analyzing liquidation opportunity: $e');
      }
    }

    return opportunities;
  }

  Future<List<Map<String, dynamic>>> _findArbitrageOpportunities(
      List<dynamic> transactions) async {
    final opportunities = <Map<String, dynamic>>[];

    for (final tx in transactions) {
      try {
        if (_involvesToken(tx, _pyusdContractAddress)) {
          final profit = await _calculateArbitrageProfit(tx);
          if (profit > 0) {
            opportunities.add({
              'type': 'arbitrage',
              'transaction': tx,
              'estimatedProfit': profit,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });
          }
        }
      } catch (e) {
        print('Error analyzing arbitrage opportunity: $e');
      }
    }

    return opportunities;
  }

  Future<bool> _isLiquidationCall(Map<String, dynamic> tx) async {
    // Check if the transaction is calling a liquidation function
    // This is a simplified check - in reality, you would need to check specific protocols
    final input = tx['input'].toString();
    return input.startsWith(
            '0x7d858b4f') || // Example liquidation function signature
        input.startsWith('0xb5f8558c'); // Another example signature
  }

  Future<Map<String, dynamic>?> _analyzeLiquidation(
      Map<String, dynamic> tx) async {
    try {
      final receipt =
          await _makeRpcCall('eth_getTransactionReceipt', [tx['hash']]);
      if (receipt == null) return null;

      // Analyze the liquidation event logs
      final liquidationProfit =
          await _calculateLiquidationProfit(receipt['logs']);

      return {
        'profit': liquidationProfit,
        'collateralToken': 'PYUSD',
        'debtToken':
            'USDC', // Example - in reality, you'd determine this from the logs
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      print('Error analyzing liquidation: $e');
      return null;
    }
  }

  Future<double> _calculateLiquidationProfit(List<dynamic> logs) async {
    double profit = 0.0;

    // Calculate profit from liquidation events
    // This is a simplified calculation - in reality, you'd need to:
    // 1. Identify the seized collateral
    // 2. Calculate its market value
    // 3. Subtract the debt repaid
    // 4. Subtract gas costs

    for (final log in logs) {
      if (log['address'].toString().toLowerCase() ==
          _pyusdContractAddress.toLowerCase()) {
        // Parse relevant events
        final data = BigInt.parse(log['data'].toString());
        profit += data.toDouble() / 1e6;
      }
    }

    return profit;
  }

  Future<Map<String, dynamic>> analyzeTransactionOrdering(
      String blockHash) async {
    try {
      _isLoading = true;
      _safeNotifyListeners();

      final blockData =
          await _makeRpcCall('eth_getBlockByHash', [blockHash, true]);
      if (blockData == null) {
        _isLoading = false;
        _safeNotifyListeners();
        return {'success': false, 'error': 'Block not found'};
      }

      final transactions = blockData['transactions'] as List;
      final orderedTransactions = <Map<String, dynamic>>[];

      // Analyze PYUSD transactions and their ordering
      for (final tx in transactions) {
        if (_involvesToken(tx, _pyusdContractAddress)) {
          final receipt =
              await _makeRpcCall('eth_getTransactionReceipt', [tx['hash']]);
          if (receipt != null) {
            orderedTransactions.add({
              'hash': tx['hash'],
              'gasPrice': int.parse(tx['gasPrice'].toString()),
              'gasUsed': int.parse(receipt['gasUsed'].toString()),
              'status': receipt['status'],
            });
          }
        }
      }

      // Sort by gas price to identify potential ordering manipulation
      orderedTransactions
          .sort((a, b) => b['gasPrice'].compareTo(a['gasPrice']));

      _isLoading = false;
      _safeNotifyListeners();

      return {
        'success': true,
        'transactions': orderedTransactions,
        'blockNumber': int.parse(blockData['number'].toString()),
        'timestamp': int.parse(blockData['timestamp'].toString()),
      };
    } catch (e) {
      print('Error analyzing transaction ordering: $e');
      _isLoading = false;
      _safeNotifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> analyzeMevOpportunities(String blockHash) async {
    try {
      _isLoading = true;
      _safeNotifyListeners();

      final blockData =
          await _makeRpcCall('eth_getBlockByHash', [blockHash, true]);
      if (blockData == null) {
        _isLoading = false;
        _safeNotifyListeners();
        return {'success': false, 'error': 'Block not found'};
      }

      final transactions = blockData['transactions'] as List;
      final opportunities = <Map<String, dynamic>>[];

      for (final tx in transactions) {
        if (_involvesToken(tx, _pyusdContractAddress)) {
          final receipt =
              await _makeRpcCall('eth_getTransactionReceipt', [tx['hash']]);
          if (receipt != null) {
            final profit = await _calculateProfit(tx, receipt);
            if (profit > 0) {
              opportunities.add({
                'hash': tx['hash'],
                'type': 'arbitrage',
                'profit': profit,
                'gasPrice': int.parse(tx['gasPrice'].toString()),
              });
            }
          }
        }
      }

      _isLoading = false;
      _safeNotifyListeners();

      return {
        'success': true,
        'opportunities': opportunities,
        'blockNumber': int.parse(blockData['number'].toString()),
        'timestamp': int.parse(blockData['timestamp'].toString()),
      };
    } catch (e) {
      print('Error analyzing MEV opportunities: $e');
      _isLoading = false;
      _safeNotifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> identifyMEVOpportunities(
      String blockHash) async {
    try {
      _isLoading = true;
      _safeNotifyListeners();

      final blockData =
          await _makeRpcCall('eth_getBlockByHash', [blockHash, true]);
      if (blockData == null) {
        return {'success': false, 'error': 'Block not found'};
      }

      final transactions = blockData['transactions'] as List;
      final opportunities = <Map<String, dynamic>>[];

      // Find liquidation opportunities
      final liquidations = await _findLiquidationOpportunities(transactions);
      opportunities.addAll(liquidations);

      // Find arbitrage opportunities
      final arbitrage = await _findArbitrageOpportunities(transactions);
      opportunities.addAll(arbitrage);

      _isLoading = false;
      _safeNotifyListeners();

      return {
        'success': true,
        'opportunities': opportunities,
        'blockHash': blockHash,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      _isLoading = false;
      _safeNotifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> trackHistoricalMEVEvents(
      int startBlock, int endBlock) async {
    try {
      _isLoading = true;
      _safeNotifyListeners();

      final events = <Map<String, dynamic>>[];

      for (int blockNumber = startBlock;
          blockNumber <= endBlock;
          blockNumber++) {
        final blockData = await getBlockWithTransactions(blockNumber);
        if (blockData['success'] != true) continue;

        final transactions = blockData['block']['transactions'] as List;

        // Check for sandwich attacks
        final sandwichResult =
            await analyzeSandwichAttacks(blockData['block']['hash']);
        if (sandwichResult['success'] == true) {
          events.addAll(
              (sandwichResult['sandwichAttacks'] as List).map((attack) => {
                    'type': 'sandwich_attack',
                    'blockNumber': blockNumber,
                    'data': attack,
                  }));
        }

        // Check for other MEV opportunities
        final opportunities =
            await identifyMEVOpportunities(blockData['block']['hash']);
        if (opportunities['success'] == true) {
          events.addAll((opportunities['opportunities'] as List).map((opp) => {
                'type': 'mev_opportunity',
                'blockNumber': blockNumber,
                'data': opp,
              }));
        }
      }

      _isLoading = false;
      _safeNotifyListeners();

      return {
        'success': true,
        'events': events,
        'startBlock': startBlock,
        'endBlock': endBlock,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      _isLoading = false;
      _safeNotifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }
}
