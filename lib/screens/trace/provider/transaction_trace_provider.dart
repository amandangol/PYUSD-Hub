import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  final List<Map<String, dynamic>> _recentTraces = [];
  List<Map<String, dynamic>> get recentTraces => _recentTraces;

  // Recent blocks traced
  final List<int> _recentBlocksTraced = [];
  List<int> get recentBlocksTraced => _recentBlocksTraced;

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

  Future<Map<String, dynamic>> getTransactionDetails(String txHash) async {
    try {
      // Get transaction
      final txData = await _makeRpcCall('eth_getTransactionByHash', [txHash]);
      if (txData == null) {
        return {'success': false, 'error': 'Transaction not found'};
      }

      // Get transaction receipt
      final receiptData =
          await _makeRpcCall('eth_getTransactionReceipt', [txHash]);

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

  Future<Map<String, dynamic>> getBlockTrace(int blockNumber) async {
    try {
      // Check cache first
      if (_blockTraceCache.containsKey(blockNumber)) {
        return _blockTraceCache[blockNumber]!;
      }

      // Convert block number to hex
      final blockHex = '0x${blockNumber.toRadixString(16)}';

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
      final traceData = await getDetailedTransactionTrace(txHash);

      // Extract token transfer details
      Map<String, dynamic> tokenDetails = {};
      if (txData['input'] != null &&
          txData['input'].toString().startsWith('0xa9059cbb')) {
        try {
          // Extract recipient address (32 bytes after method ID)
          final String recipient =
              '0x' + txData['input'].toString().substring(34, 74);

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
          'gasCostUsd': gasCost * 3000, // Approximate ETH price in USD
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
    _safeNotifyListeners();
  }

  void clearHistory() {
    _recentTraces.clear();
    _recentBlocksTraced.clear();
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
}
