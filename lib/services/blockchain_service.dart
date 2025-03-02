import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

import '../models/transaction.dart';

class BlockchainService {
  static const String _pyusdContractAddress =
      '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8'; // PYUSD on Ethereum
  static const int _decimals = 6; // PYUSD has 6 decimals

  late final Web3Client _ethClient;
  late final String _rpcUrl;
  late final EthereumAddress _contractAddress;
  late final DeployedContract _contract;

  BlockchainService() {
    _rpcUrl = dotenv.env['GCP_RPC_URL'] ?? 'https://ethereum.rpcs.gcp.io';
    _ethClient = Web3Client(_rpcUrl, http.Client());
    _contractAddress = EthereumAddress.fromHex(_pyusdContractAddress);
    _initContract();
  }

  Future<void> _initContract() async {
    // PYUSD ABI - only using necessary functions for simplicity
    const String abi = '''
[
  {
    "constant": true,
    "inputs": [{"name": "_owner", "type": "address"}],
    "name": "balanceOf",
    "outputs": [{"name": "balance", "type": "uint256"}],
    "type": "function"
  },
  {
    "constant": false,
    "inputs": [
      {"name": "_to", "type": "address"},
      {"name": "_value", "type": "uint256"}
    ],
    "name": "transfer",
    "outputs": [{"name": "", "type": "bool"}],
    "type": "function"
  }
]
''';

    _contract = DeployedContract(
      ContractAbi.fromJson(abi, 'PYUSD'),
      _contractAddress,
    );
  }

  // Get PYUSD balance for an address
  Future<double> getPYUSDBalance(String address) async {
    try {
      final balanceFunction = _contract.function('balanceOf');
      final result = await _ethClient.call(
        contract: _contract,
        function: balanceFunction,
        params: [EthereumAddress.fromHex(address)],
      );

      final balance = result[0] as BigInt;
      return balance.toDouble() / BigInt.from(10).pow(_decimals).toDouble();
    } catch (e) {
      print('Error getting balance: $e');
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
        chainId: 1, // Ethereum mainnet
      );

      return transaction;
    } catch (e) {
      print('Error transferring PYUSD: $e');
      return null;
    }
  }

  // Get transaction history for PYUSD transfers
  Future<List<TransactionModel>> getTransactionHistory(String address) async {
    try {
      // Using GCP specialized RPC methods to get transaction data
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
                // Transfer event signature
                '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef',
                // Filter by 'from' address (padded to 32 bytes)
                null,
                // Filter by 'to' address (padded to 32 bytes)
                '0x000000000000000000000000${address.substring(2)}'
              ],
              'fromBlock': 'latest',
              'toBlock': 'latest',
            }
          ],
          'id': 1,
        }),
      );

      final data = json.decode(response.body);
      final List<dynamic> logs = data['result'] ?? [];

      // Process logs into TransactionModel objects
      List<TransactionModel> transactions = [];
      for (var log in logs) {
        final String from = '0x${log['topics'][1].substring(26)}';
        final String to = '0x${log['topics'][2].substring(26)}';
        final BigInt value = BigInt.parse(log['data']);
        final double amount =
            value.toDouble() / BigInt.from(10).pow(_decimals).toDouble();

        // Get timestamp for the transaction
        final blockNum = int.parse(log['blockNumber'].substring(2), radix: 16);
        final blockResponse = await http.post(
          Uri.parse(_rpcUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'jsonrpc': '2.0',
            'method': 'eth_getBlockByNumber',
            'params': ['0x${blockNum.toRadixString(16)}', false],
            'id': 1,
          }),
        );

        final blockData = json.decode(blockResponse.body);
        final timestamp = DateTime.fromMillisecondsSinceEpoch(
          int.parse(blockData['result']['timestamp'].substring(2), radix: 16) *
              1000,
        );

        transactions.add(TransactionModel(
          hash: log['transactionHash'],
          from: from,
          to: to,
          amount: amount,
          timestamp: timestamp,
          isIncoming: to.toLowerCase() == address.toLowerCase(),
        ));
      }

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
