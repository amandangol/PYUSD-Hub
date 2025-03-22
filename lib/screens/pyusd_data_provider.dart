import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PyusdDashboardProvider extends ChangeNotifier {
  static const String rpcEndpoint =
      'https://blockchain.googleapis.com/v1/projects/oceanic-impact-451616-f5/locations/us-central1/endpoints/ethereum-mainnet/rpc?key=AIzaSyAnZZi8DTOXLn3zcRKoGYtRgMl-YQnIo1Q';
  static const String pyusdContractAddress =
      '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8'; // PYUSD contract address

  // PYUSD contract event signatures
  static const String mintEventSignature =
      '0x9d228d69b5fdb8d273a2336f8fb8612d039631024ea9bf09c424a9503aa078f0'; // Mint(address,uint256)
  static const String burnEventSignature =
      '0xcc16f5dbb4873280815c1ee09dbd06736cffcc184412cf7a71a0fdb75d397ca5'; // Burn(address,uint256)

  // State variables
  BigInt _pyusdSupply = BigInt.zero;
  BigInt _pyusdBurned = BigInt.zero;
  BigInt _pyusdMinted = BigInt.zero;
  double _pyusdBurnRate = 0;
  double _pyusdMintRate = 0;
  double _pyusdNetFlowRate = 0;
  bool _isLoading = false;
  String _error = '';

  // Data periods
  Map<String, dynamic> _dailyData = {};
  Map<String, dynamic> _weeklyData = {};
  Map<String, dynamic> _monthlyData = {};

  // Selected time period
  String _selectedPeriod = 'day'; // 'day', 'week', 'month'

  // Getters
  BigInt get pyusdSupply => _pyusdSupply;
  BigInt get pyusdBurned => _pyusdBurned;
  BigInt get pyusdMinted => _pyusdMinted;
  double get pyusdBurnRate => _pyusdBurnRate;
  double get pyusdMintRate => _pyusdMintRate;
  double get pyusdNetFlowRate => _pyusdNetFlowRate;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get selectedPeriod => _selectedPeriod;
  Map<String, dynamic> get currentPeriodData {
    switch (_selectedPeriod) {
      case 'day':
        return _dailyData;
      case 'week':
        return _weeklyData;
      case 'month':
        return _monthlyData;
      default:
        return _dailyData;
    }
  }

  // HTTP client for RPC calls
  final _httpClient = http.Client();

  // Set time period
  void setTimePeriod(String period) {
    if (period != _selectedPeriod &&
        ['day', 'week', 'month'].contains(period)) {
      _selectedPeriod = period;
      notifyListeners();
    }
  }

  // Initialize and start data fetching
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Initial data fetch
      await _fetchCurrentData();

      // Fetch historical data for different time periods
      await _fetchHistoricalData('day');
      await _fetchHistoricalData('week');
      await _fetchHistoricalData('month');

      // Start periodic updates
      Timer.periodic(const Duration(minutes: 5), (_) => _fetchCurrentData());

      // Update historical data periodically
      Timer.periodic(const Duration(hours: 1), (_) async {
        await _fetchHistoricalData(_selectedPeriod);
      });
    } catch (e) {
      _setError('Failed to initialize dashboard: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Main method to fetch current data
  Future<void> _fetchCurrentData() async {
    try {
      // Get latest block number
      final blockNumber = await _getLatestBlockNumber();

      // Get PYUSD total supply
      await _fetchPyusdSupply();

      // Get recent mint and burn events
      await _fetchRecentEvents(blockNumber - 2000, blockNumber);

      // Calculate rates based on recent events
      _calculateRates();

      notifyListeners();
    } catch (e) {
      _setError('Error fetching current data: $e');
    }
  }

  // Fetch historical data for specified time period
  Future<void> _fetchHistoricalData(String period) async {
    try {
      final latestBlock = await _getLatestBlockNumber();

      // Calculate block ranges based on period
      int blocksToFetch;
      int blockInterval;

      switch (period) {
        case 'day':
          blocksToFetch = 6400; // ~24 hours worth of blocks
          blockInterval = 800; // ~3 hour intervals
          break;
        case 'week':
          blocksToFetch = 45000; // ~7 days worth of blocks
          blockInterval = 5400; // ~1 day intervals
          break;
        case 'month':
          blocksToFetch = 192000; // ~30 days worth of blocks
          blockInterval = 16000; // ~2.5 day intervals
          break;
        default:
          blocksToFetch = 6400;
          blockInterval = 800;
      }

      final startBlock = latestBlock - blocksToFetch;

      // Get supply snapshots and events over time
      List<Map<String, dynamic>> supplyHistory = [];
      List<Map<String, dynamic>> mintEvents = [];
      List<Map<String, dynamic>> burnEvents = [];

      // Fetch data in chunks to prevent timeout
      for (int block = startBlock;
          block < latestBlock;
          block += blockInterval) {
        final endBlock = block + blockInterval > latestBlock
            ? latestBlock
            : block + blockInterval;

        // Get supply at this block
        final supply = await _getPyusdSupplyAtBlock(block);
        supplyHistory.add({
          'blockNumber': block,
          'timestamp': await _getBlockTimestamp(block),
          'supply': supply,
        });

        // Get events in this block range
        final List<Map<String, dynamic>> events =
            (await _fetchEventsByBlockRange(block, endBlock))
                .cast<Map<String, dynamic>>();

        mintEvents
            .addAll(events.where((e) => e['topics'][0] == mintEventSignature));
        burnEvents
            .addAll(events.where((e) => e['topics'][0] == burnEventSignature));
      }

      // Calculate statistics for this period
      Map<String, dynamic> periodData = {
        'supplyHistory': supplyHistory,
        'mintEvents': mintEvents,
        'burnEvents': burnEvents,
        'startSupply': supplyHistory.first['supply'],
        'endSupply': supplyHistory.last['supply'],
        'netChange':
            supplyHistory.last['supply'] - supplyHistory.first['supply'],
        'totalMinted': _calculateTotalFromEvents(mintEvents),
        'totalBurned': _calculateTotalFromEvents(burnEvents),
        'startTime': supplyHistory.first['timestamp'],
        'endTime': supplyHistory.last['timestamp'],
      };

      // Store data for selected period
      switch (period) {
        case 'day':
          _dailyData = periodData;
          break;
        case 'week':
          _weeklyData = periodData;
          break;
        case 'month':
          _monthlyData = periodData;
          break;
      }

      notifyListeners();
    } catch (e) {
      _setError('Error fetching historical data: $e');
    }
  }

  // Helper method to make JSON-RPC calls
  Future<dynamic> _makeRpcCall(String method, List<dynamic> params) async {
    final requestBody = jsonEncode({
      'jsonrpc': '2.0',
      'id': 1,
      'method': method,
      'params': params,
    });

    final response = await _httpClient.post(
      Uri.parse(rpcEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData.containsKey('error')) {
        throw Exception('RPC Error: ${responseData['error']}');
      }
      return responseData['result'];
    } else {
      throw Exception('Failed to make RPC call: ${response.statusCode}');
    }
  }

  // Get latest block number
  Future<int> _getLatestBlockNumber() async {
    final result = await _makeRpcCall('eth_blockNumber', []);
    return int.parse(result.substring(2), radix: 16);
  }

  // Get block timestamp
  Future<int> _getBlockTimestamp(int blockNumber) async {
    final blockHex = '0x${blockNumber.toRadixString(16)}';
    final blockData =
        await _makeRpcCall('eth_getBlockByNumber', [blockHex, false]);
    return int.parse(blockData['timestamp'].substring(2), radix: 16);
  }

  // Fetch PYUSD total supply from contract
  Future<void> _fetchPyusdSupply() async {
    try {
      // Call the totalSupply method on the PYUSD contract
      final data = '0x18160ddd'; // Function signature for totalSupply()
      final result = await _makeRpcCall('eth_call', [
        {
          'to': pyusdContractAddress,
          'data': data,
        },
        'latest'
      ]);

      // Parse the result - PYUSD has 6 decimals
      _pyusdSupply = BigInt.parse(result);
    } catch (e) {
      _setError('Error fetching PYUSD supply: $e');
    }
  }

  // Get PYUSD supply at a specific block
  Future<BigInt> _getPyusdSupplyAtBlock(int blockNumber) async {
    try {
      final blockHex = '0x${blockNumber.toRadixString(16)}';
      final data = '0x18160ddd'; // Function signature for totalSupply()

      final result = await _makeRpcCall('eth_call', [
        {
          'to': pyusdContractAddress,
          'data': data,
        },
        blockHex
      ]);

      return BigInt.parse(result);
    } catch (e) {
      _setError('Error fetching historical PYUSD supply: $e');
      return BigInt.zero;
    }
  }

  // Fetch event logs from contract
  Future<List<dynamic>> _fetchEventsByBlockRange(
      int fromBlock, int toBlock) async {
    try {
      final fromBlockHex = '0x${fromBlock.toRadixString(16)}';
      final toBlockHex = '0x${toBlock.toRadixString(16)}';

      final result = await _makeRpcCall('eth_getLogs', [
        {
          'address': pyusdContractAddress,
          'fromBlock': fromBlockHex,
          'toBlock': toBlockHex,
          'topics': [
            [
              mintEventSignature,
              burnEventSignature
            ] // Filter for mint and burn events
          ]
        }
      ]);

      return result as List<dynamic>;
    } catch (e) {
      _setError('Error fetching event logs: $e');
      return [];
    }
  }

  // Fetch recent events for calculating rates
  Future<void> _fetchRecentEvents(int fromBlock, int toBlock) async {
    try {
      final events = await _fetchEventsByBlockRange(fromBlock, toBlock);

      // Process events
      _pyusdMinted = BigInt.zero;
      _pyusdBurned = BigInt.zero;

      for (final event in events) {
        final value = BigInt.parse(event['data']);
        if (event['topics'][0] == mintEventSignature) {
          _pyusdMinted += value;
        } else if (event['topics'][0] == burnEventSignature) {
          _pyusdBurned += value;
        }
      }
    } catch (e) {
      _setError('Error fetching recent events: $e');
    }
  }

  // Calculate total from event list
  BigInt _calculateTotalFromEvents(List<dynamic> events) {
    BigInt total = BigInt.zero;
    for (final event in events) {
      total += BigInt.parse(event['data']);
    }
    return total;
  }

  // Calculate rates based on recent events
  void _calculateRates() {
    // Assuming the rates are per hour and based on recent blocks (~2000 blocks = ~8 hours)
    const hoursSpan = 8.0;

    _pyusdBurnRate =
        (_pyusdBurned / BigInt.from(10).pow(6) / hoursSpan).toDouble();
    _pyusdMintRate =
        (_pyusdMinted / BigInt.from(10).pow(6) / hoursSpan).toDouble();
    _pyusdNetFlowRate = _pyusdMintRate - _pyusdBurnRate;
  }

  // Helper methods for state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  // Clean up resources
  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  // Format supply for display (convert smallest unit to PYUSD)
  String formatPyusdSupply() {
    return (_pyusdSupply / BigInt.from(10).pow(6)).toStringAsFixed(2);
  }

  // Format supply for display (convert smallest unit to PYUSD)
  String formatAmount(BigInt amount) {
    return (amount / BigInt.from(10).pow(6)).toStringAsFixed(2);
  }

  // Format rate for display (PYUSD per hour)
  String formatRate(double rate) {
    return rate.toStringAsFixed(2);
  }

  // Get net change percentage for selected period
  double getNetChangePercentage() {
    final data = currentPeriodData;
    if (data.isEmpty || data['startSupply'] == BigInt.zero) {
      return 0.0;
    }

    final startSupply = data['startSupply'] as BigInt;
    final netChange = data['netChange'] as BigInt;

    return (netChange * BigInt.from(100) / startSupply).toDouble();
  }

  // Get time period duration in readable format
  String getPeriodDuration() {
    switch (_selectedPeriod) {
      case 'day':
        return 'Last 24 hours';
      case 'week':
        return 'Last 7 days';
      case 'month':
        return 'Last 30 days';
      default:
        return 'Last 24 hours';
    }
  }
}
