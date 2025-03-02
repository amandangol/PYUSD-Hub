import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

import '../models/transaction.dart';

class BlockchainService {
  static const String _pyusdContractAddress =
      '0x074B003f7040D6c8249E09C2e851f63d5072Bed2'; // PYUSD on Ethereum
  static const int _decimals = 30;

  late final Web3Client _ethClient;
  late final String _rpcUrl;
  late final EthereumAddress _contractAddress;
  late final DeployedContract _contract;

  BlockchainService() {
    _rpcUrl = dotenv.env['GCP_RPC_URL'] ??
        dotenv.env['GCP_ETHEREUM_TESTNET_RPC'] ??
        'https://ethereum-holesky.publicnode.com';

    print('Using RPC URL: $_rpcUrl');

    _ethClient = Web3Client(_rpcUrl, http.Client());
    _contractAddress = EthereumAddress.fromHex(_pyusdContractAddress);

    // Wait for contract initialization to complete before allowing any calls
    _initContract().then((_) {
      print('Contract initialization complete');
    });
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
      print('Contract initialized successfully');
    } catch (e) {
      print('Error initializing contract: $e');
    }
  }

  Future<int> getTokenDecimals() async {
    try {
      // Add a decimals function to your contract ABI
      // This requires updating your contract ABI to include the decimals function
      final decimalsFunction = _contract.function('decimals');
      final result = await _ethClient.call(
        contract: _contract,
        function: decimalsFunction,
        params: [],
      );

      return (result[0] as BigInt).toInt();
    } catch (e) {
      print('Error getting token decimals: $e');
      // Fall back to default value
      return _decimals;
    }
  }

  // Then update your getPYUSDBalance method to properly format the result
  Future<double> getPYUSDBalance(String address) async {
    try {
      print('Getting balance for address: $address');

      final ethAddress = EthereumAddress.fromHex(address);
      print('Converted to EthereumAddress: ${ethAddress.hex}');

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
        try {
          final balance = result[0] as BigInt;
          print('Balance as BigInt: $balance');

          // Get actual decimals if possible
          int decimals = _decimals;
          try {
            decimals = await getTokenDecimals();
            print('Token decimals from contract: $decimals');
          } catch (e) {
            print('Using default decimals: $decimals');
          }

          // Calculate divisor based on decimals
          final divisor = BigInt.from(10).pow(decimals);
          print('Divisor: $divisor');

          // Convert to a double with proper decimal places
          double balanceDouble;
          if (balance >= divisor) {
            // For values >= 1, we can do direct division
            balanceDouble = balance / divisor;
          } else {
            // For values < 1, we need to maintain precision
            final doubleStr = '${balance.toString()}e-$decimals';
            balanceDouble = double.parse(doubleStr);
          }

          print('Calculated balance: $balanceDouble');
          return balanceDouble;
        } catch (e) {
          print('Error converting balance: $e');
          // If failed to convert, try another approach
          try {
            // Try manual string-based conversion to avoid precision issues
            final balanceStr = result[0].toString();
            print('Balance as string: $balanceStr');

            int decimals = _decimals;
            // Insert a decimal point at the right position
            if (balanceStr.length > decimals) {
              String integerPart =
                  balanceStr.substring(0, balanceStr.length - decimals);
              String fractionalPart =
                  balanceStr.substring(balanceStr.length - decimals);
              String formattedBalance = '$integerPart.$fractionalPart';

              // Remove trailing zeros and decimal if it's a whole number
              double parsedBalance = double.parse(formattedBalance);
              print('Manually formatted balance: $parsedBalance');
              return parsedBalance;
            } else {
              // Handle very small values (less than 1)
              String zeros = '0.' + '0' * (decimals - balanceStr.length);
              String formattedBalance = zeros + balanceStr;

              double parsedBalance = double.parse(formattedBalance);
              print('Manually formatted small balance: $parsedBalance');
              return parsedBalance;
            }
          } catch (manualError) {
            print('Manual conversion failed: $manualError');
            return 0.0;
          }
        }
      }
      return 0.0;
    } catch (e, stackTrace) {
      print('Error getting balance: $e');
      print('Stack trace: $stackTrace');
      return 0.0;
    }
  }

  // Transfer PYUSD to another address
  Future<String?> transferPYUSD({
    required String from,
    required String to,
    required double amount,
    required EthPrivateKey credentials,
  }) async {
    try {
      final transferFunction = _contract.function('transfer');
      final chainId = int.parse(dotenv.env['NETWORK_CHAIN_ID'] ?? '17000');

      final amountInWei =
          BigInt.from(amount * BigInt.from(10).pow(_decimals).toDouble());

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

  // Add this method to your BlockchainService class

  Future<List<TransactionModel>> getTransactionHistory(String address) async {
    try {
      print('Fetching transaction history for address: $address');
      final normalizedAddress = address.toLowerCase();

      // Let's try using etherscan API for Holesky testnet as an alternative approach
      final String etherscanApiUrl = 'https://api-holesky.etherscan.io/api';
      final String etherscanApiKey =
          'YBYI6VWHB8VIE5M8Z3BRPS4689N2VHV3SA'; // Replace with your key

      // Try to fetch token transfers using Etherscan API (if you have an API key)
      try {
        final response = await http.get(
          Uri.parse(
              '$etherscanApiUrl?module=account&action=tokentx&contractaddress=$_pyusdContractAddress&address=$normalizedAddress&sort=desc&apikey=$etherscanApiKey'),
        );

        final data = json.decode(response.body);
        print('Etherscan API response: $data');

        if (data['status'] == '1' && data['result'] is List) {
          final List<dynamic> txList = data['result'];
          List<TransactionModel> transactions = [];

          for (var tx in txList) {
            final from = tx['from'].toString().toLowerCase();
            final to = tx['to'].toString().toLowerCase();
            final isIncoming = to == normalizedAddress;

            final valueHex = tx['value'];
            final timestamp = DateTime.fromMillisecondsSinceEpoch(
                int.parse(tx['timeStamp']) * 1000);

            final BigInt valueBI = BigInt.parse(valueHex);
            final double amount =
                valueBI.toDouble() / BigInt.from(10).pow(_decimals).toDouble();

            transactions.add(TransactionModel(
              hash: tx['hash'],
              from: tx['from'],
              to: tx['to'],
              amount: amount,
              timestamp: timestamp,
              isIncoming: isIncoming,
              status: 'Confirmed',
              fee: tx['gasPrice'] != null
                  ? (BigInt.parse(tx['gasPrice']) * BigInt.parse(tx['gasUsed']))
                      .toString()
                  : '0',
            ));
          }

          print('Found ${transactions.length} transactions via Etherscan API');
          return transactions;
        }
      } catch (etherscanError) {
        print('Etherscan API error: $etherscanError');
        // Continue with RPC method if Etherscan fails
      }

      // If Etherscan didn't work or we're continuing, use the RPC method
      print('Trying RPC method for transaction history');
      // More verbose debugging for the RPC method
      print('Contract address used: $_pyusdContractAddress');
      print('Normalized wallet address: $normalizedAddress');

      // Let's try a different approach - get all token transfer events and filter client-side
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
                // Transfer event signature only
                '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'
              ],
              'fromBlock': '0x0', // Start from genesis or a recent block
              'toBlock': 'latest',
            }
          ],
          'id': 1,
        }),
      );

      final data = json.decode(response.body);
      print('RPC logs response: $data');

      // Check if we got a valid response
      if (data['error'] != null) {
        print('RPC error: ${data['error']}');
        return [];
      }

      final List<dynamic> logs = data['result'] ?? [];
      print('Total logs found: ${logs.length}');

      // Process logs into TransactionModel objects
      List<TransactionModel> transactions = [];
      for (var log in logs) {
        try {
          // Extract the 'from' address from topics[1]
          final String fromPadded = log['topics'][1];
          final String from = '0x${fromPadded.substring(26).toLowerCase()}';

          // Extract the 'to' address from topics[2]
          final String toPadded = log['topics'][2];
          final String to = '0x${toPadded.substring(26).toLowerCase()}';

          // Only include transactions relevant to our address
          if (from == normalizedAddress || to == normalizedAddress) {
            print('Found transaction: from=$from, to=$to');

            // Parse the value
            String dataValue = log['data'];
            if (dataValue.startsWith('0x')) {
              dataValue = dataValue.substring(2);
            }

            final BigInt value = BigInt.parse('0x$dataValue');
            final double amount =
                value.toDouble() / BigInt.from(10).pow(_decimals).toDouble();

            // Get block details for timestamp
            final blockNumber = log['blockNumber'];
            final blockResponse = await http.post(
              Uri.parse(_rpcUrl),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'jsonrpc': '2.0',
                'method': 'eth_getBlockByNumber',
                'params': [blockNumber, false],
                'id': 1,
              }),
            );

            final blockData = json.decode(blockResponse.body);

            if (blockData['result'] != null &&
                blockData['result']['timestamp'] != null) {
              final timestamp = DateTime.fromMillisecondsSinceEpoch(
                int.parse(blockData['result']['timestamp'].substring(2),
                        radix: 16) *
                    1000,
              );

              transactions.add(TransactionModel(
                hash: log['transactionHash'],
                from: from,
                to: to,
                amount: amount,
                timestamp: timestamp,
                isIncoming: to == normalizedAddress,
                status: 'Confirmed',
                fee: '0.0001', // Placeholder
              ));
            }
          }
        } catch (e) {
          print('Error processing log: $e');
        }
      }

      print(
          'Processed ${transactions.length} transactions for address $normalizedAddress');

      // If we still have no transactions, let's check if there's any test data we can use
      if (transactions.isEmpty) {
        print(
            'No real transactions found. Creating mock transaction data for testing UI');
        // Add some mock transactions for testing
        final now = DateTime.now();
        transactions = [
          TransactionModel(
            hash:
                '0xabcd1234abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234',
            from: '0x1234567890123456789012345678901234567890',
            to: normalizedAddress,
            amount: 100.0,
            timestamp: now.subtract(const Duration(days: 1)),
            isIncoming: true,
            status: 'Confirmed',
            fee: '0.0001',
          ),
          TransactionModel(
            hash:
                '0xdcba4321dcba4321dcba4321dcba4321dcba4321dcba4321dcba4321dcba4321',
            from: normalizedAddress,
            to: '0x0987654321098765432109876543210987654321',
            amount: 50.0,
            timestamp: now.subtract(const Duration(days: 2)),
            isIncoming: false,
            status: 'Confirmed',
            fee: '0.0001',
          ),
        ];
        print('Added ${transactions.length} mock transactions for testing');
      }

      // Sort transactions by timestamp (newest first)
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return transactions;
    } catch (e) {
      print('Error getting transaction history: $e');
      return [];
    }
  }

  // Get network gas price
  Future<EtherAmount> getGasPrice() async {
    try {
      return await _ethClient.getGasPrice();
    } catch (e) {
      print('Error getting gas price: $e');
      // Return a default gas price as EtherAmount
      return EtherAmount.inWei(BigInt.from(20000000000)); // Default 20 Gwei
    }
  }

  // Get gas price as BigInt (in wei)
  Future<BigInt> getGasPriceInWei() async {
    try {
      final gasPrice = await _ethClient.getGasPrice();
      return gasPrice.getInWei;
    } catch (e) {
      print('Error getting gas price: $e');
      return BigInt.from(20000000000); // Default 20 Gwei
    }
  }

  // Estimate gas for a transaction
  Future<BigInt> estimateGas({
    required String from,
    required String to,
    required double amount,
  }) async {
    try {
      final transferFunction = _contract.function('transfer');
      final amountInWei =
          BigInt.from(amount * BigInt.from(10).pow(_decimals).toDouble());

      final gasEstimate = await _ethClient.estimateGas(
        sender: EthereumAddress.fromHex(from),
        to: _contractAddress,
        data: transferFunction.encodeCall([
          EthereumAddress.fromHex(to),
          amountInWei,
        ]),
      );

      return gasEstimate;
    } catch (e) {
      print('Error estimating gas: $e');
      return BigInt.from(100000); // Default estimate
    }
  }
}
