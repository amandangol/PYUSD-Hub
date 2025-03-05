import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/json_rpc.dart';
import 'package:web3dart/web3dart.dart';
import '../models/transaction.dart';

class BlockchainService {
  // PYUSD contract addresses for Sepolia and Mainnet
  static const Map<int, String> _pyusdContractAddresses = {
    1: '0x466a756E9A7401B5e2444a3fCB3c2C12FBEa0a54', // Mainnet
    11155111: '0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9', // Sepolia
  };

  // Default decimals for PYUSD
  static const int _defaultDecimals = 6;

  // RPC URLs for different networks
  static const Map<int, String> _rpcUrls = {
    1: 'https://blockchain.googleapis.com/v1/projects/tidy-computing-433704-d6/locations/us-central1/endpoints/ethereum-mainnet/rpc?key=AIzaSyCBonfhoxR_wlTKPhAhStdQ5djdv_Pah6o',
    11155111:
        'https://blockchain.googleapis.com/v1/projects/tidy-computing-433704-d6/locations/asia-east1/endpoints/ethereum-sepolia/rpc?key=AIzaSyCBonfhoxR_wlTKPhAhStdQ5djdv_Pah6o',
  };

  // Explorer configurations for different networks
  static const Map<int, Map<String, String>> _explorerConfigs = {
    1: {
      'apiUrl': 'https://api.etherscan.io/api',
      'explorerUrl': 'https://etherscan.io',
    },
    11155111: {
      'apiUrl': 'https://api-sepolia.etherscan.io/api',
      'explorerUrl': 'https://sepolia.etherscan.io',
    },
  };

  late Web3Client _ethClient;
  late String _rpcUrl;
  late EthereumAddress _contractAddress;
  late DeployedContract _contract;
  bool _isInitialized = false;
  int _chainId = 11155111; // Default to Sepolia
  String _explorerApiUrl = 'https://api-sepolia.etherscan.io/api';
  String _explorerUrl = 'https://sepolia.etherscan.io';

  // PYUSD Contract ABI
  static const String _pyusdAbi = '''
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

  BlockchainService() {
    _initializeNetwork(11155111); // Default to Sepolia
  }

  // Initialize network with specific chain ID
  void _initializeNetwork(int chainId) {
    _chainId = chainId;
    _rpcUrl = _rpcUrls[chainId] ?? _rpcUrls[11155111]!;
    _contractAddress = EthereumAddress.fromHex(
        _pyusdContractAddresses[chainId] ?? _pyusdContractAddresses[11155111]!);

    final explorerConfig =
        _explorerConfigs[chainId] ?? _explorerConfigs[11155111]!;
    _explorerApiUrl = explorerConfig['apiUrl']!;
    _explorerUrl = explorerConfig['explorerUrl']!;

    _ethClient = Web3Client(_rpcUrl, http.Client());
    _initContract();
  }

  Future<void> updateNetwork(int chainId) async {
    if (!_rpcUrls.containsKey(chainId)) {
      throw ArgumentError('Unsupported network: $chainId');
    }

    try {
      // Dispose of the existing client
      _ethClient.dispose();

      // Reinitialize the client and network
      _initializeNetwork(chainId);

      // Verify client initialization
      final testBalance = await getEthBalance('0x...');
      print('Test balance after network update: $testBalance');
    } catch (e) {
      print('Network update error: $e');
      // Potentially reinitialize with a default network
      _initializeNetwork(11155111);
    }
  }

  Future<void> _initContract() async {
    try {
      final contractAbi = ContractAbi.fromJson(_pyusdAbi, 'PYUSD');
      _contract = DeployedContract(
        contractAbi,
        _contractAddress,
      );
      _isInitialized = true;
      print('Contract initialized for network: $_chainId');
    } catch (e) {
      _isInitialized = false;
      print('Contract initialization error: $e');
      rethrow;
    }
  }

  Future<void> requestSepoliaTestEth(String address) async {
    // List of Sepolia faucet URLs
    final faucets = [
      'https://sepolia-faucet.pk910.de/api/claim',
      'https://faucet.sepolia.dev/faucet/json',
      'https://coinbase.com/faucet/sepolia'
    ];

    for (var faucetUrl in faucets) {
      try {
        final response = await http.post(
          Uri.parse(faucetUrl),
          body: json.encode({'address': address}),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          print('Successfully requested test ETH from $faucetUrl');
          return;
        }
      } catch (e) {
        print('Faucet request failed: $e');
      }
    }

    throw Exception('Could not get test ETH from any faucet');
  }

  String getSepoliaFaucetLink(String address) {
    return 'https://sepolia-faucet.pk910.de/?address=$address';
  }

  // Ensure contract is initialized before operations
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initContract();
    }
  }

  // Get token decimals
  Future<int> getTokenDecimals() async {
    await _ensureInitialized();

    try {
      final decimalsFunction = _contract.function('decimals');
      final result = await _ethClient.call(
        contract: _contract,
        function: decimalsFunction,
        params: [],
      );

      return result.isNotEmpty
          ? (result[0] as BigInt).toInt()
          : _defaultDecimals;
    } catch (e) {
      print('Error getting token decimals: $e');
      return _defaultDecimals;
    }
  }

  Future<double> getEthBalance(String address) async {
    try {
      final ethAddress = EthereumAddress.fromHex(address);
      print('Attempting to fetch ETH balance for address: ${ethAddress.hex}');

      final balance = await _ethClient.getBalance(ethAddress);

      // Manual conversion to ETH
      final ethBalance =
          balance.getInWei.toDouble() / BigInt.from(10).pow(18).toDouble();

      print('Raw balance (Wei): ${balance.getInWei}');
      print('Balance in ETH: $ethBalance');

      return ethBalance;
    } catch (e, stackTrace) {
      print('ETH balance retrieval error: $e');
      print('Stacktrace: $stackTrace');

      // Additional diagnostic information
      print('Current RPC URL: $_rpcUrl');
      print('Current Chain ID: $_chainId');

      return 0.0;
    }
  }

  // Get PYUSD balance with multiple fallback methods
  Future<double> getPYUSDBalance(String address) async {
    if (address.isEmpty) {
      print('Invalid address');
      return 0.0;
    }

    try {
      // Normalize address
      final normalizedAddress = EthereumAddress.fromHex(address).hex;

      // Try RPC method first
      final rpcBalance = await _getBalanceViaRPC(normalizedAddress);
      if (rpcBalance > 0) return rpcBalance;

      // Fallback to Etherscan API
      return await _getBalanceViaEtherscan(normalizedAddress);
    } catch (e) {
      print('Balance retrieval error: $e');
      return 0.0;
    }
  }

  // Get balance via RPC
  Future<double> _getBalanceViaRPC(String address) async {
    await _ensureInitialized();

    try {
      final balanceFunction = _contract.function('balanceOf');
      final ethAddress = EthereumAddress.fromHex(address);

      final result = await _ethClient.call(
        contract: _contract,
        function: balanceFunction,
        params: [ethAddress],
      ).timeout(Duration(seconds: 15));

      if (result.isNotEmpty && result[0] != null) {
        final balance = result[0] as BigInt;
        final decimals = await getTokenDecimals();
        return balance.toDouble() / BigInt.from(10).pow(decimals).toDouble();
      }
      return 0.0;
    } catch (e) {
      print('RPC balance retrieval error: $e');
      return 0.0;
    }
  }

  // Get balance via Etherscan API
  Future<double> _getBalanceViaEtherscan(String address) async {
    try {
      final etherscanApiKey = dotenv.env['ETHERSCAN_API_KEY'] ??
          'YBYI6VWHB8VIE5M8Z3BRPS4689N2VHV3SA';

      final response = await http
          .get(
            Uri.parse(
                '$_explorerApiUrl?module=account&action=tokenbalance&contractaddress=$_contractAddress&address=$address&tag=latest&apikey=$etherscanApiKey'),
          )
          .timeout(Duration(seconds: 15));

      final data = json.decode(response.body);

      if (data['status'] == '1' && data['result'] != null) {
        final BigInt balanceBI = BigInt.parse(data['result']);
        final decimals = await getTokenDecimals();
        return balanceBI.toDouble() / BigInt.from(10).pow(decimals).toDouble();
      }
      return 0.0;
    } catch (e) {
      print('Etherscan balance retrieval error: $e');
      return 0.0;
    }
  }

  // Get transaction history
  Future<List<TransactionModel>> getTransactionHistory(String address) async {
    if (address.isEmpty) return [];

    try {
      final normalizedAddress =
          EthereumAddress.fromHex(address).hex.toLowerCase();
      final etherscanApiKey = dotenv.env['ETHERSCAN_API_KEY'] ??
          'YBYI6VWHB8VIE5M8Z3BRPS4689N2VHV3SA';

      final response = await http
          .get(
            Uri.parse(
                '$_explorerApiUrl?module=account&action=tokentx&contractaddress=$_contractAddress&address=$normalizedAddress&sort=desc&apikey=$etherscanApiKey'),
          )
          .timeout(Duration(seconds: 15));

      final data = json.decode(response.body);
      final List<dynamic> txList = data['status'] == '1' ? data['result'] : [];

      final decimals = await getTokenDecimals();
      final List<TransactionModel> transactions = [];

      for (var tx in txList) {
        try {
          final BigInt valueBI = BigInt.parse(tx['value']);
          final double amount =
              valueBI.toDouble() / BigInt.from(10).pow(decimals).toDouble();

          final timestamp = DateTime.fromMillisecondsSinceEpoch(
              int.parse(tx['timeStamp']) * 1000);

          // Calculate gas fee
          final BigInt gasPrice = BigInt.parse(tx['gasPrice']);
          final BigInt gasUsed = BigInt.parse(tx['gasUsed']);
          final BigInt feeWei = gasPrice * gasUsed;
          final double feeEth =
              feeWei.toDouble() / BigInt.from(10).pow(18).toDouble();

          transactions.add(TransactionModel(
            hash: tx['hash'],
            hashLink: '$_explorerUrl/tx/${tx['hash']}',
            from: tx['from'],
            to: tx['to'],
            amount: amount,
            timestamp: timestamp,
            status: 'Confirmed',
            fee: feeEth.toStringAsFixed(6),
            networkName: _getNetworkName(_chainId),
          ));
        } catch (e) {
          print('Transaction processing error: $e');
        }
      }

      return transactions;
    } catch (e) {
      print('Transaction history retrieval error: $e');
      return [];
    }
  }

  Future<EtherAmount> estimateGasForPYUSDTransfer({
    required EthereumAddress from,
    required EthereumAddress to,
    required BigInt amount,
  }) async {
    await _ensureInitialized();

    try {
      final transferFunction = _contract.function('transfer');

      final transaction = Transaction(
        from: from,
        to: _contractAddress,
        data: transferFunction.encodeCall([to, amount]),
      );

      final estimatedGas = await _ethClient.estimateGas(
        sender: from,
        to: _contractAddress,
        data: transaction.data,
      );

      return EtherAmount.fromBigInt(EtherUnit.wei, estimatedGas);
    } catch (e) {
      print('Gas estimation error: $e');
      // Fallback to a standard gas limit for token transfers
      return EtherAmount.inWei(BigInt.from(100000));
    }
  }

  // Update gas price method
  Future<EtherAmount> getCurrentGasPrice() async {
    try {
      final gasPrice = await _ethClient.getGasPrice();
      return gasPrice;
    } catch (e) {
      print('Gas price retrieval error: $e');
      // Fallback to a default gas price (20 Gwei)
      return EtherAmount.fromInt(EtherUnit.gwei, 20);
    }
  }

  // Update transfer method
  Future<String?> transferPYUSD({
    required String from,
    required String to,
    required double amount,
    required EthPrivateKey credentials,
    EtherAmount? gasPrice,
    EtherAmount? gasLimit,
  }) async {
    await _ensureInitialized();

    try {
      final transferFunction = _contract.function('transfer');
      final decimals = await getTokenDecimals();
      final amountInWei =
          BigInt.from(amount * BigInt.from(10).pow(decimals).toDouble());

      // Use provided or estimated gas price and limit
      final effectiveGasPrice = gasPrice ?? await getCurrentGasPrice();
      final fromAddress = EthereumAddress.fromHex(from);
      final toAddress = EthereumAddress.fromHex(to);

      final effectiveGasLimit = gasLimit ??
          await estimateGasForPYUSDTransfer(
            from: fromAddress,
            to: toAddress,
            amount: amountInWei,
          );

      print('Transfer Details:');
      print('From: $from');
      print('To: $to');
      print('Amount: $amount');
      print(
          'Gas Price: ${effectiveGasPrice.getValueInUnit(EtherUnit.gwei)} Gwei');
      print(
          'Gas Limit: ${effectiveGasLimit.getValueInUnit(EtherUnit.wei)} Wei');

      final transaction = Transaction.callContract(
        contract: _contract,
        function: transferFunction,
        parameters: [toAddress, amountInWei],
        from: fromAddress,
        maxGas: effectiveGasLimit.getInWei.toInt(),
        gasPrice: effectiveGasPrice,
      );

      final txHash = await _ethClient.sendTransaction(
        credentials,
        transaction,
        chainId: _chainId,
      );

      return txHash;
    } catch (e) {
      print('Detailed transfer error: $e');
      return null;
    }
  }

  // Get network name from chain ID
  String _getNetworkName(int chainId) {
    switch (chainId) {
      case 1:
        return 'Ethereum Mainnet';
      case 11155111:
        return 'Sepolia Testnet';
      default:
        return 'Unknown Network';
    }
  }

  Future<Map<String, dynamic>> analyzeTransactionGas(
    String transactionHash,
    String networkName,
  ) async {
    try {
      // Fetch transaction details
      final txDetails = await _ethClient.getTransactionByHash(transactionHash);

      if (txDetails == null) {
        return {'Error': 'Transaction not found'};
      }

      // Get current gas price
      final gasPrice = await getCurrentGasPrice();

      // Calculate gas fees
      final BigInt gasUsed = BigInt.parse(txDetails.gas.toString());
      final BigInt gasPriceBI = gasPrice.getInWei;
      final BigInt totalGasFee = gasUsed * gasPriceBI;

      // Convert to ETH and USD (using current ETH price)
      final double gasFeeEth =
          totalGasFee.toDouble() / BigInt.from(10).pow(18).toDouble();

      return {
        'Gas Limit': txDetails.gas,
        'Gas Used': gasUsed,
        'Gas Price': '${gasPrice.getValueInUnit(EtherUnit.gwei)} Gwei',
        'Total Gas Fee (ETH)': gasFeeEth.toStringAsFixed(6),
        'Network': networkName,
      };
    } catch (e) {
      print('Gas analysis error: $e');
      return {'Error': 'Unable to analyze transaction gas'};
    }
  }

  // Cleanup method
  void dispose() {
    _ethClient.dispose();
  }
}

extension on BlockchainService {}
