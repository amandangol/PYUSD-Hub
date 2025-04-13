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

  String _lastTxHash = '';
  String _lastBlockNumber = '';
  String _lastReplayBlock = '';
  String _lastReplayTx = '';
  String _lastBlockHash = '';
  String _lastTxIndex = '';
  String _lastContractAddress = '';
  String _lastTraceCallTo = '';
  String _lastTraceCallData = '';
  String _lastTraceCallFrom = '';
  String _lastSelectedMethod = 'Replay Block Transactions';

  String get lastTxHash => _lastTxHash;
  String get lastBlockNumber => _lastBlockNumber;
  String get lastReplayBlock => _lastReplayBlock;
  String get lastReplayTx => _lastReplayTx;
  String get lastBlockHash => _lastBlockHash;
  String get lastTxIndex => _lastTxIndex;
  String get lastContractAddress => _lastContractAddress;
  String get lastTraceCallTo => _lastTraceCallTo;
  String get lastTraceCallData => _lastTraceCallData;
  String get lastTraceCallFrom => _lastTraceCallFrom;
  String get lastSelectedMethod => _lastSelectedMethod;

  // Add setters to update the values
  void updateLastTxHash(String value) {
    _lastTxHash = value;
    notifyListeners();
  }

  void updateLastBlockNumber(String value) {
    _lastBlockNumber = value;
    notifyListeners();
  }

  void updateLastReplayBlock(String value) {
    _lastReplayBlock = value;
    notifyListeners();
  }

  void updateLastReplayTx(String value) {
    _lastReplayTx = value;
    notifyListeners();
  }

  void updateLastBlockHash(String value) {
    _lastBlockHash = value;
    notifyListeners();
  }

  void updateLastTxIndex(String value) {
    _lastTxIndex = value;
    notifyListeners();
  }

  void updateLastContractAddress(String value) {
    _lastContractAddress = value;
    notifyListeners();
  }

  void updateLastTraceCallTo(String value) {
    _lastTraceCallTo = value;
    notifyListeners();
  }

  void updateLastTraceCallData(String value) {
    _lastTraceCallData = value;
    notifyListeners();
  }

  void updateLastTraceCallFrom(String value) {
    _lastTraceCallFrom = value;
    notifyListeners();
  }

  void updateLastSelectedMethod(String value) {
    _lastSelectedMethod = value;
    notifyListeners();
  }

  bool get isLoading => _isLoading;
  Map<String, dynamic> get traceData => _traceData;
  String get errorMessage => _errorMessage;

  TraceProvider() {
    _loadHistoryFromPrefs().then((_) => cleanupDuplicateHistory());
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

        // Sort by timestamp in descending order
        _recentTraces.sort(
            (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
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
    // Remove existing trace with the same identifier
    _recentTraces.removeWhere((existingTrace) {
      if (trace['type'] == 'transaction' || trace['type'] == 'txReplay') {
        return existingTrace['hash'] == trace['hash'];
      } else if (trace['type'] == 'block' || trace['type'] == 'blockReplay') {
        return existingTrace['blockNumber'] == trace['blockNumber'];
      }
      return false;
    });

    // Add new trace at the beginning
    _recentTraces.insert(0, trace);

    // Limit the history size to 20 entries
    if (_recentTraces.length > 20) {
      _recentTraces = _recentTraces.sublist(0, 20);
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

      // Get block with transactions first
      final dynamic blockResult =
          await _makeRpcCall('eth_getBlockByNumber', [blockHex, true]);
      if (blockResult == null) {
        return {'success': false, 'error': 'Block not found'};
      }

      final Map<String, dynamic> block =
          Map<String, dynamic>.from(blockResult as Map);
      final List<dynamic> transactions = block['transactions'] as List? ?? [];

      if (transactions.isEmpty) {
        return {
          'success': true,
          'blockNumber': blockNumber,
          'blockHash': block['hash'],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'traces': [],
        };
      }

      // Get transaction receipts
      final receiptCalls = transactions
          .map((tx) => {
                'method': 'eth_getTransactionReceipt',
                'params': [tx['hash']]
              })
          .toList();

      final receipts = await _makeBatchRpcCalls(receiptCalls);

      // Get debug traces for all transactions
      final traceResults = await Future.wait(
        transactions.map((tx) => _makeRpcCall('debug_traceTransaction', [
              tx['hash'],
              {"tracer": "callTracer", "timeout": "60s"}
            ])),
      );

      // Combine all data with proper type casting
      final enrichedTraces = List.generate(transactions.length, (i) {
        final tx = Map<String, dynamic>.from(transactions[i] as Map);
        final receipt = receipts[i] != null
            ? Map<String, dynamic>.from(receipts[i] as Map)
            : null;
        final trace = traceResults[i] != null
            ? Map<String, dynamic>.from(traceResults[i] as Map)
            : null;

        return {
          'transaction': {
            'hash': tx['hash']?.toString() ?? '',
            'from': tx['from']?.toString() ?? '',
            'to': tx['to']?.toString() ?? '',
            'value': tx['value']?.toString() ?? '0x0',
            'gas': tx['gas']?.toString() ?? '0x0',
            'gasPrice': tx['gasPrice']?.toString() ?? '0x0',
            'input': tx['input']?.toString() ?? '0x',
            'nonce': tx['nonce']?.toString() ?? '0x0',
            'blockHash': tx['blockHash']?.toString() ?? '',
            'blockNumber': tx['blockNumber']?.toString() ?? '',
            'transactionIndex': tx['transactionIndex']?.toString() ?? '0x0',
          },
          'receipt': receipt != null
              ? {
                  'status': receipt['status']?.toString() ?? '0x0',
                  'gasUsed': receipt['gasUsed']?.toString() ?? '0x0',
                  'logs': (receipt['logs'] as List?)
                          ?.map((log) => Map<String, dynamic>.from(log as Map))
                          .toList() ??
                      [],
                  'contractAddress': receipt['contractAddress']?.toString(),
                  'effectiveGasPrice':
                      receipt['effectiveGasPrice']?.toString() ?? '0x0',
                }
              : null,
          'trace': trace ?? {},
        };
      });

      // Add to recent traces with proper type safety
      _addToRecentTraces({
        'type': 'blockReplay',
        'blockNumber': blockNumber,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      return {
        'success': true,
        'blockNumber': blockNumber,
        'blockHash': block['hash']?.toString() ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'traces': enrichedTraces,
      };
    } catch (e) {
      print('Error replaying block transactions: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Replay a transaction using trace_replayTransaction
  Future<Map<String, dynamic>> replayTransaction(String txHash) async {
    try {
      // Get transaction data and trace in parallel
      final results = await Future.wait([
        _makeRpcCall('eth_getTransactionByHash', [txHash]),
        _makeRpcCall('debug_traceTransaction', [
          txHash,
          {"tracer": "callTracer", "timeout": "60s"}
        ]),
        _makeRpcCall('eth_getTransactionReceipt', [txHash]),
      ]);

      final transaction = results[0];
      final trace = results[1];
      final receipt = results[2];

      if (transaction == null) {
        return {'success': false, 'error': 'Transaction not found'};
      }

      return {
        'success': true,
        'transaction': {
          'hash': transaction['hash']?.toString() ?? '',
          'from': transaction['from']?.toString() ?? '',
          'to': transaction['to']?.toString() ?? '',
          'value': transaction['value']?.toString() ?? '0x0',
          'gas': transaction['gas']?.toString() ?? '0x0',
          'gasPrice': transaction['gasPrice']?.toString() ?? '0x0',
          'input': transaction['input']?.toString() ?? '0x',
          'blockHash': transaction['blockHash']?.toString() ?? '',
          'blockNumber': transaction['blockNumber']?.toString() ?? '',
          'transactionIndex':
              transaction['transactionIndex']?.toString() ?? '0x0',
        },
        'receipt': receipt != null
            ? {
                'status': receipt['status']?.toString() ?? '0x0',
                'gasUsed': receipt['gasUsed']?.toString() ?? '0x0',
                'logs': receipt['logs'] ?? [],
                'contractAddress': receipt['contractAddress']?.toString() ?? '',
              }
            : null,
        'trace': trace ?? {},
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

  Future<void> cleanupDuplicateHistory() async {
    final seen = <String>{};
    final uniqueTraces = <Map<String, dynamic>>[];

    for (final trace in _recentTraces) {
      final identifier = _getTraceIdentifier(trace);
      if (!seen.contains(identifier)) {
        seen.add(identifier);
        uniqueTraces.add(trace);
      }
    }

    _recentTraces = uniqueTraces;
    await _saveHistoryToPrefs();
    _safeNotifyListeners();
  }

  String _getTraceIdentifier(Map<String, dynamic> trace) {
    final type = trace['type'] as String? ?? '';
    final timestamp = trace['timestamp'] as int? ?? 0;

    switch (type) {
      case 'transaction':
      case 'txReplay':
        return '${type}_${trace['hash'] as String? ?? ''}';
      case 'block':
      case 'blockReplay':
        return '${type}_${trace['blockNumber'] as int? ?? 0}';
      case 'storageRange':
        return '${type}_${trace['blockHash'] as String? ?? ''}_${trace['txIndex'] as int? ?? 0}_${trace['contractAddress'] as String? ?? ''}';
      case 'traceCall':
        return '${type}_${trace['to'] as String? ?? ''}_${trace['data'] as String? ?? ''}_${trace['from'] as String? ?? ''}';
      default:
        return '${type}_$timestamp';
    }
  }
}
