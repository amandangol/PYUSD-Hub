import 'package:flutter/material.dart';
import '../../../providers/network_provider.dart';
import 'failed_transaction_test.dart';

class FailedTransactionTestScreen extends StatefulWidget {
  const FailedTransactionTestScreen({Key? key}) : super(key: key);

  @override
  State<FailedTransactionTestScreen> createState() =>
      _FailedTransactionTestScreenState();
}

class _FailedTransactionTestScreenState
    extends State<FailedTransactionTestScreen> {
  final _rpcUrlController = TextEditingController();
  final _fromAddressController = TextEditingController();
  final _toAddressController = TextEditingController();
  final _amountController = TextEditingController();
  String _testResult = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _rpcUrlController.dispose();
    _fromAddressController.dispose();
    _toAddressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _testFailedTransaction() async {
    if (_rpcUrlController.text.isEmpty) {
      setState(() => _testResult = 'Please enter an RPC URL');
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = 'Testing failed transaction...';
    });

    try {
      await FailedTransactionTest.testFailedTransactionWithTrace(
        _rpcUrlController.text,
      );
      setState(() => _testResult = 'Test completed successfully');
    } catch (e) {
      setState(() => _testResult = 'Test failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testTraceCall() async {
    if (_rpcUrlController.text.isEmpty ||
        _fromAddressController.text.isEmpty ||
        _toAddressController.text.isEmpty ||
        _amountController.text.isEmpty) {
      setState(() => _testResult = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = 'Testing trace call...';
    });

    try {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final result = await FailedTransactionTest.testTraceCall(
        _rpcUrlController.text,
        _fromAddressController.text,
        _toAddressController.text,
        amount,
      );

      setState(() {
        _testResult = result != null
            ? 'Trace call successful: ${result.toString()}'
            : 'Trace call failed';
      });
    } catch (e) {
      setState(() => _testResult = 'Test failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Failed Transaction Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _rpcUrlController,
              decoration: const InputDecoration(
                labelText: 'RPC URL',
                hintText: 'Enter your RPC URL',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fromAddressController,
              decoration: const InputDecoration(
                labelText: 'From Address',
                hintText: 'Enter sender address',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _toAddressController,
              decoration: const InputDecoration(
                labelText: 'To Address',
                hintText: 'Enter recipient address',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (ETH)',
                hintText: 'Enter amount in ETH',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _testFailedTransaction,
              child: const Text('Test Failed Transaction'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testTraceCall,
              child: const Text('Test Trace Call'),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_testResult),
              ),
          ],
        ),
      ),
    );
  }
}
