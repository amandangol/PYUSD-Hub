import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../transactions/view/all_transactions/all_transaction_screen.dart';
import '../../transactions/model/transaction_model.dart';
import '../provider/homescreen_provider.dart';
import 'transaction_item.dart';
import '../../../utils/empty_state_utils.dart';
import 'package:provider/provider.dart';

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
  static const _filterOptions = ['All', 'PYUSD', 'ETH'];

  String _filter = _filterOptions[0];
  List<TransactionModel> _filteredTransactions = [];

  // Memoize common styles
  late final _loadingBoxDecoration = BoxDecoration(
    color: widget.isDarkMode ? const Color(0xFF252543) : Colors.grey.shade50,
    borderRadius: BorderRadius.circular(12),
  );

  @override
  void initState() {
    super.initState();
    _updateFilteredTransactions();
  }

  @override
  void didUpdateWidget(TransactionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transactions != oldWidget.transactions) {
      _updateFilteredTransactions();
    }
  }

  void _updateFilteredTransactions() {
    if (!mounted) return;

    final homeProvider = context.read<HomeScreenProvider>();
    final currentFilter = homeProvider.currentFilter;

    final filtered = widget.transactions.where((tx) {
      switch (currentFilter) {
        case 'PYUSD':
          return tx.tokenSymbol == 'PYUSD';
        case 'ETH':
          return tx.tokenSymbol == null || tx.tokenSymbol == 'ETH';
        default:
          return true; // 'All' case
      }
    }).toList();

    // Sort transactions
    filtered.sort((a, b) {
      final aPending = a.status == TransactionStatus.pending ? 1 : 0;
      final bPending = b.status == TransactionStatus.pending ? 1 : 0;
      final pendingCompare = bPending - aPending;
      return pendingCompare != 0
          ? pendingCompare
          : b.timestamp.compareTo(a.timestamp);
    });

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeScreenProvider>();
    final cardColor =
        widget.isDarkMode ? const Color(0xFF252543) : Colors.grey.shade50;

    // Listen to filter changes and update transactions
    if (homeProvider.currentFilter != _filter) {
      _filter = homeProvider.currentFilter;
      _updateFilteredTransactions();
    }

    final displayTransactions = _filteredTransactions.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        if (widget.isLoading)
          _buildLoadingState()
        else if (displayTransactions.isEmpty)
          _buildEmptyState(homeProvider.currentFilter)
        else
          Column(
            children: [
              ...displayTransactions.map((tx) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TransactionItem(
                      transaction: tx,
                      currentAddress: widget.currentAddress,
                      isDarkMode: widget.isDarkMode,
                      cardColor: cardColor,
                    ),
                  )),
              if (_filteredTransactions.length > 3) _buildViewAllButton(),
            ],
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final homeProvider = context.watch<HomeScreenProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Transactions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: widget.isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),

        // Improved Dropdown with proper theming
        DropdownButton<String>(
          value: homeProvider.currentFilter,
          icon: Icon(
            Icons.filter_list_rounded,
            size: 20,
            color: widget.isDarkMode ? Colors.white70 : Colors.black87,
          ),
          underline: const SizedBox(), // Remove default underline
          dropdownColor:
              widget.isDarkMode ? Colors.grey.shade800 : Colors.white,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          items: homeProvider.availableFilters.map((String filter) {
            return DropdownMenuItem<String>(
              value: filter,
              child: Text(
                filter,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newFilter) async {
            if (newFilter != null) {
              await homeProvider.setTransactionFilter(newFilter);
              _updateFilteredTransactions();
            }
          },
          // Customize the dropdown button's appearance
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
      ],
    );
  }

  // Optimize loading state with const widgets where possible
  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Container(
            height: 72,
            padding: const EdgeInsets.all(16),
            decoration: _loadingBoxDecoration,
            child: const LoadingItemContent(),
          ),
        ),
      ),
    );
  }

  // Helper method to build empty state widget
  Widget _buildEmptyState(String currentFilter) {
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
              EmptyStateUtils.getTransactionEmptyStateMessage(currentFilter),
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
}

// Extract loading item content to a separate const widget
class LoadingItemContent extends StatelessWidget {
  const LoadingItemContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final loadingColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: loadingColor,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(
                  color: loadingColor,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 12,
                decoration: BoxDecoration(
                  color: loadingColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 60,
          height: 14,
          decoration: BoxDecoration(
            color: loadingColor,
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      ],
    );
  }
}
