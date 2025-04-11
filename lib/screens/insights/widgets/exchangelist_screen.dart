import 'package:flutter/material.dart';
import 'exchange_list_item.dart';

class ExchangeListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> exchanges;

  const ExchangeListScreen({
    super.key,
    required this.exchanges,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    debugPrint('Full Exchange List: ${exchanges.toString()}');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('PYUSD Exchanges'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
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
