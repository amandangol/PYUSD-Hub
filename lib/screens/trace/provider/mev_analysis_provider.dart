import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pyusd_hub/config/rpc_endpoints.dart';

class MevAnalysisProvider with ChangeNotifier {
  // RPC endpoints
  final String _httpRpcUrl = RpcEndpoints.mainnetHttpRpcUrl;

  // PYUSD Contract address on Ethereum mainnet
  final String _pyusdContractAddress =
      '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // MEV Analysis Data
  Map<String, dynamic> _mevAnalysis = {};
  Map<String, dynamic> get mevAnalysis => _mevAnalysis;

  // MEV Event History
  List<Map<String, dynamic>> _mevEvents = [];
  List<Map<String, dynamic>> get mevEvents => _mevEvents;

  // Last used values
  String? _lastMevBlockHash;
  String? _lastMevStartBlock;
  String? _lastMevEndBlock;
  String? _lastMevTxHash;
  String? _lastMevAnalysisType;

  String? get lastMevBlockHash => _lastMevBlockHash;
  String? get lastMevStartBlock => _lastMevStartBlock;
  String? get lastMevEndBlock => _lastMevEndBlock;
  String? get lastMevTxHash => _lastMevTxHash;
  String? get lastMevAnalysisType => _lastMevAnalysisType;

  MevAnalysisProvider() {
    _loadMevHistory();
  }

  Future<void> _loadMevHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _lastMevBlockHash = prefs.getString('last_mev_block_hash');
      _lastMevStartBlock = prefs.getString('last_mev_start_block');
      _lastMevEndBlock = prefs.getString('last_mev_end_block');
      _lastMevTxHash = prefs.getString('last_mev_tx_hash');
      _lastMevAnalysisType = prefs.getString('last_mev_analysis_type');

      final eventsJson = prefs.getString('mev_events');
      if (eventsJson != null) {
        final List<dynamic> decoded = jsonDecode(eventsJson);
        _mevEvents = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      notifyListeners();
    } catch (e) {
      print('Error loading MEV history: $e');
    }
  }

  Future<void> _saveMevHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('last_mev_block_hash', _lastMevBlockHash ?? '');
      await prefs.setString('last_mev_start_block', _lastMevStartBlock ?? '');
      await prefs.setString('last_mev_end_block', _lastMevEndBlock ?? '');
      await prefs.setString('last_mev_tx_hash', _lastMevTxHash ?? '');
      await prefs.setString(
          'last_mev_analysis_type', _lastMevAnalysisType ?? '');

      // Save MEV events (limit to 50)
      if (_mevEvents.length > 50) {
        _mevEvents = _mevEvents.sublist(_mevEvents.length - 50);
      }
      await prefs.setString('mev_events', jsonEncode(_mevEvents));
    } catch (e) {
      print('Error saving MEV history: $e');
    }
  }

  void updateLastMevBlockHash(String value) {
    _lastMevBlockHash = value;
    _saveMevHistory();
    notifyListeners();
  }

  void updateLastMevStartBlock(String value) {
    _lastMevStartBlock = value;
    _saveMevHistory();
    notifyListeners();
  }

  void updateLastMevEndBlock(String value) {
    _lastMevEndBlock = value;
    _saveMevHistory();
    notifyListeners();
  }

  void updateLastMevTxHash(String value) {
    _lastMevTxHash = value;
    _saveMevHistory();
    notifyListeners();
  }

  void updateLastMevAnalysisType(String value) {
    _lastMevAnalysisType = value;
    _saveMevHistory();
    notifyListeners();
  }

  Future<dynamic> _makeRpcCall(String method, List<dynamic> params) async {
    try {
      final response = await http.post(
        Uri.parse(_httpRpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'jsonrpc': '2.0',
          'id': DateTime.now().millisecondsSinceEpoch,
          'method': method,
          'params': params
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('error')) {
          print('RPC error: ${data['error']}');
          return null;
        }
        return data['result'];
      }
      return null;
    } catch (e) {
      print('RPC call error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> analyzeSandwichAttacks(String blockHash) async {
    try {
      _isLoading = true;
      notifyListeners();

      final blockData =
          await _makeRpcCall('eth_getBlockByHash', [blockHash, true]);
      if (blockData == null) {
        return {'success': false, 'error': 'Block not found'};
      }

      final transactions = blockData['transactions'] as List;
      final sandwichAttacks = <Map<String, dynamic>>[];

      for (int i = 0; i < transactions.length - 2; i++) {
        final frontrun = transactions[i];
        final victim = transactions[i + 1];
        final backrun = transactions[i + 2];

        if (await _isSandwichAttack(frontrun, victim, backrun)) {
          final profit = await _calculateMEVProfit(frontrun, victim, backrun);
          sandwichAttacks.add({
            'frontrun': frontrun,
            'victim': victim,
            'backrun': backrun,
            'profit': profit,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }

      // Add to MEV events history
      if (sandwichAttacks.isNotEmpty) {
        _mevEvents.add({
          'type': 'sandwich_attacks',
          'blockHash': blockHash,
          'attacks': sandwichAttacks,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        _saveMevHistory();
      }

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'sandwichAttacks': sandwichAttacks,
        'blockHash': blockHash,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> _isSandwichAttack(
    Map<String, dynamic> frontrun,
    Map<String, dynamic> victim,
    Map<String, dynamic> backrun,
  ) async {
    try {
      // Check if transactions involve PYUSD
      if (!_involvesToken(frontrun, _pyusdContractAddress) ||
          !_involvesToken(victim, _pyusdContractAddress) ||
          !_involvesToken(backrun, _pyusdContractAddress)) {
        return false;
      }

      // Check if transactions are from different addresses
      final frontrunFrom = frontrun['from'].toString().toLowerCase();
      final victimFrom = victim['from'].toString().toLowerCase();
      final backrunFrom = backrun['from'].toString().toLowerCase();

      if (victimFrom == frontrunFrom || victimFrom == backrunFrom) {
        return false;
      }

      // Check if frontrun and backrun are from the same address (MEV bot)
      if (frontrunFrom != backrunFrom) {
        return false;
      }

      // Check gas prices
      final frontrunGasPrice = int.parse(frontrun['gasPrice'].toString());
      final victimGasPrice = int.parse(victim['gasPrice'].toString());
      final backrunGasPrice = int.parse(backrun['gasPrice'].toString());

      return frontrunGasPrice > victimGasPrice &&
          backrunGasPrice > victimGasPrice;
    } catch (e) {
      print('Error checking sandwich attack: $e');
      return false;
    }
  }

  bool _involvesToken(Map<String, dynamic> tx, String tokenAddress) {
    final to = tx['to']?.toString().toLowerCase();
    return to == tokenAddress.toLowerCase();
  }

  Future<double> _calculateMEVProfit(
    Map<String, dynamic> frontrunTx,
    Map<String, dynamic> victimTx,
    Map<String, dynamic> backrunTx,
  ) async {
    try {
      final receipts = await Future.wait([
        _makeRpcCall('eth_getTransactionReceipt', [frontrunTx['hash']]),
        _makeRpcCall('eth_getTransactionReceipt', [backrunTx['hash']]),
      ]);

      double totalProfit = 0;

      // Calculate gas costs
      for (var i = 0; i < receipts.length; i++) {
        final receipt = receipts[i];
        final tx = i == 0 ? frontrunTx : backrunTx;

        if (receipt != null) {
          final gasUsed = int.parse(receipt['gasUsed'].toString());
          final gasPrice = int.parse(tx['gasPrice'].toString());
          final gasCost = (gasUsed * gasPrice) / 1e18; // Convert to ETH
          totalProfit -= gasCost * 2000; // Assuming ETH price of $2000
        }
      }

      // Add estimated profit from token price manipulation
      // This is a simplified calculation - in reality, you'd need to:
      // 1. Calculate the price impact of each transaction
      // 2. Determine the profit from the price differences
      // 3. Account for slippage and fees

      return totalProfit;
    } catch (e) {
      print('Error calculating MEV profit: $e');
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> analyzeFrontrunning(String txHash) async {
    try {
      _isLoading = true;
      notifyListeners();

      final tx = await _makeRpcCall('eth_getTransactionByHash', [txHash]);
      if (tx == null) {
        return {'success': false, 'error': 'Transaction not found'};
      }

      final blockHash = tx['blockHash'];
      final blockData =
          await _makeRpcCall('eth_getBlockByHash', [blockHash, true]);

      final transactions = blockData['transactions'] as List;
      final txIndex = transactions.indexWhere((t) => t['hash'] == txHash);

      if (txIndex <= 0) {
        return {'success': false, 'error': 'No potential frontrunning found'};
      }

      final prevTx = transactions[txIndex - 1];
      if (await _isFrontrunning(prevTx, tx)) {
        final profit = await _calculateFrontrunProfit(prevTx);

        final result = {
          'success': true,
          'frontrun': {
            'transaction': prevTx,
            'profit': profit,
          },
          'victim': {
            'transaction': tx,
          },
          'blockNumber': int.parse(blockData['number'].toString()),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        // Add to MEV events
        _mevEvents.add({
          'type': 'frontrunning',
          'data': result,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        _saveMevHistory();

        _isLoading = false;
        notifyListeners();
        return result;
      }

      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'No frontrunning detected'};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> _isFrontrunning(Map<String, dynamic> potentialFrontrunner,
      Map<String, dynamic> targetTx) async {
    try {
      // Check if both transactions involve PYUSD
      if (!_involvesToken(potentialFrontrunner, _pyusdContractAddress) ||
          !_involvesToken(targetTx, _pyusdContractAddress)) {
        return false;
      }

      // Compare gas prices
      final frontrunGasPrice =
          int.parse(potentialFrontrunner['gasPrice'].toString());
      final targetGasPrice = int.parse(targetTx['gasPrice'].toString());

      // Basic frontrunning detection: higher gas price and similar input data
      if (frontrunGasPrice <= targetGasPrice) {
        return false;
      }

      // Compare input data to see if they're interacting with similar methods
      final frontrunInput = potentialFrontrunner['input'].toString();
      final targetInput = targetTx['input'].toString();

      // Check method signatures (first 4 bytes)
      return frontrunInput.length >= 10 &&
          targetInput.length >= 10 &&
          frontrunInput.substring(0, 10) == targetInput.substring(0, 10);
    } catch (e) {
      print('Error checking frontrunning: $e');
      return false;
    }
  }

  Future<double> _calculateFrontrunProfit(Map<String, dynamic> tx) async {
    try {
      final receipt =
          await _makeRpcCall('eth_getTransactionReceipt', [tx['hash']]);
      if (receipt == null) return 0.0;

      // Calculate gas cost
      final gasUsed = int.parse(receipt['gasUsed'].toString());
      final gasPrice = int.parse(tx['gasPrice'].toString());
      final gasCost = (gasUsed * gasPrice) / 1e18; // Convert to ETH

      // Analyze logs for token transfers
      final logs = receipt['logs'] as List;
      double estimatedProfit = 0.0;

      for (final log in logs) {
        if (log['address'].toString().toLowerCase() ==
            _pyusdContractAddress.toLowerCase()) {
          if (log['topics'][0] ==
              '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef') {
            // This is a Transfer event
            final amount =
                BigInt.parse(log['data'].toString()) / BigInt.from(10).pow(6);
            estimatedProfit += amount.toDouble();
          }
        }
      }

      return estimatedProfit - (gasCost * 2000); // Assuming ETH price of $2000
    } catch (e) {
      print('Error calculating frontrun profit: $e');
      return 0.0;
    }
  }

  void clearMevHistory() {
    _mevEvents.clear();
    _saveMevHistory();
    notifyListeners();
  }

  @override
  void dispose() {
    _saveMevHistory();
    super.dispose();
  }

  Future<Map<String, dynamic>> analyzeTransactionOrdering(
      String blockHash) async {
    try {
      _isLoading = true;
      notifyListeners();

      final blockData =
          await _makeRpcCall('eth_getBlockByHash', [blockHash, true]);
      if (blockData == null) {
        return {'success': false, 'error': 'Block not found'};
      }

      final transactions = blockData['transactions'] as List;
      final orderedTransactions = <Map<String, dynamic>>[];

      // Filter and analyze PYUSD transactions
      for (final tx in transactions) {
        if (_involvesToken(tx, _pyusdContractAddress)) {
          final receipt =
              await _makeRpcCall('eth_getTransactionReceipt', [tx['hash']]);
          if (receipt != null) {
            orderedTransactions.add({
              'hash': tx['hash'],
              'gasPrice': int.parse(tx['gasPrice'].toString()),
              'gasUsed': int.parse(receipt['gasUsed'].toString()),
              'status': receipt['status'],
            });
          }
        }
      }

      // Sort by gas price to identify potential ordering manipulation
      orderedTransactions
          .sort((a, b) => b['gasPrice'].compareTo(a['gasPrice']));

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'transactions': orderedTransactions,
        'blockNumber': int.parse(blockData['number'].toString()),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> analyzeMevOpportunities(String blockHash) async {
    try {
      _isLoading = true;
      notifyListeners();

      final blockData =
          await _makeRpcCall('eth_getBlockByHash', [blockHash, true]);
      if (blockData == null) {
        return {'success': false, 'error': 'Block not found'};
      }

      final transactions = blockData['transactions'] as List;
      final opportunities = <Map<String, dynamic>>[];

      for (final tx in transactions) {
        if (_involvesToken(tx, _pyusdContractAddress)) {
          final receipt =
              await _makeRpcCall('eth_getTransactionReceipt', [tx['hash']]);
          if (receipt != null) {
            final profit = await _calculateMEVOpportunityProfit(tx, receipt);
            if (profit > 0) {
              opportunities.add({
                'hash': tx['hash'],
                'type': 'arbitrage',
                'profit': profit,
                'gasPrice': int.parse(tx['gasPrice'].toString()),
              });
            }
          }
        }
      }

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'opportunities': opportunities,
        'blockNumber': int.parse(blockData['number'].toString()),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> trackHistoricalMEVEvents(
      int startBlock, int endBlock) async {
    try {
      _isLoading = true;
      notifyListeners();

      final events = <Map<String, dynamic>>[];

      for (int blockNumber = startBlock;
          blockNumber <= endBlock;
          blockNumber++) {
        final blockHex = '0x${blockNumber.toRadixString(16)}';
        final blockData =
            await _makeRpcCall('eth_getBlockByNumber', [blockHex, true]);

        if (blockData != null) {
          // Check for sandwich attacks
          final sandwichResult =
              await analyzeSandwichAttacks(blockData['hash']);
          if (sandwichResult['success'] == true) {
            final attacks = sandwichResult['sandwichAttacks'] as List;
            for (final attack in attacks) {
              events.add({
                'type': 'sandwich_attack',
                'blockNumber': blockNumber,
                'data': attack,
              });
            }
          }

          // Check for MEV opportunities
          final mevResult = await analyzeMevOpportunities(blockData['hash']);
          if (mevResult['success'] == true) {
            final opportunities = mevResult['opportunities'] as List;
            for (final opportunity in opportunities) {
              events.add({
                'type': 'mev_opportunity',
                'blockNumber': blockNumber,
                'data': opportunity,
              });
            }
          }
        }
      }

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'events': events,
        'startBlock': startBlock,
        'endBlock': endBlock,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<double> _calculateMEVOpportunityProfit(
      Map<String, dynamic> tx, Map<String, dynamic> receipt) async {
    try {
      // Calculate gas cost
      final gasUsed = int.parse(receipt['gasUsed'].toString());
      final gasPrice = int.parse(tx['gasPrice'].toString());
      final gasCost = (gasUsed * gasPrice) / 1e18; // Convert to ETH

      // Analyze logs for token transfers and price impact
      final logs = receipt['logs'] as List;
      double estimatedProfit = 0.0;

      for (final log in logs) {
        if (log['address'].toString().toLowerCase() ==
            _pyusdContractAddress.toLowerCase()) {
          if (log['topics'][0] ==
              '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef') {
            // This is a Transfer event
            final amount =
                BigInt.parse(log['data'].toString()) / BigInt.from(10).pow(6);
            estimatedProfit += amount.toDouble();
          }
        }
      }

      // Subtract gas costs (assuming ETH price of $2000)
      return estimatedProfit - (gasCost * 2000);
    } catch (e) {
      print('Error calculating MEV opportunity profit: $e');
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> analyzeMEVImpact(String txHash) async {
    try {
      _isLoading = true;
      notifyListeners();

      final tx = await _makeRpcCall('eth_getTransactionByHash', [txHash]);
      if (tx == null) {
        return {
          'summary': 'Transaction not found',
          'details': [],
          'impact': 0.0,
        };
      }

      final receipt = await _makeRpcCall('eth_getTransactionReceipt', [txHash]);
      if (receipt == null) {
        return {
          'summary': 'Transaction receipt not found',
          'details': [],
          'impact': 0.0,
        };
      }

      final blockNumber = int.parse(tx['blockNumber'].toString());
      final block = await _makeRpcCall(
          'eth_getBlockByNumber', ['0x${blockNumber.toRadixString(16)}', true]);

      final transactions = block['transactions'] as List;
      final txIndex = transactions.indexWhere((t) => t['hash'] == txHash);

      final details = <String>[];
      double totalImpact = 0.0;
      String riskLevel = 'Low';

      // Analyze gas prices
      final currentGasPrice = int.parse(tx['gasPrice'].toString()) / 1e9;
      final gasUsed = int.parse(receipt['gasUsed'].toString());

      details.add('Gas used: $gasUsed');
      details.add('Gas price: ${currentGasPrice.toStringAsFixed(2)} Gwei');

      // Compare with surrounding transactions
      if (txIndex > 0) {
        final prevTx = transactions[txIndex - 1];
        final prevGasPrice = int.parse(prevTx['gasPrice'].toString()) / 1e9;
        details.add(
            'Previous tx gas price: ${prevGasPrice.toStringAsFixed(2)} Gwei');

        // Check for potential frontrunning
        if (prevGasPrice > currentGasPrice &&
            await _isFrontrunning(prevTx, tx)) {
          details.add('⚠️ Potential frontrunning detected');
          totalImpact += (prevGasPrice - currentGasPrice) *
              gasUsed /
              1e9 *
              2000; // Assuming ETH price of $2000
          riskLevel = 'High';
        }
      }

      if (txIndex < transactions.length - 1) {
        final nextTx = transactions[txIndex + 1];
        final nextGasPrice = int.parse(nextTx['gasPrice'].toString()) / 1e9;
        details
            .add('Next tx gas price: ${nextGasPrice.toStringAsFixed(2)} Gwei');

        // Check for potential sandwich attack
        if (txIndex > 0) {
          final prevTx = transactions[txIndex - 1];
          if (await _isSandwichAttack(prevTx, tx, nextTx)) {
            details.add('⚠️ Potential sandwich attack detected');
            totalImpact += await _calculateMEVProfit(prevTx, tx, nextTx);
            riskLevel = 'High';
          }
        }
      }

      // Calculate average block gas price
      final avgBlockGasPrice = transactions.fold(
              0.0, (sum, t) => sum + int.parse(t['gasPrice'].toString())) /
          (transactions.length * 1e9);

      final gasPricePremium = currentGasPrice - avgBlockGasPrice;
      if (gasPricePremium > 0) {
        totalImpact += (gasPricePremium * gasUsed / 1e9) *
            2000; // Assuming ETH price of $2000
        if (gasPricePremium > avgBlockGasPrice * 0.5) {
          details.add('⚠️ Significant gas price premium paid');
          riskLevel = riskLevel == 'Low' ? 'Medium' : riskLevel;
        }
      }

      details.add(
          'Block average gas price: ${avgBlockGasPrice.toStringAsFixed(2)} Gwei');
      details
          .add('Gas price premium: ${gasPricePremium.toStringAsFixed(2)} Gwei');

      // Check for contract interactions
      if (receipt['logs']?.isNotEmpty == true) {
        final uniqueContracts = (receipt['logs'] as List)
            .map((log) => log['address'].toString().toLowerCase())
            .toSet();
        if (uniqueContracts.length > 2) {
          details.add(
              '⚠️ Multiple contract interactions detected (${uniqueContracts.length} contracts)');
          riskLevel = riskLevel == 'Low' ? 'Medium' : riskLevel;
        }
      }

      // Add MEV event if significant impact detected
      if (totalImpact > 0) {
        _mevEvents.add({
          'type': 'mev_impact',
          'txHash': txHash,
          'impact': totalImpact,
          'riskLevel': riskLevel,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        _saveMevHistory();
      }

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'summary': _getMEVImpactSummary(totalImpact, riskLevel),
        'details': details,
        'impact': totalImpact,
        'riskLevel': riskLevel,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'summary': 'Error analyzing MEV impact',
        'details': [e.toString()],
        'impact': 0.0,
        'riskLevel': 'Unknown',
      };
    }
  }

  String _getMEVImpactSummary(double impact, String riskLevel) {
    if (impact <= 0) {
      return 'No significant MEV impact detected in this transaction.';
    }

    switch (riskLevel.toLowerCase()) {
      case 'high':
        return 'High MEV impact detected. This transaction was significantly affected by MEV activities.';
      case 'medium':
        return 'Moderate MEV impact detected. This transaction shows some exposure to MEV activities.';
      case 'low':
        return 'Low MEV impact detected. This transaction was minimally affected by MEV activities.';
      default:
        return 'Transaction analyzed for MEV impact.';
    }
  }
}
