import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pyusd_hub/utils/formatter_utils.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import '../providers/network_provider.dart';
import '../screens/transactions/model/transaction_model.dart';

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

  // Use late initialization for client cache
  late final Map<String, Web3Client> _clientCache = {};

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
    List<dynamic> params, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final client = http.Client();
      try {
        final response = await client
            .post(
              Uri.parse(rpcUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'jsonrpc': '2.0',
                'id': 1,
                'method': method,
                'params': params,
              }),
            )
            .timeout(timeout);

        if (response.statusCode != 200) {
          throw Exception(
              'Failed to connect to Ethereum node: ${response.statusCode}');
        }

        return jsonDecode(response.body);
      } finally {
        client.close();
      }
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
      print('\n=== Token Balance RPC Debug ===');
      // print('Fetching balance for:');
      // print('Token: $tokenContractAddress');
      print('Wallet: $walletAddress');
      // print('Decimals: $decimals');

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
      // print('Raw hex balance: $hexBalance');

      if (hexBalance == '0x') {
        print('Zero balance returned');
        return 0.0;
      }

      final BigInt tokenBalance = FormatterUtils.parseBigInt(hexBalance);
      final double balance = tokenBalance / BigInt.from(10).pow(decimals);

      // print('Parsed balance: $balance PYUSD');
      // print('=== End Token Balance Debug ===\n');

      return balance;
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
            FormatterUtils.parseBigInt("0x$valueHex");
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
    print('\n=== Fetching Transaction Details ===');
    print('Transaction Hash: $txHash');
    print('Network: ${networkType.name}');

    try {
      // Batch RPC calls
      final batchCalls = [
        ('eth_getTransactionByHash', [txHash]),
        ('eth_getTransactionReceipt', [txHash]),
        ('eth_blockNumber', []),
      ];

      final responses = await batchRpcCalls(rpcUrl, batchCalls);
      final txResponse = responses[0];
      final receiptResponse = responses[1];

      // Debug logs
      print('Transaction Response: ${txResponse['result']}');
      print('Receipt Response: ${receiptResponse['result']}');

      // Check if transaction exists
      if (txResponse['result'] == null) {
        print('Transaction not found: $txHash');
        return null;
      }

      final txData = txResponse['result'] as Map<String, dynamic>;
      final receiptData = receiptResponse['result'] as Map<String, dynamic>?;

      // Determine transaction status
      TransactionStatus status;
      if (receiptData == null || receiptData['blockNumber'] == null) {
        status = TransactionStatus.pending;
        print('Transaction is pending');
      } else if (receiptData['status'] == '0x1') {
        status = TransactionStatus.confirmed;
        print('Transaction is confirmed');
      } else {
        status = TransactionStatus.failed;
        print('Transaction failed');
      }

      // Handle pending transactions
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

      // Get block data and current block number in parallel
      final blockFutures = await Future.wait([
        _makeRpcCall(
            rpcUrl, 'eth_getBlockByHash', [receiptData!['blockHash'], false]),
        _makeRpcCall(rpcUrl, 'eth_blockNumber', []),
      ]);

      final blockResponse = blockFutures[0];
      final currentBlockResponse = blockFutures[1];

      // Check if blockResponse or blockResponse['result] is null
      if (blockResponse['result'] == null) {
        print('Block data not found: ${receiptData!['blockHash']}');
        return TransactionDetailModel(
          hash: txHash,
          timestamp: DateTime.now(),
          from: txData['from'] ?? '',
          to: txData['to'] ?? '',
          amount: txData['value'] != null
              ? FormatterUtils.parseBigInt(txData['value']).toDouble() / 1e18
              : 0.0,
          gasUsed: receiptData['gasUsed'] != null
              ? FormatterUtils.parseBigInt(receiptData!['gasUsed']).toDouble()
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
          network: networkType,
          blockNumber: receiptData!['blockNumber'] != null
              ? FormatterUtils.parseBigInt(receiptData!['blockNumber'])
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
          FormatterUtils.parseBigInt(receiptData!['blockNumber']);
      final confirmations = (currentBlock - txBlockNumber).toInt();

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
        // Get token details in parallel with other operations
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

      final transactionDetails = TransactionDetailModel(
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

      print(
          'Returning transaction details with status: ${transactionDetails.status}');
      return transactionDetails;
    } catch (e) {
      print('Error in getTransactionDetails: $e');
      rethrow;
    }
  }

  // Helper method to compare addresses (case-insensitive)
  bool _compareAddresses(String? address1, String? address2) {
    if (address1 == null || address2 == null) return false;
    return address1.toLowerCase() == address2.toLowerCase();
  }

  // Add new method to get detailed gas prices
  Future<Map<String, double>> getDetailedGasPrices(String rpcUrl) async {
    try {
      // print('\n=== Gas Price Debug ===');

      // Get current gas price in Wei
      final gasPriceResponse = await _makeRpcCall(rpcUrl, 'eth_gasPrice', []);
      final currentGasPriceWei =
          FormatterUtils.parseBigInt(gasPriceResponse['result']);

      // Convert Wei to Gwei
      final currentGasPriceGwei = currentGasPriceWei.toDouble() / 1e9;

      // Calculate suggested gas prices
      final slow = currentGasPriceGwei;
      final standard = currentGasPriceGwei * 1.2; // 20% higher
      final fast = currentGasPriceGwei * 1.5; // 50% higher

      print(
          'Current Gas Price: ${currentGasPriceGwei.toStringAsFixed(2)} Gwei');
      print('Suggested Prices:');
      print('- Slow: ${slow.toStringAsFixed(2)} Gwei');
      print('- Standard: ${standard.toStringAsFixed(2)} Gwei');
      print('- Fast: ${fast.toStringAsFixed(2)} Gwei');
      print('=== End Gas Price Debug ===\n');

      return {
        'slow': slow,
        'standard': standard,
        'fast': fast,
        'current': currentGasPriceGwei,
      };
    } catch (e) {
      print('Error getting gas prices: $e');
      // Return default values if error
      return {
        'slow': 20.0,
        'standard': 25.0,
        'fast': 30.0,
        'current': 20.0,
      };
    }
  }

  // Update sendTokenTransaction to handle BigInt properly
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

      // Get chain ID and nonce
      final chainId = await _getChainId(rpcUrl);
      final nonce = await _getNonce(rpcUrl, sender);

      // Handle gas price conversion properly
      BigInt gasPriceWei;
      if (gasPrice != null) {
        // Convert provided gas price from Gwei to Wei
        gasPriceWei = BigInt.from(gasPrice * 1e9);
      } else {
        // Get current gas price in Wei
        final prices = await getDetailedGasPrices(rpcUrl);
        gasPriceWei = BigInt.from(prices['fast']! * 1e9);
      }

      print('\n=== Transaction Debug ===');
      print('Chain ID: $chainId');
      print('Nonce: $nonce');
      print('Gas Price (Wei): $gasPriceWei');
      print('Gas Price (Gwei): ${gasPriceWei.toDouble() / 1e9}');

      // Convert amount to token units
      final amountInTokenUnits =
          BigInt.from(amount * BigInt.from(10).pow(tokenDecimals).toDouble());

      // Use higher default gas limit for token transfers
      final gas = gasLimit ?? 100000;

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

      final txHash = txResponse['result'] as String;
      print('Transaction hash: $txHash');
      print('=== End Transaction Debug ===\n');

      return txHash;
    } catch (e) {
      print('Error sending token transaction: $e');
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
  final Map<String, Map<String, dynamic>> _tokenDetailsCache = {};

  Future<Map<String, dynamic>> getTokenDetails(
    String rpcUrl,
    String contractAddress,
  ) async {
    // Check cache first
    if (_tokenDetailsCache.containsKey(contractAddress)) {
      return _tokenDetailsCache[contractAddress]!;
    }

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

      // Cache the result
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

  // Optimize parallel requests with batch processing
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

    final List<dynamic> results = jsonDecode(response.body);
    return results.cast<Map<String, dynamic>>();
  }

  // Clean up method to dispose of Web3Client instances
  @override
  void dispose() {
    _clientCache.forEach((url, client) {
      client.dispose();
    });
    _clientCache.clear();
    _tokenDetailsCache.clear();
  }
}
