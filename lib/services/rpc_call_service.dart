import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RpcCallService {
  static final RpcCallService _instance = RpcCallService._internal();
  final http.Client _httpClient = http.Client();
  int _requestId = 1;

  factory RpcCallService() {
    return _instance;
  }

  RpcCallService._internal();

  /// Makes a single RPC call to the specified endpoint
  Future<dynamic> makeRpcCall(
      String rpcUrl, String method, List<dynamic> params) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(rpcUrl),
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
        if (data.containsKey('error') && data['error'] != null) {
          print('RPC error: ${data['error']}');
          return {'error': data['error']};
        }
        return data; // Return the full response object, not just the result
      } else {
        print('HTTP error: ${response.statusCode}');
        return {'error': 'HTTP error: ${response.statusCode}'};
      }
    } catch (e) {
      print('RPC call error: $e');
      return {'error': 'RPC call error: $e'};
    }
  }

  /// Makes multiple RPC calls in a single batch request
  Future<List<Map<String, dynamic>>> batchRpcCalls(
      String rpcUrl, List<(String, List<dynamic>)> calls) async {
    try {
      final List<Map<String, dynamic>> batch = [];

      for (int i = 0; i < calls.length; i++) {
        batch.add({
          'jsonrpc': '2.0',
          'id': _requestId + i,
          'method': calls[i].$1,
          'params': calls[i].$2,
        });
      }

      _requestId += calls.length;

      final response = await _httpClient.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(batch),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        return results.map((result) => result as Map<String, dynamic>).toList();
      } else {
        print('HTTP error in batch request: ${response.statusCode}');
        return List.generate(
            calls.length,
            (i) => {
                  'id': batch[i]['id'],
                  'error': {
                    'code': response.statusCode,
                    'message': 'HTTP error'
                  }
                });
      }
    } catch (e) {
      print('Batch RPC call error: $e');
      return List.generate(
          calls.length,
          (i) => {
                'id': i + _requestId - calls.length,
                'error': {'code': -32000, 'message': 'Batch RPC call error: $e'}
              });
    }
  }

  Future<Map<String, dynamic>> makeApiGet(Uri uri) async {
    try {
      final response = await _httpClient.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('API GET error: ${response.statusCode}');
        return {
          'status': 'error',
          'message': 'HTTP error: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('API GET error: $e');
      return {'status': 'error', 'message': 'API call error: $e'};
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
