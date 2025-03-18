import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../utils/formatter_utils.dart';

class TransactionTraceWidget extends StatelessWidget {
  final Map<String, dynamic> traceData;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final Color primaryColor;
  final VoidCallback onShowRawTraceData;

  const TransactionTraceWidget({
    super.key,
    required this.traceData,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.primaryColor,
    required this.onShowRawTraceData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardColor,
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Transaction Trace',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Transaction call hierarchy
            if (traceData.containsKey('calls'))
              _buildTraceCallHierarchy(
                  traceData, 0, cardColor, textColor, subtitleColor),

            // Transaction call execution status
            if (traceData.containsKey('type'))
              _buildDetailRow(
                title: 'Type',
                value: traceData['type'].toString(),
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),

            if (traceData.containsKey('from'))
              _buildDetailRow(
                title: 'Origin',
                value: FormatterUtils.formatHash(traceData['from'].toString()),
                canCopy: true,
                data: traceData['from'].toString(),
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),

            if (traceData.containsKey('to'))
              _buildDetailRow(
                title: 'Target',
                value: FormatterUtils.formatHash(traceData['to'].toString()),
                canCopy: true,
                data: traceData['to'].toString(),
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),

            if (traceData.containsKey('value'))
              _buildDetailRow(
                title: 'Value',
                value:
                    '${FormatterUtils.formatEther(traceData['value'].toString())} ETH',
                textColor: textColor,
                subtitleColor: subtitleColor,
                valueColor: primaryColor,
              ),

            if (traceData.containsKey('gas'))
              _buildDetailRow(
                title: 'Gas',
                value: traceData['gas'].toString(),
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),

            if (traceData.containsKey('gasUsed'))
              _buildDetailRow(
                title: 'Gas Used',
                value: traceData['gasUsed'].toString(),
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),

            if (traceData.containsKey('error'))
              _buildDetailRow(
                title: 'Error',
                value: traceData['error'].toString(),
                textColor: textColor,
                subtitleColor: subtitleColor,
                valueColor: Colors.red,
              ),

            // View raw trace data button
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.data_object),
                label: const Text('View Raw Trace Data'),
                onPressed: onShowRawTraceData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraceCallHierarchy(Map<String, dynamic> data, int depth,
      Color cardColor, Color textColor, Color subtitleColor) {
    final padding = EdgeInsets.only(left: depth * 16.0);
    final calls = data['calls'] as List<dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: subtitleColor.withOpacity(0.2)),
            ),
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.call_made,
                      size: 14,
                      color: subtitleColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${data['type'] ?? 'CALL'} to ${FormatterUtils.formatHash(data['to'] ?? '')}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Value: ${FormatterUtils.formatEther(data['value'] ?? '0')} ETH',
                  style: TextStyle(color: subtitleColor),
                ),
                if (data['gas'] != null)
                  Text(
                    'Gas: ${data['gas']}',
                    style: TextStyle(color: subtitleColor),
                  ),
                if (data['gasUsed'] != null)
                  Text(
                    'Gas Used: ${data['gasUsed']}',
                    style: TextStyle(color: subtitleColor),
                  ),
                if (data['error'] != null)
                  Text(
                    'Error: ${data['error']}',
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
        if (calls != null && calls.isNotEmpty)
          ...calls.map((call) => _buildTraceCallHierarchy(
              call as Map<String, dynamic>,
              depth + 1,
              cardColor,
              textColor,
              subtitleColor)),
      ],
    );
  }

  Widget _buildDetailRow({
    required String title,
    required String value,
    bool canCopy = false,
    String? data,
    Color? valueColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? textColor,
              ),
            ),
          ),
          if (canCopy && data != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: data));
                  // Note: The actual snackbar is shown from the parent widget
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.copy_outlined,
                    size: 16,
                    color: subtitleColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
