// import 'dart:async';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:web_socket_channel/web_socket_channel.dart';
// import '../model/network_congestion_model.dart';
// import '../../../providers/network_provider.dart';

// class NetworkCongestionService {
//   // Stream controller for network updates
//   final _controller = StreamController<Map<String, dynamic>>.broadcast();
//   Stream<Map<String, dynamic>> get updates => _controller.stream;

//   // Network endpoints (will be set dynamically based on selected network)
//   String _httpEndpoint = '';
//   String _wsEndpoint = '';

//   // WebSocket connection
//   WebSocketChannel? _channel;

//   // Default RPC endpoints
//   final Map<NetworkType, String> _httpEndpoints = {
//     NetworkType.sepoliaTestnet:
//         'https://blockchain.googleapis.com/v1/projects/oceanic-impact-451616-f5/locations/us-central1/endpoints/ethereum-sepolia/rpc?key=AIzaSyAnZZi8DTOXLn3zcRKoGYtRgMl-YQnIo1Q',
//     NetworkType.ethereumMainnet:
//         'https://blockchain.googleapis.com/v1/projects/oceanic-impact-451616-f5/locations/us-central1/endpoints/ethereum-mainnet/rpc?key=AIzaSyAnZZi8DTOXLn3zcRKoGYtRgMl-YQnIo1Q',
//   };

//   final Map<NetworkType, String> _wsEndpoints = {
//     NetworkType.sepoliaTestnet:
//         'wss://blockchain.googleapis.com/v1/projects/oceanic-impact-451616-f5/locations/us-central1/endpoints/ethereum-sepolia/rpc?key=AIzaSyAnZZi8DTOXLn3zcRKoGYtRgMl-YQnIo1Q',
//     NetworkType.ethereumMainnet:
//         'wss://blockchain.googleapis.com/v1/projects/oceanic-impact-451616-f5/locations/us-central1/endpoints/ethereum-mainnet/rpc?key=AIzaSyAnZZi8DTOXLn3zcRKoGYtRgMl-YQnIo1Q',
//   };

//   // Current network type
//   NetworkType _currentNetwork = NetworkType.ethereumMainnet;

//   // Constructor with optional network parameter
//   NetworkCongestionService(
//       {NetworkType initialNetwork = NetworkType.ethereumMainnet}) {
//     setNetwork(initialNetwork);
//   }

//   // Set the network type and update endpoints
//   void setNetwork(NetworkType networkType) {
//     _currentNetwork = networkType;
//     _httpEndpoint = _httpEndpoints[networkType] ?? '';
//     _wsEndpoint = _wsEndpoints[networkType] ?? '';

//     // Reset connections if they exist
//     _resetConnections();
//   }

//   // Reset and restart connections
//   void _resetConnections() {
//     // Close existing WebSocket connection
//     _channel?.sink.close();
//     _channel = null;

//     // Restart WebSocket if needed
//     startWebSocketConnection();
//   }

//   // Start WebSocket connection
//   void startWebSocketConnection() {
//     if (_wsEndpoint.isEmpty) return;

//     try {
//       _channel = WebSocketChannel.connect(Uri.parse(_wsEndpoint));

//       // Subscribe to new block headers
//       _channel?.sink.add(jsonEncode({
//         "jsonrpc": "2.0",
//         "id": 1,
//         "method": "eth_subscribe",
//         "params": ["newHeads"]
//       }));

//       // Listen for updates
//       _channel?.stream.listen((message) {
//         _handleWebSocketMessage(message);
//       }, onError: (error) {
//         print('WebSocket error: $error');
//         // Reconnect after delay
//         Future.delayed(const Duration(seconds: 5), startWebSocketConnection);
//       }, onDone: () {
//         print('WebSocket connection closed');
//         // Reconnect after delay
//         Future.delayed(const Duration(seconds: 5), startWebSocketConnection);
//       });
//     } catch (e) {
//       print('Failed to connect to WebSocket: $e');
//     }
//   }

//   // Handle incoming WebSocket messages
//   void _handleWebSocketMessage(dynamic message) {
//     try {
//       final data = jsonDecode(message);
//       if (data['params'] != null && data['params']['result'] != null) {
//         // New block received, fetch updated network data
//         fetchNetworkData();
//       }
//     } catch (e) {
//       print('Error parsing WebSocket message: $e');
//     }
//   }

//   // Fetch current network data
//   Future<void> fetchNetworkData() async {
//     if (_httpEndpoint.isEmpty) {
//       _controller.addError('No endpoint available for the selected network');
//       return;
//     }

//     try {
//       // Get gas price
//       final gasPrice = await _getGasPrice();

//       // Get pending transaction count
//       final pendingTxCount = await _getPendingTransactionCount();

//       // For simplicity, we'll generate mock PYUSD data based on the network type
//       // In a real app, you would fetch this from an API
//       final isPyusdAvailable = _currentNetwork == NetworkType.ethereumMainnet;
//       final pyusdTransactions =
//           isPyusdAvailable ? (200 + (DateTime.now().second * 5)) : 0;
//       final pyusdVolume =
//           isPyusdAvailable ? (100000 + (DateTime.now().minute * 1000)) : 0;

//       // Calculate network utilization (based on gas price and pending txs)
//       // This is a simplified model; real utilization would be more complex
//       final utilization = _calculateUtilization(gasPrice, pendingTxCount);

//       // Create network status data
//       final statusData = {
//         'timestamp': DateTime.now().toIso8601String(),
//         'gasPrice': gasPrice,
//         'pendingTransactions': pendingTxCount,
//         'pyusdTransactions': pyusdTransactions,
//         'pyusdVolume': pyusdVolume,
//         'networkUtilization': utilization,
//       };

//       // Send update
//       _controller.add(statusData);
//     } catch (e) {
//       print('Error fetching network data: $e');
//       _controller.addError('Failed to fetch network data: $e');
//     }
//   }

//   // Get current gas price in Gwei
//   Future<double> _getGasPrice() async {
//     try {
//       final response = await http.post(
//         Uri.parse(_httpEndpoint),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'jsonrpc': '2.0',
//           'method': 'eth_gasPrice',
//           'params': [],
//           'id': 1
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data['result'] != null) {
//           // Convert from wei to gwei
//           final weiValue = int.parse(data['result'].substring(2), radix: 16);
//           return weiValue / 1000000000;
//         }
//       }
//       return _currentNetwork == NetworkType.ethereumMainnet
//           ? 30.0
//           : 5.0; // Fallback values
//     } catch (e) {
//       print('Error getting gas price: $e');
//       return _currentNetwork == NetworkType.ethereumMainnet
//           ? 30.0
//           : 5.0; // Fallback values
//     }
//   }

//   // Get pending transaction count
//   Future<int> _getPendingTransactionCount() async {
//     try {
//       final response = await http.post(
//         Uri.parse(_httpEndpoint),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'jsonrpc': '2.0',
//           'method': 'eth_getBlockByNumber',
//           'params': ['pending', false],
//           'id': 1
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data['result'] != null && data['result']['transactions'] != null) {
//           return data['result']['transactions'].length;
//         }
//       }
//       // Fallback: generate mock values based on network
//       return _currentNetwork == NetworkType.ethereumMainnet
//           ? (1000 + (DateTime.now().second * 30))
//           : (100 + (DateTime.now().second * 5));
//     } catch (e) {
//       print('Error getting pending txs: $e');
//       // Fallback: generate mock values
//       return _currentNetwork == NetworkType.ethereumMainnet
//           ? (1000 + (DateTime.now().second * 30))
//           : (100 + (DateTime.now().second * 5));
//     }
//   }

//   // Calculate network utilization percentage
//   double _calculateUtilization(double gasPrice, int pendingTxCount) {
//     // Network-specific scaling factors
//     final baseGasPrice =
//         _currentNetwork == NetworkType.ethereumMainnet ? 15.0 : 3.0;
//     final maxGasPrice =
//         _currentNetwork == NetworkType.ethereumMainnet ? 100.0 : 30.0;
//     final basePendingTx =
//         _currentNetwork == NetworkType.ethereumMainnet ? 1000 : 200;
//     final maxPendingTx =
//         _currentNetwork == NetworkType.ethereumMainnet ? 5000 : 1000;

//     // Calculate utilization components
//     double gasPriceComponent =
//         ((gasPrice - baseGasPrice) / (maxGasPrice - baseGasPrice)) * 100;
//     gasPriceComponent = gasPriceComponent.clamp(0, 100);

//     double pendingTxComponent =
//         ((pendingTxCount - basePendingTx) / (maxPendingTx - basePendingTx)) *
//             100;
//     pendingTxComponent = pendingTxComponent.clamp(0, 100);

//     // Weighted average (60% gas price, 40% pending transactions)
//     return (gasPriceComponent * 0.6) + (pendingTxComponent * 0.4);
//   }

//   // Clean up resources
//   void dispose() {
//     _channel?.sink.close();
//     _controller.close();
//   }
// }
