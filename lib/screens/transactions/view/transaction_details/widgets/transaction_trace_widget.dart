import 'package:flutter/material.dart';
import '../../../model/transaction_model.dart';

class TransactionTraceWidget extends StatelessWidget {
  final TransactionDetailModel transaction;
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final Color primaryColor;
  final Function(Map<String, dynamic> traceData)? onShowRawTraceData;

  const TransactionTraceWidget({
    Key? key,
    required this.transaction,
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.primaryColor,
    this.onShowRawTraceData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (transaction.traceData == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: cardColor,
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Trace',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: textColor,
                      ),
                ),
                if (onShowRawTraceData != null)
                  IconButton(
                    icon: Icon(Icons.code, color: primaryColor),
                    onPressed: () =>
                        onShowRawTraceData!(transaction.traceData!),
                    tooltip: 'View Raw Trace Data',
                  ),
              ],
            ),
            const SizedBox(height: 16.0),
            _buildTraceDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildTraceDetails() {
    final traceData = transaction.traceData!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTraceItem('Type', traceData['type']?.toString() ?? 'N/A'),
        if (traceData['errorDetails'] != null)
          _buildErrorDetails(traceData['errorDetails']),
        _buildTraceItem('From', traceData['from']?.toString() ?? 'N/A'),
        _buildTraceItem('To', traceData['to']?.toString() ?? 'N/A'),
        _buildTraceItem(
          'Value',
          _formatValue(traceData['value']?.toString() ?? '0x0'),
        ),
        _buildTraceItem(
          'Gas Used',
          _formatGas(traceData['gasUsed']?.toString() ?? '0x0'),
        ),
        if (traceData['input'] != null)
          _buildTraceItem('Input Data', traceData['input'].toString()),
        if (traceData['output'] != null)
          _buildTraceItem('Output Data', traceData['output'].toString()),
      ],
    );
  }

  Widget _buildErrorDetails(Map<String, dynamic> errorDetails) {
    final errorType = errorDetails['type'] as String;
    final errorMessage = errorDetails['message'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.red),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                errorType == 'revert'
                    ? 'Transaction Reverted'
                    : 'Execution Error',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildTraceItem(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: subtitleColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(String hexValue) {
    try {
      final value = BigInt.parse(hexValue.replaceFirst('0x', ''), radix: 16);
      return '${value.toString()} Wei (${value / BigInt.from(1e18)} ETH)';
    } catch (e) {
      return hexValue;
    }
  }

  String _formatGas(String hexGas) {
    try {
      final gas = BigInt.parse(hexGas.replaceFirst('0x', ''), radix: 16);
      return gas.toString();
    } catch (e) {
      return hexGas;
    }
  }
}
