import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

class DebugTraceService {
  // Make RPC call to the Ethereum node
  Future<Map<String, dynamic>> _makeRpcCall(
      String rpcUrl, String method, List<dynamic> params) async {
    try {
      final response = await http.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': method,
          'params': params,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('error')) {
          throw Exception('RPC error: ${data['error']}');
        }
        return data['result'] as Map<String, dynamic>;
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to make RPC call: $e');
    }
  }

  // Trace a transaction that has already been mined
  Future<Map<String, dynamic>> traceTransaction(
    String rpcUrl,
    String txHash, {
    Map<String, dynamic>? tracerConfig,
  }) async {
    try {
      final params = [
        txHash,
        {
          'tracer': 'callTracer',
          'tracerConfig': tracerConfig ??
              {
                'onlyTopCall': false,
                'withLog': true,
                'withError': true,
              },
        },
      ];

      final traceResult =
          await _makeRpcCall(rpcUrl, 'debug_traceTransaction', params);

      // Extract error information if present
      if (traceResult.containsKey('error')) {
        traceResult['errorDetails'] = {
          'message': traceResult['error'],
          'type': 'execution_error',
        };
      }

      // Check for revert reason
      if (traceResult.containsKey('revert')) {
        traceResult['errorDetails'] = {
          'message': traceResult['revert'],
          'type': 'revert',
        };
      }

      return traceResult;
    } catch (e) {
      throw Exception('Failed to trace transaction: $e');
    }
  }

  // Trace a call without submitting it to the network
  Future<Map<String, dynamic>> traceCall(
    String rpcUrl, {
    required String from,
    required String to,
    required String data,
    String? value,
    String? gas,
    String? gasPrice,
    Map<String, dynamic>? tracerConfig,
  }) async {
    try {
      final callObject = {
        'from': from,
        'to': to,
        'data': data,
      };

      if (value != null) callObject['value'] = value;
      if (gas != null) callObject['gas'] = gas;
      if (gasPrice != null) callObject['gasPrice'] = gasPrice;

      final params = [
        callObject,
        'latest',
        {
          'tracer': 'callTracer',
          'tracerConfig': tracerConfig ??
              {
                'onlyTopCall': false,
                'withLog': true,
              },
        },
      ];

      return await _makeRpcCall(rpcUrl, 'debug_traceCall', params);
    } catch (e) {
      throw Exception('Failed to trace call: $e');
    }
  }

  // Get a more detailed error message from a failed transaction
  Future<String> getDetailedErrorMessage(
    String rpcUrl,
    String txHash,
  ) async {
    try {
      final traceResult = await traceTransaction(rpcUrl, txHash);

      // Check for error details in the trace
      if (traceResult.containsKey('errorDetails')) {
        final errorDetails = traceResult['errorDetails'];
        if (errorDetails['type'] == 'revert') {
          return 'Transaction reverted: ${errorDetails['message']}';
        } else if (errorDetails['type'] == 'execution_error') {
          return 'Execution error: ${errorDetails['message']}';
        }
      }

      // Check for gas-related errors
      if (traceResult.containsKey('gasUsed') &&
          traceResult.containsKey('gasLimit')) {
        final gasUsed = BigInt.parse(
            traceResult['gasUsed'].toString().replaceFirst('0x', ''),
            radix: 16);
        final gasLimit = BigInt.parse(
            traceResult['gasLimit'].toString().replaceFirst('0x', ''),
            radix: 16);

        if (gasUsed >= gasLimit * BigInt.from(95) ~/ BigInt.from(100)) {
          return 'Transaction failed: Out of gas';
        }
      }

      // If no specific error is found
      return 'Transaction failed: Unknown error';
    } catch (e) {
      return 'Failed to get detailed error: $e';
    }
  }
}
