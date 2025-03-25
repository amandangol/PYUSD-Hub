import 'package:flutter/material.dart';
import '../../transactions/view/all_transactions/all_transaction_screen.dart';
import '../../transactions/model/transaction_model.dart';
import 'transaction_item.dart';
import '../../../utils/empty_state_utils.dart';

class TransactionsSection extends StatefulWidget {
  final List<TransactionModel> transactions;
  final String currentAddress;
  final bool isLoading;
  final bool isDarkMode;
  final Color primaryColor;

  const TransactionsSection({
    super.key,
    required this.transactions,
    required this.currentAddress,
    required this.isLoading,
    required this.isDarkMode,
    required this.primaryColor,
  });

  @override
  State<TransactionsSection> createState() => _TransactionsSectionState();
}

class _TransactionsSectionState extends State<TransactionsSection> {
  String _filter = 'All'; // 'All', 'PYUSD', 'ETH'

  // Cached filtered transactions to avoid recalculating every build
  List<TransactionModel> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _updateFilteredTransactions();
  }

  @override
  void didUpdateWidget(TransactionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update filtered transactions when the original transactions list changes
    if (widget.transactions != oldWidget.transactions) {
      _updateFilteredTransactions();
    }
  }

  // Helper method to update filtered transactions
  void _updateFilteredTransactions() {
    // Debug print to see all transactions
    print('All Transactions: ${widget.transactions.length}');
    print('Transactions Details:');
    for (var tx in widget.transactions) {
      // print(
      //     'Hash: ${tx.hash}, Status: ${tx.status}, Symbol: ${tx.tokenSymbol}');
    }

    // First get filtered transactions based on type
    List<TransactionModel> filtered = _getFilteredTransactions();

    // More robust sorting to prioritize pending transactions
    filtered.sort((a, b) {
      // Pending transactions are always first
      if (a.status == TransactionStatus.pending &&
          b.status != TransactionStatus.pending) {
        return -1;
      }
      if (b.status == TransactionStatus.pending &&
          a.status != TransactionStatus.pending) {
        return 1;
      }

      // If both are pending, sort by most recent first
      if (a.status == TransactionStatus.pending &&
          b.status == TransactionStatus.pending) {
        return b.timestamp.compareTo(a.timestamp);
      }

      // For non-pending transactions, sort by timestamp (newest first)
      return b.timestamp.compareTo(a.timestamp);
    });

    // Debug print filtered transactions
    print('Filtered Transactions: ${filtered.length}');
    for (var tx in filtered) {}

    _filteredTransactions = filtered;
  }

  @override
  Widget build(BuildContext context) {
    final cardColor =
        widget.isDarkMode ? const Color(0xFF252543) : Colors.grey.shade50;

    // Limit to 3 transactions for the home screen
    final displayTransactions = _filteredTransactions.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    widget.isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            // Filter dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  if (newValue != null && newValue != _filter) {
                    setState(() {
                      _filter = newValue;
                      _updateFilteredTransactions();
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Show loading state
        if (widget.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        // Show empty state
        else if (displayTransactions.isEmpty)
          _buildEmptyState()
        // Show transactions
        else
          Column(
            children: displayTransactions
                .map((tx) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TransactionItem(
                        transaction: tx,
                        currentAddress: widget.currentAddress,
                        isDarkMode: widget.isDarkMode,
                        cardColor: cardColor,
                      ),
                    ))
                .toList(),
          ),

        // View All button - only show if we have transactions and there are more than 3
        if (_filteredTransactions.isNotEmpty &&
            _filteredTransactions.length > 3)
          _buildViewAllButton(),
      ],
    );
  }

  // Helper method to build empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: widget.isDarkMode ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              EmptyStateUtils.getTransactionEmptyStateMessage(_filter),
              style: TextStyle(
                fontSize: 16,
                color: widget.isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build view all button
  Widget _buildViewAllButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AllTransactionsScreen(
                transactions: _filteredTransactions,
                currentAddress: widget.currentAddress,
                isDarkMode: widget.isDarkMode,
                primaryColor: widget.primaryColor,
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.grey.shade800.withOpacity(0.5)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDarkMode
                  ? Colors.grey.shade700
                  : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All Transactions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ],
            ),
          ),
        ),
      ),
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
}
