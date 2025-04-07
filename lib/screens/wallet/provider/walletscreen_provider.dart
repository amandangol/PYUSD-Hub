import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../providers/walletstate_provider.dart';
import '../../transactions/model/transaction_model.dart';
import '../../transactions/provider/transaction_provider.dart';

class WaletScreenProvider with ChangeNotifier {
  // Shared Preferences keys
  static const String _balanceVisibilityKey = 'balance_visibility';
  static const String _transactionFilterKey = 'transaction_filter';
  static const String _networkSelectorKey = 'network_selector_visible';

  // Balance visibility state
  bool _isBalanceVisible = true;
  bool get isBalanceVisible => _isBalanceVisible;

  // Transaction filter state
  String _currentFilter = 'All';
  static const List<String> filterOptions = ['All', 'PYUSD', 'ETH'];
  String get currentFilter => _currentFilter;
  List<String> get availableFilters => filterOptions;

  // Network selector visibility state
  bool _isNetworkSelectorVisible = false;
  bool get isNetworkSelectorVisible => _isNetworkSelectorVisible;

  // Loading states
  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  // Shared Preferences instance
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Providers
  TransactionProvider? _transactionProvider;
  WalletStateProvider? _walletStateProvider;

  // Constructor
  WaletScreenProvider() {
    _loadSavedStates();
  }

  // Initialize the provider
  Future<void> initialize({
    required TransactionProvider transactionProvider,
    required WalletStateProvider walletStateProvider,
  }) async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _transactionProvider = transactionProvider;
      _walletStateProvider = walletStateProvider;
      await _loadSavedStates();
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Load saved states
  Future<void> _loadSavedStates() async {
    if (_prefs != null) {
      _isBalanceVisible = _prefs!.getBool(_balanceVisibilityKey) ?? true;
      _currentFilter = _prefs!.getString(_transactionFilterKey) ?? 'All';
      _isNetworkSelectorVisible = _prefs!.getBool(_networkSelectorKey) ?? false;
    }
    notifyListeners();
  }

  // Balance visibility methods
  Future<void> toggleBalanceVisibility() async {
    _isBalanceVisible = !_isBalanceVisible;
    await _prefs?.setBool(_balanceVisibilityKey, _isBalanceVisible);
    notifyListeners();
  }

  // Refresh all data
  Future<void> refreshAllData() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      // Refresh transactions and balances in parallel
      await Future.wait([
        _transactionProvider?.fetchTransactions(forceRefresh: true) ??
            Future.value(),
        _walletStateProvider?.refreshBalances() ?? Future.value(),
      ]);

      // Add a small delay to ensure smooth UI update
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      print('Error refreshing data: $e');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // Transaction filter methods
  Future<void> setTransactionFilter(String filter) async {
    if (filterOptions.contains(filter) && _currentFilter != filter) {
      _currentFilter = filter;
      await _prefs?.setString(_transactionFilterKey, filter);
      notifyListeners();
    }
  }

  // Enhanced filtering method that can be reused across components
  List<TransactionModel> getFilteredAndSortedTransactions(
    List<TransactionModel> transactions, {
    String? filterOverride,
  }) {
    final filterToUse = filterOverride ?? _currentFilter;

    // First, filter transactions based on current filter
    final filtered = transactions.where((tx) {
      // Always show pending transactions regardless of filter
      if (tx.status == TransactionStatus.pending) {
        return true;
      }

      // Skip ETH gas fee transactions that are associated with PYUSD transactions
      if (tx.tokenSymbol == 'ETH' && tx.amount == 0) {
        // Check if this is a gas fee transaction for a PYUSD transaction
        final hasPyusdTransaction = transactions.any((otherTx) =>
            otherTx.hash == tx.hash &&
            otherTx.tokenSymbol == 'PYUSD' &&
            otherTx.timestamp == tx.timestamp);
        if (hasPyusdTransaction) {
          return false;
        }
      }

      // Apply filter based on current selection
      switch (filterToUse) {
        case 'PYUSD':
          return tx.tokenSymbol == 'PYUSD';
        case 'ETH':
          return tx.tokenSymbol == 'ETH';
        default:
          return true;
      }
    }).toList();

    // Sort transactions by timestamp in descending order (newest first)
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return filtered;
  }

  // Network selector methods
  Future<void> toggleNetworkSelector() async {
    _isNetworkSelectorVisible = !_isNetworkSelectorVisible;
    await _prefs?.setBool(_networkSelectorKey, _isNetworkSelectorVisible);
    notifyListeners();
  }

  void setNetworkSelectorVisibility(bool isVisible) {
    if (_isNetworkSelectorVisible != isVisible) {
      _isNetworkSelectorVisible = isVisible;
      _prefs?.setBool(_networkSelectorKey, isVisible);
      notifyListeners();
    }
  }

  // Clean up method
  @override
  void dispose() {
    _prefs = null;
    super.dispose();
  }
}
