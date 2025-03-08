// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'provider/pyusd_analytics_provider.dart';
// import 'widgets/metric_card.dart';

// class PYUSDDashboardScreen extends StatefulWidget {
//   const PYUSDDashboardScreen({Key? key}) : super(key: key);

//   @override
//   State<PYUSDDashboardScreen> createState() => _PYUSDDashboardScreenState();
// }

// class _PYUSDDashboardScreenState extends State<PYUSDDashboardScreen> {
//   bool _isLoading = true;
//   String _timeRange = '7d'; // Default time range

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   Future<void> _loadData() async {
//     final provider =
//         Provider.of<PYUSDAnalyticsProvider>(context, listen: false);
//     setState(() => _isLoading = true);
//     await provider.fetchDashboardData(_timeRange);
//     setState(() => _isLoading = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final provider = Provider.of<PYUSDAnalyticsProvider>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('PYUSD Dashboard'),
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadData,
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : RefreshIndicator(
//               onRefresh: _loadData,
//               child: SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Time range selector
//                     _buildTimeRangeSelector(theme),
//                     const SizedBox(height: 16),

//                     // Key metrics
//                     _buildKeyMetricsSection(provider, theme),
//                     const SizedBox(height: 24),

//                     // Supply metrics
//                     Text('PYUSD Supply', style: theme.textTheme.titleLarge),
//                     const SizedBox(height: 8),
//                     _buildSupplyMetrics(provider, theme),
//                     const SizedBox(height: 24),

//                     // Transaction activity
//                     Text('Transaction Activity',
//                         style: theme.textTheme.titleLarge),
//                     const SizedBox(height: 8),
//                     _buildTransactionActivityChart(provider, theme),
//                     const SizedBox(height: 24),

//                     // Network distribution
//                     Text('Network Distribution',
//                         style: theme.textTheme.titleLarge),
//                     const SizedBox(height: 8),
//                     _buildNetworkDistribution(provider, theme),
//                     const SizedBox(height: 24),

//                     // PYUSD Facts
//                     Text('PYUSD Facts', style: theme.textTheme.titleLarge),
//                     const SizedBox(height: 8),
//                     _buildPYUSDFacts(provider, theme),
//                     const SizedBox(height: 16),

//                     // Data source attribution
//                     Text(
//                       'Data provided by Google Cloud Blockchain RPC & BigQuery',
//                       style: theme.textTheme.bodySmall?.copyWith(
//                         color: theme.colorScheme.onSurface.withOpacity(0.6),
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }

//   Widget _buildTimeRangeSelector(ThemeData theme) {
//     return Container(
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surface,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
//       ),
//       child: Row(
//         children: [
//           _timeRangeButton('24h', theme),
//           _timeRangeButton('7d', theme),
//           _timeRangeButton('30d', theme),
//           _timeRangeButton('90d', theme),
//           _timeRangeButton('1y', theme),
//           _timeRangeButton('All', theme),
//         ],
//       ),
//     );
//   }

//   Widget _timeRangeButton(String range, ThemeData theme) {
//     final isSelected = _timeRange == range;
//     return Expanded(
//       child: GestureDetector(
//         onTap: () {
//           if (_timeRange != range) {
//             setState(() => _timeRange = range);
//             _loadData();
//           }
//         },
//         child: Container(
//           alignment: Alignment.center,
//           padding: const EdgeInsets.symmetric(vertical: 8),
//           decoration: BoxDecoration(
//             color: isSelected ? theme.colorScheme.primary : Colors.transparent,
//             borderRadius: BorderRadius.circular(6),
//           ),
//           child: Text(
//             range,
//             style: TextStyle(
//               color: isSelected
//                   ? theme.colorScheme.onPrimary
//                   : theme.colorScheme.onSurface,
//               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildKeyMetricsSection(
//       PYUSDAnalyticsProvider provider, ThemeData theme) {
//     final format = NumberFormat.compact();

//     return GridView.count(
//       crossAxisCount: 2,
//       crossAxisSpacing: 16,
//       mainAxisSpacing: 16,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       children: [
//         MetricCard(
//           title: 'Total Supply',
//           value: '\$${format.format(provider.totalSupply)}',
//           change: provider.supplyChangePercentage,
//           icon: Icons.account_balance,
//           theme: theme,
//         ),
//         MetricCard(
//           title: 'Holders',
//           value: format.format(provider.totalHolders),
//           change: provider.holdersChangePercentage,
//           icon: Icons.people,
//           theme: theme,
//         ),
//         MetricCard(
//           title: '24h Volume',
//           value: '\$${format.format(provider.volume24h)}',
//           change: provider.volumeChangePercentage,
//           icon: Icons.swap_horiz,
//           theme: theme,
//         ),
//         MetricCard(
//           title: 'Transactions',
//           value: format.format(provider.totalTransactions),
//           change: provider.transactionsChangePercentage,
//           icon: Icons.receipt_long,
//           theme: theme,
//         ),
//       ],
//     );
//   }

//   Widget _buildSupplyMetrics(PYUSDAnalyticsProvider provider, ThemeData theme) {
//     return ChartCard(
//       theme: theme,
//       height: 240,
//       child: Column(
//         children: [
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.only(top: 16, right: 16),
//               child: LineChart(
//                 LineChartData(
//                   gridData: FlGridData(show: false),
//                   titlesData: FlTitlesData(show: false),
//                   borderData: FlBorderData(show: false),
//                   lineBarsData: [
//                     LineChartBarData(
//                       spots:
//                           provider.supplyHistory.asMap().entries.map((entry) {
//                         return FlSpot(entry.key.toDouble(), entry.value);
//                       }).toList(),
//                       isCurved: true,
//                       color: theme.colorScheme.primary,
//                       barWidth: 3,
//                       isStrokeCapRound: true,
//                       dotData: FlDotData(show: false),
//                       belowBarData: BarAreaData(
//                         show: true,
//                         color: theme.colorScheme.primary.withOpacity(0.2),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: provider.supplyLabels
//                   .map((label) => Text(label, style: theme.textTheme.bodySmall))
//                   .toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTransactionActivityChart(
//       PYUSDAnalyticsProvider provider, ThemeData theme) {
//     return ChartCard(
//       theme: theme,
//       height: 240,
//       child: Column(
//         children: [
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.only(top: 16, right: 16),
//               child: BarChart(
//                 BarChartData(
//                   alignment: BarChartAlignment.spaceAround,
//                   gridData: FlGridData(show: false),
//                   titlesData: FlTitlesData(
//                     bottomTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         getTitlesWidget: (value, meta) {
//                           if (value.toInt() >= 0 &&
//                               value.toInt() <
//                                   provider.transactionLabels.length) {
//                             return Padding(
//                               padding: const EdgeInsets.only(top: 8.0),
//                               child: Text(
//                                 provider.transactionLabels[value.toInt()],
//                                 style: theme.textTheme.bodySmall,
//                               ),
//                             );
//                           }
//                           return const SizedBox();
//                         },
//                         reservedSize: 30,
//                       ),
//                     ),
//                     leftTitles:
//                         AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                     topTitles:
//                         AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                     rightTitles:
//                         AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                   ),
//                   borderData: FlBorderData(show: false),
//                   barGroups:
//                       provider.transactionData.asMap().entries.map((entry) {
//                     return BarChartGroupData(
//                       x: entry.key,
//                       barRods: [
//                         BarChartRodData(
//                           toY: entry.value,
//                           color: theme.colorScheme.primary,
//                           width: 18,
//                           borderRadius: const BorderRadius.only(
//                             topLeft: Radius.circular(4),
//                             topRight: Radius.circular(4),
//                           ),
//                         ),
//                       ],
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNetworkDistribution(
//       PYUSDAnalyticsProvider provider, ThemeData theme) {
//     return ChartCard(
//       theme: theme,
//       height: 280,
//       child: Column(
//         children: [
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: PieChart(
//                 PieChartData(
//                   sectionsSpace: 2,
//                   centerSpaceRadius: 40,
//                   sections:
//                       provider.networkDistribution.asMap().entries.map((entry) {
//                     final colors = [
//                       theme.colorScheme.primary,
//                       theme.colorScheme.tertiary,
//                       theme.colorScheme.secondary,
//                       theme.colorScheme.error,
//                       Colors.amber,
//                     ];

//                     return PieChartSectionData(
//                       color: colors[entry.key % colors.length],
//                       value: entry.value.percentage,
//                       title: '${entry.value.percentage.toStringAsFixed(1)}%',
//                       radius: 100,
//                       titleStyle: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: theme.colorScheme.onPrimary,
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               alignment: WrapAlignment.center,
//               children:
//                   provider.networkDistribution.asMap().entries.map((entry) {
//                 final colors = [
//                   theme.colorScheme.primary,
//                   theme.colorScheme.tertiary,
//                   theme.colorScheme.secondary,
//                   theme.colorScheme.error,
//                   Colors.amber,
//                 ];

//                 return Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Container(
//                       width: 12,
//                       height: 12,
//                       decoration: BoxDecoration(
//                         color: colors[entry.key % colors.length],
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       entry.value.network,
//                       style: theme.textTheme.bodySmall,
//                     ),
//                   ],
//                 );
//               }).toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPYUSDFacts(PYUSDAnalyticsProvider provider, ThemeData theme) {
//     return ListView.separated(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: provider.pyusdFacts.length,
//       separatorBuilder: (context, index) => const SizedBox(height: 8),
//       itemBuilder: (context, index) {
//         final fact = provider.pyusdFacts[index];
//         return FactCard(
//           fact: fact,
//           theme: theme,
//         );
//       },
//     );
//   }
// }
