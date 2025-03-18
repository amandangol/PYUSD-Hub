import 'package:web3dart/web3dart.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';
import 'ethereum_rpc_client.dart';

/// Service for token-related operations
class TokenService {
  static const String _tokenInfoAbi = '''
  [
    {"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},
    {"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},
    {"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"}
  ]
  ''';

  final EthereumRpcClient _rpcClient;

  TokenService(this._rpcClient);

  // Extract token information from transaction input data
  Future<(String, double, int?)> extractTokenTransferData(
      String rpcUrl, Map<String, dynamic> tx, String to) async {
    String tokenContractAddress = to;
    String actualTo = to;
    double tokenValue = 0.0;
    int? tokenDecimals;

    // Extract recipient address from input data
    if (tx['input'].length >= 74) {
      actualTo = '0x' + tx['input'].substring(34, 74);
    }

    // Try to fetch token decimals
    try {
      // Decimals function signature: '0x313ce567'
      final decimalsResponse = await _rpcClient.makeRpcCall(
        rpcUrl,
        'eth_call',
        [
          {'to': tokenContractAddress, 'data': '0x313ce567'},
          'latest'
        ],
      );

      // Parse token decimals
      if (decimalsResponse['result'].length > 2) {
        tokenDecimals =
            FormatterUtils.parseBigInt(decimalsResponse['result']).toInt();
      } else {
        tokenDecimals = 18; // Default to 18 decimals
      }

      // Extract token value from input data
      if (tx['input'].length >= 138) {
        final String valueHex = tx['input'].substring(74);
        final BigInt tokenValueBigInt =
            FormatterUtils.parseBigInt("0x" + valueHex);
        tokenValue = tokenValueBigInt / BigInt.from(10).pow(tokenDecimals);
      }
    } catch (e) {
      print('Error extracting token transfer data: $e');
      tokenDecimals = 18; // Default to 18 decimals
    }

    return (actualTo, tokenValue, tokenDecimals);
  }

  // Get token details (name, symbol, decimals) with improved error handling
  Future<Map<String, dynamic>> getTokenDetails(
      String rpcUrl, String contractAddress) async {
    final client = _rpcClient.getClient(rpcUrl);

    final contract = DeployedContract(
      ContractAbi.fromJson(_tokenInfoAbi, 'TokenInfo'),
      EthereumAddress.fromHex(contractAddress),
    );

    // Default values
    String name = 'Unknown';
    String symbol = 'UNK';
    int decimals = 18;

    try {
      // Get name
      try {
        final nameFunction = contract.function('name');
        final nameResult = await client?.call(
          contract: contract,
          function: nameFunction,
          params: [],
        );
        if (nameResult!.isNotEmpty) {
          name = nameResult[0].toString();
        }
      } catch (_) {}

      // Get symbol
      try {
        final symbolFunction = contract.function('symbol');
        final symbolResult = await client!.call(
          contract: contract,
          function: symbolFunction,
          params: [],
        );
        if (symbolResult.isNotEmpty) {
          symbol = symbolResult[0].toString();
        }
      } catch (_) {}

      // Get decimals
      try {
        final decimalsFunction = contract.function('decimals');
        final decimalsResult = await client?.call(
          contract: contract,
          function: decimalsFunction,
          params: [],
        );
        if (decimalsResult!.isNotEmpty) {
          decimals = decimalsResult[0] as int;
        }
      } catch (_) {}

      return {
        'name': name,
        'symbol': symbol,
        'decimals': decimals,
        'address': contractAddress,
      };
    } catch (e) {
      throw Exception('Failed to get token details: $e');
    }
  }
}
