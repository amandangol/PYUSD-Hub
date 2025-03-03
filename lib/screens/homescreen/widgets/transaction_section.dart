import 'package:flutter/material.dart';
import '../../../models/transaction.dart';
import '../../all_transaction_screen.dart';
import 'transaction_list_item.dart';

class TransactionsSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? const Color(0xFF252543) : Colors.white;
    // Show only the 3 most recent transactions on home screen
    final displayedTransactions = transactions.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
            ],
          ),
        ),

        // Transactions List or Empty State
        if (transactions.isEmpty)
          _buildEmptyState(isDarkMode)
        else
          _buildTransactionsList(
            displayedTransactions,
            currentAddress,
            isDarkMode,
            cardColor,
          ),

        // "View All" button only shown for mobile UI when there are more than 3 transactions
        if (transactions.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllTransactionsScreen(
                      transactions: transactions,
                      currentAddress: currentAddress,
                      isDarkMode: isDarkMode,
                      primaryColor: primaryColor,
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: primaryColor),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'View All Transactions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        // For 1-3 transactions, add a decorative element to improve blank space
        if (transactions.length <= 3)
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.swap_vert_circle_outlined,
                    size: 48,
                    color: isDarkMode
                        ? primaryColor.withOpacity(0.3)
                        : primaryColor.withOpacity(0.2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    transactions.length == 1
                        ? 'Your transaction history is just beginning!'
                        : 'Make more transactions to build your history',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white60 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF252543).withOpacity(0.5)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 60,
              color: isDarkMode ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your transaction history will appear here',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(
    List<TransactionModel> transactions,
    String currentAddress,
    bool isDarkMode,
    Color cardColor,
  ) {
    return ListView.builder(
      itemCount: transactions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return TransactionListItem(
          transaction: tx,
          currentAddress: currentAddress,
          isDarkMode: isDarkMode,
          cardColor: cardColor,
        );
      },
    );
  }
}
