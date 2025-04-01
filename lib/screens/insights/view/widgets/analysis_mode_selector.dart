import 'package:flutter/material.dart';
import '../../../../widgets/pyusd_components.dart';

class AnalysisModeSelector extends StatelessWidget {
  final bool isAnalyzingWallet;
  final Function(bool) onModeChanged;

  const AnalysisModeSelector({
    super.key,
    required this.isAnalyzingWallet,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PyusdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Analysis Mode',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Wallet Analysis'),
                icon: Icon(Icons.account_balance_wallet),
              ),
              ButtonSegment(
                value: false,
                label: Text('Transaction Analysis'),
                icon: Icon(Icons.receipt_long),
              ),
            ],
            selected: {isAnalyzingWallet},
            onSelectionChanged: (Set<bool> newSelection) {
              onModeChanged(newSelection.first);
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).colorScheme.primaryContainer;
                }
                return null;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).colorScheme.onPrimaryContainer;
                }
                return null;
              }),
            ),
          ),
        ],
      ),
    );
  }
}
