import 'package:flutter/material.dart';
import '../../transactions/view/all_transactions/all_transaction_screen.dart';
import '../../transactions/model/transaction_model.dart';
import '../provider/walletscreen_provider.dart';
import 'shimmer/transaction_shimmer_item.dart';
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
  String _filter = 'All';
  List<TransactionModel> _filteredTransactions = [];
  WaletScreenProvider? _homeProvider;

  @override
  void initState() {
    super.initState();
    // Defer the first update to after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _homeProvider = context.read<WaletScreenProvider>();
        _updateFilteredTransactions();
      }
    });
  }

  @override
  void didUpdateWidget(TransactionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transactions != oldWidget.transactions) {
      print('Transactions updated in TransactionSection');
      _updateFilteredTransactions();
    }
  }

  void _updateFilteredTransactions() {
    if (!mounted) return;

    final homeProvider = _homeProvider ?? context.read<WaletScreenProvider>();
    final filtered =
        homeProvider.getFilteredAndSortedTransactions(widget.transactions);

    if (mounted) {
      setState(() {
        _filteredTransactions = filtered;
        print('Filtered transactions updated: ${_filteredTransactions.length}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use select to minimize rebuilds
    final currentFilter = context.select<WaletScreenProvider, String>(
      (provider) => provider.currentFilter,
    );

    final cardColor =
        widget.isDarkMode ? const Color(0xFF252543) : Colors.grey.shade50;

    // Update filter if changed
    if (currentFilter != _filter) {
      _filter = currentFilter;
      _updateFilteredTransactions();
    }

    final displayTransactions = _filteredTransactions.take(3).toList();
    print(
        'Building TransactionSection with ${displayTransactions.length} transactions');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        if (widget.isLoading)
          _buildLoadingState()
        else if (displayTransactions.isEmpty)
          _buildEmptyState(currentFilter)
        else
          Column(
            children: [
              ...displayTransactions.map((tx) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: TransactionItem(
                      transaction: tx,
                      currentAddress: widget.currentAddress,
                      isDarkMode: widget.isDarkMode,
                      cardColor: cardColor,
                    ),
                  )),
              if (_filteredTransactions.length > 3)
                _buildViewAllButton(
                    filteredTransactions: _filteredTransactions),
            ],
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final homeProvider = context.watch<WaletScreenProvider>();

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

  // Optimize loading state with shimmer effect
  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        3,
        (index) => TransactionShimmerItem(
          isDarkMode: widget.isDarkMode,
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

  // Update the view all button to take filtered transactions as parameter
  Widget _buildViewAllButton({
    required List<TransactionModel> filteredTransactions,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: InkWell(
        onTap: () {
          if (mounted) {
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
          }
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
