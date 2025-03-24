import 'package:flutter/material.dart';
import 'failed_transaction_test.dart';
import '../view/transaction_details/transaction_detail_screen.dart';
import '../model/transaction_model.dart';
import '../../../providers/network_provider.dart';
import '../../../config/rpc_endpoints.dart';

class FailedTransactionTestUsage extends StatelessWidget {
  const FailedTransactionTestUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Failed Transaction Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Create a failed transaction
                final failedTx = FailedTransactionTest.createFailedTransaction(
                  hash:
                      '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
                  fromAddress: '0x1234567890123456789012345678901234567890',
                  toAddress: '0x0987654321098765432109876543210987654321',
                  amount: 0.1,
                  network: NetworkType.ethereumMainnet,
                  errorMessage:
                      'Transaction failed - Insufficient funds for gas',
                );

                // Navigate to transaction detail screen with the failed transaction
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransactionDetailScreen(
                      transaction: failedTx,
                      currentAddress: failedTx.from,
                      isDarkMode: false,
                      networkType: NetworkType.ethereumMainnet,
                      rpcUrl: RpcEndpoints.mainnetHttpRpcUrl,
                    ),
                  ),
                );
              },
              child: const Text('View Failed Transaction'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Create a failed transaction with a different error message
                final failedTx = FailedTransactionTest.createFailedTransaction(
                  hash:
                      '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
                  fromAddress: '0xabcdef123456789012345678901234567890123456',
                  toAddress: '0x1234567890abcdef1234567890abcdef1234567890',
                  amount: 0.5,
                  network: NetworkType.ethereumMainnet,
                  errorMessage: 'Transaction failed - Out of gas',
                );

                // Navigate to transaction detail screen with the failed transaction
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransactionDetailScreen(
                      transaction: failedTx,
                      currentAddress: failedTx.from,
                      isDarkMode: false,
                      networkType: NetworkType.ethereumMainnet,
                      rpcUrl: RpcEndpoints.mainnetHttpRpcUrl,
                    ),
                  ),
                );
              },
              child: const Text('View Another Failed Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
