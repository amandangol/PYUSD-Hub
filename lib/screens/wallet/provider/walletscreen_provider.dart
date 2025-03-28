import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../transactions/model/transaction_model.dart';

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

  // Constructor
  HomeScreenProvider() {
    _loadSavedStates();
  }

  // Initialize the provider
  Future<void> initialize() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
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

    // Apply filter
    final filtered = transactions.where((tx) {
      switch (filterToUse) {
        case 'PYUSD':
          return tx.tokenSymbol == 'PYUSD';
        case 'ETH':
          return tx.tokenSymbol == null || tx.tokenSymbol == 'ETH';
        default:
          return true; // 'All' case
      }
    }).toList();

    // Sort transactions: Pending first, then by timestamp
    filtered.sort((a, b) {
      final aPending = a.status == TransactionStatus.pending ? 1 : 0;
      final bPending = b.status == TransactionStatus.pending ? 1 : 0;
      final pendingCompare = bPending - aPending;
      return pendingCompare != 0
          ? pendingCompare
          : b.timestamp.compareTo(a.timestamp);
    });

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

  // Refresh state methods
  void setRefreshing(bool refreshing) {
    if (_isRefreshing != refreshing) {
      _isRefreshing = refreshing;
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
