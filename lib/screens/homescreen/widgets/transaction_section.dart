import 'package:flutter/material.dart';
import '../../../models/transaction.dart';
import '../../all_transaction_screen.dart';
import 'transaction_list_item.dart';

class TransactionsSection extends StatefulWidget {
  final List<TransactionModel> transactions;
  final String currentAddress;
  final bool isLoading;
  final bool isDarkMode;
  final Color primaryColor;

  const TransactionsSection({
    Key? key,
    required this.transactions,
    required this.currentAddress,
    required this.isLoading,
    required this.isDarkMode,
    required this.primaryColor,
  }) : super(key: key);

  @override
  State<TransactionsSection> createState() => _TransactionsSectionState();
}

class _TransactionsSectionState extends State<TransactionsSection> {
  String _filter = 'All'; // 'All', 'PYUSD', 'ETH'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode
        ? const Color(0xFF222447)
        : theme.colorScheme.primary.withOpacity(0.05);

    // Filter transactions based on selected filter
    final filteredTransactions = _getFilteredTransactions();

    // Limit to 4 transactions for the home screen
    final displayTransactions = filteredTransactions.take(3).toList();
    final hasMoreTransactions = filteredTransactions.length > 3;

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
                  if (newValue != null) {
                    setState(() {
                      _filter = newValue;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (displayTransactions.isEmpty)
          Center(
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
                      color:
                          widget.isDarkMode ? Colors.white60 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayTransactions.length,
            itemBuilder: (context, index) {
              final tx = displayTransactions[index];
              return TransactionItem(
                transaction: tx,
                currentAddress: widget.currentAddress,
                isDarkMode: widget.isDarkMode,
                cardColor: cardColor,
              );
            },
          ),

        // View All button - only show if we have transactions and there are more than 4
        if (filteredTransactions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllTransactionsScreen(
                      transactions: filteredTransactions,
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
                          color: widget.isDarkMode
                              ? Colors.white70
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color:
                            widget.isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ],
                  ),
                ),
              ),
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
