// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:http/http.dart';
// import 'package:web3dart/web3dart.dart';

// class BlockchainService {
//   static const String _etherscanApiKey =
//       'YBYI6VWHB8VIE5M8Z3BRPS4689N2VHV3SA'; // Replace with your API key
//   static const String _pyusdContractAddress =
//       '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8'; // PYUSD contract address
//   static const String _etherscanBaseUrl = 'https://api.etherscan.io/api';

//   final Web3Client _web3Client;

//   BlockchainService()
//       : _web3Client = Web3Client(
//           'https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID', // Replace with your Infura project ID
//           Client(),
//         );

//   Future<Map<String, dynamic>> getNetworkCongestion() async {
//     try {
//       // Get current gas price
//       final gasPrice = await _web3Client.getGasPrice();

//       // Get pending transactions count
//       final pendingTxs = await _getPendingTransactions();

//       // Get PYUSD transaction count
//       final pyusdTxs = await _getPyusdTransactionCount();

//       // Calculate gas usage percentage
//       final gasUsage = await _calculateGasUsage();

//       return {
//         'currentGasPrice': gasPrice.getInWei,
//         'pendingTransactions': pendingTxs,
//         'confirmedPyusdTxCount': pyusdTxs,
//         'gasUsagePercentage': gasUsage,
//         'blockTime': 12, // Average Ethereum block time
//       };
//     } catch (e) {
//       print('Error fetching network congestion: $e');
//       return _getDefaultData();
//     }
//   }

//   Future<List<Map<String, dynamic>>> getRecentPyusdTransactions() async {
//     try {
//       final response = await http.get(Uri.parse(
//           '$_etherscanBaseUrl?module=account&action=tokentx&contractaddress=$_pyusdContractAddress&page=1&offset=100&sort=desc&apikey=$_etherscanApiKey'));

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['status'] == '1') {
//           return List<Map<String, dynamic>>.from(data['result']);
//         }
//       }
//       return [];
//     } catch (e) {
//       print('Error fetching recent transactions: $e');
//       return [];
//     }
//   }

//   Future<int> _getPendingTransactions() async {
//     try {
//       final response = await http.get(Uri.parse(
//           '$_etherscanBaseUrl?module=proxy&action=eth_getBlockByNumber&tag=latest&boolean=true&apikey=$_etherscanApiKey'));

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return data['result']['transactions'].length;
//       }
//       return 0;
//     } catch (e) {
//       print('Error fetching pending transactions: $e');
//       return 0;
//     }
//   }

//   Future<int> _getPyusdTransactionCount() async {
//     try {
//       final response = await http.get(Uri.parse(
//           '$_etherscanBaseUrl?module=proxy&action=eth_getTransactionCount&address=$_pyusdContractAddress&tag=latest&apikey=$_etherscanApiKey'));

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return int.parse(data['result'], radix: 16);
//       }
//       return 0;
//     } catch (e) {
//       print('Error fetching PYUSD transaction count: $e');
//       return 0;
//     }
//   }

//   Future<double> _calculateGasUsage() async {
//     try {
//       final response = await http.get(Uri.parse(
//           '$_etherscanApiKey?module=gastracker&action=gasoracle&apikey=$_etherscanApiKey'));

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['status'] == '1') {
//           final safeLow = int.parse(data['result']['SafeGasPrice']);
//           final standard = int.parse(data['result']['ProposeGasPrice']);
//           final fast = int.parse(data['result']['FastGasPrice']);

//           // Calculate average gas usage percentage based on gas prices
//           return (standard / fast) * 100;
//         }
//       }
//       return 0.0;
//     } catch (e) {
//       print('Error calculating gas usage: $e');
//       return 0.0;
//     }
//   }

//   Map<String, dynamic> _getDefaultData() {
//     return {
//       'currentGasPrice': BigInt.from(20000000000), // 20 Gwei
//       'pendingTransactions': 0,
//       'confirmedPyusdTxCount': 0,
//       'gasUsagePercentage': 0.0,
//       'blockTime': 12,
//     };
//   }
// }
