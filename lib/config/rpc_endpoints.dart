import 'package:flutter_dotenv/flutter_dotenv.dart';

class RpcEndpoints {
  static String get mainnetHttpRpcUrl =>
      dotenv.env['MAINNET_HTTP_RPC_URL'] ?? '';
  static String get mainnetWssRpcUrl => dotenv.env['MAINNET_WSS_RPC_URL'] ?? '';
  static String get sepoliaTestnetHttpRpcUrl =>
      dotenv.env['SEPOLIA_HTTP_RPC_URL'] ?? '';
  static String get sepoliaTestnetWssRpcUrl =>
      dotenv.env['SEPOLIA_WSS_RPC_URL'] ?? '';
}
