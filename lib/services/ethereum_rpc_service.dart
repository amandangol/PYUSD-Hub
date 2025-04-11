import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/rpc_endpoints.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import '../providers/network_provider.dart';
import '../screens/transactions/model/transaction_model.dart';
import 'dart:math' as Math;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EthereumRpcService {
  static final EthereumRpcService _instance = EthereumRpcService._internal();
  factory EthereumRpcService() => _instance;
  EthereumRpcService._internal();

  static const String erc20TransferAbi =
      '[{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"}]';

  static const String _tokenInfoAbi = '''
  [
    {"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},
    {"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},
    {"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"}
  ]
  ''';

  final Map<String, Web3Client> _clientPool = {};
  static const int _maxPoolSize = 5;

  Web3Client _getClient(String rpcUrl) {
    if (!_clientPool.containsKey(rpcUrl)) {
      if (_clientPool.length >= _maxPoolSize) {
        final oldestUrl = _clientPool.keys.first;
        _clientPool[oldestUrl]?.dispose();
        _clientPool.remove(oldestUrl);
      }
      _clientPool[rpcUrl] = Web3Client(rpcUrl, http.Client());
    }
    return _clientPool[rpcUrl]!;
  }

  Future<Map<String, dynamic>> _makeRpcCall(
    String rpcUrl,
    String method,
    List<dynamic> params, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final client = http.Client();
      try {
        final requestBody = {
          'jsonrpc': '2.0',
          'id': 1,
          'method': method,
          'params': params,
        };

        print('Making RPC call to $rpcUrl');
        print('Method: $method');
        print('Params: ${jsonEncode(params)}');

        final response = await client
            .post(
              Uri.parse(rpcUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestBody),
            )
            .timeout(timeout);

        if (response.statusCode != 200) {
          print('RPC Error Response: ${response.body}');
          throw Exception(
              'Failed to connect to Ethereum node: ${response.statusCode}. Response: ${response.body}');
        }

        final result = jsonDecode(response.body);

        if (result['error'] != null) {
          print('RPC Error: ${result['error']}');
          throw Exception('RPC Error: ${result['error']['message']}');
        }

        return result;
      } finally {
        client.close();
      }
    } catch (e) {
      print('RPC call failed for $method: $e');
      throw Exception('RPC call failed for $method: $e');
    }
  }

  Future<Map<String, dynamic>> _makeRpcCallWithRetry(
    String rpcUrl,
    String method,
    List<dynamic> params, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await _makeRpcCall(rpcUrl, method, params);
      } catch (e) {
        attempts++;
        if (attempts == maxRetries) rethrow;
        await Future.delayed(delay * attempts);
      }
    }
    throw Exception('Failed after $maxRetries attempts');
  }

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

  Future<double> getTokenBalance(
    String rpcUrl,
    String tokenContractAddress,
    String walletAddress, {
    int decimals = 6,
  }) async {
    if (walletAddress.isEmpty || tokenContractAddress.isEmpty) return 0.0;

    try {
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

      if (hexBalance == '0x') {
        return 0.0;
      }

      final BigInt tokenBalance = FormatterUtils.parseBigInt(hexBalance);
      return tokenBalance / BigInt.from(10).pow(decimals);
    } catch (e) {
      print('Error fetching token balance: $e');
      return 0.0;
    }
  }

  String _getEtherscanDomain(NetworkType networkType) {
    switch (networkType) {
      case NetworkType.sepoliaTestnet:
        return 'api-sepolia.etherscan.io';
      default:
        return 'api.etherscan.io';
    }
  }

  Future<(String, double, int?)> _extractTokenTransferData(
      String rpcUrl, Map<String, dynamic> tx, String to) async {
    String tokenContractAddress = to;
    String actualTo = to;
    double tokenValue = 0.0;
    int? tokenDecimals;

    if (tx['input'].length >= 74) {
      actualTo = '0x' + tx['input'].substring(34, 74);
    }

    try {
      final decimalsResponse = await _makeRpcCall(
        rpcUrl,
        'eth_call',
        [
          {'to': tokenContractAddress, 'data': '0x313ce567'},
          'latest'
        ],
      );

      if (decimalsResponse['result'].length > 2) {
        tokenDecimals =
            FormatterUtils.parseBigInt(decimalsResponse['result']).toInt();
      } else {
        tokenDecimals = 18;
      }

      if (tx['input'].length >= 138) {
        final String valueHex = tx['input'].substring(74);
        final BigInt tokenValueBigInt =
            FormatterUtils.parseBigInt("0x$valueHex");
        tokenValue = tokenValueBigInt / BigInt.from(10).pow(tokenDecimals);
      }
    } catch (e) {
      print('Error extracting token transfer data: $e');
      tokenDecimals = 18;
    }

    return (actualTo, tokenValue, tokenDecimals);
  }

  Future<int> _getChainId(String rpcUrl) async {
    final chainIdResponse = await _makeRpcCall(rpcUrl, 'eth_chainId', []);
    final chainIdHex = chainIdResponse['result'] as String;
    return int.parse(chainIdHex.substring(2), radix: 16);
  }

  Future<int> _getNonce(String rpcUrl, EthereumAddress sender) async {
    final nonceResponse = await _makeRpcCall(
        rpcUrl, 'eth_getTransactionCount', [sender.hex, 'latest']);
    final nonceHex = nonceResponse['result'] as String;
    return int.parse(nonceHex.substring(2), radix: 16);
  }

  Future<BigInt> _getCurrentGasPrice(String rpcUrl) async {
    final gasPriceResponse = await _makeRpcCall(rpcUrl, 'eth_gasPrice', []);
    return FormatterUtils.parseBigInt(gasPriceResponse['result']);
  }

  Future<String> sendEthTransaction(
      String rpcUrl, String privateKey, String toAddress, double amount,
      {double? gasPrice, int? gasLimit}) async {
    try {
      final credentials = EthPrivateKey.fromHex(privateKey);
      final sender = credentials.address;

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

      final amountInWei = BigInt.from(amount * 1e18);
      final gas = gasLimit ?? 21000;

      final tx = Transaction(
        from: sender,
        to: EthereumAddress.fromHex(toAddress),
        value: EtherAmount.fromBigInt(EtherUnit.wei, amountInWei),
        gasPrice: EtherAmount.fromBigInt(EtherUnit.wei, gasPriceWei),
        maxGas: gas,
        nonce: nonce,
      );

      final client = _getClient(rpcUrl);
      final signedTx = await client.signTransaction(
        credentials,
        tx,
        chainId: chainId,
      );

      final txResponse = await _makeRpcCall(
        rpcUrl,
        'eth_sendRawTransaction',
        ['0x${bytesToHex(signedTx)}'],
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
    final rpcUrl = networkType == NetworkType.ethereumMainnet
        ? RpcEndpoints.mainnetHttpRpcUrl
        : RpcEndpoints.sepoliaTestnetHttpRpcUrl;

    try {
      final blockNumberResponse =
          await _makeRpcCall(rpcUrl, 'eth_blockNumber', []);
      final latestBlock =
          int.parse(blockNumberResponse['result'].substring(2), radix: 16);

      final startBlock = Math.max(0, latestBlock - 4);

      final logsResponse = await _makeRpcCall(rpcUrl, 'eth_getLogs', [
        {
          'fromBlock': '0x${startBlock.toRadixString(16)}',
          'toBlock': 'latest',
          'topics': [
            null,
            null,
            '0x000000000000000000000000${address.substring(2).toLowerCase().padLeft(64, '0')}',
          ],
        }
      ]);

      if (logsResponse['result'] == null) {
        return [];
      }

      final logs = logsResponse['result'] as List;
      final transactions = <Map<String, dynamic>>[];

      for (var i = 0; i < logs.length && i < perPage; i++) {
        final log = logs[i] as Map<String, dynamic>;
        final txHash = log['transactionHash'];

        final txResponse =
            await _makeRpcCall(rpcUrl, 'eth_getTransactionByHash', [txHash]);
        final receiptResponse =
            await _makeRpcCall(rpcUrl, 'eth_getTransactionReceipt', [txHash]);

        if (txResponse['result'] != null && receiptResponse['result'] != null) {
          final tx = txResponse['result'] as Map<String, dynamic>;
          final receipt = receiptResponse['result'] as Map<String, dynamic>;

          final blockResponse = await _makeRpcCall(
              rpcUrl, 'eth_getBlockByHash', [receipt['blockHash'], false]);

          final block = blockResponse['result'] as Map<String, dynamic>;

          transactions.add({
            'hash': tx['hash'],
            'blockNumber': tx['blockNumber'],
            'timeStamp': (int.parse(block['timestamp'].substring(2), radix: 16))
                .toString(),
            'from': tx['from'],
            'to': tx['to'],
            'value': tx['value'],
            'gasUsed': receipt['gasUsed'],
            'gasLimit': tx['gas'],
            'gasPrice': tx['gasPrice'],
            'isError': receipt['status'] == '0x0' ? '1' : '0',
            'confirmations': (latestBlock -
                    int.parse(tx['blockNumber'].substring(2), radix: 16))
                .toString(),
          });
        }
      }

      return transactions;
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTokenTransactions(
    String address,
    NetworkType networkType, {
    int page = 1,
    int perPage = 20,
  }) async {
    final rpcUrl = networkType == NetworkType.ethereumMainnet
        ? RpcEndpoints.mainnetHttpRpcUrl
        : RpcEndpoints.sepoliaTestnetHttpRpcUrl;

    try {
      final blockNumberResponse =
          await _makeRpcCall(rpcUrl, 'eth_blockNumber', []);
      final latestBlock =
          int.parse(blockNumberResponse['result'].substring(2), radix: 16);

      final startBlock = Math.max(0, latestBlock - 10000);

      final logsResponse = await _makeRpcCall(rpcUrl, 'eth_getLogs', [
        {
          'fromBlock': '0x${startBlock.toRadixString(16)}',
          'toBlock': 'latest',
          'topics': [
            '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef',
            null,
            '0x000000000000000000000000${address.substring(2).toLowerCase().padLeft(64, '0')}',
          ],
        }
      ]);

      if (logsResponse['result'] == null) {
        return [];
      }

      final logs = logsResponse['result'] as List;
      final transactions = <Map<String, dynamic>>[];

      for (var i = 0; i < logs.length && i < perPage; i++) {
        final log = logs[i] as Map<String, dynamic>;
        final txHash = log['transactionHash'];
        final contractAddress = log['address'];

        final tokenDetails = await getTokenDetails(rpcUrl, contractAddress);

        final txResponse =
            await _makeRpcCall(rpcUrl, 'eth_getTransactionByHash', [txHash]);
        final receiptResponse =
            await _makeRpcCall(rpcUrl, 'eth_getTransactionReceipt', [txHash]);

        if (txResponse['result'] != null && receiptResponse['result'] != null) {
          final tx = txResponse['result'] as Map<String, dynamic>;
          final receipt = receiptResponse['result'] as Map<String, dynamic>;

          final blockResponse = await _makeRpcCall(
              rpcUrl, 'eth_getBlockByHash', [receipt['blockHash'], false]);

          final block = blockResponse['result'] as Map<String, dynamic>;

          final value = log['data'];
          final from = '0x' + log['topics'][1].substring(26);
          final to = '0x' + log['topics'][2].substring(26);

          transactions.add({
            'hash': tx['hash'],
            'blockNumber': tx['blockNumber'],
            'timeStamp': (int.parse(block['timestamp'].substring(2), radix: 16))
                .toString(),
            'from': from,
            'to': to,
            'value': value,
            'gasUsed': receipt['gasUsed'],
            'gasLimit': tx['gas'],
            'gasPrice': tx['gasPrice'],
            'tokenSymbol': tokenDetails['symbol'] ?? 'Unknown',
            'tokenName': tokenDetails['name'] ?? 'Unknown Token',
            'tokenDecimal': tokenDetails['decimals']?.toString() ?? '18',
            'contractAddress': contractAddress,
            'isError': receipt['status'] == '0x0' ? '1' : '0',
            'confirmations': (latestBlock -
                    int.parse(tx['blockNumber'].substring(2), radix: 16))
                .toString(),
          });
        }
      }

      return transactions;
    } catch (e) {
      print('Error fetching token transactions: $e');
      return [];
    }
  }

  Future<NetworkType> detectNetworkFromTxHash(String txHash) async {
    // Try mainnet first
    try {
      final mainnetTx = await _makeRpcCall(
        RpcEndpoints.mainnetHttpRpcUrl,
        'eth_getTransactionByHash',
        [txHash],
      );
      if (mainnetTx['result'] != null) {
        return NetworkType.ethereumMainnet;
      }
    } catch (e) {
      print('Error checking mainnet: $e');
    }

    // Try Sepolia testnet
    try {
      final sepoliaTx = await _makeRpcCall(
        RpcEndpoints.sepoliaTestnetHttpRpcUrl,
        'eth_getTransactionByHash',
        [txHash],
      );
      if (sepoliaTx['result'] != null) {
        return NetworkType.sepoliaTestnet;
      }
    } catch (e) {
      print('Error checking Sepolia: $e');
    }

    throw Exception('Transaction not found on any supported network');
  }

  Future<TransactionDetailModel?> getTransactionDetails(
    String rpcUrl,
    String txHash,
    NetworkType networkType,
    String userAddress,
  ) async {
    try {
      // First detect the actual network of the transaction
      final actualNetwork = await detectNetworkFromTxHash(txHash);

      // Use the appropriate RPC URL based on the detected network
      final actualRpcUrl = actualNetwork == NetworkType.ethereumMainnet
          ? RpcEndpoints.mainnetHttpRpcUrl
          : RpcEndpoints.sepoliaTestnetHttpRpcUrl;

      final batchCalls = [
        ('eth_getTransactionByHash', [txHash]),
        ('eth_getTransactionReceipt', [txHash]),
        ('eth_blockNumber', []),
      ];

      final responses = await batchRpcCalls(actualRpcUrl, batchCalls);
      final txResponse = responses[0];
      final receiptResponse = responses[1];

      if (txResponse['result'] == null) {
        return null;
      }

      final txData = txResponse['result'] as Map<String, dynamic>;
      final receiptData = receiptResponse['result'] as Map<String, dynamic>?;

      TransactionStatus status;
      if (receiptData == null || receiptData['blockNumber'] == null) {
        status = TransactionStatus.pending;
      } else if (receiptData['status'] == '0x1') {
        status = TransactionStatus.confirmed;
      } else {
        status = TransactionStatus.failed;
      }

      if (status == TransactionStatus.pending) {
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
          gasLimit: txData['gas'] != null
              ? FormatterUtils.parseBigInt(txData['gas']).toDouble()
              : 0.0,
          gasPrice: txData['gasPrice'] != null
              ? FormatterUtils.parseBigInt(txData['gasPrice']).toDouble() / 1e9
              : 0.0,
          status: status,
          direction: _compareAddresses(txData['from'], userAddress)
              ? TransactionDirection.outgoing
              : TransactionDirection.incoming,
          confirmations: 0,
          network: actualNetwork,
          blockNumber: 'Pending',
          nonce: txData['nonce'] != null
              ? int.parse(txData['nonce'].substring(2), radix: 16)
              : 0,
          blockHash: 'Pending',
          isError: false,
          data: txData['input'],
        );
      }

      final blockFutures = await Future.wait([
        _makeRpcCall(actualRpcUrl, 'eth_getBlockByHash',
            [receiptData!['blockHash'], false]),
        _makeRpcCall(actualRpcUrl, 'eth_blockNumber', []),
      ]);

      final blockResponse = blockFutures[0];
      final currentBlockResponse = blockFutures[1];

      if (blockResponse['result'] == null) {
        return TransactionDetailModel(
          hash: txHash,
          timestamp: DateTime.now(),
          from: txData['from'] ?? '',
          to: txData['to'] ?? '',
          amount: txData['value'] != null
              ? FormatterUtils.parseBigInt(txData['value']).toDouble() / 1e18
              : 0.0,
          gasUsed: receiptData['gasUsed'] != null
              ? FormatterUtils.parseBigInt(receiptData['gasUsed']).toDouble()
              : 0.0,
          gasLimit: txData['gas'] != null
              ? FormatterUtils.parseBigInt(txData['gas']).toDouble()
              : 0.0,
          gasPrice: txData['gasPrice'] != null
              ? FormatterUtils.parseBigInt(txData['gasPrice']).toDouble() / 1e9
              : 0.0,
          status: status,
          direction: _compareAddresses(txData['from'], userAddress)
              ? TransactionDirection.outgoing
              : TransactionDirection.incoming,
          confirmations: 0,
          network: actualNetwork,
          blockNumber: receiptData['blockNumber'] != null
              ? FormatterUtils.parseBigInt(receiptData['blockNumber'])
                  .toString()
              : '0',
          nonce: txData['nonce'] != null
              ? int.parse(txData['nonce'].substring(2), radix: 16)
              : 0,
          blockHash: receiptData['blockHash'] ?? '',
          isError: status == TransactionStatus.failed,
          data: txData['input'],
        );
      }

      final blockData = blockResponse['result'] as Map<String, dynamic>;
      final currentBlock =
          FormatterUtils.parseBigInt(currentBlockResponse['result']);
      final txBlockNumber =
          FormatterUtils.parseBigInt(receiptData['blockNumber']);
      final confirmations = (currentBlock - txBlockNumber).toInt();

      bool isTokenTransfer = txData['input'] != null &&
          txData['input'].toString().startsWith('0xa9059cbb');

      String toAddress = txData['to'] ?? '';
      double amount = 0.0;
      String? tokenSymbol;
      String? tokenName;
      int? tokenDecimals;
      String? tokenContractAddress;

      if (isTokenTransfer) {
        try {
          tokenContractAddress = toAddress;
          final tokenDetails = await getTokenDetails(actualRpcUrl, toAddress);
          tokenName = tokenDetails['name'];
          tokenSymbol = tokenDetails['symbol'];
          tokenDecimals = tokenDetails['decimals'];

          final (actualTo, tokenValue, decimals) =
              await _extractTokenTransferData(actualRpcUrl, txData, toAddress);
          toAddress = actualTo;
          amount = tokenValue;
          tokenDecimals = decimals;
        } catch (e) {
          print('Error getting token details: $e');
        }
      } else {
        amount = txData['value'] != null
            ? FormatterUtils.parseBigInt(txData['value']).toDouble() / 1e18
            : 0.0;
      }

      String? errorMessage;
      if (status == TransactionStatus.failed) {
        errorMessage = 'Transaction failed';

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
        gasLimit: txData['gas'] != null
            ? FormatterUtils.parseBigInt(txData['gas']).toDouble()
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
        network: actualNetwork,
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
      print('Error in getTransactionDetails: $e');
      rethrow;
    }
  }

  bool _compareAddresses(String? address1, String? address2) {
    if (address1 == null || address2 == null) return false;
    return address1.toLowerCase() == address2.toLowerCase();
  }

  Future<Map<String, double>> getDetailedGasPrices(String rpcUrl) async {
    try {
      final gasPriceResponse = await _makeRpcCall(rpcUrl, 'eth_gasPrice', []);
      final currentGasPriceWei =
          FormatterUtils.parseBigInt(gasPriceResponse['result']);
      final currentGasPriceGwei = currentGasPriceWei.toDouble() / 1e9;

      final slow = currentGasPriceGwei;
      final standard = currentGasPriceGwei * 1.2;
      final fast = currentGasPriceGwei * 1.5;

      return {
        'slow': slow,
        'standard': standard,
        'fast': fast,
        'current': currentGasPriceGwei,
      };
    } catch (e) {
      print('Error getting gas prices: $e');
      return {
        'slow': 20.0,
        'standard': 25.0,
        'fast': 30.0,
        'current': 20.0,
      };
    }
  }

  Future<String> sendTokenTransaction(
    String rpcUrl,
    String privateKey,
    String contractAddress,
    String toAddress,
    double amount,
    int tokenDecimals, {
    double? gasPrice,
    int? gasLimit,
  }) async {
    try {
      String formattedPrivateKey =
          privateKey.startsWith('0x') ? privateKey.substring(2) : privateKey;
      final credentials = EthPrivateKey.fromHex(formattedPrivateKey);
      final sender = credentials.address;

      final chainId = await _getChainId(rpcUrl);
      final nonce = await _getNonce(rpcUrl, sender);

      BigInt gasPriceWei;
      if (gasPrice != null) {
        gasPriceWei = BigInt.from(gasPrice * 1e9);
      } else {
        final prices = await getDetailedGasPrices(rpcUrl);
        gasPriceWei = BigInt.from(prices['fast']! * 1e9);
      }

      final amountInTokenUnits =
          BigInt.from(amount * BigInt.from(10).pow(tokenDecimals).toDouble());

      final gas = gasLimit ?? 100000;

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

      final tx = Transaction(
        from: sender,
        to: EthereumAddress.fromHex(contractAddress),
        value: EtherAmount.zero(),
        gasPrice: EtherAmount.fromBigInt(EtherUnit.wei, gasPriceWei),
        maxGas: gas,
        nonce: nonce,
        data: callData,
      );

      final signedTx = await client.signTransaction(
        credentials,
        tx,
        chainId: chainId,
      );

      final txResponse = await _makeRpcCall(
        rpcUrl,
        'eth_sendRawTransaction',
        ['0x${bytesToHex(signedTx)}'],
      );

      return txResponse['result'];
    } catch (e) {
      print('Error sending token transaction: $e');
      throw Exception('Failed to send token transaction: $e');
    }
  }

  Future<int> estimateEthGas(String rpcUrl, String fromAddress,
      String toAddress, double amount) async {
    try {
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

  Future<int> estimateTokenGas(
      String rpcUrl,
      String fromAddress,
      String contractAddress,
      String toAddress,
      double amount,
      int tokenDecimals) async {
    try {
      final amountInTokenUnits =
          BigInt.from(amount * BigInt.from(10).pow(tokenDecimals).toDouble());

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

  final Map<String, Map<String, dynamic>> _tokenDetailsCache = {};

  Future<Map<String, dynamic>> getTokenDetails(
    String rpcUrl,
    String contractAddress,
  ) async {
    if (_tokenDetailsCache.containsKey(contractAddress)) {
      return _tokenDetailsCache[contractAddress]!;
    }

    final client = _getClient(rpcUrl);

    final contract = DeployedContract(
      ContractAbi.fromJson(_tokenInfoAbi, 'TokenInfo'),
      EthereumAddress.fromHex(contractAddress),
    );

    String name = 'Unknown';
    String symbol = 'UNK';
    int decimals = 18;

    try {
      try {
        final nameFunction = contract.function('name');
        final nameResult = await client.call(
          contract: contract,
          function: nameFunction,
          params: [],
        );
        if (nameResult.isNotEmpty) {
          name = nameResult[0].toString();
        }
      } catch (_) {}

      try {
        final symbolFunction = contract.function('symbol');
        final symbolResult = await client.call(
          contract: contract,
          function: symbolFunction,
          params: [],
        );
        if (symbolResult.isNotEmpty) {
          symbol = symbolResult[0].toString();
        }
      } catch (_) {}

      try {
        final decimalsFunction = contract.function('decimals');
        final decimalsResult = await client.call(
          contract: contract,
          function: decimalsFunction,
          params: [],
        );
        if (decimalsResult.isNotEmpty) {
          decimals = decimalsResult[0] as int;
        }
      } catch (_) {}

      _tokenDetailsCache[contractAddress] = {
        'name': name,
        'symbol': symbol,
        'decimals': decimals,
        'address': contractAddress,
      };

      return _tokenDetailsCache[contractAddress]!;
    } catch (e) {
      throw Exception('Failed to get token details: $e');
    }
  }

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

  Future<double> getGasPrice(String rpcUrl) async {
    try {
      final response = await _makeRpcCall(rpcUrl, 'eth_gasPrice', []);
      final BigInt weiGasPrice = FormatterUtils.parseBigInt(response['result']);
      return weiGasPrice / BigInt.from(10).pow(9);
    } catch (e) {
      print('Error fetching gas price: $e');
      return 0.0;
    }
  }

  Future<List<Map<String, dynamic>>> batchRpcCalls(
    String rpcUrl,
    List<(String, List<dynamic>)> calls,
  ) async {
    final batch = calls.asMap().map((index, call) => MapEntry(index, {
          'jsonrpc': '2.0',
          'id': index,
          'method': call.$1,
          'params': call.$2,
        }));

    final response = await http.post(
      Uri.parse(rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(batch.values.toList()),
    );

    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  Future<Map<String, dynamic>?> getTransactionTrace(
      String rpcUrl, String txHash) async {
    try {
      // First check if debug namespace is available
      final supportResponse = await _makeRpcCall(
        rpcUrl,
        'debug_traceTransaction',
        [
          txHash,
          {"tracer": "callTracer"}
        ],
      );

      if (supportResponse['error'] != null) {
        final error = supportResponse['error'];
        if (error['code'] == -32000 &&
            error['message']
                .toString()
                .contains('historical state not available')) {
          print(
              'Node does not support historical state tracing: ${error['message']}');
          return {
            'error':
                'Node does not support transaction tracing. Try using a full archive node.',
            'details': error['message'],
            'isNodeLimitError': true
          };
        } else if (error['code'] == -32601) {
          print('Node does not support debug_traceTransaction method');
          return {
            'error': 'Node does not support transaction tracing.',
            'details':
                'The debug_traceTransaction method is not available on this node.',
            'isNodeLimitError': true
          };
        }

        print('Error getting transaction trace: $error');
        return {
          'error': 'Failed to trace transaction',
          'details': error['message'],
          'isNodeLimitError': false
        };
      }

      final traceData = supportResponse['result'] as Map<String, dynamic>;

      // Pretty print the trace data
      print('\n=== Transaction Trace for $txHash ===');
      print(const JsonEncoder.withIndent('  ').convert(traceData));
      print('=====================================\n');

      return traceData;
    } catch (e) {
      print('Error getting transaction trace: $e');
      return {
        'error': 'Failed to trace transaction',
        'details': e.toString(),
        'isNodeLimitError': false
      };
    }
  }

  Future<List<Map<String, dynamic>>> getTransactionsFromEtherscan(
    String rpcUrl,
    String address,
    NetworkType networkType,
  ) async {
    try {
      final apiKey = dotenv.env['ETHERSCAN_API_KEY'];
      if (apiKey == null) {
        throw Exception('Etherscan API key not found');
      }

      final baseUrl = networkType == NetworkType.sepoliaTestnet
          ? 'https://api-sepolia.etherscan.io/api'
          : 'https://api.etherscan.io/api';

      // Get normal transactions
      final normalTxResponse = await http.get(
        Uri.parse(
          '$baseUrl?module=account&action=txlist&address=$address&startblock=0&endblock=99999999&page=1&offset=100&sort=desc&apikey=$apiKey',
        ),
      );

      if (normalTxResponse.statusCode != 200) {
        throw Exception(
            'Failed to fetch normal transactions: ${normalTxResponse.statusCode}');
      }

      final normalTxData = json.decode(normalTxResponse.body);
      if (normalTxData['status'] != '1') {
        throw Exception('Etherscan API error: ${normalTxData['message']}');
      }

      // Get token transfers
      final tokenTxResponse = await http.get(
        Uri.parse(
          '$baseUrl?module=account&action=tokentx&address=$address&startblock=0&endblock=99999999&page=1&offset=100&sort=desc&apikey=$apiKey',
        ),
      );

      if (tokenTxResponse.statusCode != 200) {
        throw Exception(
            'Failed to fetch token transactions: ${tokenTxResponse.statusCode}');
      }

      final tokenTxData = json.decode(tokenTxResponse.body);
      if (tokenTxData['status'] != '1') {
        throw Exception('Etherscan API error: ${tokenTxData['message']}');
      }

      final normalTransactions = (normalTxData['result'] as List)
          .map((tx) => _processNormalTransaction(tx, networkType))
          .toList();

      final tokenTransactions = (tokenTxData['result'] as List)
          .map((tx) => _processTokenTransaction(tx, networkType))
          .toList();

      // Combine and sort transactions by timestamp
      final allTransactions = [...normalTransactions, ...tokenTransactions];
      allTransactions.sort(
          (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

      return allTransactions;
    } catch (e) {
      print('Error fetching transactions from Etherscan: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _processNormalTransaction(
      Map<String, dynamic> tx, NetworkType networkType) {
    return {
      'hash': tx['hash'],
      'timestamp': int.parse(tx['timeStamp']),
      'from': tx['from'],
      'to': tx['to'],
      'amount': double.parse(tx['value']) / 1e18, // Convert from wei to ETH
      'gasUsed': double.parse(tx['gasUsed']),
      'gasLimit': double.parse(tx['gas']),
      'gasPrice':
          double.parse(tx['gasPrice']) / 1e9, // Convert from wei to gwei
      'status': tx['isError'] == '1' ? 'failed' : 'confirmed',
      'direction': tx['from'].toString().toLowerCase() ==
              tx['to'].toString().toLowerCase()
          ? 'self'
          : 'normal',
      'confirmations': int.parse(tx['confirmations']),
      'network': networkType.toString(),
      'tokenSymbol': null,
      'tokenName': null,
      'tokenDecimals': null,
      'tokenContractAddress': null,
    };
  }

  Map<String, dynamic> _processTokenTransaction(
      Map<String, dynamic> tx, NetworkType networkType) {
    return {
      'hash': tx['hash'],
      'timestamp': int.parse(tx['timeStamp']),
      'from': tx['from'],
      'to': tx['to'],
      'amount': double.parse(tx['value']) / 1e6, // PYUSD has 6 decimals
      'gasUsed': double.parse(tx['gasUsed']),
      'gasLimit': double.parse(tx['gas']),
      'gasPrice':
          double.parse(tx['gasPrice']) / 1e9, // Convert from wei to gwei
      'status': tx['isError'] == '1' ? 'failed' : 'confirmed',
      'direction': tx['from'].toString().toLowerCase() ==
              tx['to'].toString().toLowerCase()
          ? 'self'
          : 'normal',
      'confirmations': int.parse(tx['confirmations']),
      'network': networkType.toString(),
      'tokenSymbol': tx['tokenSymbol'],
      'tokenName': tx['tokenName'],
      'tokenDecimals': int.parse(tx['tokenDecimal']),
      'tokenContractAddress': tx['contractAddress'],
    };
  }

  void dispose() {
    _clientPool.forEach((url, client) {
      client.dispose();
    });
    _clientPool.clear();
    _tokenDetailsCache.clear();
  }
}
