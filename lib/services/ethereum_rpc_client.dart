import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

/// Core RPC client that handles connections to Ethereum nodes
class EthereumRpcClient {
  // Cache for Web3Client instances to avoid creating new ones for each request
  final Map<String, Web3Client> _clientCache = {};

  // Get or create a cached Web3Client
  Web3Client? getClient(String rpcUrl) {
    if (!_clientCache.containsKey(rpcUrl)) {
      _clientCache[rpcUrl] = Web3Client(rpcUrl, http.Client());
    }
    return _clientCache[rpcUrl];
  }

  // Make HTTP POST request to RPC endpoint with error handling
  Future<Map<String, dynamic>> makeRpcCall(
    String rpcUrl,
    String method,
    List<dynamic> params,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': method,
          'params': params,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to connect to Ethereum node: ${response.statusCode}');
      }

      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (jsonResponse.containsKey('error')) {
        throw Exception('RPC Error: ${jsonResponse['error']['message']}');
      }

      return jsonResponse;
    } catch (e) {
      throw Exception('RPC call failed for $method: $e');
    }
  }

  // Clean up method to dispose of Web3Client instances
  void dispose() {
    _clientCache.forEach((url, client) {
      client.dispose();
    });
    _clientCache.clear();
  }
}
