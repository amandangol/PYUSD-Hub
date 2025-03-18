import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/network_provider.dart';
import '../model/transaction_model.dart';

class TransactionService {
  // Store a pending transaction to SharedPreferences
  Future<void> storePendingTransactionToPrefs(TransactionModel tx) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing pending transactions for this network
      final String key = 'pending_transactions_${tx.network.toString()}';
      final String? existingJson = prefs.getString(key);

      List<Map<String, dynamic>> pendingList = [];
      if (existingJson != null) {
        pendingList = List<Map<String, dynamic>>.from(jsonDecode(existingJson));
      }

      // Add the new transaction if it doesn't already exist
      if (!pendingList.any((item) => item['hash'] == tx.hash)) {
        pendingList.add(tx.toJson());

        // Save back to SharedPreferences
        await prefs.setString(key, jsonEncode(pendingList));
        print('Stored pending transaction in SharedPreferences: ${tx.hash}');
      }
    } catch (e) {
      print('Error storing pending transaction: $e');
    }
  }

  // Remove a pending transaction from SharedPreferences
  Future<void> removePendingTransactionFromPrefs(TransactionModel tx) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing pending transactions for this network
      final String key = 'pending_transactions_${tx.network.toString()}';
      final String? existingJson = prefs.getString(key);

      if (existingJson != null) {
        List<Map<String, dynamic>> pendingList =
            List<Map<String, dynamic>>.from(jsonDecode(existingJson));

        // Remove the transaction
        pendingList.removeWhere((item) => item['hash'] == tx.hash);

        // Save back to SharedPreferences
        await prefs.setString(key, jsonEncode(pendingList));
        print('Removed transaction from pending storage: ${tx.hash}');
      }
    } catch (e) {
      print('Error removing pending transaction: $e');
    }
  }

  // Get pending transactions for a specific network
  Future<List<TransactionModel>> getPendingTransactions(
      NetworkType network) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'pending_transactions_${network.toString()}';
      final String? pendingJson = prefs.getString(key);

      if (pendingJson != null) {
        final List<dynamic> pendingList = jsonDecode(pendingJson);
        final List<TransactionModel> transactions = [];

        for (final txJson in pendingList) {
          try {
            final tx = TransactionModel.fromJson(txJson);

            // Only include transactions less than 24 hours old
            if (DateTime.now().difference(tx.timestamp).inHours < 24) {
              transactions.add(tx);
            }
          } catch (e) {
            print('Error parsing pending transaction: $e');
          }
        }

        return transactions;
      }

      return [];
    } catch (e) {
      print('Error getting pending transactions: $e');
      return [];
    }
  }

  // Load pending transactions from SharedPreferences
  Future<Map<NetworkType, Map<String, TransactionModel>>>
      loadPendingTransactionsFromPrefs(
          List<NetworkType> availableNetworks) async {
    final Map<NetworkType, Map<String, TransactionModel>>
        pendingTransactionMap = {};

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load for all available networks
      for (final network in availableNetworks) {
        final String key = 'pending_transactions_${network.toString()}';
        final String? pendingJson = prefs.getString(key);

        pendingTransactionMap[network] = {};

        if (pendingJson != null) {
          final List<dynamic> pendingList = jsonDecode(pendingJson);

          // Convert JSON back to TransactionModel objects
          for (final txJson in pendingList) {
            try {
              final tx = TransactionModel.fromJson(txJson);

              // Only keep pending transactions that are recent (less than 24 hours old)
              if (DateTime.now().difference(tx.timestamp).inHours < 24) {
                pendingTransactionMap[network]![tx.hash] = tx;
              }
            } catch (e) {
              print('Error parsing pending transaction: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error loading pending transactions: $e');
    }

    return pendingTransactionMap;
  }
}
