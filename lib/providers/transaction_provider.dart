import 'package:flutter/foundation.dart';
import '../models/transaction.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement actual API call to load transactions
      // For now, we'll use dummy data
      await Future.delayed(const Duration(seconds: 1));
      _transactions = [
        Transaction(
          id: '1',
          type: TransactionType.send,
          amount: 100,
          fromAddress: '0x1234...5678',
          toAddress: '0x8765...4321',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          status: TransactionStatus.completed,
        ),
        Transaction(
          id: '2',
          type: TransactionType.receive,
          amount: 50,
          fromAddress: '0x8765...4321',
          toAddress: '0x1234...5678',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          status: TransactionStatus.completed,
        ),
        Transaction(
          id: '3',
          type: TransactionType.swap,
          amount: 200,
          fromAddress: '0x1234...5678',
          toAddress: '0x8765...4321',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          status: TransactionStatus.pending,
          fromToken: 'PYUSD',
          toToken: 'USDT',
          fromAmount: 200,
          toAmount: 200,
        ),
      ];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      // TODO: Implement actual API call to add transaction
      _transactions.insert(0, transaction);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTransactionStatus(
      String id, TransactionStatus status) async {
    try {
      // TODO: Implement actual API call to update transaction status
      final index = _transactions.indexWhere((t) => t.id == id);
      if (index != -1) {
        final transaction = _transactions[index];
        _transactions[index] = Transaction(
          id: transaction.id,
          type: transaction.type,
          amount: transaction.amount,
          fromAddress: transaction.fromAddress,
          toAddress: transaction.toAddress,
          timestamp: transaction.timestamp,
          status: status,
          fromToken: transaction.fromToken,
          toToken: transaction.toToken,
          fromAmount: transaction.fromAmount,
          toAmount: transaction.toAmount,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
