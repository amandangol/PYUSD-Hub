import 'package:flutter/material.dart';
import '../model/transaction_model.dart';
import '../provider/transaction_provider.dart';
import '../../../providers/network_provider.dart';
import '../../../services/debug_trace_service.dart';

class FailedTransactionTest {
  static final DebugTraceService _debugTraceService = DebugTraceService();

  static TransactionDetailModel createFailedTransaction({
    required String hash,
    required String fromAddress,
    required String toAddress,
    required double amount,
    required NetworkType network,
    String? errorMessage,
    Map<String, dynamic>? traceData,
  }) {
    return TransactionDetailModel(
      hash: hash,
      timestamp: DateTime.now(),
      from: fromAddress,
      to: toAddress,
      amount: amount,
      gasUsed: 21000.0,
      gasLimit: 21000.0,
      gasPrice: 50.0,
      status: TransactionStatus.failed,
      direction: TransactionDirection.outgoing,
      confirmations: 0,
      network: network,
      blockNumber: '0',
      nonce: 0,
      blockHash:
          '0x0000000000000000000000000000000000000000000000000000000000000000',
      isError: true,
      errorMessage: errorMessage ?? 'Transaction failed - Insufficient funds',
      tokenSymbol: null,
      tokenName: null,
      tokenDecimals: null,
      tokenContractAddress: null,
      data: null,
      traceData: traceData ??
          {
            'type': 'CALL',
            'from': fromAddress,
            'to': toAddress,
            'value': '0x${BigInt.from(amount * 1e18).toRadixString(16)}',
            'gas': '0x5208', // 21000
            'gasUsed': '0x5208',
            'error': errorMessage ?? 'Transaction failed - Insufficient funds',
          },
    );
  }

  // Example usage with trace data
  static Future<void> testFailedTransactionWithTrace(String rpcUrl) async {
    try {
      final failedTx = createFailedTransaction(
        hash:
            '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
        fromAddress: '0x1234567890123456789012345678901234567890',
        toAddress: '0x0987654321098765432109876543210987654321',
        amount: 0.1,
        network: NetworkType.ethereumMainnet,
        errorMessage: 'Transaction failed - Insufficient funds for gas',
      );

      // Get actual trace data from the network
      final traceData = await _debugTraceService.traceTransaction(
        rpcUrl,
        failedTx.hash,
      );

      // Create a new transaction with the actual trace data
      final failedTxWithTrace = failedTx.copyWith(
        traceData: traceData,
      );

      // Get detailed error message
      final detailedError = await _debugTraceService.getDetailedErrorMessage(
        rpcUrl,
        failedTx.hash,
      );

      // Print debug information
      print('Failed Transaction Hash: ${failedTxWithTrace.hash}');
      print('Status: ${failedTxWithTrace.status}');
      print('Error Message: ${failedTxWithTrace.errorMessage}');
      print('Detailed Error: $detailedError');
      print('Is Error: ${failedTxWithTrace.isError}');
      print('Trace Data: ${failedTxWithTrace.traceData}');
    } catch (e) {
      print('Error in testFailedTransactionWithTrace: $e');
    }
  }

  // Test debug_traceCall
  static Future<Map<String, dynamic>?> testTraceCall(
    String rpcUrl,
    String fromAddress,
    String toAddress,
    double amount,
  ) async {
    try {
      final traceData = await _debugTraceService.traceCall(
        rpcUrl,
        from: fromAddress,
        to: toAddress,
        data: '0x', // Empty data for ETH transfer
        value: '0x${BigInt.from(amount * 1e18).toRadixString(16)}',
        gas: '0x5208', // 21000
      );

      print('Trace Call Result: $traceData');
      return traceData;
    } catch (e) {
      print('Error in testTraceCall: $e');
      return null;
    }
  }
}
