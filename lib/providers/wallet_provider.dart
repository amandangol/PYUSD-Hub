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
  String? _error;

  // Getters
  WalletModel? get wallet => _wallet;
  double get balance => _balance;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasWallet => _wallet != null;

  // Initialize wallet
  Future<void> initWallet() async {
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

  // Refresh balance
  Future<void> refreshBalance() async {
    if (_wallet == null) return;

    try {
      _balance = await _blockchainService.getPYUSDBalance(_wallet!.address);
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh balance: $e');
    }
  }

  // Fetch transaction history
  Future<void> fetchTransactions() async {
    if (_wallet == null) return;

    _setLoading(true);
    try {
      _transactions =
          await _blockchainService.getTransactionHistory(_wallet!.address);
      notifyListeners();
    } catch (e) {
      _setError('Failed to fetch transactions: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Send PYUSD
  Future<bool> sendPYUSD({
    required String to,
    required double amount,
  }) async {
    if (_wallet == null) return false;

    _setLoading(true);
    try {
      final txHash = await _blockchainService.transferPYUSD(
        from: _wallet!.address,
        to: to,
        amount: amount,
        credentials: _wallet!.credentials,
      );

      if (txHash != null) {
        // Add pending transaction to the list
        final newTx = TransactionModel(
          hash: txHash,
          from: _wallet!.address,
          to: to,
          amount: amount,
          timestamp: DateTime.now(),
          isIncoming: false,
          status: 'Pending', // Instead of isPending
        );

        _transactions.insert(0, newTx);
        await refreshBalance();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Transaction failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete wallet
  Future<void> deleteWallet() async {
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

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMsg) {
    _error = errorMsg;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
