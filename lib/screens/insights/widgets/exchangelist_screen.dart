import 'package:flutter/material.dart';
import 'exchange_list_item.dart';

class ExchangeListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> exchanges;

  const ExchangeListScreen({
    Key? key,
    required this.exchanges,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    debugPrint('Full Exchange List: ${exchanges.toString()}');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('PYUSD Exchanges'),
        elevation: 0,
      ),
      body: exchanges.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business,
                    size: 64,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No exchange data available',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: exchanges.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return ExchangeListItem(exchange: exchanges[index]);
              },
            ),
    );
  }
}
