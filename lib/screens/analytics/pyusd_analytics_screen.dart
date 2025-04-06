import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pyusd_analytics_provider.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';
import 'package:fl_chart/fl_chart.dart';

class PyusdAnalyticsScreen extends StatefulWidget {
  const PyusdAnalyticsScreen({super.key});

  @override
  State<PyusdAnalyticsScreen> createState() => _PyusdAnalyticsScreenState();
}

class _PyusdAnalyticsScreenState extends State<PyusdAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PyusdAnalyticsProvider>().fetchAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PYUSD Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<PyusdAnalyticsProvider>().fetchAnalytics(),
          ),
        ],
      ),
      body: Consumer<PyusdAnalyticsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.error}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchAnalytics(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.dailyData.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 64,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No PYUSD transaction data available',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try refreshing or check back later',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchAnalytics(),
                    child: const Text('Refresh Data'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchAnalytics(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(provider, theme),
                  const SizedBox(height: 16),
                  _buildVolumeChart(provider, theme),
                  const SizedBox(height: 16),
                  _buildActivityTable(provider, theme),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(PyusdAnalyticsProvider provider, ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '14-Day Summary',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Volume',
                  '\$${FormatterUtils.formatNumber(provider.totalVolume)}',
                  Icons.attach_money,
                  theme,
                ),
                _buildStatItem(
                  'Transactions',
                  FormatterUtils.formatNumber(provider.totalTransactions),
                  Icons.swap_horiz,
                  theme,
                ),
                _buildStatItem(
                  'Unique Addresses',
                  FormatterUtils.formatNumber(provider.uniqueAddresses),
                  Icons.people,
                  theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, size: 32, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildVolumeChart(PyusdAnalyticsProvider provider, ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Volume',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < provider.dailyData.length &&
                              value.toInt() % 2 == 0) {
                            return Text(
                              provider.dailyData[value.toInt()].date,
                              style: theme.textTheme.bodySmall,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: provider.dailyData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.volume,
                        );
                      }).toList(),
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTable(PyusdAnalyticsProvider provider, ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Activity',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(
                    label: Text('Date', style: theme.textTheme.titleSmall),
                  ),
                  DataColumn(
                    label: Text('Volume', style: theme.textTheme.titleSmall),
                  ),
                  DataColumn(
                    label:
                        Text('Transactions', style: theme.textTheme.titleSmall),
                  ),
                  DataColumn(
                    label: Text('Unique Addresses',
                        style: theme.textTheme.titleSmall),
                  ),
                ],
                rows: provider.dailyData.map((data) {
                  return DataRow(
                    cells: [
                      DataCell(Text(data.date)),
                      DataCell(Text(
                          '\$${FormatterUtils.formatNumber(data.volume)}')),
                      DataCell(
                          Text(FormatterUtils.formatNumber(data.transactions))),
                      DataCell(Text(
                          FormatterUtils.formatNumber(data.uniqueAddresses))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
