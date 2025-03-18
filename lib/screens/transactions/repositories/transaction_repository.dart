// lib/features/transactions/repositories/transaction_repository.dart

import '../../../providers/network_provider.dart';
import '../model/transaction_model.dart';
import '../../../services/ethereum_rpc_service.dart';
import '../utils/transaction_utils.dart';

class TransactionRepository {
  final EthereumRpcService _rpcService = EthereumRpcService();

  // Get transaction details
  Future<TransactionDetailModel?> getTransactionDetails(
      String rpcUrl, String txHash, NetworkType network, String address) async {
    try {
      return await _rpcService.getTransactionDetails(
        rpcUrl,
        txHash,
        network,
        address,
      );
    } catch (e) {
      print('Failed to get transaction details: $e');
      return null;
    }
  }

  // Process transactions
  List<TransactionModel> processTransactions(
      List<dynamic> ethTxs,
      List<dynamic> tokenTxs,
      String address,
      NetworkType currentNetwork,
      Map<NetworkType, Map<String, TransactionModel>> pendingTransactionMap) {
    // Track all transactions by hash for deduplication
    final Map<String, TransactionModel> processedTransactions = {};
    final Set<String> processedHashes = {};

    // Process ETH transactions first
    for (final tx in ethTxs) {
      if (tx['hash'] == null) continue;

      final hash = tx['hash'];
      processedHashes.add(hash);

      final direction =
          TransactionUtils.compareAddresses(tx['from'] ?? '', address)
              ? TransactionDirection.outgoing
              : TransactionDirection.incoming;

      // Determine transaction status
      TransactionStatus status;
      if (tx['blockNumber'] == null || tx['blockNumber'] == '0') {
        status = TransactionStatus.pending;
      } else if (int.parse(tx['isError'] ?? '0') == 1) {
        status = TransactionStatus.failed;
      } else {
        status = TransactionStatus.confirmed;
      }

      // Handle timestamp
      DateTime timestamp;
      if (tx['timeStamp'] != null) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(
            int.parse(tx['timeStamp']) * 1000);
      } else {
        timestamp = DateTime.now();
      }

      // Safe parsing of numeric values
      final value = tx['value'] ?? '0';
      final gasUsed = tx['gasUsed'] ?? '0';
      final gasPrice = tx['gasPrice'] ?? '0';
      final confirmations = tx['confirmations'] ?? '0';

      processedTransactions[hash] = TransactionModel(
        hash: hash,
        timestamp: timestamp,
        from: tx['from'] ?? '',
        to: tx['to'] ?? '',
        amount: double.parse(value) / 1e18,
        gasUsed: double.parse(gasUsed),
        gasPrice: double.parse(gasPrice) / 1e9,
        status: status,
        direction: direction,
        confirmations: int.parse(confirmations),
        network: currentNetwork,
        tokenSymbol: 'ETH', // Explicitly set to ETH
      );
    }

    // Process token transactions
    for (final tx in tokenTxs) {
      if (tx['hash'] == null) continue;

      final hash = tx['hash'];
      processedHashes.add(hash);

      final direction = TransactionUtils.compareAddresses(tx['from'], address)
          ? TransactionDirection.outgoing
          : TransactionDirection.incoming;

      // Determine transaction status
      TransactionStatus status;
      if (tx['blockNumber'] == null || tx['blockNumber'] == '0') {
        status = TransactionStatus.pending;
      } else if (int.parse(tx['isError'] ?? '0') == 1) {
        status = TransactionStatus.failed;
      } else {
        status = TransactionStatus.confirmed;
      }

      // Handle timestamp
      DateTime timestamp;
      if (tx['timeStamp'] != null) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(
            int.parse(tx['timeStamp']) * 1000);
      } else {
        timestamp = DateTime.now();
      }

      // Token amount with proper decimals
      final decimals = int.parse(tx['tokenDecimal'] ?? '18');
      final rawAmount = BigInt.tryParse(tx['value'] ?? '0') ?? BigInt.zero;
      final tokenAmount =
          rawAmount.toDouble() / BigInt.from(10).pow(decimals).toDouble();

      processedTransactions[hash] = TransactionModel(
        hash: hash,
        timestamp: timestamp,
        from: tx['from'] ?? '',
        to: tx['to'] ?? '',
        amount: tokenAmount,
        gasUsed: double.tryParse(tx['gasUsed'] ?? '0') ?? 0.0,
        gasPrice: double.tryParse(tx['gasPrice'] ?? '0') ?? 0.0 / 1e9,
        status: status,
        direction: direction,
        confirmations: int.tryParse(tx['confirmations'] ?? '0') ?? 0,
        tokenSymbol: tx['tokenSymbol'],
        tokenName: tx['tokenName'],
        tokenDecimals: decimals,
        tokenContractAddress: tx['contractAddress'],
        network: currentNetwork,
      );
    }

    // Add locally stored pending transactions that aren't in the fetched data
    final pendingTxs =
        pendingTransactionMap[currentNetwork]?.values.toList() ?? [];

    for (final pendingTx in pendingTxs) {
      // Only add pending transactions that weren't already processed from API
      if (!processedHashes.contains(pendingTx.hash)) {
        processedTransactions[pendingTx.hash] = pendingTx;
      }
    }

    // Convert map to list and sort by timestamp
    final result = processedTransactions.values.toList();
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return result;
  }

  // Fetch transactions
  Future<List<dynamic>> getTransactions(String address, NetworkType network,
      {int page = 1, int perPage = 20}) async {
    return await _rpcService.getTransactions(
      address,
      network,
      page: page,
      perPage: perPage,
    );
  }

  // Fetch token transactions
  Future<List<dynamic>> getTokenTransactions(
      String address, NetworkType network,
      {int page = 1, int perPage = 20}) async {
    return await _rpcService.getTokenTransactions(
      address,
      network,
      page: page,
      perPage: perPage,
    );
  }

  // Send ETH transaction
  Future<String> sendEthTransaction(
      String rpcUrl, String privateKey, String toAddress, double amount,
      {double? gasPrice, int? gasLimit}) async {
    return await _rpcService.sendEthTransaction(
      rpcUrl,
      privateKey,
      toAddress,
      amount,
      gasPrice: gasPrice,
      gasLimit: gasLimit,
    );
  }

  // Send token transaction
  Future<String> sendTokenTransaction(String rpcUrl, String privateKey,
      String tokenAddress, String toAddress, double amount, int tokenDecimals,
      {double? gasPrice, int? gasLimit}) async {
    return await _rpcService.sendTokenTransaction(
      rpcUrl,
      privateKey,
      tokenAddress,
      toAddress,
      amount,
      tokenDecimals,
      gasPrice: gasPrice,
      gasLimit: gasLimit,
    );
  }

  // Estimate ETH gas
  Future<int> estimateEthGas(String rpcUrl, String fromAddress,
      String toAddress, double amount) async {
    return await _rpcService.estimateEthGas(
      rpcUrl,
      fromAddress,
      toAddress,
      amount,
    );
  }

  // Estimate token gas
  Future<int> estimateTokenGas(
      String rpcUrl,
      String fromAddress,
      String tokenAddress,
      String toAddress,
      double amount,
      int tokenDecimals) async {
    return await _rpcService.estimateTokenGas(
      rpcUrl,
      fromAddress,
      tokenAddress,
      toAddress,
      amount,
      tokenDecimals,
    );
  }

  // Get gas price
  Future<double> getGasPrice(String rpcUrl) async {
    return await _rpcService.getGasPrice(rpcUrl);
  }
}
