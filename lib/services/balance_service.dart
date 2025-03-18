import 'package:web3dart/web3dart.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';
import 'ethereum_rpc_client.dart';

/// Service to handle balance-related operations
class BalanceService {
  final EthereumRpcClient _rpcClient;

  BalanceService(this._rpcClient);

  // Get ETH balance for an address
  Future<double> getEthBalance(String rpcUrl, String address) async {
    if (address.isEmpty) return 0.0;

    try {
      final response = await _rpcClient.makeRpcCall(
        rpcUrl,
        'eth_getBalance',
        [address, 'latest'],
      );

      final BigInt weiBalance = FormatterUtils.parseBigInt(response['result']);
      return EtherAmount.fromBigInt(EtherUnit.wei, weiBalance)
          .getValueInUnit(EtherUnit.ether);
    } catch (e) {
      print('Error fetching ETH balance: $e');
      return 0.0;
    }
  }

  // Get token balance
  Future<double> getTokenBalance(
    String rpcUrl,
    String tokenContractAddress,
    String walletAddress, {
    int decimals = 6, // Default to 6 decimals for PYUSD
  }) async {
    if (walletAddress.isEmpty || tokenContractAddress.isEmpty) return 0.0;

    try {
      // ERC20 balanceOf function signature + wallet address (padded)
      final String data =
          '0x70a08231000000000000000000000000${walletAddress.replaceAll('0x', '')}';

      final response = await _rpcClient.makeRpcCall(
        rpcUrl,
        'eth_call',
        [
          {
            'to': tokenContractAddress,
            'data': data,
          },
          'latest'
        ],
      );

      final String hexBalance = response['result'];
      if (hexBalance == '0x') return 0.0;

      final BigInt tokenBalance = FormatterUtils.parseBigInt(hexBalance);
      return tokenBalance / BigInt.from(10).pow(decimals);
    } catch (e) {
      print('Error fetching token balance: $e');
      return 0.0;
    }
  }
}
