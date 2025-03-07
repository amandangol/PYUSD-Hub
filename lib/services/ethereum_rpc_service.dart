import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import '../models/transaction.dart';
import '../providers/network_provider.dart';

class EthereumRpcService {
  static const String erc20TransferAbi =
      '[{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"}]';

  // Helper method to safely parse BigInt from hex strings
  BigInt _parseBigInt(String? hex) {
    // Handle null, empty string, '0x0', or '0x' cases
    if (hex == null || hex.isEmpty || hex == '0x0' || hex == '0x') {
      return BigInt.zero;
    }

    // Normal case: parse the hex string (removing '0x' prefix if present)
    return BigInt.parse(hex.startsWith('0x') ? hex.substring(2) : hex,
        radix: 16);
  }

  // Make HTTP POST request to RPC endpoint
  Future<Map<String, dynamic>> _makeRpcCall(
    String rpcUrl,
    String method,
    List<dynamic> params,
  ) async {
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

      final String hexBalance = response['result'];
      final BigInt weiBalance = _parseBigInt(hexBalance);

      // Convert Wei to ETH (1 ETH = 10^18 Wei)
      return EtherAmount.fromBigInt(EtherUnit.wei, weiBalance)
          .getValueInUnit(EtherUnit.ether);
    } catch (e) {
      print('Error fetching ETH balance: $e');
      return 0.0;
    }
  }

  // Get PYUSD token balance (if applicable to your app)
  Future<double> getTokenBalance(
    String rpcUrl,
    String tokenContractAddress,
    String walletAddress,
  ) async {
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

      // Assuming 6 decimals for PYUSD (adjust according to your token)
      return tokenBalance / BigInt.from(10).pow(6);
    } catch (e) {
      print('Error fetching token balance: $e');
      return 0.0;
    }
  }

  // Get recent transactions for an address
  Future<List<TransactionModel>> getTransactions(
      String rpcUrl, String address, NetworkType networkType,
      {int limit = 10}) async {
    if (address.isEmpty) return [];

    try {
      // For simplicity, we'll use etherscan API for transactions
      final String apiDomain = networkType == NetworkType.sepoliaTestnet
          ? 'api-sepolia.etherscan.io'
          : 'api.etherscan.io';

      // Get normal ETH transactions
      final Uri ethTxUrl = Uri.https(apiDomain, '/api', {
        'module': 'account',
        'action': 'txlist',
        'address': address,
        'startblock': '0',
        'endblock': '99999999',
        'page': '1',
        'offset': limit.toString(),
        'sort': 'desc',
        'apikey': 'YBYI6VWHB8VIE5M8Z3BRPS4689N2VHV3SA',
      });

      // Get ERC20 token transactions
      final Uri tokenTxUrl = Uri.https(apiDomain, '/api', {
        'module': 'account',
        'action': 'tokentx',
        'address': address,
        'startblock': '0',
        'endblock': '99999999',
        'page': '1',
        'offset': limit.toString(),
        'sort': 'desc',
        'apikey': 'YBYI6VWHB8VIE5M8Z3BRPS4689N2VHV3SA',
      });

      final ethResponse = await http.get(ethTxUrl);
      final tokenResponse = await http.get(tokenTxUrl);

      List<TransactionModel> allTransactions = [];

      // Process ETH transactions
      if (ethResponse.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(ethResponse.body);

        if (jsonResponse['status'] == '1') {
          final List<dynamic> txList = jsonResponse['result'];

          // Convert raw JSON to TransactionModel objects
          final ethTransactions = txList.map((tx) {
            final bool isOutgoing =
                address.toLowerCase() == tx['from'].toString().toLowerCase();

            // Safely parse BigInt value using the helper method
            final BigInt valueWei = _parseBigInt(tx['value']);

            return TransactionModel(
              hash: tx['hash'],
              from: tx['from'],
              to: tx['to'],
              value: EtherAmount.fromBigInt(
                EtherUnit.wei,
                valueWei,
              ).getValueInUnit(EtherUnit.ether),
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
          }).toList();

          allTransactions.addAll(ethTransactions);
        }
      }

      // Process token transactions
      if (tokenResponse.statusCode == 200) {
        final Map<String, dynamic> jsonResponse =
            jsonDecode(tokenResponse.body);

        if (jsonResponse['status'] == '1') {
          final List<dynamic> txList = jsonResponse['result'];

          // Convert raw JSON to TransactionModel objects
          final tokenTransactions = txList.map((tx) {
            final bool isOutgoing =
                address.toLowerCase() == tx['from'].toString().toLowerCase();

            // Parse token value using the token's decimals
            final int tokenDecimals = int.parse(tx['tokenDecimal']);
            final BigInt tokenValueWei = _parseBigInt(tx['value']);
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
              status:
                  TransactionStatus.confirmed, // Token txs are always confirmed
              tokenSymbol: tx['tokenSymbol'],
              tokenContractAddress: tx['contractAddress'],
              tokenDecimals: tokenDecimals,
            );
          }).toList();

          allTransactions.addAll(tokenTransactions);
        }
      }

      // Sort all transactions by timestamp (newest first)
      allTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Limit the combined result
      if (allTransactions.length > limit) {
        allTransactions = allTransactions.sublist(0, limit);
      }

      return allTransactions;
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  // Updated sendEthTransaction method with chain ID support
  Future<String> sendEthTransaction(
      String rpcUrl, String privateKey, String toAddress, double amount,
      {double? gasPrice, int? gasLimit}) async {
    try {
      final credentials = EthPrivateKey.fromHex(privateKey);
      final sender = credentials.address;

      // Get the chain ID for the current network
      final chainIdResponse = await http.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'eth_chainId',
          'params': [],
          'id': 1,
        }),
      );

      final chainIdData = jsonDecode(chainIdResponse.body);
      if (chainIdData['error'] != null) {
        throw Exception(chainIdData['error']['message']);
      }

      // Parse the chain ID (comes as hex)
      final chainId = int.parse(chainIdData['result'].substring(2), radix: 16);
      print('Using chain ID: $chainId for network at $rpcUrl');

      // Convert amount from ETH to wei
      final amountInWei = BigInt.from(amount * 1e18);

      // Get nonce
      final nonceResponse = await http.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'eth_getTransactionCount',
          'params': [sender.hex, 'latest'],
          'id': 1,
        }),
      );

      final nonceData = jsonDecode(nonceResponse.body);
      if (nonceData['error'] != null) {
        throw Exception(nonceData['error']['message']);
      }

      final nonce = int.parse(nonceData['result'].substring(2), radix: 16);

      // Get gas price if not provided
      BigInt gasPriceWei;
      if (gasPrice == null) {
        final gasPriceResponse = await http.post(
          Uri.parse(rpcUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'jsonrpc': '2.0',
            'method': 'eth_gasPrice',
            'params': [],
            'id': 1,
          }),
        );

        final gasPriceData = jsonDecode(gasPriceResponse.body);
        if (gasPriceData['error'] != null) {
          throw Exception(gasPriceData['error']['message']);
        }

        gasPriceWei =
            BigInt.parse(gasPriceData['result'].substring(2), radix: 16);
      } else {
        gasPriceWei = BigInt.from(gasPrice * 1e9); // Convert gwei to wei
      }

      // Use default gas limit if not provided
      final gas = gasLimit ??
          21000; // 21000 is the standard gas limit for ETH transfers

      // Create and sign transaction
      final tx = Transaction(
        from: sender,
        to: EthereumAddress.fromHex(toAddress),
        value: EtherAmount.fromBigInt(EtherUnit.wei, amountInWei),
        gasPrice: EtherAmount.fromBigInt(EtherUnit.wei, gasPriceWei),
        maxGas: gas,
        nonce: nonce,
      );

      final client = Web3Client(rpcUrl, http.Client());

      final signedTx = await client.signTransaction(
        credentials,
        tx,
        chainId: chainId, // This is the important addition
      );

      // Send raw transaction
      final txResponse = await http.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'eth_sendRawTransaction',
          'params': ['0x${bytesToHex(signedTx)}'],
          'id': 1,
        }),
      );

      final txData = jsonDecode(txResponse.body);
      if (txData['error'] != null) {
        throw Exception(txData['error']['message']);
      }

      return txData['result'];
    } catch (e) {
      throw Exception('Failed to send ETH transaction: $e');
    }
  }

// Updated sendTokenTransaction method with chain ID support
  Future<String> sendTokenTransaction(
      String rpcUrl,
      String privateKey,
      String contractAddress,
      String toAddress,
      double amount,
      int tokenDecimals, // PYUSD has 6 decimals
      {double? gasPrice,
      int? gasLimit}) async {
    try {
      final credentials = EthPrivateKey.fromHex(privateKey);
      final sender = credentials.address;

      // Get the chain ID for the current network
      final chainIdResponse = await http.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'eth_chainId',
          'params': [],
          'id': 1,
        }),
      );

      final chainIdData = jsonDecode(chainIdResponse.body);
      if (chainIdData['error'] != null) {
        throw Exception(chainIdData['error']['message']);
      }

      // Parse the chain ID (comes as hex)
      final chainId = int.parse(chainIdData['result'].substring(2), radix: 16);
      print(
          'Using chain ID: $chainId for token transaction on network at $rpcUrl');

      // Convert amount to token units
      final amountInTokenUnits =
          BigInt.from(amount * BigInt.from(10).pow(tokenDecimals).toDouble());

      // Get nonce
      final nonceResponse = await http.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'eth_getTransactionCount',
          'params': [sender.hex, 'latest'],
          'id': 1,
        }),
      );

      final nonceData = jsonDecode(nonceResponse.body);
      if (nonceData['error'] != null) {
        throw Exception(nonceData['error']['message']);
      }

      final nonce = int.parse(nonceData['result'].substring(2), radix: 16);

      // Get gas price if not provided
      BigInt gasPriceWei;
      if (gasPrice == null) {
        final gasPriceResponse = await http.post(
          Uri.parse(rpcUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'jsonrpc': '2.0',
            'method': 'eth_gasPrice',
            'params': [],
            'id': 1,
          }),
        );

        final gasPriceData = jsonDecode(gasPriceResponse.body);
        if (gasPriceData['error'] != null) {
          throw Exception(gasPriceData['error']['message']);
        }

        gasPriceWei =
            BigInt.parse(gasPriceData['result'].substring(2), radix: 16);
      } else {
        gasPriceWei = BigInt.from(gasPrice * 1e9); // Convert gwei to wei
      }

      // Use default gas limit for token transfers if not provided
      final gas = gasLimit ?? 100000; // Higher gas limit for token transfers

      // Create contract instance and prepare the transfer function call
      final client = Web3Client(rpcUrl, http.Client());
      final contract = DeployedContract(
        ContractAbi.fromJson(erc20TransferAbi, 'Token'),
        EthereumAddress.fromHex(contractAddress),
      );

      final transferFunction = contract.function('transfer');
      final callData = transferFunction.encodeCall([
        EthereumAddress.fromHex(toAddress),
        amountInTokenUnits,
      ]);

      // Create and sign transaction
      final tx = Transaction(
        from: sender,
        to: EthereumAddress.fromHex(contractAddress),
        value: EtherAmount.zero(),
        gasPrice: EtherAmount.fromBigInt(EtherUnit.wei, gasPriceWei),
        maxGas: gas,
        nonce: nonce,
        data: callData,
      );

      // Include the chainId parameter when signing the transaction
      final signedTx = await client.signTransaction(
        credentials,
        tx,
        chainId: chainId, // This is the important addition
      );

      // Send raw transaction
      final txResponse = await http.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'eth_sendRawTransaction',
          'params': ['0x${bytesToHex(signedTx)}'],
          'id': 1,
        }),
      );

      final txData = jsonDecode(txResponse.body);
      if (txData['error'] != null) {
        throw Exception(txData['error']['message']);
      }

      return txData['result'];
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

      final response = await http.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'eth_estimateGas',
          'params': [
            {
              'from': fromAddress,
              'to': toAddress,
              'value': '0x${amountInWei.toRadixString(16)}',
            }
          ],
          'id': 1,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        throw Exception(data['error']['message']);
      }

      final hexValue = data['result'] as String;
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

      final response = await http.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'eth_estimateGas',
          'params': [
            {
              'from': fromAddress,
              'to': contractAddress,
              'data': '0x${bytesToHex(callData)}',
            }
          ],
          'id': 1,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        throw Exception(data['error']['message']);
      }

      final hexValue = data['result'] as String;
      return int.parse(hexValue.substring(2), radix: 16);
    } catch (e) {
      throw Exception('Failed to estimate token gas: $e');
    }
  }

  // Get token details (name, symbol, decimals)
  Future<Map<String, dynamic>> getTokenDetails(
      String rpcUrl, String contractAddress) async {
    try {
      final client = Web3Client(rpcUrl, http.Client());

      // ABI for ERC20 token information functions
      const String tokenInfoAbi = '''
      [
        {"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},
        {"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},
        {"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"}
      ]
      ''';

      final contract = DeployedContract(
        ContractAbi.fromJson(tokenInfoAbi, 'TokenInfo'),
        EthereumAddress.fromHex(contractAddress),
      );

      // Get token name
      String name = '';
      try {
        final nameFunction = contract.function('name');
        final nameResult = await client.call(
          contract: contract,
          function: nameFunction,
          params: [],
        );
        name = nameResult[0].toString();
      } catch (e) {
        name = 'Unknown';
      }

      // Get token symbol
      String symbol = '';
      try {
        final symbolFunction = contract.function('symbol');
        final symbolResult = await client.call(
          contract: contract,
          function: symbolFunction,
          params: [],
        );
        symbol = symbolResult[0].toString();
      } catch (e) {
        symbol = 'UNK';
      }

      // Get token decimals
      int decimals = 18; // Default to 18 if not specified
      try {
        final decimalsFunction = contract.function('decimals');
        final decimalsResult = await client.call(
          contract: contract,
          function: decimalsFunction,
          params: [],
        );
        decimals = decimalsResult[0] as int;
      } catch (e) {
        // Keep default decimals
      }

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
      final response = await http.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'eth_getCode',
          'params': [address, 'latest'],
          'id': 1,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        throw Exception(data['error']['message']);
      }

      final code = data['result'] as String;

      // If the code is just '0x', it's not a contract
      return code != '0x' && code.length > 2;
    } catch (e) {
      throw Exception('Failed to check if address is contract: $e');
    }
  }

  // Get gas price
  Future<double> getGasPrice(String rpcUrl) async {
    try {
      final response = await _makeRpcCall(
        rpcUrl,
        'eth_gasPrice',
        [],
      );

      final String hexGasPrice = response['result'];
      final BigInt weiGasPrice = _parseBigInt(hexGasPrice);

      // Convert Wei to Gwei
      return weiGasPrice / BigInt.from(10).pow(9);
    } catch (e) {
      print('Error fetching gas price: $e');
      return 0.0;
    }
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
      // First get the transaction data
      final txResponse = await _makeRpcCall(
        rpcUrl,
        'eth_getTransactionByHash',
        [txHash],
      );

      if (txResponse['result'] == null) {
        throw Exception('Transaction not found');
      }

      final tx = txResponse['result'];

      // Next get the transaction receipt for status and gas usage info
      final receiptResponse = await _makeRpcCall(
        rpcUrl,
        'eth_getTransactionReceipt',
        [txHash],
      );

      final receipt = receiptResponse['result'];

      // Get block information to confirm timestamp
      final blockResponse = await _makeRpcCall(
        rpcUrl,
        'eth_getBlockByHash',
        [tx['blockHash'], false],
      );

      final block = blockResponse['result'];

      // Parse the values
      final String from = tx['from'];
      final String to = tx['to'] ?? 'Contract Creation';

      // Parse value - for ETH transactions (using the safe parse method)
      final BigInt valueWei = _parseBigInt(tx['value']);
      final double valueEth = EtherAmount.fromBigInt(
        EtherUnit.wei,
        valueWei,
      ).getValueInUnit(EtherUnit.ether);

      // Get gas usage details (using the safe parse method)
      final BigInt gasLimit = _parseBigInt(tx['gas']);
      final BigInt gasUsed =
          receipt != null ? _parseBigInt(receipt['gasUsed']) : BigInt.zero;
      final BigInt gasPrice = _parseBigInt(tx['gasPrice']);

      // Calculate fee in ETH
      final double feeEth = EtherAmount.fromBigInt(
        EtherUnit.wei,
        gasUsed * gasPrice,
      ).getValueInUnit(EtherUnit.ether);

      // Parse timestamp (using the safe parse method)
      final BigInt timestamp =
          block != null ? _parseBigInt(block['timestamp']) : BigInt.zero;
      final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
        timestamp.toInt() * 1000,
      );

      // Determine transaction status
      TransactionStatus status;
      if (receipt == null) {
        status = TransactionStatus.pending;
      } else if (receipt['status'] == '0x1') {
        status = TransactionStatus.confirmed;
      } else {
        status = TransactionStatus.failed;
      }

      // Get block number (using the safe parse method)
      final BigInt blockNumber =
          block != null ? _parseBigInt(block['number']) : BigInt.zero;

      // Determine if this is a token transfer by checking input data
      String? tokenSymbol;
      String? tokenContractAddress;
      int? tokenDecimals;
      double tokenValue = 0.0;
      String actualTo = to; // Default to the transaction 'to' address

      // Check if the input data matches ERC20 transfer method signature
      if (tx['input'].startsWith('0xa9059cbb')) {
        // It's likely an ERC20 token transfer
        tokenContractAddress = to;

        // Extract recipient address from input data
        if (tx['input'].length >= 74) {
          final String recipientHex = '0x' + tx['input'].substring(34, 74);
          actualTo = recipientHex; // Update the actual recipient
        }

        // Try to fetch token symbol and decimals
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

          // Decimals function signature: '0x313ce567'
          final decimalsResponse = await _makeRpcCall(
            rpcUrl,
            'eth_call',
            [
              {'to': tokenContractAddress, 'data': '0x313ce567'},
              'latest'
            ],
          );

          // Parse token symbol (if available)
          final String symbolHex = symbolResponse['result'];
          if (symbolHex.length > 2) {
            // Skip first 32 bytes, then decode the string
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
          print('Error fetching token details: $e');
          tokenSymbol = 'Unknown Token';
          tokenDecimals = 18;
        }
      }

      // Determine if it's incoming or outgoing
      final bool isOutgoing =
          currentAddress.toLowerCase() == from.toLowerCase();
      final TransactionDirection direction = isOutgoing
          ? TransactionDirection.outgoing
          : TransactionDirection.incoming;

      // Create transaction detail model
      return TransactionDetailModel(
        hash: txHash,
        from: from,
        to: actualTo, // Use the extracted recipient for token transfers
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
        confirmations: block != null
            ? await _calculateConfirmations(rpcUrl, blockNumber)
            : 0,
      );
    } catch (e) {
      print('Error fetching transaction details: $e');
      return null;
    }
  }

  // Helper method to calculate confirmations
  Future<int> _calculateConfirmations(
      String rpcUrl, BigInt txBlockNumber) async {
    try {
      // Get current block number
      final response = await _makeRpcCall(
        rpcUrl,
        'eth_blockNumber',
        [],
      );

      final String currentBlockHex = response['result'];
      final BigInt currentBlock = _parseBigInt(currentBlockHex);

      // Calculate confirmations
      return (currentBlock - txBlockNumber).toInt();
    } catch (e) {
      print('Error calculating confirmations: $e');
      return 0;
    }
  }
}
