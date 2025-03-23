import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pyusd_data_provider.dart';
import 'network_congestion/provider/network_congestion_provider.dart';
import 'dart:math';

class NetworkActivityScreen extends StatefulWidget {
  const NetworkActivityScreen({super.key});

  @override
  State<NetworkActivityScreen> createState() => _NetworkActivityScreenState();
}

class _NetworkActivityScreenState extends State<NetworkActivityScreen> {
  final PyusdDashboardProvider _pyusdProvider = PyusdDashboardProvider();
  final Random _random = Random();
  String _currentLevel = "Loading...";
  String _statusMessage = "Initializing...";
  List<TransactionEvent> _transactionHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRealTransactionData();
  }

  Future<void> _loadRealTransactionData() async {
    try {
      setState(() => _isLoading = true);

      // Get the NetworkCongestionProvider instance
      final networkProvider =
          Provider.of<NetworkCongestionProvider>(context, listen: false);

      // Fetch PYUSD transaction activity
      await networkProvider.refresh();

      // Get the recent transactions
      final recentTransactions = networkProvider.recentPyusdTransactions;

      setState(() {
        _transactionHistory = recentTransactions
            .map((tx) => TransactionEvent(
                  type: 'PYUSD',
                  timestamp: DateTime.fromMillisecondsSinceEpoch(
                    int.parse(tx['timestamp'] ?? '0') * 1000,
                  ),
                  destination: tx['to']?.toString().toLowerCase() ==
                          PyusdDashboardProvider.pyusdContractAddress
                              .toLowerCase()
                      ? 'Mint'
                      : 'Burn',
                  amount: _pyusdProvider
                      .formatAmount(BigInt.parse(tx['value'] ?? '0')),
                  confirmationTime: '1',
                  position: Offset(
                    _random.nextDouble() * 800,
                    200 + _random.nextDouble() * 300,
                  ),
                ))
            .toList();

        // Update network status based on real data
        _updateNetworkStatus(_pyusdProvider.pyusdNetFlowRate);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading PYUSD transaction data: $e');
      setState(() {
        _currentLevel = "Error";
        _statusMessage = "Failed to load data";
        _isLoading = false;
      });
    }
  }

  void _updateNetworkStatus(double netFlowRate) {
    if (netFlowRate > 1000) {
      _currentLevel = "High Activity";
      _statusMessage = "Strong PYUSD growth";
    } else if (netFlowRate > 0) {
      _currentLevel = "Moderate Activity";
      _statusMessage = "Normal PYUSD activity";
    } else if (netFlowRate > -1000) {
      _currentLevel = "Low Activity";
      _statusMessage = "Reduced PYUSD activity";
    } else {
      _currentLevel = "Negative Growth";
      _statusMessage = "PYUSD supply decreasing";
    }
  }

  Widget _buildNetworkStatusWidget() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor =
        isDarkMode ? const Color(0xFFB3B3B3) : const Color(0xFF757575);

    // Get the NetworkCongestionProvider instance
    final networkProvider = Provider.of<NetworkCongestionProvider>(context);
    final congestionData = networkProvider.congestionData;

    // Determine color based on PYUSD activity
    Color statusColor;
    if (congestionData.confirmedPyusdTxCount > 100) {
      statusColor = Colors.green;
    } else if (congestionData.confirmedPyusdTxCount > 50) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Container(
      width: 220,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black26 : Colors.black12,
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.currency_exchange,
                  size: 16,
                  color: statusColor,
                ),
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PYUSD Network Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  Text(
                    _currentLevel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value:
                  (congestionData.confirmedPyusdTxCount / 200).clamp(0.0, 1.0),
              backgroundColor:
                  isDarkMode ? Colors.grey[700] : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${congestionData.confirmedPyusdTxCount} Txs/hr',
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              ),
              Text(
                '${_pyusdProvider.formatPyusdSupply()} Total',
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_transactionHistory.isEmpty) {
      return Center(
        child: Text(
          'No transactions found',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _transactionHistory.length,
      itemBuilder: (context, index) {
        final tx = _transactionHistory[index];
        return ListTile(
          leading: Icon(
            tx.destination == 'Mint' ? Icons.add_circle : Icons.remove_circle,
            color: tx.destination == 'Mint' ? Colors.green : Colors.red,
          ),
          title: Text(
            '${tx.destination} ${tx.amount} PYUSD',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${tx.timestamp.hour.toString().padLeft(2, '0')}:${tx.timestamp.minute.toString().padLeft(2, '0')}:${tx.timestamp.second.toString().padLeft(2, '0')}',
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PYUSD Network Activity'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRealTransactionData,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildNetworkStatusWidget(),
          ),
          Expanded(
            child: _buildTransactionList(),
          ),
        ],
      ),
    );
  }
}

class TransactionEvent {
  final String type;
  final DateTime timestamp;
  final String destination;
  final String amount;
  final String confirmationTime;
  final Offset position;

  TransactionEvent({
    required this.type,
    required this.timestamp,
    required this.destination,
    required this.amount,
    required this.confirmationTime,
    required this.position,
  });
}
