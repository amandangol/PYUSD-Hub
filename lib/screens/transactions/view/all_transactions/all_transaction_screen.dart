import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../utils/snackbar_utils.dart';
import '../../model/transaction_model.dart';
import '../../../../providers/network_provider.dart';
import '../../../homescreen/widgets/transaction_item.dart';
import '../../provider/transactiondetail_provider.dart';
import '../../../../utils/empty_state_utils.dart';
import '../../../homescreen/provider/homescreen_provider.dart';

class AllTransactionsScreen extends StatefulWidget {
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
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  String _filter = 'All';
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final cardColor =
        widget.isDarkMode ? const Color(0xFF252543) : Colors.grey.shade50;
    final backgroundColor =
        widget.isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;

    final filteredTransactions = _getFilteredTransactions();

    Provider.of<NetworkProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: filteredTransactions.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredTransactions.length,
                itemBuilder: (context, index) {
                  final tx = filteredTransactions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TransactionItem(
                      transaction: tx,
                      currentAddress: widget.currentAddress,
                      isDarkMode: widget.isDarkMode,
                      cardColor: cardColor,
                    ),
                  );
                },
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Text(
            'All Transactions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const Spacer(),
          // Custom styled filter dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            child: DropdownButton<String>(
              value: _filter,
              icon: Icon(
                Icons.filter_list_rounded,
                size: 20,
                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              ),
              underline: const SizedBox(),
              isDense: true,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor:
                  widget.isDarkMode ? Colors.grey.shade800 : Colors.white,
              items: ['All', 'PYUSD', 'ETH'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
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
          const SizedBox(width: 8),
          // Refresh button
          _buildRefreshButton(),
        ],
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: widget.isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return IconButton(
      icon: _isRefreshing
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            )
          : Icon(
              Icons.refresh,
              color: widget.isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
            ),
      onPressed: _isRefreshing ? null : _handleRefresh,
    );
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    // Clear transaction details cache
    final transactionDetailProvider =
        Provider.of<TransactionDetailProvider>(context, listen: false);
    transactionDetailProvider.clearCache();

    // Wait a moment for visual feedback
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
      SnackbarUtil.showSnackbar(
        context: context,
        message: 'Transaction cache refreshed',
      );
    }
  }

  List<TransactionModel> _getFilteredTransactions() {
    final homeProvider =
        Provider.of<HomeScreenProvider>(context, listen: false);
    return homeProvider.getFilteredAndSortedTransactions(
      widget.transactions,
      filterOverride: _filter,
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
                EmptyStateUtils.getTransactionEmptyStateMessage(_filter),
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
}
