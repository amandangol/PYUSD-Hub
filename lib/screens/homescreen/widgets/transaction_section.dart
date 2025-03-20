import 'package:flutter/material.dart';
import '../../transactions/view/all_transactions/all_transaction_screen.dart';
import '../../transactions/model/transaction_model.dart';
import 'transaction_item.dart';

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
    _filteredTransactions = _getFilteredTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode
        ? const Color(0xFF222447)
        : theme.colorScheme.primary.withOpacity(0.05);

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
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            // Filter dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
              Icons.history,
              size: 48,
              color: widget.isDarkMode ? Colors.white30 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateMessage(),
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white60 : Colors.black45,
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
  // Helper method to filter transactions based on selected filter
  List<TransactionModel> _getFilteredTransactions() {
    final allTransactions = widget.transactions;

    if (_filter == 'All') {
      return allTransactions;
    } else if (_filter == 'PYUSD') {
      return allTransactions.where((tx) => tx.tokenSymbol == 'PYUSD').toList();
    } else {
      // ETH
      return allTransactions.where((tx) => tx.tokenSymbol == 'ETH').toList();
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
