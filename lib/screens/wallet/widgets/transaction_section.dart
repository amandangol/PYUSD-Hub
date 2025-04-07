import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../transactions/provider/transaction_provider.dart';
import '../../transactions/view/all_transactions/all_transaction_screen.dart';
import '../provider/walletscreen_provider.dart';
import 'transaction_item.dart';
import 'shimmer/transaction_shimmer_item.dart';
import '../../transactions/model/transaction_model.dart';

class TransactionSection extends StatelessWidget {
  final bool isDarkMode;
  final String currentAddress;

  const TransactionSection({
    super.key,
    required this.isDarkMode,
    required this.currentAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, WaletScreenProvider>(
      builder: (context, transactionProvider, walletScreenProvider, child) {
        final transactions = transactionProvider.transactions;
        final isFetching = transactionProvider.isFetchingTransactions;
        final currentFilter = walletScreenProvider.currentFilter;

        final filteredTransactions =
            walletScreenProvider.getFilteredAndSortedTransactions(transactions);

        final pendingTransactions = filteredTransactions
            .where((tx) => tx.status == TransactionStatus.pending)
            .toList();
        final nonPendingTransactions = filteredTransactions
            .where((tx) => tx.status != TransactionStatus.pending)
            .take(4)
            .toList();

        final recentTransactions = [
          ...pendingTransactions,
          ...nonPendingTransactions
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  _buildFilterDropdown(context, walletScreenProvider),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (isFetching && transactions.isEmpty)
              _buildLoadingState(isDarkMode)
            else if (recentTransactions.isEmpty)
              _buildEmptyState(isDarkMode, currentFilter)
            else
              Column(
                children: [
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: recentTransactions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final transaction = recentTransactions[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TransactionItem(
                          transaction: transaction,
                          currentAddress: currentAddress,
                          isDarkMode: isDarkMode,
                          cardColor: isDarkMode
                              ? const Color(0xFF252543)
                              : Colors.white,
                        ),
                      );
                    },
                  ),
                  if (filteredTransactions.length > 4)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllTransactionsScreen(
                                  transactions: transactions,
                                  currentAddress: currentAddress,
                                  isDarkMode: isDarkMode,
                                  primaryColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          label: Text(
                            'View All Transactions',
                            style: TextStyle(
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilterDropdown(
      BuildContext context, WaletScreenProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white10 : Colors.black12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: provider.currentFilter,
        icon: Icon(
          Icons.filter_list_rounded,
          size: 16,
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
        underline: const SizedBox(),
        isDense: true,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: 12,
        ),
        dropdownColor: isDarkMode ? const Color(0xFF252543) : Colors.white,
        items: WaletScreenProvider.filterOptions.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            provider.setTransactionFilter(newValue);
          }
        },
      ),
    );
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: List.generate(
          4,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TransactionShimmerItem(
              isDarkMode: isDarkMode,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode, String currentFilter) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF252543) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black12 : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 48,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
          const SizedBox(height: 16),
          Text(
            _getEmptyStateMessage(currentFilter),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  String _getEmptyStateMessage(String filter) {
    switch (filter) {
      case 'PYUSD':
        return 'No PYUSD transactions yet';
      case 'ETH':
        return 'No ETH transactions yet';
      default:
        return 'No transactions yet';
    }
  }
}
