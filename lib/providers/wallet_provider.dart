import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../services/blockchain_service.dart';
import '../services/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();
  final BlockchainService _blockchainService = BlockchainService();

  WalletModel? _wallet;
  double _balance = 0;
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  bool _isBalanceRefreshing = false;
  String? _error;

  // Add flags to prevent duplicate calls
  bool _isRefreshingBalance = false;
  bool _isFetchingTransactions = false;

  // Getters
  WalletModel? get wallet => _wallet;
  double get balance => _balance;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isBalanceRefreshing => _isBalanceRefreshing;
  String? get error => _error;
  bool get hasWallet => _wallet != null;

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

  // Refresh balance with dedicated loading state
  Future<void> refreshBalance() async {
    if (_wallet == null) return;
    if (_isRefreshingBalance) return; // Prevent multiple concurrent calls

    _isRefreshingBalance = true;
    // Set dedicated balance loading state
    _isBalanceRefreshing = true;
    notifyListeners();

    try {
      print('Refreshing balance for ${_wallet!.address}');
      final newBalance =
          await _blockchainService.getPYUSDBalance(_wallet!.address);

      // Update balance only if it changed
      if (_balance != newBalance) {
        print('Balance updated: $_balance -> $newBalance');
        _balance = newBalance;
        notifyListeners();
      }
    } catch (e) {
      print('Failed to refresh balance: $e');
      _setError('Failed to refresh balance: $e');
    } finally {
      _isBalanceRefreshing = false;
      _isRefreshingBalance = false; // Reset the flag
      notifyListeners();
    }
  }

  // Fetch transaction history
  Future<void> fetchTransactions() async {
    if (_wallet == null) return;
    if (_isFetchingTransactions) return; // Prevent multiple concurrent calls

    _isFetchingTransactions = true;
    _setLoading(true);
    try {
      final newTransactions =
          await _blockchainService.getTransactionHistory(_wallet!.address);

      // Check if transactions have changed before updating
      if (_transactionsChanged(newTransactions)) {
        _transactions = newTransactions;
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

  // Helper to check if transactions have changed
  bool _transactionsChanged(List<TransactionModel> newTransactions) {
    if (_transactions.length != newTransactions.length) return true;

    // Check if any transaction hashes differ
    for (int i = 0; i < newTransactions.length; i++) {
      if (i >= _transactions.length ||
          newTransactions[i].hash != _transactions[i].hash) {
        return true;
      }
    }
    return false;
  }

  // Modified part of the wallet_provider.dart file

  Future<bool> sendPYUSD({
    required String to,
    required double amount,
    required double gasFee,
  }) async {
    if (_wallet == null) return false;
    if (_isLoading) return false;

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

      if (amount + gasFee > _balance) {
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
      );

      // Add pending transaction immediately for responsive UI
      _transactions.insert(0, pendingTx);
      // Pre-emptively update balance to provide immediate feedback
      _balance = _balance - amount - gasFee;
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

        // Find the pending transaction by its unique ID
        final index = _transactions.indexWhere((tx) => tx.hash == pendingTxId);

        if (index != -1) {
          // Replace the pending transaction with the confirmed one
          _transactions[index] = TransactionModel(
            hash: txHash,
            from: _wallet!.address,
            to: to,
            amount: amount,
            timestamp: DateTime.now(),
            status: 'Pending', // Keep as pending until confirmation
            fee: gasFee.toString(),
          );
          notifyListeners();
        } else {
          // If we somehow lost the pending transaction, add the new one
          _transactions.insert(
              0,
              TransactionModel(
                hash: txHash,
                from: _wallet!.address,
                to: to,
                amount: amount,
                timestamp: DateTime.now(),
                status: 'Pending',
                fee: gasFee.toString(),
              ));
          notifyListeners();
        }

        // Schedule a balance refresh after a short delay to allow the blockchain to update
        Future.delayed(const Duration(seconds: 2), () async {
          await refreshWalletData();
        });

        // Schedule a status update check after some time
        Future.delayed(const Duration(seconds: 30), () async {
          _checkTransactionStatus(txHash!);
        });

        return true;
      }

      // If transaction failed, remove the pending transaction and restore balance
      _removeAndRestorePendingTransaction(pendingTxId, amount, gasFee);
      _setError('Transaction failed: No transaction hash returned');
      return false;
    } catch (e) {
      print('Transaction failed with error: $e');
      // Remove the pending transaction and restore balance
      _removeAndRestorePendingTransaction(pendingTxId, amount, gasFee);
      _setError('Transaction failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

// Helper method to remove pending transaction and restore balance
  void _removeAndRestorePendingTransaction(
      String pendingTxId, double amount, double gasFee) {
    final index = _transactions.indexWhere((tx) => tx.hash == pendingTxId);
    if (index != -1) {
      _transactions.removeAt(index);
      _balance = _balance + amount + gasFee; // Restore balance
      notifyListeners();
    }
  }

// Improved transaction status check method
  Future<void> _checkTransactionStatus(String txHash) async {
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

        // Find the transaction in our list
        final index = _transactions.indexWhere((tx) => tx.hash == txHash);
        if (index != -1 && _transactions[index].status == 'Pending') {
          // Update the transaction status to confirmed
          final updatedTx = TransactionModel(
            hash: _transactions[index].hash,
            from: _transactions[index].from,
            to: _transactions[index].to,
            amount: _transactions[index].amount,
            timestamp: _transactions[index].timestamp,
            status: 'Confirmed', // Update the status
            fee: _transactions[index].fee,
          );

          _transactions[index] = updatedTx;
          notifyListeners();
          isConfirmed = true;
        } else if (index == -1) {
          // If we can't find the transaction, try to refresh transactions
          await fetchTransactions();
          // Check if it was added after refresh
          if (_transactions.any((tx) => tx.hash == txHash)) {
            isConfirmed = true;
          }
        }
      }

      // Final refresh to ensure everything is up to date
      await refreshWalletData();
    } catch (e) {
      print('Error checking transaction status: $e');
      // Even if we have an error, try to refresh data
      await refreshWalletData();
    }
  }

  // Delete wallet
  Future<void> deleteWallet() async {
    if (_isLoading) return;
    _setLoading(true);
    try {
      await _walletService.deleteWallet();
      _wallet = null;
      _balance = 0;
      _transactions = [];
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete wallet: $e');
    } finally {
      _setLoading(false);
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
