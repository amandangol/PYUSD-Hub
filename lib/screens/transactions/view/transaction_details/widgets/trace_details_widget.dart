import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import '../../../../../utils/snackbar_utils.dart';

class TraceDetailsWidget extends StatelessWidget {
  final Map<String, dynamic>? traceData;
  final bool isLoading;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final Color primaryColor;
  final VoidCallback onRefresh;

  const TraceDetailsWidget({
    super.key,
    required this.traceData,
    required this.isLoading,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.primaryColor,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (traceData == null) {
      return _buildErrorState(
        'Trace data not available',
        'Failed to load trace data',
        showRetry: true,
      );
    }

    // Check for node limitation errors
    if (traceData!.containsKey('error')) {
      final bool isNodeLimitError = traceData!['isNodeLimitError'] ?? false;
      final String errorMessage = traceData!['error'] ?? 'Unknown error';
      final String details = traceData!['details'] ?? '';

      // Check specifically for historical state tracing error
      if (errorMessage
              .contains('Node does not support historical state tracing') ||
          details.contains('historical state not available')) {
        return _buildHistoricalTraceErrorState(context);
      }

      return _buildErrorState(
        errorMessage,
        details,
        showRetry: !isNodeLimitError,
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTraceCard(context),
        ],
      ),
    );
  }

  Widget _buildHistoricalTraceErrorState(BuildContext context) {
    final transactionAge = "older"; // This could be dynamic based on actual age

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: subtitleColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history, size: 64, color: primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              'This transaction is too old',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Detailed transaction analysis is only available for most recent transactions.',
              style: TextStyle(color: subtitleColor, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to recent transactions list
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.update),
              label: const Text('View Recent Transactions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                minimumSize: const Size(240, 48),
              ),
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              title: Text(
                'Why is this happening?',
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    'Blockchain nodes only keep detailed analysis data (traces) for recent transactions to save storage space. This transaction from $transactionAge is beyond the available history range on the current network.',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String title, String message,
      {bool showRetry = true}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: subtitleColor),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              message,
              style: TextStyle(color: subtitleColor),
              textAlign: TextAlign.center,
            ),
          ),
          if (showRetry) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTraceCard(BuildContext context) {
    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: subtitleColor.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Call Trace',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyTraceData(context),
                  tooltip: 'Copy trace data',
                  color: subtitleColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTraceTree(traceData!, 0),
          ],
        ),
      ),
    );
  }

  Widget _buildTraceTree(Map<String, dynamic> trace, int depth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: depth * 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTraceRow('Type', trace['type']?.toString() ?? 'Unknown'),
              _buildTraceRow('From', trace['from']?.toString() ?? 'Unknown'),
              _buildTraceRow('To', trace['to']?.toString() ?? 'Unknown'),
              if (trace['value'] != null)
                _buildTraceRow('Value', '${trace['value']} Wei'),
              if (trace['gas'] != null)
                _buildTraceRow('Gas', trace['gas'].toString()),
              if (trace['input'] != null && trace['input'] != '0x')
                _buildTraceRow('Input', trace['input'].toString()),
            ],
          ),
        ),
        if (trace['calls'] != null)
          ...(trace['calls'] as List).map((call) => _buildTraceTree(
                call as Map<String, dynamic>,
                depth + 1,
              )),
      ],
    );
  }

  Widget _buildTraceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: subtitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyTraceData(BuildContext context) {
    final jsonString = traceData != null
        ? const JsonEncoder.withIndent('  ').convert(traceData)
        : 'No trace data available';

    Clipboard.setData(ClipboardData(text: jsonString));

    SnackbarUtil.showSnackbar(
      context: context,
      message: 'Trace data copied to clipboard',
    );
  }
}
