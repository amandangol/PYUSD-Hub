import 'package:flutter_dotenv/flutter_dotenv.dart';

class RpcEndpoints {
  static String get mainnetHttpRpcUrl =>
      dotenv.env['MAINNET_HTTP_RPC_URL'] ?? '';
  static String get mainnetWssRpcUrl => dotenv.env['MAINNET_WSS_RPC_URL'] ?? '';
  static String get sepoliaTestnetHttpRpcUrl =>
      dotenv.env['SEPOLIA_HTTP_RPC_URL'] ?? '';
  static String get sepoliaTestnetWssRpcUrl =>
      dotenv.env['SEPOLIA_WSS_RPC_URL'] ?? '';

  static const String getBlockByNumber = 'eth_getBlockByNumber';
  static const String getTransactionByHash = 'eth_getTransactionByHash';
  static const String getTransactionReceipt = 'eth_getTransactionReceipt';
  static const String getBalance = 'eth_getBalance';
  static const String getBlockNumber = 'eth_blockNumber';
  static const String call = 'eth_call';
  static const String estimateGas = 'eth_estimateGas';
  static const String gasPrice = 'eth_gasPrice';
  static const String sendRawTransaction = 'eth_sendRawTransaction';

  static const String latest = 'latest';
  static const String pending = 'pending';
  static const String earliest = 'earliest';
}
