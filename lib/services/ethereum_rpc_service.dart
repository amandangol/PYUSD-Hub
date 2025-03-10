import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import '../screens/transactions/transaction_details/model/transaction.dart';
import '../providers/network_provider.dart';

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

  // Helper method to safely parse BigInt from hex strings
  BigInt _parseBigInt(String? hex) {
    if (hex == null || hex.isEmpty || hex == '0x0' || hex == '0x') {
      return BigInt.zero;
    }
    return BigInt.parse(hex.startsWith('0x') ? hex.substring(2) : hex,
        radix: 16);
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

      final BigInt weiBalance = _parseBigInt(response['result']);
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

      final BigInt tokenBalance = _parseBigInt(hexBalance);
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

  // Get recent transactions for an address
  Future<List<TransactionModel>> getTransactions(
      String rpcUrl, String address, NetworkType networkType,
      {int limit = 10}) async {
    if (address.isEmpty) return [];

    try {
      final String apiDomain = _getEtherscanDomain(networkType);

      // Common query parameters
      final Map<String, String> commonParams = {
        'address': address,
        'startblock': '0',
        'endblock': '99999999',
        'page': '1',
        'offset': limit.toString(),
        'sort': 'desc',
        'apikey': _etherscanApiKey,
      };

      // Get normal ETH transactions
      final Uri ethTxUrl = Uri.https(apiDomain, '/api', {
        'module': 'account',
        'action': 'txlist',
        ...commonParams,
      });

      // Get ERC20 token transactions
      final Uri tokenTxUrl = Uri.https(apiDomain, '/api', {
        'module': 'account',
        'action': 'tokentx',
        ...commonParams,
      });

      // Execute requests in parallel
      final futures = await Future.wait([
        http.get(ethTxUrl),
        http.get(tokenTxUrl),
      ]);

      final ethResponse = futures[0];
      final tokenResponse = futures[1];

      List<TransactionModel> allTransactions = [];

      // Process ETH transactions
      if (ethResponse.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(ethResponse.body);

        if (jsonResponse['status'] == '1' && jsonResponse['result'] is List) {
          final List<dynamic> txList = jsonResponse['result'];

          // Convert raw JSON to TransactionModel objects
          allTransactions.addAll(txList.map((tx) {
            final bool isOutgoing =
                address.toLowerCase() == tx['from'].toString().toLowerCase();
            final BigInt valueWei = _parseBigInt(tx['value']);
            final double valueEth = valueWei / BigInt.from(10).pow(18);

            return TransactionModel(
              hash: tx['hash'],
              from: tx['from'],
              to: tx['to'],
              value: valueEth,
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                  int.parse(tx['timeStamp']) * 1000),
              networkType: networkType,
              direction: isOutgoing
                  ? TransactionDirection.outgoing
                  : TransactionDirection.incoming,
              status: tx['txreceipt_status'] == '1'
                  ? TransactionStatus.confirmed
                  : TransactionStatus.failed,
            );
          }));
        }
      }

      // Process token transactions
      if (tokenResponse.statusCode == 200) {
        final Map<String, dynamic> jsonResponse =
            jsonDecode(tokenResponse.body);

        if (jsonResponse['status'] == '1' && jsonResponse['result'] is List) {
          final List<dynamic> txList = jsonResponse['result'];

          // Convert raw JSON to TransactionModel objects
          allTransactions.addAll(txList.map((tx) {
            final bool isOutgoing =
                address.toLowerCase() == tx['from'].toString().toLowerCase();
            final int tokenDecimals = int.parse(tx['tokenDecimal']);

            // Handle different value formats safely
            BigInt tokenValueWei;
            if (tx['value'] is String) {
              final String valueStr = tx['value'];
              tokenValueWei = valueStr.startsWith('0x')
                  ? _parseBigInt(valueStr)
                  : BigInt.parse(valueStr);
            } else {
              tokenValueWei = BigInt.from(tx['value'] as int? ?? 0);
            }

            final double tokenValue =
                tokenValueWei / BigInt.from(10).pow(tokenDecimals);

            return TransactionModel(
              hash: tx['hash'],
              from: tx['from'],
              to: tx['to'],
              value: tokenValue,
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                  int.parse(tx['timeStamp']) * 1000),
              networkType: networkType,
              direction: isOutgoing
                  ? TransactionDirection.outgoing
                  : TransactionDirection.incoming,
              status: TransactionStatus.confirmed,
              tokenSymbol: tx['tokenSymbol'],
              tokenContractAddress: tx['contractAddress'],
              tokenDecimals: tokenDecimals,
            );
          }));
        }
      }

      // Sort all transactions by timestamp (newest first)
      allTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Limit the combined result
      return allTransactions.length > limit
          ? allTransactions.sublist(0, limit)
          : allTransactions;
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
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
        tokenDecimals = _parseBigInt(decimalsResponse['result']).toInt();
      } else {
        tokenDecimals = 18; // Default to 18 decimals
      }

      // Extract token value from input data
      if (tx['input'].length >= 138) {
        final String valueHex = tx['input'].substring(74);
        final BigInt tokenValueBigInt = _parseBigInt("0x" + valueHex);
        tokenValue = tokenValueBigInt / BigInt.from(10).pow(tokenDecimals);
      }
    } catch (e) {
      print('Error extracting token transfer data: $e');
      tokenDecimals = 18; // Default to 18 decimals
    }

    return (actualTo, tokenValue, tokenDecimals);
  }

  // Get detailed transaction information using JSON RPC
  Future<TransactionDetailModel?> getTransactionDetails(
    String rpcUrl,
    String txHash,
    NetworkType networkType,
    String currentAddress,
  ) async {
    if (txHash.isEmpty) return null;

    try {
      // Execute requests in parallel to improve performance
      final futures = await Future.wait([
        _makeRpcCall(rpcUrl, 'eth_getTransactionByHash', [txHash]),
        _makeRpcCall(rpcUrl, 'eth_getTransactionReceipt', [txHash]),
      ]);

      final txResponse = futures[0];
      final receiptResponse = futures[1];

      if (txResponse['result'] == null) {
        throw Exception('Transaction not found');
      }

      final tx = txResponse['result'];
      final receipt = receiptResponse['result'];

      // Get block info only if transaction is confirmed
      final blockResponse = tx['blockHash'] != null
          ? await _makeRpcCall(
              rpcUrl, 'eth_getBlockByHash', [tx['blockHash'], false])
          : {'result': null};

      final block = blockResponse['result'];

      // Parse basic transaction data
      final String from = tx['from'];
      final String to = tx['to'] ?? 'Contract Creation';
      final BigInt valueWei = _parseBigInt(tx['value']);
      final double valueEth = EtherAmount.fromBigInt(
        EtherUnit.wei,
        valueWei,
      ).getValueInUnit(EtherUnit.ether);

      // Parse gas data
      final BigInt gasLimit = _parseBigInt(tx['gas']);
      final BigInt gasUsed =
          receipt != null ? _parseBigInt(receipt['gasUsed']) : BigInt.zero;
      final BigInt gasPrice = _parseBigInt(tx['gasPrice']);
      final double feeEth = EtherAmount.fromBigInt(
        EtherUnit.wei,
        gasUsed * gasPrice,
      ).getValueInUnit(EtherUnit.ether);

      // Parse timestamp
      final BigInt timestamp =
          block != null ? _parseBigInt(block['timestamp']) : BigInt.zero;
      final DateTime dateTime =
          DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);

      // Determine transaction status
      TransactionStatus status;
      if (receipt == null) {
        status = TransactionStatus.pending;
      } else if (receipt['status'] == '0x1') {
        status = TransactionStatus.confirmed;
      } else {
        status = TransactionStatus.failed;
      }

      // Get block number
      final BigInt blockNumber =
          block != null ? _parseBigInt(block['number']) : BigInt.zero;

      // Token transfer variables
      String? tokenSymbol;
      String? tokenContractAddress;
      int? tokenDecimals;
      double tokenValue = 0.0;
      String actualTo = to;

      // Check if this is a token transfer
      if (tx['input'].startsWith('0xa9059cbb')) {
        tokenContractAddress = to;

        // Extract token transfer details
        final tokenTransferData =
            await _extractTokenTransferData(rpcUrl, tx, to);
        actualTo = tokenTransferData.$1;
        tokenValue = tokenTransferData.$2;
        tokenDecimals = tokenTransferData.$3;

        // Try to fetch token symbol
        try {
          // Symbol function signature: '0x95d89b41'
          final symbolResponse = await _makeRpcCall(
            rpcUrl,
            'eth_call',
            [
              {'to': tokenContractAddress, 'data': '0x95d89b41'},
              'latest'
            ],
          );

          final String symbolHex = symbolResponse['result'];
          if (symbolHex.length > 2) {
            final String hexString =
                symbolHex.substring(130).replaceAll('00', '');
            tokenSymbol = String.fromCharCodes(
              List.generate(
                hexString.length ~/ 2,
                (i) =>
                    int.parse(hexString.substring(i * 2, i * 2 + 2), radix: 16),
              ),
            );
          } else {
            tokenSymbol = 'Unknown Token';
          }
        } catch (e) {
          print('Error fetching token symbol: $e');
          tokenSymbol = 'Unknown Token';
        }
      }

      // Determine transaction direction
      final bool isOutgoing =
          currentAddress.toLowerCase() == from.toLowerCase();
      final TransactionDirection direction = isOutgoing
          ? TransactionDirection.outgoing
          : TransactionDirection.incoming;

      // Get confirmations if transaction is confirmed
      final int confirmations = block != null
          ? await _calculateConfirmations(rpcUrl, blockNumber)
          : 0;

      // Create transaction detail model
      return TransactionDetailModel(
        hash: txHash,
        from: from,
        to: actualTo,
        value: tokenContractAddress != null ? tokenValue : valueEth,
        timestamp: dateTime,
        blockNumber: blockNumber.toInt(),
        gasLimit: gasLimit.toDouble(),
        gasPrice: EtherAmount.fromBigInt(
          EtherUnit.wei,
          gasPrice,
        ).getValueInUnit(EtherUnit.gwei),
        gasUsed: gasUsed.toDouble(),
        fee: feeEth,
        status: status,
        networkType: networkType,
        direction: direction,
        tokenContractAddress: tokenContractAddress,
        tokenSymbol: tokenSymbol,
        tokenDecimals: tokenDecimals,
        nonce: _parseBigInt(tx['nonce']).toInt(),
        input: tx['input'],
        confirmations: confirmations,
      );
    } catch (e) {
      print('Error fetching transaction details: $e');
      return null;
    }
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
    return _parseBigInt(gasPriceResponse['result']);
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
      final BigInt weiGasPrice = _parseBigInt(response['result']);
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
      final BigInt currentBlock = _parseBigInt(response['result']);
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
