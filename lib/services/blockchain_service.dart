import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import '../models/transaction.dart';

class BlockchainService {
  // Default contract address for Holesky testnet
  String _pyusdContractAddress = '0x36b40228133cb20F83d4AED93E00865d435F36A1';
  static const int _defaultDecimals = 6;

  late Web3Client _ethClient;
  late String _rpcUrl;
  late EthereumAddress _contractAddress;
  late DeployedContract _contract;
  bool _isInitialized = false;
  int _chainId = 17000; // Default to Holesky
  String _explorerApiUrl =
      'https://api-holesky.etherscan.io/api'; // Default to Holesky explorer
  String _explorerUrl =
      'https://holesky.etherscan.io'; // Default to Holesky explorer

  BlockchainService() {
    _rpcUrl = dotenv.env['GCP_RPC_URL'] ??
        dotenv.env['GCP_ETHEREUM_TESTNET_RPC'] ??
        'https://blockchain.googleapis.com/v1/projects/oceanic-impact-451616-f5/locations/asia-east1/endpoints/ethereum-holesky/rpc?key=AIzaSyAnZZi8DTOXLn3zcRKoGYtRgMl-YQnIo1Q';

    print('Using RPC URL: $_rpcUrl');

    _ethClient = Web3Client(_rpcUrl, http.Client());
    _contractAddress = EthereumAddress.fromHex(_pyusdContractAddress);

    // Initialize contract immediately
    _initContract();
  }

  // New method to update network with explorer URL parameter
  Future<void> updateNetwork(String rpcUrl, String contractAddress, int chainId,
      String explorerUrl) async {
    print(
        'Updating network. New RPC: $rpcUrl, New contract: $contractAddress, New chainId: $chainId, Explorer: $explorerUrl');

    // Close existing client
    _ethClient.dispose();

    // Update parameters
    _rpcUrl = rpcUrl;
    _pyusdContractAddress = contractAddress;
    _contractAddress = EthereumAddress.fromHex(contractAddress);
    _chainId = chainId;
    _explorerUrl = explorerUrl;

    // Update explorer API URL based on chainId
    if (chainId == 1) {
      _explorerApiUrl = 'https://api.etherscan.io/api';
    } else if (chainId == 11155111) {
      _explorerApiUrl = 'https://api-sepolia.etherscan.io/api';
    } else {
      _explorerApiUrl = 'https://api-holesky.etherscan.io/api';
    }

    // Initialize new client and contract
    _ethClient = Web3Client(_rpcUrl, http.Client());
    _isInitialized = false;
    await _initContract();

    print('Network updated. Using explorer API: $_explorerApiUrl');
  }

  Future<void> _initContract() async {
    try {
      // More complete PYUSD ABI with proper output formatting
      const String abi = '''
[
  {
    "constant": true,
    "inputs": [{"name": "_owner", "type": "address"}],
    "name": "balanceOf",
    "outputs": [{"name": "balance", "type": "uint256"}],
    "payable": false,
    "stateMutability": "view",
    "type": "function"
  },
  {
    "constant": true,
    "inputs": [],
    "name": "decimals",
    "outputs": [{"name": "", "type": "uint8"}],
    "payable": false,
    "stateMutability": "view",
    "type": "function"
  },
  {
    "constant": false,
    "inputs": [
      {"name": "_to", "type": "address"},
      {"name": "_value", "type": "uint256"}
    ],
    "name": "transfer",
    "outputs": [{"name": "success", "type": "bool"}],
    "payable": false,
    "stateMutability": "nonpayable",
    "type": "function"
  }
]
''';

      final contractAbi = ContractAbi.fromJson(abi, 'PYUSD');
      _contract = DeployedContract(
        contractAbi,
        _contractAddress,
      );
      _isInitialized = true;
      print(
          'Contract initialized successfully for address: $_pyusdContractAddress');
    } catch (e) {
      print('Error initializing contract: $e');
      _isInitialized = false;
    }
  }

  // Helper method to ensure contract is initialized before operations
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initContract();
      if (!_isInitialized) {
        throw Exception('Failed to initialize contract');
      }
    }
  }

  Future<int> getTokenDecimals() async {
    await _ensureInitialized();

    try {
      final decimalsFunction = _contract.function('decimals');
      final result = await _ethClient.call(
        contract: _contract,
        function: decimalsFunction,
        params: [],
      );

      if (result.isNotEmpty && result[0] != null) {
        return (result[0] as BigInt).toInt();
      }
      return _defaultDecimals;
    } catch (e) {
      print('Error getting token decimals: $e');
      // Fall back to default value
      return _defaultDecimals;
    }
  }

  Future<double> _getBalanceViaEtherscan(String address) async {
    print(
        'Trying to get balance via Etherscan API for $address on $_explorerApiUrl');
    try {
      final String etherscanApiKey = dotenv.env['ETHERSCAN_API_KEY'] ??
          'YBYI6VWHB8VIE5M8Z3BRPS4689N2VHV3SA';

      final response = await http
          .get(
            Uri.parse(
                '$_explorerApiUrl?module=account&action=tokenbalance&contractaddress=$_pyusdContractAddress&address=$address&tag=latest&apikey=$etherscanApiKey'),
          )
          .timeout(Duration(seconds: 15));

      final data = json.decode(response.body);
      print('Etherscan balance API response: $data');

      if (data['status'] == '1' && data['result'] != null) {
        final BigInt balanceBI = BigInt.parse(data['result']);
        final int decimals = await getTokenDecimals();
        final double balance =
            balanceBI.toDouble() / BigInt.from(10).pow(decimals).toDouble();
        print('Etherscan balance: $balance');
        return balance;
      }
      return 0.0;
    } catch (e) {
      print('Error getting balance via Etherscan: $e');
      return 0.0;
    }
  }

  Future<double> getPYUSDBalance(String address) async {
    if (address.isEmpty) {
      print('Empty address provided');
      return 0.0;
    }

    // Normalize the address to ensure consistent formatting
    final normalizedAddress = EthereumAddress.fromHex(address).hex;
    print('Normalized address: $normalizedAddress');

    await _ensureInitialized();

    // Try both RPC and fallback methods
    try {
      // First try Web3 RPC method
      print(
          'Getting balance for address: $normalizedAddress on chain ID: $_chainId');
      final ethAddress = EthereumAddress.fromHex(normalizedAddress);
      final balanceFunction = _contract.function('balanceOf');
      print('Calling balance function...');

      // Add timeout to the call
      final result = await _ethClient.call(
        contract: _contract,
        function: balanceFunction,
        params: [ethAddress],
      ).timeout(Duration(seconds: 15));

      print('Raw balance result: $result');

      if (result.isNotEmpty && result[0] != null) {
        final balance = result[0] as BigInt;
        print('Balance as BigInt: $balance');

        // Get actual decimals if possible
        int decimals = await getTokenDecimals();
        print('Token decimals: $decimals');

        // Convert to a double with proper decimal places
        final divisor = BigInt.from(10).pow(decimals);
        final balanceDouble = balance.toDouble() / divisor.toDouble();

        print('Calculated balance: $balanceDouble');
        return balanceDouble;
      }

      // If no results from RPC, try Etherscan fallback
      return await _getBalanceViaEtherscan(normalizedAddress);
    } catch (e, stackTrace) {
      print('Error getting balance via RPC: $e');
      print('Stack trace: $stackTrace');

      // Try Etherscan fallback
      try {
        return await _getBalanceViaEtherscan(normalizedAddress);
      } catch (fallbackError) {
        print('Fallback balance method also failed: $fallbackError');
        return 0.0;
      }
    }
  }

  Future<List<TransactionModel>> getTransactionHistory(String address) async {
    if (address.isEmpty) {
      print('Empty address provided for transaction history');
      return [];
    }

    await _ensureInitialized();

    // Normalize the address to ensure consistent comparison
    final normalizedAddress =
        EthereumAddress.fromHex(address).hex.toLowerCase();
    print(
        'Fetching transaction history for normalized address: $normalizedAddress on $_explorerApiUrl');

    try {
      // Get the appropriate Etherscan API URL based on current network
      final String etherscanApiUrl = _explorerApiUrl;
      final String etherscanApiKey = dotenv.env['ETHERSCAN_API_KEY'] ??
          'YBYI6VWHB8VIE5M8Z3BRPS4689N2VHV3SA';

      final response = await http
          .get(
            Uri.parse(
                '$etherscanApiUrl?module=account&action=tokentx&contractaddress=$_pyusdContractAddress&address=$normalizedAddress&sort=desc&apikey=$etherscanApiKey'),
          )
          .timeout(Duration(seconds: 15));

      final data = json.decode(response.body);
      print('API response: ${response.body}');
      print('API response status: ${data['status']}');

      List<TransactionModel> transactions = [];

      if (data['status'] == '1' && data['result'] is List) {
        final List<dynamic> txList = data['result'];
        print('Found ${txList.length} transactions');

        int decimals = await getTokenDecimals();

        for (var tx in txList) {
          try {
            final BigInt valueBI = BigInt.parse(tx['value']);
            final double amount =
                valueBI.toDouble() / BigInt.from(10).pow(decimals).toDouble();

            final timestamp = DateTime.fromMillisecondsSinceEpoch(
                int.parse(tx['timeStamp']) * 1000);

            // Calculate actual gas fee
            final BigInt gasPrice = BigInt.parse(tx['gasPrice']);
            final BigInt gasUsed = BigInt.parse(tx['gasUsed']);
            final BigInt feeWei = gasPrice * gasUsed;
            final double feeEth =
                feeWei.toDouble() / BigInt.from(10).pow(18).toDouble();

            // Add transaction hash link using current explorer URL
            final String txHashLink = '$_explorerUrl/tx/${tx['hash']}';

            transactions.add(TransactionModel(
              hash: tx['hash'],
              hashLink: txHashLink,
              from: tx['from'],
              to: tx['to'],
              amount: amount,
              timestamp: timestamp,
              status: 'Confirmed',
              fee: feeEth.toStringAsFixed(6),
              networkName: _getNetworkNameFromChainId(_chainId),
            ));
          } catch (e) {
            print('Error processing transaction: $e');
          }
        }
      } else {
        print('No transactions found or invalid response: ${data['message']}');
        // Fallback to RPC method if needed
        transactions = await _getTransactionsViaRPC(normalizedAddress,
            decimals: await getTokenDecimals());
      }

      return transactions;
    } catch (e) {
      print('Error getting transaction history: $e');
      // Try fallback method
      try {
        return await _getTransactionsViaRPC(normalizedAddress,
            decimals: await getTokenDecimals());
      } catch (fallbackError) {
        print('Fallback method also failed: $fallbackError');
        return [];
      }
    }
  }

  String _getNetworkNameFromChainId(int chainId) {
    switch (chainId) {
      case 1:
        return 'Ethereum Mainnet';
      case 11155111:
        return 'Sepolia Testnet';
      case 17000:
        return 'Holesky Testnet';
      default:
        return 'Unknown Network';
    }
  }

  Future<List<TransactionModel>> _getTransactionsViaRPC(
      String normalizedAddress,
      {required int decimals}) async {
    print(
        'Attempting to get transactions via RPC for $normalizedAddress on $_rpcUrl');

    try {
      // Fix: Use specific block numbers instead of 'latest' for toBlock
      // Get the latest block number first
      final blockNumberResponse = await http.post(
        Uri.parse(_rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'jsonrpc': '2.0',
          'method': 'eth_blockNumber',
          'params': [],
          'id': 1,
        }),
      );

      final blockNumberData = json.decode(blockNumberResponse.body);
      final latestBlock = blockNumberData['result'] ?? '0x0';

      // Use fromBlock as 0 with hex format and latest block number for toBlock
      final response = await http.post(
        Uri.parse(_rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'jsonrpc': '2.0',
          'method': 'eth_getLogs',
          'params': [
            {
              'address': _pyusdContractAddress,
              'topics': [
                '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'
              ],
              'fromBlock': '0x0',
              'toBlock': latestBlock,
            }
          ],
          'id': 1,
        }),
      );

      final data = json.decode(response.body);

      if (data['error'] != null) {
        print('RPC error: ${data['error']}');
        return [];
      }

      final List<dynamic> logs = data['result'] ?? [];
      print('Found ${logs.length} logs via RPC');

      List<TransactionModel> transactions = [];

      for (var log in logs) {
        try {
          // Extract addresses from topics
          final String fromPadded = log['topics'][1];
          final String from = '0x${fromPadded.substring(26).toLowerCase()}';

          final String toPadded = log['topics'][2];
          final String to = '0x${toPadded.substring(26).toLowerCase()}';

          // Only include relevant transactions
          if (from == normalizedAddress || to == normalizedAddress) {
            print('Found relevant transaction: $from -> $to');

            // Parse value
            String dataValue = log['data'];
            if (dataValue.startsWith('0x')) {
              dataValue = dataValue.substring(2);
            }

            final BigInt value = BigInt.parse('0x$dataValue');
            final double amount =
                value.toDouble() / BigInt.from(10).pow(decimals).toDouble();

            // Get block info for timestamp
            final blockResponse = await http.post(
              Uri.parse(_rpcUrl),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'jsonrpc': '2.0',
                'method': 'eth_getBlockByNumber',
                'params': [log['blockNumber'], false],
                'id': 1,
              }),
            );

            final blockData = json.decode(blockResponse.body);
            DateTime timestamp;

            if (blockData['result'] != null &&
                blockData['result']['timestamp'] != null) {
              timestamp = DateTime.fromMillisecondsSinceEpoch(
                int.parse(blockData['result']['timestamp'].substring(2),
                        radix: 16) *
                    1000,
              );
            } else {
              timestamp = DateTime.now();
            }

            // Create transaction hash link
            final String txHashLink =
                '$_explorerUrl/tx/${log['transactionHash']}';

            transactions.add(TransactionModel(
              hash: log['transactionHash'],
              hashLink: txHashLink,
              from: from,
              to: to,
              amount: amount,
              timestamp: timestamp,
              status: 'Confirmed',
              fee:
                  '0.0001', // Placeholder since actual fee calculation would require more calls
              networkName: _getNetworkNameFromChainId(_chainId),
            ));
          }
        } catch (e) {
          print('Error processing log: $e');
        }
      }

      // Sort by timestamp
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return transactions;
    } catch (e) {
      print('RPC method error: $e');
      return [];
    }
  }

  Future<String?> transferPYUSD({
    required String from,
    required String to,
    required double amount,
    required EthPrivateKey credentials,
  }) async {
    await _ensureInitialized();

    try {
      final transferFunction = _contract.function('transfer');

      // Use current chainId instead of getting from dotenv
      final chainId = _chainId;

      int decimals = await getTokenDecimals();
      final amountInWei =
          BigInt.from(amount * BigInt.from(10).pow(decimals).toDouble());

      final transaction = await _ethClient.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: _contract,
          function: transferFunction,
          parameters: [
            EthereumAddress.fromHex(to),
            amountInWei,
          ],
        ),
        chainId: chainId,
      );

      return transaction;
    } catch (e) {
      print('Error transferring PYUSD: $e');
      return null;
    }
  }
}
