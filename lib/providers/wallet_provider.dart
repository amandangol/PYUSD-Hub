import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../services/blockchain_service.dart';
import '../services/wallet_service.dart';
import 'network_provider.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();
  final BlockchainService _blockchainService = BlockchainService();
  final NetworkProvider _networkProvider;

  WalletModel? _wallet;

  // Replace single balance with a map of balances per network
  Map<NetworkType, double> _balances = {
    NetworkType.holeskyTestnet: 0,
    NetworkType.sepoliaTestnet: 0,
    NetworkType.ethereumMainnet: 0,
  };

  // Replace single transactions list with a map of transactions per network
  Map<NetworkType, List<TransactionModel>> _transactionsByNetwork = {
    NetworkType.holeskyTestnet: [],
    NetworkType.sepoliaTestnet: [],
    NetworkType.ethereumMainnet: [],
  };

  bool _isLoading = false;
  bool _isBalanceRefreshing = false;
  String? _error;

  // Add flags to prevent duplicate calls
  bool _isRefreshingBalance = false;
  bool _isFetchingTransactions = false;

  // Getters
  WalletModel? get wallet => _wallet;

  // Return balance for current network
  double get balance => _balances[_networkProvider.currentNetwork] ?? 0;

  // Return transactions for current network
  List<TransactionModel> get transactions =>
      _transactionsByNetwork[_networkProvider.currentNetwork] ?? [];

  bool get isLoading => _isLoading;
  bool get isBalanceRefreshing => _isBalanceRefreshing;
  String? get error => _error;
  bool get hasWallet => _wallet != null;
  NetworkProvider get networkProvider => _networkProvider;

  WalletProvider(this._networkProvider);

  // Initialize wallet
  Future<void> initWallet() async {
    if (_isLoading) return;
    _setLoading(true);
    try {
      _wallet = await _walletService.loadWallet();
      if (_wallet != null) {
        await refreshBalance();
        await fetchTransactions();
      }
    } catch (e) {
      _setError('Failed to initialize wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new wallet
  Future<void> createWallet() async {
    if (_isLoading) return;
    _setLoading(true);
    try {
      _wallet = await _walletService.createWallet();
      await refreshBalance();
      notifyListeners();
    } catch (e) {
      _setError('Failed to create wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Import wallet from mnemonic
  Future<void> importWalletFromMnemonic(String mnemonic) async {
    if (_isLoading) return;
    _setLoading(true);
    try {
      _wallet = await _walletService.importWalletFromMnemonic(mnemonic);
      await refreshBalance();
      await fetchTransactions();
    } catch (e) {
      _setError('Failed to import wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Import wallet from private key
  Future<void> importWalletFromPrivateKey(String privateKey) async {
    if (_isLoading) return;
    _setLoading(true);
    try {
      _wallet = await _walletService.importWalletFromPrivateKey(privateKey);
      await refreshBalance();
      await fetchTransactions();
    } catch (e) {
      _setError('Failed to import wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh balance with dedicated loading state - modified to use current network
  Future<void> refreshBalance() async {
    if (_wallet == null) return;
    if (_isRefreshingBalance) return; // Prevent multiple concurrent calls

    final currentNetwork = _networkProvider.currentNetwork;

    _isRefreshingBalance = true;
    // Set dedicated balance loading state
    _isBalanceRefreshing = true;
    notifyListeners();

    try {
      print(
          'Refreshing balance for ${_wallet!.address} on ${_networkProvider.currentNetworkConfig.name}');

      // Make sure blockchain service is using the current network config
      await _blockchainService.updateNetwork(
        _networkProvider.currentNetworkConfig.rpcUrl,
        _networkProvider.currentNetworkConfig.pyusdContractAddress,
        _networkProvider.currentNetworkConfig.chainId,
        _networkProvider.currentNetworkConfig.explorerUrl,
      );

      final newBalance =
          await _blockchainService.getPYUSDBalance(_wallet!.address);

      print(
          'Balance fetched on ${_networkProvider.currentNetworkConfig.name}: $newBalance (previous: ${_balances[currentNetwork]})');

      // Always update the balance for the current network
      _balances[currentNetwork] = newBalance;
      notifyListeners();
    } catch (e) {
      print('Failed to refresh balance: $e');
      _setError('Failed to refresh balance: $e');
    } finally {
      _isBalanceRefreshing = false;
      _isRefreshingBalance = false; // Reset the flag
      notifyListeners();
    }
  }

  // Fetch transaction history - modified to use current network
  Future<void> fetchTransactions() async {
    if (_wallet == null) return;
    if (_isFetchingTransactions) return; // Prevent multiple concurrent calls

    final currentNetwork = _networkProvider.currentNetwork;

    _isFetchingTransactions = true;
    _setLoading(true);
    try {
      final newTransactions =
          await _blockchainService.getTransactionHistory(_wallet!.address);

      // Get current transactions for this network
      final currentTxs = _transactionsByNetwork[currentNetwork] ?? [];

      // Check if transactions have changed before updating
      if (_transactionsChanged(newTransactions, currentTxs)) {
        _transactionsByNetwork[currentNetwork] = newTransactions;
        notifyListeners();

        // Only refresh balance if transactions have changed and we're not already refreshing
        if (!_isRefreshingBalance) {
          await refreshBalance();
        }
      }
    } catch (e) {
      _setError('Failed to fetch transactions: $e');
    } finally {
      _isFetchingTransactions = false; // Reset the flag
      _setLoading(false);
    }
  }

  // Modified helper to check if transactions have changed
  bool _transactionsChanged(List<TransactionModel> newTransactions,
      List<TransactionModel> currentTransactions) {
    if (currentTransactions.length != newTransactions.length) return true;

    // Check if any transaction hashes differ
    for (int i = 0; i < newTransactions.length; i++) {
      if (i >= currentTransactions.length ||
          newTransactions[i].hash != currentTransactions[i].hash) {
        return true;
      }
    }
    return false;
  }

  // Modified sendPYUSD to use current network
  Future<bool> sendPYUSD({
    required String to,
    required double amount,
    required double gasFee,
  }) async {
    if (_wallet == null) return false;
    if (_isLoading) return false;

    final currentNetwork = _networkProvider.currentNetwork;
    final currentBalance = _balances[currentNetwork] ?? 0;

    _setLoading(true);

    // Create a unique identifier for this pending transaction
    final String pendingTxId =
        'pending-${DateTime.now().millisecondsSinceEpoch}';

    try {
      // Validate transaction parameters
      if (amount <= 0) {
        _setError('Amount must be greater than 0');
        return false;
      }

      if (amount + gasFee > currentBalance) {
        _setError('Insufficient balance');
        return false;
      }

      // Create a pending transaction before submitting to blockchain
      final pendingTx = TransactionModel(
        hash: pendingTxId,
        from: _wallet!.address,
        to: to,
        amount: amount,
        timestamp: DateTime.now(),
        status: 'Pending',
        fee: gasFee.toString(),
        networkName: _networkProvider.currentNetworkConfig.name,
      );

      // Add pending transaction immediately for responsive UI
      final currentTxs = _transactionsByNetwork[currentNetwork] ?? [];
      currentTxs.insert(0, pendingTx);
      _transactionsByNetwork[currentNetwork] = currentTxs;

      // Pre-emptively update balance to provide immediate feedback
      _balances[currentNetwork] = currentBalance - amount - gasFee;
      notifyListeners();

      String? txHash;
      try {
        txHash = await _blockchainService.transferPYUSD(
          from: _wallet!.address,
          to: to,
          amount: amount,
          credentials: _wallet!.credentials,
        );
      } catch (e) {
        print('Blockchain service error: $e');
        // Don't throw here, let the outer try-catch handle it
        // This ensures we can properly clean up the pending transaction
        txHash = null;
      }

      if (txHash != null) {
        print('Transaction successful: $txHash');

        // Get current transactions list for this network
        final currentTxs = _transactionsByNetwork[currentNetwork] ?? [];

        // Find the pending transaction by its unique ID
        final index = currentTxs.indexWhere((tx) => tx.hash == pendingTxId);

        if (index != -1) {
          // Replace the pending transaction with the confirmed one
          currentTxs[index] = TransactionModel(
            hash: txHash,
            from: _wallet!.address,
            to: to,
            amount: amount,
            timestamp: DateTime.now(),
            status: 'Pending', // Keep as pending until confirmation
            fee: gasFee.toString(),
            networkName: _networkProvider.currentNetworkConfig.name,
          );
          _transactionsByNetwork[currentNetwork] = currentTxs;
          notifyListeners();
        } else {
          // If we somehow lost the pending transaction, add the new one
          currentTxs.insert(
              0,
              TransactionModel(
                hash: txHash,
                from: _wallet!.address,
                to: to,
                amount: amount,
                timestamp: DateTime.now(),
                status: 'Pending',
                fee: gasFee.toString(),
                networkName: _networkProvider.currentNetworkConfig.name,
              ));
          _transactionsByNetwork[currentNetwork] = currentTxs;
          notifyListeners();
        }

        // Schedule a balance refresh after a short delay to allow the blockchain to update
        Future.delayed(const Duration(seconds: 2), () async {
          await refreshWalletData();
        });

        // Schedule a status update check after some time
        Future.delayed(const Duration(seconds: 30), () async {
          _checkTransactionStatus(txHash!, currentNetwork);
        });

        return true;
      }

      // If transaction failed, remove the pending transaction and restore balance
      _removeAndRestorePendingTransaction(
          pendingTxId, amount, gasFee, currentNetwork);
      _setError('Transaction failed: No transaction hash returned');
      return false;
    } catch (e) {
      print('Transaction failed with error: $e');
      // Remove the pending transaction and restore balance
      _removeAndRestorePendingTransaction(
          pendingTxId, amount, gasFee, currentNetwork);
      _setError('Transaction failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get current network name
  String getCurrentNetworkName() {
    return _networkProvider.currentNetworkConfig.name;
  }

  // Get contract address for current network
  String getCurrentContractAddress() {
    return _networkProvider.currentNetworkConfig.pyusdContractAddress;
  }

  // Get chain ID for current network
  int getCurrentChainId() {
    return _networkProvider.currentNetworkConfig.chainId;
  }

  // Get explorer URL for current network
  String getCurrentExplorerUrl() {
    return _networkProvider.currentNetworkConfig.explorerUrl;
  }

  Future<void> handleNetworkChange() async {
    final currentNetwork = _networkProvider.currentNetwork;
    print('Network changed to: ${_networkProvider.currentNetworkConfig.name}');

    // Reset state for UI purposes but don't clear data
    _isRefreshingBalance = false;
    _isFetchingTransactions = false;
    _error = null; // Clear any existing errors

    // Set loading states immediately
    _isBalanceRefreshing = true;
    _isLoading = true;
    notifyListeners();

    try {
      // Ensure blockchain service is updated with the new network settings
      await _blockchainService.updateNetwork(
        _networkProvider.currentNetworkConfig.rpcUrl,
        _networkProvider.currentNetworkConfig.pyusdContractAddress,
        _networkProvider.currentNetworkConfig.chainId,
        _networkProvider.currentNetworkConfig.explorerUrl,
      );

      print(
          'BlockchainService updated for network: ${_networkProvider.currentNetworkConfig.name}');

      // Refresh data for the current network
      if (_wallet != null) {
        // Force a fresh balance fetch
        print(
            'Fetching balance for network: ${_networkProvider.currentNetworkConfig.name}');
        final newBalance =
            await _blockchainService.getPYUSDBalance(_wallet!.address);

        // Update the balance for this specific network
        _balances[currentNetwork] = newBalance;

        print(
            'Balance updated for ${_networkProvider.currentNetworkConfig.name}: $newBalance');

        // Fetch transactions separately
        await fetchTransactions();
      }
    } catch (e) {
      print('Error during network change: $e');
      _setError('Failed to update data after network change: $e');
    } finally {
      _isBalanceRefreshing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Modified helper method to remove pending transaction and restore balance
  void _removeAndRestorePendingTransaction(
      String pendingTxId, double amount, double gasFee, NetworkType network) {
    final txList = _transactionsByNetwork[network] ?? [];
    final index = txList.indexWhere((tx) => tx.hash == pendingTxId);

    if (index != -1) {
      txList.removeAt(index);
      _transactionsByNetwork[network] = txList;

      // Restore balance for this network
      _balances[network] = (_balances[network] ?? 0) + amount + gasFee;
      notifyListeners();
    }
  }

  // Modified transaction status check method
  Future<void> _checkTransactionStatus(
      String txHash, NetworkType network) async {
    try {
      // Make multiple attempts to check transaction status
      bool isConfirmed = false;
      int attempts = 0;
      const maxAttempts = 5;

      while (!isConfirmed && attempts < maxAttempts) {
        attempts++;

        // In a real implementation, you would check with the blockchain service
        // For now, we'll simulate confirmation after a delay
        await Future.delayed(const Duration(seconds: 10));

        // Get transactions for the specific network
        final txList = _transactionsByNetwork[network] ?? [];

        // Find the transaction in our list
        final index = txList.indexWhere((tx) => tx.hash == txHash);
        if (index != -1 && txList[index].status == 'Pending') {
          // Update the transaction status to confirmed
          final updatedTx = TransactionModel(
            hash: txList[index].hash,
            from: txList[index].from,
            to: txList[index].to,
            amount: txList[index].amount,
            timestamp: txList[index].timestamp,
            status: 'Confirmed', // Update the status
            fee: txList[index].fee,
            networkName: txList[index].networkName,
          );

          txList[index] = updatedTx;
          _transactionsByNetwork[network] = txList;
          notifyListeners();
          isConfirmed = true;
        } else if (index == -1) {
          // If we can't find the transaction, try to refresh transactions
          // Only refresh if the current network is the one with the transaction
          if (network == _networkProvider.currentNetwork) {
            await fetchTransactions();

            // Check if it was added after refresh
            final refreshedTxs = _transactionsByNetwork[network] ?? [];
            if (refreshedTxs.any((tx) => tx.hash == txHash)) {
              isConfirmed = true;
            }
          }
        }
      }

      // Final refresh to ensure everything is up to date
      if (network == _networkProvider.currentNetwork) {
        await refreshWalletData();
      }
    } catch (e) {
      print('Error checking transaction status: $e');
      // Even if we have an error, try to refresh data
      await refreshWalletData();
    }
  }

  // Full refresh of wallet data
  Future<void> refreshWalletData() async {
    if (_wallet == null) return;
    if (_isLoading && !_isBalanceRefreshing) return;

    try {
      // Only call refreshBalance first, then fetchTransactions
      // This prevents circular refresh calls
      await refreshBalance();

      // Only fetch transactions if not already loading balance
      if (!_isBalanceRefreshing) {
        await fetchTransactions();
      }
    } catch (e) {
      _setError('Failed to refresh wallet data: $e');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMsg) {
    _error = errorMsg;
    print('WalletProvider error: $errorMsg');
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
