import 'package:web3dart/web3dart.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';
import 'ethereum_rpc_client.dart';

/// Utility functions for blockchain interactions
class BlockchainUtils {
  final EthereumRpcClient _rpcClient;

  BlockchainUtils(this._rpcClient);

  // Get chain ID for the current network
  Future<int> getChainId(String rpcUrl) async {
    final chainIdResponse =
        await _rpcClient.makeRpcCall(rpcUrl, 'eth_chainId', []);
    final chainIdHex = chainIdResponse['result'] as String;
    return int.parse(chainIdHex.substring(2), radix: 16);
  }

  // Get account nonce
  Future<int> getNonce(String rpcUrl, EthereumAddress sender) async {
    final nonceResponse = await _rpcClient
        .makeRpcCall(rpcUrl, 'eth_getTransactionCount', [sender.hex, 'latest']);
    final nonceHex = nonceResponse['result'] as String;
    return int.parse(nonceHex.substring(2), radix: 16);
  }

  // Get current gas price
  Future<BigInt> getCurrentGasPrice(String rpcUrl) async {
    final gasPriceResponse =
        await _rpcClient.makeRpcCall(rpcUrl, 'eth_gasPrice', []);
    return FormatterUtils.parseBigInt(gasPriceResponse['result']);
  }

  // Get gas price with better error handling
  Future<double> getGasPrice(String rpcUrl) async {
    try {
      final response = await _rpcClient.makeRpcCall(rpcUrl, 'eth_gasPrice', []);
      final BigInt weiGasPrice = FormatterUtils.parseBigInt(response['result']);
      return weiGasPrice / BigInt.from(10).pow(9); // Convert to Gwei
    } catch (e) {
      print('Error fetching gas price: $e');
      return 0.0;
    }
  }

  // Check if an address is a contract
  Future<bool> isContract(String rpcUrl, String address) async {
    try {
      final response = await _rpcClient.makeRpcCall(
        rpcUrl,
        'eth_getCode',
        [address, 'latest'],
      );

      final code = response['result'] as String;
      return code != '0x' && code.length > 2;
    } catch (e) {
      throw Exception('Failed to check if address is contract: $e');
    }
  }

  // Helper method to calculate confirmations
  Future<int> calculateConfirmations(
      String rpcUrl, BigInt txBlockNumber) async {
    try {
      final response =
          await _rpcClient.makeRpcCall(rpcUrl, 'eth_blockNumber', []);
      final BigInt currentBlock =
          FormatterUtils.parseBigInt(response['result']);
      return (currentBlock - txBlockNumber).toInt();
    } catch (e) {
      print('Error calculating confirmations: $e');
      return 0;
    }
  }

  // Helper method to compare addresses (case-insensitive)
  bool compareAddresses(String? address1, String? address2) {
    if (address1 == null || address2 == null) return false;
    return address1.toLowerCase() == address2.toLowerCase();
  }
}
