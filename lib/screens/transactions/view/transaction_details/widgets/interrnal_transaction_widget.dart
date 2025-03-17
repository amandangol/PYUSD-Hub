import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../utils/formatter_utils.dart';

class InternalTransactionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> internalTransactions;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final Color primaryColor;

  const InternalTransactionWidget({
    super.key,
    required this.internalTransactions,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.primaryColor,
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
                Icon(Icons.account_tree_outlined,
                    size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Internal Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // List of internal transactions
            ...List.generate(internalTransactions.length, (index) {
              final tx = internalTransactions[index];
              return Card(
                color: cardColor.withOpacity(0.5),
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        title: 'From',
                        value: FormatterUtils.formatHash(tx['from'] ?? ''),
                        canCopy: true,
                        data: tx['from'],
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      _buildDetailRow(
                        title: 'To',
                        value: FormatterUtils.formatHash(tx['to'] ?? ''),
                        canCopy: true,
                        data: tx['to'],
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      _buildDetailRow(
                        title: 'Value',
                        value:
                            '${FormatterUtils.formatEther(tx['value'] ?? '0')} ETH',
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        valueColor: primaryColor,
                      ),
                      if (tx['input'] != null && tx['input'].length > 2)
                        _buildDetailRow(
                          title: 'Input',
                          value: FormatterUtils.formatHash(tx['input']),
                          canCopy: true,
                          data: tx['input'],
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                      if (tx['type'] != null)
                        _buildDetailRow(
                          title: 'Type',
                          value: tx['type'],
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                    ],
                  ),
                ),
              );
            }),

            // If no internal transactions were found
            if (internalTransactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No internal transactions found',
                    style: TextStyle(color: subtitleColor),
                  ),
                ),
              ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   const SnackBar(content: Text('Copied to clipboard')),
                  // );
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
