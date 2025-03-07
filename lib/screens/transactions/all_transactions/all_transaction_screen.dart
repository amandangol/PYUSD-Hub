import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/transaction.dart';
import '../../../providers/transactiondetail_provider.dart';
import '../../../providers/network_provider.dart';
import '../../homescreen/widgets/transaction_list_item.dart';

class AllTransactionsScreen extends StatefulWidget {
  final List<TransactionModel> transactions;
  final String currentAddress;
  final bool isDarkMode;
  final Color primaryColor;

  const AllTransactionsScreen({
    Key? key,
    required this.transactions,
    required this.currentAddress,
    required this.isDarkMode,
    required this.primaryColor,
  }) : super(key: key);

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  String _filter = 'All'; // 'All', 'PYUSD', 'ETH'
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final cardColor =
        widget.isDarkMode ? const Color(0xFF252543) : Colors.white;
    final backgroundColor =
        widget.isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;

    // Filter transactions based on selected filter
    final filteredTransactions = _getFilteredTransactions();

    // Ensure we have the providers available
    final transactionDetailProvider =
        Provider.of<TransactionDetailProvider>(context, listen: false);
    Provider.of<NetworkProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'All Transactions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: widget.isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Filter dropdown in the app bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButton<String>(
              value: _filter,
              icon: const Icon(Icons.filter_list, size: 16),
              underline: const SizedBox(),
              isDense: true,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
              dropdownColor:
                  widget.isDarkMode ? Colors.grey.shade800 : Colors.white,
              items: <String>['All', 'PYUSD', 'ETH']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _filter = newValue;
                  });
                }
              },
            ),
          ),

          // Refresh button
          IconButton(
            icon: _isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isDarkMode
                              ? Colors.white
                              : const Color(0xFF1A1A2E)),
                    ),
                  )
                : Icon(
                    Icons.refresh,
                    color: widget.isDarkMode
                        ? Colors.white
                        : const Color(0xFF1A1A2E),
                  ),
            onPressed: _isRefreshing
                ? null
                : () async {
                    setState(() {
                      _isRefreshing = true;
                    });

                    // Clear transaction details cache
                    transactionDetailProvider.clearCache();

                    // Wait a moment for visual feedback
                    await Future.delayed(const Duration(milliseconds: 1000));

                    if (mounted) {
                      setState(() {
                        _isRefreshing = false;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transaction cache refreshed'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _isRefreshing = true;
          });

          // Clear transaction details cache
          transactionDetailProvider.clearCache();

          // Wait a moment for visual feedback
          await Future.delayed(const Duration(milliseconds: 1000));

          if (mounted) {
            setState(() {
              _isRefreshing = false;
            });
          }
        },
        child: filteredTransactions.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredTransactions.length,
                itemBuilder: (context, index) {
                  final tx = filteredTransactions[index];
                  return TransactionItem(
                    transaction: tx,
                    currentAddress: widget.currentAddress,
                    isDarkMode: widget.isDarkMode,
                    cardColor: cardColor,
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 80,
                color: widget.isDarkMode ? Colors.white38 : Colors.black26,
              ),
              const SizedBox(height: 24),
              Text(
                _getEmptyStateMessage(),
                style: TextStyle(
                  fontSize: 20,
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pull down to refresh',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isDarkMode ? Colors.white30 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to filter transactions based on selected filter
  List<TransactionModel> _getFilteredTransactions() {
    if (_filter == 'All') {
      return widget.transactions;
    } else if (_filter == 'PYUSD') {
      return widget.transactions
          .where((tx) => tx.tokenSymbol == 'PYUSD')
          .toList();
    } else {
      // ETH
      return widget.transactions
          .where((tx) => tx.tokenSymbol == null || tx.tokenSymbol == 'ETH')
          .toList();
    }
  }

  // Helper method to get appropriate empty state message
  String _getEmptyStateMessage() {
    if (_filter == 'All') {
      return 'No transactions yet';
    } else if (_filter == 'PYUSD') {
      return 'No PYUSD transactions yet';
    } else {
      return 'No ETH transactions yet';
    }
  }
}
