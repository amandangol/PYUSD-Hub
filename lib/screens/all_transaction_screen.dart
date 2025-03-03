import 'package:flutter/material.dart';
import '../models/transaction.dart';
import 'homescreen/widgets/transaction_list_item.dart';

class AllTransactionsScreen extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String currentAddress;
  final bool isDarkMode;
  final Color primaryColor;

  const AllTransactionsScreen({
    super.key,
    required this.transactions,
    required this.currentAddress,
    required this.isDarkMode,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? const Color(0xFF252543) : Colors.white;
    final backgroundColor = isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'All Transactions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 80,
                    color: isDarkMode ? Colors.white38 : Colors.black26,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No transactions yet',
                    style: TextStyle(
                      fontSize: 20,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return TransactionListItem(
                  transaction: tx,
                  currentAddress: currentAddress,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                );
              },
            ),
    );
  }
}
