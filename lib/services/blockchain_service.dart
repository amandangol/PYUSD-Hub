import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import '../models/transaction.dart';

class BlockchainService {
  static const String _pyusdContractAddress =
      '0x36b40228133cb20F83d4AED93E00865d435F36A1';
  static const int _decimals = 6;

  late final Web3Client _ethClient;
  late final String _rpcUrl;
  late final EthereumAddress _contractAddress;
  late DeployedContract _contract;
  bool _isInitialized = false;

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
      print('Contract initialized successfully');
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
      return _decimals;
    } catch (e) {
      print('Error getting token decimals: $e');
      // Fall back to default value
      return _decimals;
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
      print('Getting balance for address: $normalizedAddress');
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

  Future<double> _getBalanceViaEtherscan(String address) async {
    print('Trying to get balance via Etherscan API for $address');
    try {
      final String etherscanApiUrl = 'https://api-holesky.etherscan.io/api';
      final String etherscanApiKey = dotenv.env['ETHERSCAN_API_KEY'] ??
          'YBYI6VWHB8VIE5M8Z3BRPS4689N2VHV3SA';

      final response = await http
          .get(
            Uri.parse(
                '$etherscanApiUrl?module=account&action=tokenbalance&contractaddress=$_pyusdContractAddress&address=$address&tag=latest&apikey=$etherscanApiKey'),
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
        'Fetching transaction history for normalized address: $normalizedAddress');

    try {
      // Etherscan API approach for Holesky testnet
      final String etherscanApiUrl = 'https://api-holesky.etherscan.io/api';
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
            final from = tx['from'].toString().toLowerCase();
            final to = tx['to'].toString().toLowerCase();
            final isIncoming = to == normalizedAddress;

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

            transactions.add(TransactionModel(
              hash: tx['hash'],
              from: tx['from'],
              to: tx['to'],
              amount: amount,
              timestamp: timestamp,
              status: 'Confirmed',
              fee: feeEth.toStringAsFixed(6),
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

  Future<List<TransactionModel>> _getTransactionsViaRPC(
      String normalizedAddress,
      {required int decimals}) async {
    print('Attempting to get transactions via RPC for $normalizedAddress');

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

            transactions.add(TransactionModel(
              hash: log['transactionHash'],
              from: from,
              to: to,
              amount: amount,
              timestamp: timestamp,
              status: 'Confirmed',
              fee:
                  '0.0001', // Placeholder since actual fee calculation would require more calls
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
      final chainId = int.parse(dotenv.env['NETWORK_CHAIN_ID'] ?? '17000');

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
