import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/crypto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web3dart/web3dart.dart';

class PyusdInsightsProvider extends ChangeNotifier {
  // Constants
  static const String _rpcHttpUrl =
      'https://blockchain.googleapis.com/v1/projects/oceanic-impact-451616-f5/locations/us-central1/endpoints/ethereum-mainnet/rpc?key=AIzaSyAnZZi8DTOXLn3zcRKoGYtRgMl-YQnIo1Q';
  static const String _rpcWsUrl =
      'wss://blockchain.googleapis.com/v1/projects/oceanic-impact-451616-f5/locations/us-central1/endpoints/ethereum-mainnet/rpc?key=AIzaSyAnZZi8DTOXLn3zcRKoGYtRgMl-YQnIo1Q';

  // PYUSD contract address on Ethereum mainnet
  static const String _pyusdContractAddress =
      '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8';

  // ABIs - simplified for the required methods
  static const String _erc20Abi = '''
  [
    {"inputs": [], "name": "totalSupply", "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}], "stateMutability": "view", "type": "function"},
    {"inputs": [{"internalType": "address", "name": "", "type": "address"}], "name": "balanceOf", "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}], "stateMutability": "view", "type": "function"}
  ]
  ''';

  // State
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // Provider services
  late Web3Client _web3Client;
  WebSocketChannel? _wsChannel;

  // PYUSD Data
  double _totalSupply = 0;
  double get totalSupply => _totalSupply;

  int _uniqueHolders = 0;
  int get uniqueHolders => _uniqueHolders;

  int _totalTransfers = 0;
  int get totalTransfers => _totalTransfers;

  double _dailyVolume = 0;
  double get dailyVolume => _dailyVolume;

  double _weeklyVolume = 0;
  double get weeklyVolume => _weeklyVolume;

  double _monthlyVolume = 0;
  double get monthlyVolume => _monthlyVolume;

  double _ethBurned = 0;
  double get ethBurned => _ethBurned;

  double _marketShare = 0;
  double get marketShare => _marketShare;

  List<Map<String, dynamic>> _topHolders = [];
  List<Map<String, dynamic>> get topHolders => _topHolders;

  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> get recentTransactions => _recentTransactions;

  List<Map<String, dynamic>> _supplyHistory = [];
  List<Map<String, dynamic>> get supplyHistory => _supplyHistory;

  Map<String, double> _chainDistribution = {};
  Map<String, double> get chainDistribution => _chainDistribution;

  // Constructor
  PyusdInsightsProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Initialize Web3 client
      final httpClient = http.Client();
      _web3Client = Web3Client(_rpcHttpUrl, httpClient);

      // Initialize WebSocket for real-time updates
      _initializeWebSocket();

      // Fetch data
      await _fetchAllData();

      _isLoading = false;
      _errorMessage = '';
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to initialize: ${e.toString()}';
      print('Initialization error: $e');
    } finally {
      notifyListeners();
    }
  }

  void _initializeWebSocket() {
    try {
      _wsChannel = WebSocketChannel.connect(Uri.parse(_rpcWsUrl));

      // Subscribe to new blocks
      _wsChannel!.sink.add(jsonEncode({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "eth_subscribe",
        "params": ["newHeads"]
      }));

      // Subscribe to PYUSD Transfer events
      final transferEventSignature = keccak256(
          Uint8List.fromList(utf8.encode('Transfer(address,address,uint256)')));
      _wsChannel!.sink.add(jsonEncode({
        "jsonrpc": "2.0",
        "id": 2,
        "method": "eth_subscribe",
        "params": [
          "logs",
          {
            "address": _pyusdContractAddress,
            // "topics": [transferEventSignature.hex]
          }
        ]
      }));

      // Listen for WebSocket messages
      _wsChannel!.stream.listen((message) {
        final data = jsonDecode(message);
        if (data['method'] == 'eth_subscription' &&
            data['params']['subscription'] == 2) {
          // New PYUSD transfer detected
          _handleNewTransfer(data['params']['result']);
        }
      });
    } catch (e) {
      print('WebSocket initialization error: $e');
    }
  }

  void _handleNewTransfer(Map<String, dynamic> transferData) {
    // Process new transfer and update UI
    _fetchRecentTransactions();
    _fetchTotalSupply();
    notifyListeners();
  }

  Future<void> _fetchAllData() async {
    try {
      // Fetch basic metrics
      await _fetchTotalSupply();
      await _fetchUniqueHolders();
      await _fetchTransferCount();
      await _fetchVolumeMetrics();

      // Fetch more detailed data
      await _fetchSupplyHistory();
      await _fetchChainDistribution();
      await _fetchTopHolders();
      await _fetchRecentTransactions();
      await _fetchNetworkMetrics();

      // Sample data - would be replaced with actual data in production
      _setupSampleDataForDemo();
    } catch (e) {
      _errorMessage = 'Error fetching data: ${e.toString()}';
      print('Data fetching error: $e');
    }
  }

  Future<void> _fetchTotalSupply() async {
    try {
      final contract = DeployedContract(
        ContractAbi.fromJson(_erc20Abi, 'PYUSD'),
        EthereumAddress.fromHex(_pyusdContractAddress),
      );

      final totalSupplyFunction = contract.function('totalSupply');
      final result = await _web3Client.call(
        contract: contract,
        function: totalSupplyFunction,
        params: [],
      );

      // ERC-20 tokens typically have 18 decimals
      final rawSupply = BigInt.parse(result[0].toString());
      _totalSupply = rawSupply / BigInt.from(10).pow(6);
    } catch (e) {
      print('Error fetching total supply: $e');
    }
  }

  Future<void> _fetchUniqueHolders() async {
    try {
      // This would be a BigQuery call in production to count unique addresses with balance > 0
      // Sample implementation:
      final query = '''
        SELECT COUNT(DISTINCT holder_address) as unique_holders
        FROM `blockchain-etl.ethereum_pyusd.token_holders`
        WHERE token_address = '$_pyusdContractAddress'
          AND balance > 0
      ''';

      // For demo, we'll simulate the API call
      await Future.delayed(const Duration(milliseconds: 500));
      _uniqueHolders = 43219;
    } catch (e) {
      print('Error fetching unique holders: $e');
    }
  }

  Future<void> _fetchTransferCount() async {
    try {
      // This would be a BigQuery call in production to count total transfers
      // Sample implementation:
      final query = '''
        SELECT COUNT(*) as transfer_count
        FROM `blockchain-etl.ethereum_pyusd.token_transfers`
        WHERE token_address = '$_pyusdContractAddress'
      ''';

      // For demo, we'll simulate the API call
      await Future.delayed(const Duration(milliseconds: 400));
      _totalTransfers = 182467;
    } catch (e) {
      print('Error fetching transfer count: $e');
    }
  }

  Future<void> _fetchVolumeMetrics() async {
    try {
      // This would be a BigQuery call in production to sum transfer values by time period
      // Sample implementation for daily volume:
      final dailyQuery = '''
        SELECT SUM(value/1000000) as daily_volume
        FROM `blockchain-etl.ethereum_pyusd.token_transfers`
        WHERE token_address = '$_pyusdContractAddress'
          AND DATE(block_timestamp) = CURRENT_DATE()
      ''';

      // For demo, we'll simulate the API calls
      await Future.delayed(const Duration(milliseconds: 300));
      _dailyVolume = 24528937.42;
      _weeklyVolume = 187645200.18;
      _monthlyVolume = 892345678.92;
    } catch (e) {
      print('Error fetching volume metrics: $e');
    }
  }

  Future<void> _fetchSupplyHistory() async {
    try {
      // This would be a BigQuery call in production to get daily supply snapshots
      // Sample implementation:
      final query = '''
        SELECT 
          DATE(block_timestamp) as date,
          MAX(value) as supply
        FROM `blockchain-etl.ethereum_pyusd.token_supply_snapshots`
        WHERE token_address = '$_pyusdContractAddress'
        GROUP BY date
        ORDER BY date
        LIMIT 30
      ''';

      // For demo, we'll simulate the API call
      await Future.delayed(const Duration(milliseconds: 600));
      _generateSupplyHistoryData();
    } catch (e) {
      print('Error fetching supply history: $e');
    }
  }

  Future<void> _fetchChainDistribution() async {
    try {
      // This would require cross-chain data collection in production
      // For demo, we'll simulate the API call
      await Future.delayed(const Duration(milliseconds: 400));
      _chainDistribution = {
        'Ethereum': 68.5,
        'Avalanche': 12.8,
        'Polygon': 10.4,
        'Arbitrum': 6.2,
        'Optimism': 2.1,
      };
    } catch (e) {
      print('Error fetching chain distribution: $e');
    }
  }

  Future<void> _fetchTopHolders() async {
    try {
      // This would be a BigQuery call in production to get top holders
      // Sample implementation:
      final query = '''
        SELECT 
          holder_address as address,
          balance/1000000 as balance,
          balance/1000000 / total_supply * 100 as percentage
        FROM `blockchain-etl.ethereum_pyusd.token_holders`
        WHERE token_address = '$_pyusdContractAddress'
        ORDER BY balance DESC
        LIMIT 10
      ''';

      // For demo, we'll simulate the API call
      await Future.delayed(const Duration(milliseconds: 700));
      _generateTopHoldersData();
    } catch (e) {
      print('Error fetching top holders: $e');
    }
  }

  Future<void> _fetchRecentTransactions() async {
    try {
      // This would be a BigQuery call in production to get recent transfers
      // Sample implementation:
      final query = '''
        SELECT 
          from_address as `from`,
          to_address as `to`,
          transaction_hash as hash,
          value/1000000 as value,
          UNIX_MILLIS(block_timestamp) as timestamp
        FROM `blockchain-etl.ethereum_pyusd.token_transfers`
        WHERE token_address = '$_pyusdContractAddress'
        ORDER BY block_timestamp DESC
        LIMIT 20
      ''';

      // For demo, we'll simulate the API call
      await Future.delayed(const Duration(milliseconds: 500));
      _generateRecentTransactionsData();
    } catch (e) {
      print('Error fetching recent transactions: $e');
    }
  }

  Future<void> _fetchNetworkMetrics() async {
    try {
      // This would be a combination of BigQuery calls in production
      // For demo, we'll simulate the API calls
      await Future.delayed(const Duration(milliseconds: 400));
      _ethBurned = 842.58;
      _marketShare = 8.2;
    } catch (e) {
      print('Error fetching network metrics: $e');
    }
  }

  // Generate sample data
  void _generateSupplyHistoryData() {
    _supplyHistory = [];
    double baseSupply = 1800000000;
    final now = DateTime.now();

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      // Add some randomness to simulate natural growth
      baseSupply += (10000000 * (30 - i) / 30) +
          (5000000 * (DateTime.now().millisecondsSinceEpoch % 100) / 100);

      _supplyHistory.add({
        'date': date.toIso8601String().split('T')[0],
        'supply': baseSupply,
      });
    }
  }

  void _generateTopHoldersData() {
    _topHolders = [
      {
        'address': '0x5754284f345afc66a98fbB0a0Afe71e0F007B949',
        'balance': 523648992.38,
        'percentage': 25.8,
        'label': 'Paypal Treasury',
      },
      {
        'address': '0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503',
        'balance': 312874562.91,
        'percentage': 15.4,
        'label': 'Binance Hot Wallet',
      },
      {
        'address': '0x28C6c06298d514Db089934071355E5743bf21d60',
        'balance': 187652341.72,
        'percentage': 9.2,
        'label': 'Coinbase Custody',
      },
      {
        'address': '0x21a31Ee1afC51d94C2eFcCAa2092aD1028285549',
        'balance': 126459873.08,
        'percentage': 6.2,
        'label': 'FTX Deposits',
      },
      {
        'address': '0xe04F27eb70E3c5ddf1baA222ef3933C6FA9674F4',
        'balance': 98765432.19,
        'percentage': 4.9,
        'label': 'Kraken',
      },
      {
        'address': '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
        'balance': 78954321.07,
        'percentage': 3.9,
        'label': 'Circle Treasury',
      },
      {
        'address': '0x6B175474E89094C44Da98b954EedeAC495271d0F',
        'balance': 65432198.76,
        'percentage': 3.2,
        'label': 'MakerDAO Vault',
      },
      {
        'address': '0x3883f5e181fccaF8410FA61e12b59BAd963fb645',
        'balance': 54321987.65,
        'percentage': 2.7,
        'label': 'Alameda Research',
      },
      {
        'address': '0xdAC17F958D2ee523a2206206994597C13D831ec7',
        'balance': 43219876.54,
        'percentage': 2.1,
        'label': 'Tether Treasury',
      },
      {
        'address': '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D',
        'balance': 32198765.43,
        'percentage': 1.6,
        'label': 'Uniswap V2 Pool',
      },
    ];
  }

  void _generateRecentTransactionsData() {
    final now = DateTime.now();
    _recentTransactions = [
      {
        'from': '0x5754284f345afc66a98fbB0a0Afe71e0F007B949',
        'to': '0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503',
        'hash':
            '0x1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b',
        'value': 15000000,
        'timestamp':
            now.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch,
      },
      {
        'from': '0x28C6c06298d514Db089934071355E5743bf21d60',
        'to': '0x21a31Ee1afC51d94C2eFcCAa2092aD1028285549',
        'hash':
            '0x2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c',
        'value': 8500000,
        'timestamp':
            now.subtract(const Duration(minutes: 12)).millisecondsSinceEpoch,
      },
      {
        'from': '0xe04F27eb70E3c5ddf1baA222ef3933C6FA9674F4',
        'to': '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
        'hash':
            '0x3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d',
        'value': 5000000,
        'timestamp':
            now.subtract(const Duration(minutes: 18)).millisecondsSinceEpoch,
      },
      {
        'from': '0x6B175474E89094C44Da98b954EedeAC495271d0F',
        'to': '0x3883f5e181fccaF8410FA61e12b59BAd963fb645',
        'hash':
            '0x4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e',
        'value': 3200000,
        'timestamp':
            now.subtract(const Duration(minutes: 27)).millisecondsSinceEpoch,
      },
      {
        'from': '0xdAC17F958D2ee523a2206206994597C13D831ec7',
        'to': '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D',
        'hash':
            '0x5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f',
        'value': 1800000,
        'timestamp':
            now.subtract(const Duration(minutes: 35)).millisecondsSinceEpoch,
      },
      {
        'from': '0x5754284f345afc66a98fbB0a0Afe71e0F007B949',
        'to': '0x28C6c06298d514Db089934071355E5743bf21d60',
        'hash':
            '0x6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a',
        'value': 9500000,
        'timestamp':
            now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
      },
      {
        'from': '0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503',
        'to': '0x21a31Ee1afC51d94C2eFcCAa2092aD1028285549',
        'hash':
            '0x7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b',
        'value': 4300000,
        'timestamp': now
            .subtract(const Duration(hours: 1, minutes: 15))
            .millisecondsSinceEpoch,
      },
      {
        'from': '0xe04F27eb70E3c5ddf1baA222ef3933C6FA9674F4',
        'to': '0x6B175474E89094C44Da98b954EedeAC495271d0F',
        'hash':
            '0x8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c',
        'value': 2700000,
        'timestamp': now
            .subtract(const Duration(hours: 1, minutes: 30))
            .millisecondsSinceEpoch,
      },
      {
        'from': '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
        'to': '0x3883f5e181fccaF8410FA61e12b59BAd963fb645',
        'hash':
            '0x9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d',
        'value': 1900000,
        'timestamp': now
            .subtract(const Duration(hours: 1, minutes: 45))
            .millisecondsSinceEpoch,
      },
      {
        'from': '0xdAC17F958D2ee523a2206206994597C13D831ec7',
        'to': '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D',
        'hash':
            '0x0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e',
        'value': 1200000,
        'timestamp':
            now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
      },
    ];
  }

  void _setupSampleDataForDemo() {
    // This is a placeholder for demo data that would be replaced with actual API data in production
    _totalSupply = 2025000000;
    _uniqueHolders = 43219;
    _totalTransfers = 182467;
    _dailyVolume = 24528937.42;
    _weeklyVolume = 187645200.18;
    _monthlyVolume = 892345678.92;
    _ethBurned = 842.58;
    _marketShare = 8.2;

    _generateSupplyHistoryData();
    _generateTopHoldersData();
    _generateRecentTransactionsData();

    _chainDistribution = {
      'Ethereum': 68.5,
      'Avalanche': 12.8,
      'Polygon': 10.4,
      'Arbitrum': 6.2,
      'Optimism': 2.1,
    };
  }

// Method to manually refresh data
  Future<void> refreshData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Fetch fresh data
      await _fetchAllData();

      _isLoading = false;
      _errorMessage = '';
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to refresh data: ${e.toString()}';
      print('Refresh error: $e');
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Clean up resources
    _wsChannel?.sink.close();
    _web3Client.dispose();
    super.dispose();
  }
}
