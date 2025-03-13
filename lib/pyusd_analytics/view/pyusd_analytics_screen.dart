// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:intl/intl.dart';

// import '../model/pyusd_stats_model.dart';
// import '../provider/pyusd_analytics_provider.dart';

// class PyusdDashboardScreen extends StatefulWidget {
//   const PyusdDashboardScreen({Key? key}) : super(key: key);

//   @override
//   State<PyusdDashboardScreen> createState() => _PyusdDashboardScreenState();
// }

// class _PyusdDashboardScreenState extends State<PyusdDashboardScreen> {
//   int _selectedPeriod = 30; // Default to 30 days

//   @override
//   void initState() {
//     super.initState();
//     // Load data when the screen is first shown
//     Future.microtask(() =>
//         Provider.of<PyusdDashboardProvider>(context, listen: false)
//             .loadDashboardData());
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final provider = Provider.of<PyusdDashboardProvider>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('PYUSD Dashboard'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               provider.loadDashboardData();
//             },
//           ),
//         ],
//       ),
//       body: provider.isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : provider.error != null
//               ? Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         'Error loading data',
//                         style: theme.textTheme.titleLarge,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         provider.error!,
//                         style: theme.textTheme.bodyMedium,
//                         textAlign: TextAlign.center,
//                       ),
//                       const SizedBox(height: 16),
//                       ElevatedButton(
//                         onPressed: () => provider.loadDashboardData(),
//                         child: const Text('Retry'),
//                       ),
//                     ],
//                   ),
//                 )
//               : _buildDashboardContent(context, provider),
//     );
//   }

//   Widget _buildDashboardContent(
//       BuildContext context, PyusdDashboardProvider provider) {
//     final theme = Theme.of(context);
//     final stats = provider.stats;
//     final formatter = NumberFormat("#,##0.00", "en_US");
//     final compactFormatter = NumberFormat.compact();

//     return RefreshIndicator(
//       onRefresh: () => provider.loadDashboardData(),
//       child: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           // Header stats
//           _buildHeaderStats(context, stats, formatter),

//           const SizedBox(height: 24),

//           // Time period selector
//           _buildTimePeriodSelector(context),

//           const SizedBox(height: 24),

//           // Supply chart
//           _buildCard(
//             context,
//             title: 'PYUSD Supply',
//             child: Container(
//               height: 250,
//               padding: const EdgeInsets.all(16),
//               child: _buildSupplyChart(context, provider),
//             ),
//           ),

//           const SizedBox(height: 16),

//           // Transaction volume chart
//           _buildCard(
//             context,
//             title: 'Transaction Volume',
//             child: Container(
//               height: 250,
//               padding: const EdgeInsets.all(16),
//               child: _buildTransactionVolumeChart(context, provider),
//             ),
//           ),

//           const SizedBox(height: 16),

//           // Network metrics
//           _buildCard(
//             context,
//             title: 'Network Metrics',
//             child: _buildNetworkMetrics(context, stats),
//           ),

//           const SizedBox(height: 16),

//           // Chain distribution
//           _buildCard(
//             context,
//             title: 'Chain Distribution',
//             child: _buildChainDistribution(context, stats.adoption),
//           ),

//           const SizedBox(height: 16),

//           // Wallet type distribution
//           _buildCard(
//             context,
//             title: 'Wallet Type Distribution',
//             child: _buildWalletTypeDistribution(context, stats.adoption),
//           ),

//           const SizedBox(height: 24),

//           // Transaction stats table
//           _buildCard(
//             context,
//             title: 'Transaction Statistics',
//             child: _buildTransactionStatsTable(context, provider),
//           ),

//           const SizedBox(height: 24),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeaderStats(
//       BuildContext context, PyusdStats stats, NumberFormat formatter) {
//     final theme = Theme.of(context);

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: theme.colorScheme.primaryContainer,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'PYUSD',
//             style: theme.textTheme.headlineMedium?.copyWith(
//               color: theme.colorScheme.onPrimaryContainer,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'PayPal USD Stablecoin',
//             style: theme.textTheme.titleMedium?.copyWith(
//               color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
//             ),
//           ),
//           const SizedBox(height: 24),
//           Row(
//             children: [
//               _buildStatCard(
//                 context,
//                 'Total Supply',
//                 '\$${formatter.format(stats.totalSupply)}',
//                 Icons.attach_money,
//               ),
//               const SizedBox(width: 16),
//               _buildStatCard(
//                 context,
//                 'Price',
//                 '\$${formatter.format(stats.price)}',
//                 Icons.trending_up,
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               _buildStatCard(
//                 context,
//                 '24h Volume',
//                 '\$${formatter.format(stats.volume24h)}',
//                 Icons.swap_horiz,
//               ),
//               const SizedBox(width: 16),
//               _buildStatCard(
//                 context,
//                 'Holders',
//                 '${stats.adoption.totalHolders}',
//                 Icons.people,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard(
//       BuildContext context, String title, String value, IconData icon) {
//     final theme = Theme.of(context);

//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: theme.colorScheme.surface,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(
//                   icon,
//                   size: 20,
//                   color: theme.colorScheme.primary,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     color: theme.colorScheme.onSurface.withOpacity(0.6),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value,
//               style: theme.textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTimePeriodSelector(BuildContext context) {
//     final theme = Theme.of(context);

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surface,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           _buildPeriodButton(context, 7, '7D'),
//           _buildPeriodButton(context, 30, '30D'),
//           _buildPeriodButton(context, 90, '90D'),
//           _buildPeriodButton(context, 365, '1Y'),
//           _buildPeriodButton(context, 0, 'All'),
//         ],
//       ),
//     );
//   }

//   Widget _buildPeriodButton(BuildContext context, int days, String label) {
//     final theme = Theme.of(context);
//     final isSelected = _selectedPeriod == days;

//     return TextButton(
//       onPressed: () {
//         setState(() {
//           _selectedPeriod = days;
//         });
//       },
//       style: TextButton.styleFrom(
//         backgroundColor: isSelected ? theme.colorScheme.primary : null,
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//       child: Text(
//         label,
//         style: theme.textTheme.labelMedium?.copyWith(
//           color: isSelected
//               ? theme.colorScheme.onPrimary
//               : theme.colorScheme.primary,
//           fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//         ),
//       ),
//     );
//   }

//   Widget _buildCard(BuildContext context,
//       {required String title, required Widget child}) {
//     final theme = Theme.of(context);

//     return Container(
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surface,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Text(
//               title,
//               style: theme.textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: theme.colorScheme.onSurface,
//               ),
//             ),
//           ),
//           const Divider(height: 1),
//           child,
//         ],
//       ),
//     );
//   }

//   Widget _buildSupplyChart(
//       BuildContext context, PyusdDashboardProvider provider) {
//     final theme = Theme.of(context);
//     final supplyData = _selectedPeriod == 0
//         ? provider.stats.supplyHistory
//         : provider.getSupplyHistoryForPeriod(_selectedPeriod);

//     if (supplyData.isEmpty) {
//       return const Center(child: Text('No data available'));
//     }

//     // Calculate min and max values for better chart scaling
//     final minY =
//         supplyData.map((point) => point.value).reduce((a, b) => a < b ? a : b) *
//             0.95;
//     final maxY =
//         supplyData.map((point) => point.value).reduce((a, b) => a > b ? a : b) *
//             1.05;

//     return LineChart(
//       LineChartData(
//         gridData: FlGridData(
//           show: true,
//           drawVerticalLine: true,
//           getDrawingHorizontalLine: (value) {
//             return FlLine(
//               color: theme.colorScheme.onSurface.withOpacity(0.1),
//               strokeWidth: 1,
//             );
//           },
//           getDrawingVerticalLine: (value) {
//             return FlLine(
//               color: theme.colorScheme.onSurface.withOpacity(0.1),
//               strokeWidth: 1,
//             );
//           },
//         ),
//         titlesData: FlTitlesData(
//           show: true,
//           rightTitles: AxisTitles(
//             sideTitles: SideTitles(showTitles: false),
//           ),
//           topTitles: AxisTitles(
//             sideTitles: SideTitles(showTitles: false),
//           ),
//           bottomTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               reservedSize: 30,
//               interval: supplyData.length > 30 ? supplyData.length / 5 : 1,
//               getTitlesWidget: (value, meta) {
//                 if (value.toInt() >= 0 && value.toInt() < supplyData.length) {
//                   final date = supplyData[value.toInt()].timestamp;
//                   return Padding(
//                     padding: const EdgeInsets.only(top: 8.0),
//                     child: Text(
//                       DateFormat('MM/dd').format(date),
//                       style: theme.textTheme.bodySmall?.copyWith(
//                         color: theme.colorScheme.onSurface.withOpacity(0.6),
//                       ),
//                     ),
//                   );
//                 }
//                 return const SizedBox();
//               },
//             ),
//           ),
//           leftTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               interval: (maxY - minY) / 5,
//               getTitlesWidget: (value, meta) {
//                 final formatter = NumberFormat.compact();
//                 return Text(
//                   formatter.format(value),
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     color: theme.colorScheme.onSurface.withOpacity(0.6),
//                   ),
//                 );
//               },
//               reservedSize: 42,
//             ),
//           ),
//         ),
//         borderData: FlBorderData(
//           show: true,
//           border: Border.all(
//             color: theme.colorScheme.onSurface.withOpacity(0.1),
//             width: 1,
//           ),
//         ),
//         minX: 0,
//         maxX: supplyData.length - 1,
//         minY: minY,
//         maxY: maxY,
//         lineBarsData: [
//           LineChartBarData(
//             spots: List.generate(supplyData.length, (index) {
//               return FlSpot(index.toDouble(), supplyData[index].value);
//             }),
//             isCurved: true,
//             gradient: LinearGradient(
//               colors: [
//                 theme.colorScheme.primary,
//                 theme.colorScheme.secondary,
//               ],
//             ),
//             barWidth: 3,
//             isStrokeCapRound: true,
//             dotData: FlDotData(
//               show: false,
//             ),
//             belowBarData: BarAreaData(
//               show: true,
//               gradient: LinearGradient(
//                 colors: [
//                   theme.colorScheme.primary.withOpacity(0.3),
//                   theme.colorScheme.secondary.withOpacity(0.0),
//                 ],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTransactionVolumeChart(
//       BuildContext context, PyusdDashboardProvider provider) {
//     final theme = Theme.of(context);
//     final transactionStats = _selectedPeriod == 0
//         ? provider.stats.transactionStats
//         : provider.getTransactionStatsForPeriod(_selectedPeriod);

//     if (transactionStats.isEmpty) {
//       return const Center(child: Text('No data available'));
//     }

//     // Sort by date
//     final sortedStats = List<TransactionStat>.from(transactionStats)
//       ..sort((a, b) => a.date.compareTo(b.date));

//     // Calculate min and max values for better chart scaling
//     final minY =
//         sortedStats.map((stat) => stat.volume).reduce((a, b) => a < b ? a : b) *
//             0.95;
//     final maxY =
//         sortedStats.map((stat) => stat.volume).reduce((a, b) => a > b ? a : b) *
//             1.05;

//     return LineChart(
//       LineChartData(
//         gridData: FlGridData(
//           show: true,
//           drawVerticalLine: true,
//           getDrawingHorizontalLine: (value) {
//             return FlLine(
//               color: theme.colorScheme.onSurface.withOpacity(0.1),
//               strokeWidth: 1,
//             );
//           },
//           getDrawingVerticalLine: (value) {
//             return FlLine(
//               color: theme.colorScheme.onSurface.withOpacity(0.1),
//               strokeWidth: 1,
//             );
//           },
//         ),
//         titlesData: FlTitlesData(
//           show: true,
//           rightTitles: AxisTitles(
//             sideTitles: SideTitles(showTitles: false),
//           ),
//           topTitles: AxisTitles(
//             sideTitles: SideTitles(showTitles: false),
//           ),
//           bottomTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               reservedSize: 30,
//               interval: sortedStats.length > 30 ? sortedStats.length / 5 : 1,
//               getTitlesWidget: (value, meta) {
//                 if (value.toInt() >= 0 && value.toInt() < sortedStats.length) {
//                   final date = sortedStats[value.toInt()].date;
//                   return Padding(
//                     padding: const EdgeInsets.only(top: 8.0),
//                     child: Text(
//                       DateFormat('MM/dd').format(date),
//                       style: theme.textTheme.bodySmall?.copyWith(
//                         color: theme.colorScheme.onSurface.withOpacity(0.6),
//                       ),
//                     ),
//                   );
//                 }
//                 return const SizedBox();
//               },
//             ),
//           ),
//           leftTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               interval: (maxY - minY) / 5,
//               getTitlesWidget: (value, meta) {
//                 final formatter = NumberFormat.compact();
//                 return Text(
//                   formatter.format(value),
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     color: theme.colorScheme.onSurface.withOpacity(0.6),
//                   ),
//                 );
//               },
//               reservedSize: 42,
//             ),
//           ),
//         ),
//         borderData: FlBorderData(
//           show: true,
//           border: Border.all(
//             color: theme.colorScheme.onSurface.withOpacity(0.1),
//             width: 1,
//           ),
//         ),
//         minX: 0,
//         maxX: sortedStats.length - 1,
//         minY: minY,
//         maxY: maxY,
//         lineBarsData: [
//           LineChartBarData(
//             spots: List.generate(sortedStats.length, (index) {
//               return FlSpot(index.toDouble(), sortedStats[index].volume);
//             }),
//             isCurved: true,
//             gradient: LinearGradient(
//               colors: [
//                 theme.colorScheme.secondary,
//                 theme.colorScheme.tertiary,
//               ],
//             ),
//             barWidth: 3,
//             isStrokeCapRound: true,
//             dotData: FlDotData(
//               show: false,
//             ),
//             belowBarData: BarAreaData(
//               show: true,
//               gradient: LinearGradient(
//                 colors: [
//                   theme.colorScheme.secondary.withOpacity(0.3),
//                   theme.colorScheme.tertiary.withOpacity(0.0),
//                 ],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNetworkMetrics(BuildContext context, PyusdStats stats) {
//     final theme = Theme.of(context);
//     final metrics = stats.networkMetrics;

//     if (metrics.isEmpty) {
//       return const Padding(
//         padding: EdgeInsets.all(16),
//         child: Center(child: Text('No metrics available')),
//       );
//     }

//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: metrics.map((metric) {
//           return Padding(
//             padding: const EdgeInsets.only(bottom: 16),
//             child: Row(
//               children: [
//                 Expanded(
//                   flex: 3,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         metric.name,
//                         style: theme.textTheme.titleSmall,
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         metric.description,
//                         style: theme.textTheme.bodySmall?.copyWith(
//                           color: theme.colorScheme.onSurface.withOpacity(0.6),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   flex: 2,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Text(
//                         NumberFormat.compact().format(metric.value),
//                         style: theme.textTheme.titleMedium?.copyWith(
//                           fontWeight: FontWeight.bold,
//                           color: theme.colorScheme.primary,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         metric.unit,
//                         style: theme.textTheme.bodySmall?.copyWith(
//                           color: theme.colorScheme.onSurface.withOpacity(0.6),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   Widget _buildChainDistribution(BuildContext context, PyusdAdoption adoption) {
//     final theme = Theme.of(context);
//     final chainDistribution = adoption.chainDistribution;

//     if (chainDistribution.isEmpty) {
//       return const Padding(
//         padding: EdgeInsets.all(16),
//         child: Center(child: Text('No chain distribution data available')),
//       );
//     }

//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           SizedBox(
//             height: 200,
//             child: PieChart(
//               PieChartData(
//                 sections: chainDistribution.map((chain) {
//                   final index = chainDistribution.indexOf(chain);
//                   final colors = [
//                     Colors.blue,
//                     Colors.purple,
//                     Colors.green,
//                     Colors.orange,
//                     Colors.red,
//                   ];

//                   return PieChartSectionData(
//                     color: colors[index % colors.length],
//                     value: chain.percentage,
//                     title: '${chain.percentage.round()}%',
//                     radius: 100,
//                     titleStyle: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   );
//                 }).toList(),
//                 sectionsSpace: 2,
//                 centerSpaceRadius: 40,
//                 startDegreeOffset: -90,
//               ),
//             ),
//           ),
//           const SizedBox(height: 24),
//           Column(
//             children: chainDistribution.map((chain) {
//               final index = chainDistribution.indexOf(chain);
//               final colors = [
//                 Colors.blue,
//                 Colors.purple,
//                 Colors.green,
//                 Colors.orange,
//                 Colors.red,
//               ];

//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 12),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 16,
//                       height: 16,
//                       decoration: BoxDecoration(
//                         color: colors[index % colors.length],
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         chain.chainName,
//                         style: theme.textTheme.bodyMedium,
//                       ),
//                     ),
//                     Text(
//                       '${chain.percentage.round()}%',
//                       style: theme.textTheme.bodyMedium,
//                     ),
//                     const SizedBox(width: 16),
//                     Text(
//                       NumberFormat.compact().format(chain.amount),
//                       style: theme.textTheme.bodyMedium?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }).toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildWalletTypeDistribution(
//       BuildContext context, PyusdAdoption adoption) {
//     final theme = Theme.of(context);
//     final walletTypes = adoption.walletTypeDistribution;

//     if (walletTypes.isEmpty) {
//       return const Padding(
//         padding: EdgeInsets.all(16),
//         child: Center(child: Text('No wallet distribution data available')),
//       );
//     }

//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           SizedBox(
//             height: 200,
//             child: PieChart(
//               PieChartData(
//                 sections: walletTypes.map((wallet) {
//                   final index = walletTypes.indexOf(wallet);
//                   final colors = [
//                     Colors.amber,
//                     Colors.teal,
//                     Colors.pink,
//                     Colors.cyan,
//                     Colors.indigo,
//                   ];

//                   return PieChartSectionData(
//                     color: colors[index % colors.length],
//                     value: wallet.percentage,
//                     title: '${wallet.percentage.round()}%',
//                     radius: 100,
//                     titleStyle: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   );
//                 }).toList(),
//                 sectionsSpace: 2,
//                 centerSpaceRadius: 40,
//                 startDegreeOffset: -90,
//               ),
//             ),
//           ),
//           const SizedBox(height: 24),
//           Column(
//             children: walletTypes.map((wallet) {
//               final index = walletTypes.indexOf(wallet);
//               final colors = [
//                 Colors.amber,
//                 Colors.teal,
//                 Colors.pink,
//                 Colors.cyan,
//                 Colors.indigo,
//               ];

//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 12),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 16,
//                       height: 16,
//                       decoration: BoxDecoration(
//                         color: colors[index % colors.length],
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         wallet.walletType,
//                         style: theme.textTheme.bodyMedium,
//                       ),
//                     ),
//                     Text(
//                       '${wallet.percentage.round()}%',
//                       style: theme.textTheme.bodyMedium,
//                     ),
//                     const SizedBox(width: 16),
//                     Text(
//                       NumberFormat.compact().format(wallet.count),
//                       style: theme.textTheme.bodyMedium?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }).toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTransactionStatsTable(
//       BuildContext context, PyusdDashboardProvider provider) {
//     final theme = Theme.of(context);
//     final transactionStats = _selectedPeriod == 0
//         ? provider.stats.transactionStats
//         : provider.getTransactionStatsForPeriod(_selectedPeriod);

//     if (transactionStats.isEmpty) {
//       return const Padding(
//         padding: EdgeInsets.all(16),
//         child: Center(child: Text('No transaction data available')),
//       );
//     }

//     // Sort by date (most recent first)
//     final sortedStats = List<TransactionStat>.from(transactionStats)
//       ..sort((a, b) => b.date.compareTo(a.date));

//     // Limit to last 10 days
//     final limitedStats = sortedStats.take(10).toList();

//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: DataTable(
//         columnSpacing: 16,
//         columns: [
//           DataColumn(
//             label: Text(
//               'Date',
//               style: theme.textTheme.titleSmall,
//             ),
//           ),
//           DataColumn(
//             label: Text(
//               'Transactions',
//               style: theme.textTheme.titleSmall,
//             ),
//           ),
//           DataColumn(
//             label: Text(
//               'Volume',
//               style: theme.textTheme.titleSmall,
//             ),
//           ),
//           DataColumn(
//             label: Text(
//               'Avg Gas (gwei)',
//               style: theme.textTheme.titleSmall,
//             ),
//           ),
//         ],
//         rows: limitedStats.map((stat) {
//           return DataRow(
//             cells: [
//               DataCell(
//                 Text(
//                   DateFormat('MM/dd/yyyy').format(stat.date),
//                   style: theme.textTheme.bodyMedium,
//                 ),
//               ),
//               DataCell(
//                 Text(
//                   NumberFormat.compact().format(stat.count),
//                   style: theme.textTheme.bodyMedium,
//                 ),
//               ),
//               DataCell(
//                 Text(
//                   '\$${NumberFormat.compact().format(stat.volume)}',
//                   style: theme.textTheme.bodyMedium,
//                 ),
//               ),
//               DataCell(
//                 Text(
//                   NumberFormat('0.0').format(stat.avgGasPrice),
//                   style: theme.textTheme.bodyMedium,
//                 ),
//               ),
//             ],
//           );
//         }).toList(),
//       ),
//     );
//   }
// }
