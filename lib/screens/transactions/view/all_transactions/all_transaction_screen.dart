import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../utils/snackbar_utils.dart';
import '../../model/transaction_model.dart';
import '../../../../providers/network_provider.dart';
import '../../../wallet/widgets/transaction_item.dart';
import '../../provider/transactiondetail_provider.dart';
import '../../../../utils/empty_state_utils.dart';
import '../../../wallet/provider/walletscreen_provider.dart';

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
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color;
    final backgroundColor = theme.scaffoldBackgroundColor;

    final filteredTransactions = _getFilteredTransactions();

    Provider.of<NetworkProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(theme),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: filteredTransactions.isEmpty
            ? _buildEmptyState(theme)
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
                      cardColor: cardColor!,
                    ),
                  );
                },
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    final textColor = theme.textTheme.titleLarge?.color;
    final dropdownBackgroundColor = widget.isDarkMode
        ? theme.colorScheme.surface.withOpacity(0.5)
        : theme.colorScheme.surface;
    final dropdownBorderColor =
        widget.isDarkMode ? theme.dividerTheme.color : theme.dividerTheme.color;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Text(
            'All Transactions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Custom styled filter dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: dropdownBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: dropdownBorderColor ?? Colors.transparent,
                width: 1,
              ),
            ),
            child: DropdownButton<String>(
              value: _filter,
              icon: Icon(
                Icons.filter_list_rounded,
                size: 20,
                color: textColor,
              ),
              underline: const SizedBox(),
              isDense: true,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: theme.colorScheme.surface,
              items: ['All', 'PYUSD', 'ETH'].map((String value) {
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
          const SizedBox(width: 8),
          // Refresh button
          _buildRefreshButton(theme),
        ],
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: textColor,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildRefreshButton(ThemeData theme) {
    final iconColor = theme.textTheme.titleLarge?.color;

    return IconButton(
      icon: _isRefreshing
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            )
          : Icon(
              Icons.refresh,
              color: iconColor,
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
        Provider.of<WaletScreenProvider>(context, listen: false);
    return homeProvider.getFilteredAndSortedTransactions(
      widget.transactions,
      filterOverride: _filter,
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final primaryIconColor = widget.isDarkMode
        ? theme.colorScheme.onSurface.withOpacity(0.38)
        : theme.colorScheme.onSurface.withOpacity(0.26);
    final primaryTextColor = widget.isDarkMode
        ? theme.colorScheme.onSurface.withOpacity(0.7)
        : theme.colorScheme.onSurface.withOpacity(0.54);
    final secondaryTextColor = widget.isDarkMode
        ? theme.colorScheme.onSurface.withOpacity(0.3)
        : theme.colorScheme.onSurface.withOpacity(0.38);

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
                color: primaryIconColor,
              ),
              const SizedBox(height: 24),
              Text(
                EmptyStateUtils.getTransactionEmptyStateMessage(_filter),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pull down to refresh',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
