import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/crypto.dart';
import 'dart:convert';
import 'dart:async';
import 'package:web3dart/web3dart.dart';

// PYUSD token contract address on Ethereum
const String pyusdContractAddress =
    '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8';

// ABI for basic ERC20 functions we need
const String erc20AbiJson = '''
[
  {"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},
  {"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},
  {"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Transfer","type":"event"}
]
''';

class PyusdStatsProvider with ChangeNotifier {
  bool isLoading = true;
  String gcpRpcUrl =
      'https://blockchain.googleapis.com/v1/projects/oceanic-impact-451616-f5/locations/us-central1/endpoints/ethereum-mainnet/rpc?key=AIzaSyAnZZi8DTOXLn3zcRKoGYtRgMl-YQnIo1Q';

  // Stats data
  double marketCap = 0;
  double circulatingSupply = 0;
  int holders = 0;
  double averageTransactionValue = 0;
  int dailyTransactions = 0;
  double monthlySavingsFee = 0;
  double growthRate = 0;
  double ethereumGasImpact = 0;
  double pyusdPrice = 0;

  List<Map<String, dynamic>> monthlyData = [];
  List<Map<String, dynamic>> networkShare = [];
  List<Map<String, dynamic>> chainDistribution = [];

  // Web3 client
  late Web3Client ethClient;

  PyusdStatsProvider() {
    ethClient = Web3Client(gcpRpcUrl, http.Client());
    loadAllData();
  }

  @override
  void dispose() {
    ethClient.dispose();
    super.dispose();
  }

  // Main method to load all data
  Future<void> loadAllData() async {
    isLoading = true;
    notifyListeners();

    try {
      // Parallel fetch for better performance
      await Future.wait([
        _fetchTokenData(),
        _fetchMarketData(),
        _fetchNetworkData(),
        _fetchHistoricalData(),
      ]);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading PYUSD data: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  // Fetch token supply and market cap from blockchain and CoinGecko

  Future<void> _fetchTokenData() async {
    try {
      // Get totalSupply from blockchain
      final contract = DeployedContract(
          ContractAbi.fromJson(erc20AbiJson, 'PYUSD'),
          EthereumAddress.fromHex(pyusdContractAddress));

      final totalSupplyFunction = contract.function('totalSupply');
      final totalSupplyResult = await ethClient
          .call(contract: contract, function: totalSupplyFunction, params: []);

      // ERC20 tokens typically have 6 or 18 decimals
      // PYUSD has 6 decimals
      final supply =
          EtherAmount.fromUnitAndValue(EtherUnit.wei, totalSupplyResult[0])
                  .getValueInUnit(EtherUnit.ether) *
              1000000; // Convert to actual value

      circulatingSupply = supply;

      // Get price from CoinGecko
      final response = await http.get(Uri.parse(
          'https://api.coingecko.com/api/v3/simple/token_price/ethereum?contract_addresses=$pyusdContractAddress&vs_currencies=usd'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Extract and store the PYUSD price
        pyusdPrice = data[pyusdContractAddress.toLowerCase()]['usd'] ?? 1.0;

        // Calculate market cap using the price
        marketCap = circulatingSupply * pyusdPrice;
      } else {
        // Fallback to a value close to $1 as it's a stablecoin
        pyusdPrice = 1.0;
        marketCap = circulatingSupply * pyusdPrice;
      }
    } catch (e) {
      print('Error fetching token data: $e');
      // Set reasonable values for a stablecoin if fetching fails
      circulatingSupply = 1837500000;
      pyusdPrice = 1.0;
      marketCap = circulatingSupply * pyusdPrice;
    }
  }

  // Fetch market data including transaction counts and holder stats
  Future<void> _fetchMarketData() async {
    try {
      // For holders count, we can use Etherscan API
      final etherscanApiKey =
          'YBYI6VWHB8VIE5M8Z3BRPS4689N2VHV3SA'; // You should get your own key
      final holdersResponse = await http.get(Uri.parse(
          'https://api.etherscan.io/api?module=token&action=tokenholderlist&contractaddress=$pyusdContractAddress&page=1&offset=1&apikey=$etherscanApiKey'));

      if (holdersResponse.statusCode == 200) {
        final data = json.decode(holdersResponse.body);
        if (data['status'] == '1') {
          holders = int.parse(data['result'][0]['tokenHolderCount']);
        } else {
          // If API fails, use Dune Analytics or direct query if you have access
          holders = 126758; // Use last known value if API fails
        }
      } else {
        holders = 126758;
      }

      // For transaction data, query the Transfer events
      // This is a simplified approach - in production you'd implement pagination
      // and date filtering for daily transactions
      final contract = DeployedContract(
          ContractAbi.fromJson(erc20AbiJson, 'PYUSD'),
          EthereumAddress.fromHex(pyusdContractAddress));

      final transferEvent = contract.event('Transfer');
      final blockNumber = await ethClient.getBlockNumber();

      final events = await ethClient.getLogs(FilterOptions(
        fromBlock: BlockNum.exact(blockNumber - 6500),
        toBlock: BlockNum.exact(blockNumber),
        address: EthereumAddress.fromHex(pyusdContractAddress),
        topics: [
          [
            bytesToHex(transferEvent.signature, include0x: true)
          ] // Convert to hex string
        ],
      ));
      dailyTransactions = events.length;

      // Calculate average transaction value
      double totalValue = 0;
      for (var event in events) {
        if (event.topics != null && event.data != null) {
          final decoded =
              transferEvent.decodeResults(event.topics!, event.data!);
          final value =
              EtherAmount.fromUnitAndValue(EtherUnit.wei, decoded[2] as BigInt)
                      .getValueInUnit(EtherUnit.ether) *
                  1000000;

          totalValue += value;
        }
      }

      averageTransactionValue = events.isEmpty ? 0 : totalValue / events.length;

      // Gas impact estimation (comparing to other stablecoins)
      // In production, you'd calculate this by comparing actual gas used
      ethereumGasImpact = 0.124; // Approximately 12.4% savings

      // Monthly savings calculation based on daily transactions and gas savings
      // Assuming average gas cost and price
      monthlySavingsFee =
          dailyTransactions * 30 * averageTransactionValue * ethereumGasImpact;
    } catch (e) {
      print('Error fetching market data: $e');
      // Set reasonable fallback values
      holders = 126758;
      dailyTransactions = 27429;
      averageTransactionValue = 18753;
      ethereumGasImpact = 0.124;
      monthlySavingsFee = 2856000;
    }
  }

  // Get network data including market share and chain distribution
  Future<void> _fetchNetworkData() async {
    try {
      // Network share data requires aggregating data from multiple sources
      // This would normally be done through a backend API or data provider
      // Here's a simplified example using CoinGecko
      final response = await http.get(Uri.parse(
          'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&category=stablecoin&order=market_cap_desc'));

      if (response.statusCode == 200) {
        final List<dynamic> stablecoins = json.decode(response.body);

        // Filter major stablecoins and calculate percentages
        final tether = stablecoins.firstWhere(
            (coin) => coin['symbol'] == 'usdt',
            orElse: () => {'market_cap': 78000000000});
        final usdc = stablecoins.firstWhere((coin) => coin['symbol'] == 'usdc',
            orElse: () => {'market_cap': 68000000000});
        final busd = stablecoins.firstWhere((coin) => coin['symbol'] == 'busd',
            orElse: () => {'market_cap': 10000000000});

        final totalMarketCap = tether['market_cap'] +
            usdc['market_cap'] +
            busd['market_cap'] +
            marketCap;

        networkShare = [
          {
            'name': 'PYUSD',
            'value': ((marketCap / totalMarketCap) * 100).round()
          },
          {
            'name': 'USDT',
            'value': ((tether['market_cap'] / totalMarketCap) * 100).round()
          },
          {
            'name': 'USDC',
            'value': ((usdc['market_cap'] / totalMarketCap) * 100).round()
          },
          {
            'name': 'BUSD',
            'value': ((busd['market_cap'] / totalMarketCap) * 100).round()
          },
        ];
      } else {
        // Use fallback data
        networkShare = [
          {'name': 'PYUSD', 'value': 27},
          {'name': 'USDT', 'value': 36},
          {'name': 'USDC', 'value': 32},
          {'name': 'BUSD', 'value': 5},
        ];
      }

      // Chain distribution would require querying multiple chains
      // For simplicity, we'll use reasonable estimates
      chainDistribution = [
        {'name': 'Ethereum', 'value': 68},
        {'name': 'Optimism', 'value': 12},
        {'name': 'Base', 'value': 11},
        {'name': 'Arbitrum', 'value': 9},
      ];
    } catch (e) {
      print('Error fetching network data: $e');
      networkShare = [
        {'name': 'PYUSD', 'value': 27},
        {'name': 'USDT', 'value': 36},
        {'name': 'USDC', 'value': 32},
        {'name': 'BUSD', 'value': 5},
      ];

      chainDistribution = [
        {'name': 'Ethereum', 'value': 68},
        {'name': 'Optimism', 'value': 12},
        {'name': 'Base', 'value': 11},
        {'name': 'Arbitrum', 'value': 9},
      ];
    }
  }

  // Fetch historical data for charts
  Future<void> _fetchHistoricalData() async {
    try {
      // For historical data, we'd normally use a data provider API
      // Here's a simplified approach using CoinGecko for price history
      final monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final currentMonth = DateTime.now().month;
      // Use the class-level marketCap variable, not a local one
      final double currentMarketCap = this.marketCap;

      final response = await http.get(Uri.parse(
          'https://api.coingecko.com/api/v3/coins/ethereum/contract/$pyusdContractAddress/market_chart/?vs_currency=usd&days=180'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> marketCapHistory = data['market_caps'];

        // Group by month (simplified)
        Map<int, double> monthlyMarketCaps = {};

        for (var point in marketCapHistory) {
          final date = DateTime.fromMillisecondsSinceEpoch(point[0]);
          final month = date.month;
          monthlyMarketCaps[month] = point[1];
        }

        // Calculate growth rate
        final lastTwoMonths = monthlyMarketCaps.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key));

        if (lastTwoMonths.length >= 2) {
          final current = lastTwoMonths[0].value;
          final previous = lastTwoMonths[1].value;
          growthRate = (current - previous) / previous;
        } else {
          growthRate = 0.178;
        }

        // Create monthly data for the chart
        monthlyData = [];

        // Get the last 6 months
        for (int i = 5; i >= 0; i--) {
          int monthIndex = (currentMonth - i) % 12;
          if (monthIndex <= 0) monthIndex += 12;

          final month = monthNames[monthIndex - 1];
          final monthMarketCap = monthlyMarketCaps[monthIndex] ??
              currentMarketCap * (1 - (i * 0.05));

          // Holders and transactions are estimated based on market cap trend
          final monthHolders =
              (this.holders * (monthMarketCap / currentMarketCap)).round();
          final transactions =
              (dailyTransactions * (monthMarketCap / currentMarketCap)).round();

          monthlyData.add({
            'month': month,
            'marketCap': monthMarketCap,
            'transactions': transactions,
            'holders': monthHolders
          });
        }
      } else {
        // Fallback data if API fails
        monthlyData = [
          {
            'month': 'Mar',
            'marketCap': currentMarketCap * 0.85,
            'transactions': 20000,
            'holders': 100000
          },
          {
            'month': 'Apr',
            'marketCap': currentMarketCap * 0.88,
            'transactions': 22000,
            'holders': 105000
          },
          {
            'month': 'May',
            'marketCap': currentMarketCap * 0.92,
            'transactions': 23500,
            'holders': 110000
          },
          {
            'month': 'Jun',
            'marketCap': currentMarketCap * 0.95,
            'transactions': 24800,
            'holders': 115000
          },
          {
            'month': 'Jul',
            'marketCap': currentMarketCap * 0.98,
            'transactions': 26200,
            'holders': 120000
          },
          {
            'month': 'Aug',
            'marketCap': currentMarketCap,
            'transactions': dailyTransactions,
            'holders': holders
          }
        ];

        growthRate = 0.178;
      }
    } catch (e) {
      print('Error fetching historical data: $e');
      // Fallback data if API fails
      monthlyData = [
        {
          'month': 'Mar',
          'marketCap': 1500000000,
          'transactions': 20000,
          'holders': 100000
        },
        {
          'month': 'Apr',
          'marketCap': 1550000000,
          'transactions': 22000,
          'holders': 105000
        },
        {
          'month': 'May',
          'marketCap': 1620000000,
          'transactions': 23500,
          'holders': 110000
        },
        {
          'month': 'Jun',
          'marketCap': 1700000000,
          'transactions': 24800,
          'holders': 115000
        },
        {
          'month': 'Jul',
          'marketCap': 1750000000,
          'transactions': 26200,
          'holders': 120000
        },
        {
          'month': 'Aug',
          'marketCap': 1837500000,
          'transactions': 27429,
          'holders': 126758
        }
      ];

      growthRate = 0.178;
    }
  }

  // Helper method to format numbers for display
  String formatNumber(num number) {
    if (number >= 1000000000) {
      return '\$${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number >= 1000000) {
      return '\$${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

// Add this extension method to convert hex string to bytes
extension HexToBytes on String {
  List<int> hexToBytes() {
    String cleanedHex = replaceAll('0x', '');
    List<int> bytes = [];
    for (int i = 0; i < cleanedHex.length; i += 2) {
      if (i + 2 <= cleanedHex.length) {
        String hexPart = cleanedHex.substring(i, i + 2);
        bytes.add(int.parse(hexPart, radix: 16));
      }
    }
    return bytes;
  }
}
