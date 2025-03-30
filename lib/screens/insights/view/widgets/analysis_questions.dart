import 'package:flutter/material.dart';
import '../../../../widgets/pyusd_components.dart';

class AnalysisQuestions extends StatelessWidget {
  final bool isAnalyzingWallet;
  final String? selectedQuestion;
  final TextEditingController queryController;
  final Function(String?) onQuestionSelected;

  const AnalysisQuestions({
    super.key,
    required this.isAnalyzingWallet,
    required this.selectedQuestion,
    required this.queryController,
    required this.onQuestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final questions = isAnalyzingWallet
        ? _builtInQuestions['Wallet Analysis']!
        : _builtInQuestions['Transaction Analysis']!;

    return PyusdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.question_answer,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Analysis Questions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedQuestion,
            decoration: InputDecoration(
              hintText: 'Select a question',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.help_outline),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Custom Question'),
              ),
              ...questions.map((question) => DropdownMenuItem(
                    value: question,
                    child: Text(
                      question,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
            ],
            onChanged: onQuestionSelected,
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: selectedQuestion == null
                ? PyusdTextField(
                    controller: queryController,
                    labelText: isAnalyzingWallet
                        ? 'Ask your own question about this wallet...'
                        : 'Ask your own question about this transaction...',
                    hintText: 'Type your question here...',
                    prefixIcon: const Icon(Icons.edit),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // Built-in questions for transaction analysis
  static const Map<String, List<String>> _builtInQuestions = {
    'Transaction Analysis': [
      'What happened in this transaction?',
      'Is this a token transfer? If so, what token and amount?',
      'Was this transaction successful? If not, why did it fail?',
      'What was the gas cost of this transaction?',
      'Is this a contract interaction? What method was called?',
      'Are there any suspicious patterns in this transaction?',
      'What was the USD value of this transaction at the time?',
      'Compare this gas price to the network average at that time',
    ],
    'Wallet Analysis': [
      'What are the most common tokens in this wallet?',
      'Show me the largest transactions in this wallet',
      'Are there any recurring patterns in this wallet\'s activity?',
      'What DeFi protocols has this wallet interacted with?',
      'Show me all PYUSD transactions for this wallet',
      'What\'s the total value of transactions in this wallet?',
      'Are there any suspicious or unusual transactions?',
      'What\'s the most active period for this wallet?',
    ],
  };
}
