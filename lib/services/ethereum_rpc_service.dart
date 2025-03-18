import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pyusd_hub/utils/formatter_utils.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import '../providers/network_provider.dart';
import '../screens/transactions/model/transaction_model.dart';

class EthereumRpcService {
  static const String erc20TransferAbi =
      '[{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"}]';

  static const String _tokenInfoAbi = '''
  [
    {"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},
    {"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},
    {"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"}
  ]
  ''';

  // Cache for Web3Client instances to avoid creating new ones for each request
  final Map<String, Web3Client> _clientCache = {};

  // API key for Etherscan
  static const String _etherscanApiKey = 'YBYI6VWHB8VIE5M8Z3BRPS4689N2VHV3SA';

  // Get or create a cached Web3Client
  Web3Client? _getClient(String rpcUrl) {
    if (!_clientCache.containsKey(rpcUrl)) {
      _clientCache[rpcUrl] = Web3Client(rpcUrl, http.Client());
    }
    return _clientCache[rpcUrl];
  }

  // Make HTTP POST request to RPC endpoint with error handling
  Future<Map<String, dynamic>> _makeRpcCall(
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

  // Get ETH balance for an address
  Future<double> getEthBalance(String rpcUrl, String address) async {
    if (address.isEmpty) return 0.0;

    try {
      final response = await _makeRpcCall(
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

      final response = await _makeRpcCall(
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

  // Get Etherscan API domain based on network type
  String _getEtherscanDomain(NetworkType networkType) {
    switch (networkType) {
      case NetworkType.sepoliaTestnet:
        return 'api-sepolia.etherscan.io';
      default:
        return 'api.etherscan.io';
    }
  }

  // Extract token information from transaction input data
  Future<(String, double, int?)> _extractTokenTransferData(
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
      final decimalsResponse = await _makeRpcCall(
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

  // Get chain ID for the current network
  Future<int> _getChainId(String rpcUrl) async {
    final chainIdResponse = await _makeRpcCall(rpcUrl, 'eth_chainId', []);
    final chainIdHex = chainIdResponse['result'] as String;
    return int.parse(chainIdHex.substring(2), radix: 16);
  }

  // Get account nonce
  Future<int> _getNonce(String rpcUrl, EthereumAddress sender) async {
    final nonceResponse = await _makeRpcCall(
        rpcUrl, 'eth_getTransactionCount', [sender.hex, 'latest']);
    final nonceHex = nonceResponse['result'] as String;
    return int.parse(nonceHex.substring(2), radix: 16);
  }

  // Get current gas price
  Future<BigInt> _getCurrentGasPrice(String rpcUrl) async {
    final gasPriceResponse = await _makeRpcCall(rpcUrl, 'eth_gasPrice', []);
    return FormatterUtils.parseBigInt(gasPriceResponse['result']);
  }

  // Send Ethereum transaction with improved error handling
  Future<String> sendEthTransaction(
      String rpcUrl, String privateKey, String toAddress, double amount,
      {double? gasPrice, int? gasLimit}) async {
    try {
      final credentials = EthPrivateKey.fromHex(privateKey);
      final sender = credentials.address;

      // Get chain ID, nonce, and gas price in parallel
      final futures = await Future.wait([
        _getChainId(rpcUrl),
        _getNonce(rpcUrl, sender),
        gasPrice == null
            ? _getCurrentGasPrice(rpcUrl)
            : Future.value(BigInt.from(gasPrice * 1e9)),
      ]);

      final chainId = futures[0] as int;
      final nonce = futures[1] as int;
      final gasPriceWei = futures[2] as BigInt;

      // Convert amount from ETH to wei
      final amountInWei = BigInt.from(amount * 1e18);

      // Use default gas limit if not provided
      final gas = gasLimit ?? 21000; // Standard gas limit for ETH transfers

      // Create transaction
      final tx = Transaction(
        from: sender,
        to: EthereumAddress.fromHex(toAddress),
        value: EtherAmount.fromBigInt(EtherUnit.wei, amountInWei),
        gasPrice: EtherAmount.fromBigInt(EtherUnit.wei, gasPriceWei),
        maxGas: gas,
        nonce: nonce,
      );

      // Get or create Web3Client
      final client = _getClient(rpcUrl);

      // Sign transaction
      final signedTx = await client?.signTransaction(
        credentials,
        tx,
        chainId: chainId,
      );

      // Send raw transaction
      final txResponse = await _makeRpcCall(
        rpcUrl,
        'eth_sendRawTransaction',
        ['0x${bytesToHex(signedTx!)}'],
      );

      return txResponse['result'];
    } catch (e) {
      throw Exception('Failed to send ETH transaction: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions(
    String address,
    NetworkType networkType, {
    int page = 1,
    int perPage = 20,
  }) async {
    final domain = _getEtherscanDomain(networkType);
    final uri = Uri.https(domain, '/api', {
      'module': 'account',
      'action': 'txlist',
      'address': address,
      'page': page.toString(),
      'offset': perPage.toString(),
      'sort': 'desc',
      'apikey': _etherscanApiKey,
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch transactions: ${response.statusCode}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] != '1') {
        // No transactions or error
        if (data['message'] == 'No transactions found') {
          return [];
        }
        throw Exception('Etherscan API error: ${data['message']}');
      }

      return List<Map<String, dynamic>>.from(data['result']);
    } catch (e) {
      print('Error fetching transactions: $e');
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  // Get token transactions for an address (from Etherscan API)
  Future<List<Map<String, dynamic>>> getTokenTransactions(
    String address,
    NetworkType networkType, {
    int page = 1,
    int perPage = 20,
  }) async {
    final domain = _getEtherscanDomain(networkType);
    final uri = Uri.https(domain, '/api', {
      'module': 'account',
      'action': 'tokentx',
      'address': address,
      'page': page.toString(),
      'offset': perPage.toString(),
      'sort': 'desc',
      'apikey': _etherscanApiKey,
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch token transactions: ${response.statusCode}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] != '1') {
        // No transactions or error
        if (data['message'] == 'No transactions found') {
          return [];
        }
        throw Exception('Etherscan API error: ${data['message']}');
      }

      return List<Map<String, dynamic>>.from(data['result']);
    } catch (e) {
      print('Error fetching token transactions: $e');
      throw Exception('Failed to fetch token transactions: $e');
    }
  }

  Future<TransactionDetailModel?> getTransactionDetails(
    String rpcUrl,
    String txHash,
    NetworkType networkType,
    String userAddress,
  ) async {
    try {
      // First get basic transaction information
      final txResponse = await _makeRpcCall(
        rpcUrl,
        'eth_getTransactionByHash',
        [txHash],
      );

      // Check if txResponse or txResponse['result'] is null
      if (txResponse == null || txResponse['result'] == null) {
        print('Transaction not found or returned null result: $txHash');
        return null;
      }

      final txData = txResponse['result'] as Map<String, dynamic>?;
      if (txData == null || txData.isEmpty) {
        print('Transaction data is null or empty: $txHash');
        return null;
      }

      // Get transaction receipt for status and gas used
      final receiptResponse = await _makeRpcCall(
        rpcUrl,
        'eth_getTransactionReceipt',
        [txHash],
      );

      final receiptData =
          receiptResponse != null && receiptResponse['result'] != null
              ? receiptResponse['result'] as Map<String, dynamic>?
              : null;

      // Handle pending transactions
      if (receiptData == null) {
        return TransactionDetailModel(
          hash: txHash,
          timestamp: DateTime.now(),
          from: txData['from'] ?? '',
          to: txData['to'] ?? '',
          amount: txData['value'] != null && txData['value'] != '0x0'
              ? FormatterUtils.parseBigInt(txData['value']).toDouble() / 1e18
              : 0.0,
          gasUsed: txData['gas'] != null
              ? FormatterUtils.parseBigInt(txData['gas']).toDouble()
              : 0.0,
          gasPrice: txData['gasPrice'] != null
              ? FormatterUtils.parseBigInt(txData['gasPrice']).toDouble() / 1e9
              : 0.0,
          status: TransactionStatus.pending,
          direction: _compareAddresses(txData['from'], userAddress)
              ? TransactionDirection.outgoing
              : TransactionDirection.incoming,
          confirmations: 0,
          network: networkType,
          blockNumber: 'Pending',
          nonce: txData['nonce'] != null
              ? int.parse(txData['nonce'].substring(2), radix: 16)
              : 0,
          blockHash: 'Pending',
          isError: false,
          data: txData['input'],
        );
      }

      // Get block for timestamp
      final blockResponse = await _makeRpcCall(
        rpcUrl,
        'eth_getBlockByHash',
        [receiptData['blockHash'], false],
      );

      // Check if blockResponse or blockResponse['result] is null
      if (blockResponse == null || blockResponse['result'] == null) {
        print('Block data not found: ${receiptData['blockHash']}');
        // Return transaction with estimated timestamp since we couldn't get the block
        return TransactionDetailModel(
          hash: txHash,
          timestamp: DateTime.now(), // Use current time as fallback
          from: txData['from'] ?? '',
          to: txData['to'] ?? '',
          amount: txData['value'] != null
              ? FormatterUtils.parseBigInt(txData['value']).toDouble() / 1e18
              : 0.0,
          gasUsed: receiptData['gasUsed'] != null
              ? FormatterUtils.parseBigInt(receiptData['gasUsed']).toDouble()
              : 0.0,
          gasPrice: txData['gasPrice'] != null
              ? FormatterUtils.parseBigInt(txData['gasPrice']).toDouble() / 1e9
              : 0.0,
          status: receiptData['status'] == '0x1'
              ? TransactionStatus.confirmed
              : TransactionStatus.failed,
          direction: _compareAddresses(txData['from'], userAddress)
              ? TransactionDirection.outgoing
              : TransactionDirection.incoming,
          confirmations: 0, // Can't calculate without block data
          network: networkType,
          blockNumber: receiptData['blockNumber'] != null
              ? FormatterUtils.parseBigInt(receiptData['blockNumber'])
                  .toString()
              : '0',
          nonce: txData['nonce'] != null
              ? int.parse(txData['nonce'].substring(2), radix: 16)
              : 0,
          blockHash: receiptData['blockHash'] ?? '',
          isError: receiptData['status'] != '0x1',
          data: txData['input'],
        );
      }

      final blockData = blockResponse['result'] as Map<String, dynamic>;

      // Check if it's a token transfer
      bool isTokenTransfer = txData['input'] != null &&
          txData['input'].toString().startsWith('0xa9059cbb');

      String toAddress = txData['to'] ?? '';
      double amount = 0.0;
      String? tokenSymbol;
      String? tokenName;
      int? tokenDecimals;
      String? tokenContractAddress;

      if (isTokenTransfer) {
        // Get token details
        try {
          tokenContractAddress = toAddress;
          final tokenDetails = await getTokenDetails(rpcUrl, toAddress);
          tokenName = tokenDetails['name'];
          tokenSymbol = tokenDetails['symbol'];
          tokenDecimals = tokenDetails['decimals'];

          // Extract token transfer details
          final (actualTo, tokenValue, decimals) =
              await _extractTokenTransferData(rpcUrl, txData, toAddress);
          toAddress = actualTo;
          amount = tokenValue;
          tokenDecimals = decimals;
        } catch (e) {
          print('Error getting token details: $e');
        }
      } else {
        // Regular ETH transfer
        amount = txData['value'] != null
            ? FormatterUtils.parseBigInt(txData['value']).toDouble() / 1e18
            : 0.0;
      }

      // Determine transaction status
      final status = receiptData['status'] == '0x1'
          ? TransactionStatus.confirmed
          : TransactionStatus.failed;

      // Calculate confirmations
      final txBlockNumber =
          FormatterUtils.parseBigInt(receiptData['blockNumber']);
      final confirmations =
          await _calculateConfirmations(rpcUrl, txBlockNumber);

      // Determine basic error status for failed transactions
      String? errorMessage;
      if (status == TransactionStatus.failed) {
        errorMessage = 'Transaction failed';

        // Basic failure detection without trace data
        final gasUsed = receiptData['gasUsed'] != null
            ? FormatterUtils.parseBigInt(receiptData['gasUsed']).toDouble()
            : 0.0;
        final gasLimit = txData['gas'] != null
            ? FormatterUtils.parseBigInt(txData['gas']).toDouble()
            : 0.0;

        if (gasUsed >= gasLimit * 0.95) {
          errorMessage = 'Transaction failed. Likely out of gas.';
        }
      }

      return TransactionDetailModel(
        hash: txHash,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            int.parse(blockData['timestamp'].substring(2), radix: 16) * 1000),
        from: txData['from'] ?? '',
        to: toAddress,
        amount: amount,
        gasUsed: receiptData['gasUsed'] != null
            ? FormatterUtils.parseBigInt(receiptData['gasUsed']).toDouble()
            : 0.0,
        gasPrice: txData['gasPrice'] != null
            ? FormatterUtils.parseBigInt(txData['gasPrice']).toDouble() / 1e9
            : 0.0,
        status: status,
        direction: _compareAddresses(txData['from'], userAddress)
            ? TransactionDirection.outgoing
            : TransactionDirection.incoming,
        confirmations: confirmations,
        tokenSymbol: tokenSymbol,
        tokenName: tokenName,
        tokenDecimals: tokenDecimals,
        tokenContractAddress: tokenContractAddress,
        network: networkType,
        blockNumber: receiptData['blockNumber'] != null
            ? FormatterUtils.parseBigInt(receiptData['blockNumber']).toString()
            : '0',
        nonce: txData['nonce'] != null
            ? int.parse(txData['nonce'].substring(2), radix: 16)
            : 0,
        blockHash: receiptData['blockHash'] ?? '',
        isError: status == TransactionStatus.failed,
        errorMessage: errorMessage,
        data: txData['input'],
      );
    } catch (e) {
      print('Exception in getTransactionDetails: $e');
      // Return null instead of throwing an exception
      return null;
    }
  }

  // Helper method to compare addresses (case-insensitive)
  bool _compareAddresses(String? address1, String? address2) {
    if (address1 == null || address2 == null) return false;
    return address1.toLowerCase() == address2.toLowerCase();
  }

  // Send token transaction with improved error handling
  Future<String> sendTokenTransaction(
      String rpcUrl,
      String privateKey,
      String contractAddress,
      String toAddress,
      double amount,
      int tokenDecimals,
      {double? gasPrice,
      int? gasLimit}) async {
    try {
      final credentials = EthPrivateKey.fromHex(privateKey);
      final sender = credentials.address;

      // Get chain ID, nonce, and gas price in parallel
      final futures = await Future.wait([
        _getChainId(rpcUrl),
        _getNonce(rpcUrl, sender),
        gasPrice == null
            ? _getCurrentGasPrice(rpcUrl)
            : Future.value(BigInt.from(gasPrice * 1e9)),
      ]);

      final chainId = futures[0] as int;
      final nonce = futures[1] as int;
      final gasPriceWei = futures[2] as BigInt;

      // Convert amount to token units
      final amountInTokenUnits =
          BigInt.from(amount * BigInt.from(10).pow(tokenDecimals).toDouble());

      // Use default gas limit for token transfers if not provided
      final gas = gasLimit ?? 100000; // Higher gas limit for token transfers

      // Create contract and prepare transfer call data
      final client = _getClient(rpcUrl);
      final contract = DeployedContract(
        ContractAbi.fromJson(erc20TransferAbi, 'Token'),
        EthereumAddress.fromHex(contractAddress),
      );

      final transferFunction = contract.function('transfer');
      final callData = transferFunction.encodeCall([
        EthereumAddress.fromHex(toAddress),
        amountInTokenUnits,
      ]);

      // Create transaction
      final tx = Transaction(
        from: sender,
        to: EthereumAddress.fromHex(contractAddress),
        value: EtherAmount.zero(),
        gasPrice: EtherAmount.fromBigInt(EtherUnit.wei, gasPriceWei),
        maxGas: gas,
        nonce: nonce,
        data: callData,
      );

      // Sign transaction
      final signedTx = await client?.signTransaction(
        credentials,
        tx,
        chainId: chainId,
      );

      // Send raw transaction
      final txResponse = await _makeRpcCall(
        rpcUrl,
        'eth_sendRawTransaction',
        ['0x${bytesToHex(signedTx!)}'],
      );

      return txResponse['result'];
    } catch (e) {
      throw Exception('Failed to send token transaction: $e');
    }
  }

  // Estimate gas for ETH transaction
  Future<int> estimateEthGas(String rpcUrl, String fromAddress,
      String toAddress, double amount) async {
    try {
      // Convert amount from ETH to wei
      final amountInWei = BigInt.from(amount * 1e18);

      final response = await _makeRpcCall(
        rpcUrl,
        'eth_estimateGas',
        [
          {
            'from': fromAddress,
            'to': toAddress,
            'value': '0x${amountInWei.toRadixString(16)}',
          }
        ],
      );

      final hexValue = response['result'] as String;
      return int.parse(hexValue.substring(2), radix: 16);
    } catch (e) {
      throw Exception('Failed to estimate gas: $e');
    }
  }

  // Estimate gas for token transaction
  Future<int> estimateTokenGas(
      String rpcUrl,
      String fromAddress,
      String contractAddress,
      String toAddress,
      double amount,
      int tokenDecimals) async {
    try {
      // Convert amount to token units
      final amountInTokenUnits =
          BigInt.from(amount * BigInt.from(10).pow(tokenDecimals).toDouble());

      // Create contract instance
      final contract = DeployedContract(
        ContractAbi.fromJson(erc20TransferAbi, 'Token'),
        EthereumAddress.fromHex(contractAddress),
      );

      final transferFunction = contract.function('transfer');
      final callData = transferFunction.encodeCall([
        EthereumAddress.fromHex(toAddress),
        amountInTokenUnits,
      ]);

      final response = await _makeRpcCall(
        rpcUrl,
        'eth_estimateGas',
        [
          {
            'from': fromAddress,
            'to': contractAddress,
            'data': '0x${bytesToHex(callData)}',
          }
        ],
      );

      final hexValue = response['result'] as String;
      return int.parse(hexValue.substring(2), radix: 16);
    } catch (e) {
      throw Exception('Failed to estimate token gas: $e');
    }
  }

  // Get token details (name, symbol, decimals) with improved error handling
  Future<Map<String, dynamic>> getTokenDetails(
      String rpcUrl, String contractAddress) async {
    final client = _getClient(rpcUrl);

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

  // Check if an address is a contract
  Future<bool> isContract(String rpcUrl, String address) async {
    try {
      final response = await _makeRpcCall(
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

  // Get gas price with better error handling
  Future<double> getGasPrice(String rpcUrl) async {
    try {
      final response = await _makeRpcCall(rpcUrl, 'eth_gasPrice', []);
      final BigInt weiGasPrice = FormatterUtils.parseBigInt(response['result']);
      return weiGasPrice / BigInt.from(10).pow(9); // Convert to Gwei
    } catch (e) {
      print('Error fetching gas price: $e');
      return 0.0;
    }
  }

  // Helper method to calculate confirmations
  Future<int> _calculateConfirmations(
      String rpcUrl, BigInt txBlockNumber) async {
    try {
      final response = await _makeRpcCall(rpcUrl, 'eth_blockNumber', []);
      final BigInt currentBlock =
          FormatterUtils.parseBigInt(response['result']);
      return (currentBlock - txBlockNumber).toInt();
    } catch (e) {
      print('Error calculating confirmations: $e');
      return 0;
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
