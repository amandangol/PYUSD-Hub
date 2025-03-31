import 'package:flutter/material.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';

class TransactionTraceViewer extends StatelessWidget {
  final Map<String, dynamic> trace;
  final bool isExpanded;
  final VoidCallback onToggle;

  const TransactionTraceViewer({
    super.key,
    required this.trace,
    this.isExpanded = false,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              '${trace['type'] ?? 'Unknown'} Call',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('From: ${trace['from'] ?? 'Unknown'}'),
                Text('To: ${trace['to'] ?? 'Unknown'}'),
                Text(
                  'Value: ${FormatterUtils.formatEther(trace['value'] ?? '0')} ETH',
                ),
                Text(
                  'Gas Used: ${FormatterUtils.formatGas(trace['gasUsed'] ?? '0')}',
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: onToggle,
            ),
          ),
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (trace['input'] != null &&
                      trace['input'].toString().isNotEmpty)
                    Text('Input: ${trace['input']}'),
                  if (trace['output'] != null &&
                      trace['output'].toString().isNotEmpty)
                    Text('Output: ${trace['output']}'),
                  if (trace['error'] != null)
                    Text(
                      'Error: ${trace['error']}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  if (trace['calls'] != null &&
                      (trace['calls'] as List).isNotEmpty)
                    ...(trace['calls'] as List).map((call) => Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TransactionTraceViewer(
                            trace: call,
                            isExpanded: false,
                            onToggle: () {},
                          ),
                        )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
