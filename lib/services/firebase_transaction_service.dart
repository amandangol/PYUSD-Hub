import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../screens/transactions/model/transaction_model.dart';
import '../../providers/network_provider.dart';

class FirebaseTransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NetworkProvider _networkProvider;

  FirebaseTransactionService(this._networkProvider);

  Future<void> saveTransaction(TransactionModel transaction) async {
    if (transaction.status != TransactionStatus.confirmed &&
        transaction.status != TransactionStatus.failed) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    final transactionData = {
      'hash': transaction.hash,
      'timestamp': transaction.timestamp.millisecondsSinceEpoch,
      'from': transaction.from,
      'to': transaction.to,
      'amount': transaction.amount,
      'gasUsed': transaction.gasUsed,
      'gasLimit': transaction.gasLimit,
      'gasPrice': transaction.gasPrice,
      'status': transaction.status.toString(),
      'direction': transaction.direction.toString(),
      'confirmations': transaction.confirmations,
      'network': transaction.network.toString(),
      'tokenSymbol': transaction.tokenSymbol,
      'tokenName': transaction.tokenName,
      'tokenDecimals': transaction.tokenDecimals,
      'tokenContractAddress': transaction.tokenContractAddress,
    };

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc('${transaction.network}_${transaction.hash}')
          .set(transactionData);
    } catch (e) {
      print('Error saving transaction to Firebase: $e');
    }
  }

  Future<List<TransactionModel>> getTransactions() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final currentNetwork = _networkProvider.currentNetwork;
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where('network', isEqualTo: currentNetwork.toString())
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionModel(
          hash: data['hash'] as String,
          timestamp:
              DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
          from: data['from'] as String,
          to: data['to'] as String,
          amount: (data['amount'] as num).toDouble(),
          gasUsed: (data['gasUsed'] as num).toDouble(),
          gasLimit: (data['gasLimit'] as num).toDouble(),
          gasPrice: (data['gasPrice'] as num).toDouble(),
          status: _parseTransactionStatus(data['status'] as String),
          direction: _parseTransactionDirection(data['direction'] as String),
          confirmations: data['confirmations'] as int,
          network: _parseNetworkType(data['network'] as String),
          tokenSymbol: data['tokenSymbol'] as String?,
          tokenName: data['tokenName'] as String?,
          tokenDecimals: data['tokenDecimals'] as int?,
          tokenContractAddress: data['tokenContractAddress'] as String?,
        );
      }).toList();
    } catch (e) {
      print('Error fetching transactions from Firebase: $e');
      return [];
    }
  }

  TransactionStatus _parseTransactionStatus(String status) {
    switch (status) {
      case 'TransactionStatus.confirmed':
        return TransactionStatus.confirmed;
      case 'TransactionStatus.failed':
        return TransactionStatus.failed;
      default:
        return TransactionStatus.pending;
    }
  }

  TransactionDirection _parseTransactionDirection(String direction) {
    switch (direction) {
      case 'TransactionDirection.incoming':
        return TransactionDirection.incoming;
      case 'TransactionDirection.outgoing':
        return TransactionDirection.outgoing;
      default:
        return TransactionDirection.incoming;
    }
  }

  NetworkType _parseNetworkType(String network) {
    switch (network) {
      case 'NetworkType.ethereumMainnet':
        return NetworkType.ethereumMainnet;
      case 'NetworkType.sepoliaTestnet':
        return NetworkType.sepoliaTestnet;
      default:
        return _networkProvider.currentNetwork;
    }
  }
}
