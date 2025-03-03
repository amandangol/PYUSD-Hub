// // File: lib/screens/analytics_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:intl/intl.dart';
// import '../providers/analytics_provider.dart';

// class AnalyticsScreen extends StatefulWidget {
//   const AnalyticsScreen({Key? key}) : super(key: key);

//   @override
//   State<AnalyticsScreen> createState() => _AnalyticsScreenState();
// }

// String _selectedNetwork = 'Ethereum';
// final List<String> _availableNetworks = [
//   'Ethereum',
//   'Solana',
//   'Avalanche',
//   'Optimism',
//   'Arbitrum'
// ];

// class _AnalyticsScreenState extends State<AnalyticsScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _refreshData();
//   }

//   Future<void> _refreshData() async {
//     final analyticsProvider =
//         Provider.of<AnalyticsProvider>(context, listen: false);
//     await analyticsProvider.fetchAnalyticsData();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('PYUSD Analytics'),
//       ),
//       body: RefreshIndicator(
//         onRefresh: _refreshData,
//         child: Consumer<AnalyticsProvider>(
//           builder: (context, analyticsProvider, child) {
//             if (analyticsProvider.isLoading) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             return SingleChildScrollView(
//               physics: const AlwaysScrollableScrollPhysics(),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Volume chart
//                   _buildVolumeChart(analyticsProvider),

//                   // Chain distribution
//                   _buildChainDistribution(analyticsProvider),

//                   // Transaction types
//                   _buildTransactionTypes(analyticsProvider),

//                   // Holder distribution
//                   _buildHolderDistribution(analyticsProvider),

//                   // Recent transactions
//                   _buildRecentTransactions(analyticsProvider),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildVolumeChart(AnalyticsProvider provider) {
//     final currencyFormat = NumberFormat.compactCurrency(
//       decimalDigits: 2,
//       symbol: '\$',
//     );

//     return Card(
//       margin: const EdgeInsets.all(16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'PYUSD Daily Transfer Volume (30 Days)',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               height: 250,
//               child: LineChart(
//                 LineChartData(
//                   gridData: FlGridData(
//                     show: true,
//                     drawVerticalLine: false,
//                   ),
//                   titlesData: FlTitlesData(
//                     show: true,
//                     rightTitles: AxisTitles(
//                       sideTitles: SideTitles(showTitles: false),
//                     ),
//                     topTitles: AxisTitles(
//                       sideTitles: SideTitles(showTitles: false),
//                     ),
//                     bottomTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         getTitlesWidget: (value, meta) {
//                           if (value.toInt() % 5 == 0) {
//                             final date = provider.dailyVolume[value.toInt()]
//                                 ['date'] as DateTime;
//                             return Padding(
//                               padding: const EdgeInsets.only(top: 8.0),
//                               child: Text(
//                                 DateFormat('MM/dd').format(date),
//                                 style: const TextStyle(fontSize: 10),
//                               ),
//                             );
//                           }
//                           return const Text('');
//                         },
//                       ),
//                     ),
//                     leftTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         getTitlesWidget: (value, meta) {
//                           return Padding(
//                             padding: const EdgeInsets.only(right: 8.0),
//                             child: Text(
//                               currencyFormat.format(value),
//                               style: const TextStyle(fontSize: 10),
//                             ),
//                           );
//                         },
//                         reservedSize: 42,
//                       ),
//                     ),
//                   ),
//                   borderData: FlBorderData(
//                     show: true,
//                     border: Border.all(color: Colors.black12),
//                   ),
//                   lineBarsData: [
//                     LineChartBarData(
//                       spots: provider.dailyVolume.asMap().entries.map((entry) {
//                         return FlSpot(
//                           entry.key.toDouble(),
//                           entry.value['volume'],
//                         );
//                       }).toList(),
//                       isCurved: true,
//                       gradient: LinearGradient(
//                         colors: [Colors.blue, Colors.purple],
//                       ),
//                       barWidth: 3,
//                       isStrokeCapRound: true,
//                       dotData: FlDotData(show: false),
//                       belowBarData: BarAreaData(
//                         show: true,
//                         gradient: LinearGradient(
//                           colors: [
//                             Colors.blue.withOpacity(0.3),
//                             Colors.purple.withOpacity(0.1),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildChainDistribution(AnalyticsProvider provider) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'PYUSD Distribution by Chain',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               height: 200,
//               child: PieChart(
//                 PieChartData(
//                   sectionsSpace: 2,
//                   centerSpaceRadius: 40,
//                   sections: provider.chainDistribution.entries.map((entry) {
//                     final index = provider.chainDistribution.keys
//                         .toList()
//                         .indexOf(entry.key);
//                     final colors = [
//                       Colors.blue,
//                       Colors.purple,
//                       Colors.orange,
//                       Colors.green,
//                       Colors.red,
//                       Colors.teal,
//                     ];
//                     return PieChartSectionData(
//                       color: colors[index % colors.length],
//                       value: entry.value,
//                       title: '${entry.key}\n${entry.value.toStringAsFixed(1)}%',
//                       radius: 80,
//                       titleStyle: const TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTransactionTypes(AnalyticsProvider provider) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'PYUSD Transactions by Type',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               height: 200,
//               child: BarChart(
//                 BarChartData(
//                   alignment: BarChartAlignment.spaceBetween,
//                   maxY: provider.txnsByType
//                           .map((e) => e['count'] as int)
//                           .reduce((a, b) => a > b ? a : b) *
//                       1.2,
//                   barGroups: provider.txnsByType.asMap().entries.map((entry) {
//                     final index = entry.key;
//                     final value = entry.value['count'] as int;
//                     return BarChartGroupData(
//                       x: index,
//                       barRods: [
//                         BarChartRodData(
//                           toY: value.toDouble(),
//                           gradient: LinearGradient(
//                             colors: [Colors.lightBlueAccent, Colors.blue],
//                             begin: Alignment.bottomCenter,
//                             end: Alignment.topCenter,
//                           ),
//                           borderRadius: const BorderRadius.only(
//                             topLeft: Radius.circular(6),
//                             topRight: Radius.circular(6),
//                           ),
//                         ),
//                       ],
//                     );
//                   }).toList(),
//                   titlesData: FlTitlesData(
//                     show: true,
//                     bottomTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         getTitlesWidget: (value, meta) {
//                           final index = value.toInt();
//                           if (index >= 0 &&
//                               index < provider.txnsByType.length) {
//                             return Padding(
//                               padding: const EdgeInsets.only(top: 8.0),
//                               child: Text(
//                                 provider.txnsByType[index]['type'] as String,
//                                 style: const TextStyle(fontSize: 10),
//                               ),
//                             );
//                           }
//                           return const Text('');
//                         },
//                       ),
//                     ),
//                     leftTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         getTitlesWidget: (value, meta) {
//                           final formatter = NumberFormat.compact();
//                           return Padding(
//                             padding: const EdgeInsets.only(right: 8.0),
//                             child: Text(
//                               formatter.format(value),
//                               style: const TextStyle(fontSize: 10),
//                             ),
//                           );
//                         },
//                         reservedSize: 36,
//                       ),
//                     ),
//                     topTitles: AxisTitles(
//                       sideTitles: SideTitles(showTitles: false),
//                     ),
//                     rightTitles: AxisTitles(
//                       sideTitles: SideTitles(showTitles: false),
//                     ),
//                   ),
//                   gridData: FlGridData(
//                     show: true,
//                     horizontalInterval: provider.txnsByType
//                             .map((e) => e['count'] as int)
//                             .reduce((a, b) => a > b ? a : b) /
//                         5,
//                     drawVerticalLine: false,
//                   ),
//                   borderData: FlBorderData(
//                     show: true,
//                     border: Border.all(color: Colors.black12),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHolderDistribution(AnalyticsProvider provider) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'PYUSD Holder Distribution',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ListView.builder(
//               physics: const NeverScrollableScrollPhysics(),
//               shrinkWrap: true,
//               itemCount: provider.holdersBySize.length,
//               itemBuilder: (context, index) {
//                 final entry = provider.holdersBySize.entries.elementAt(index);
//                 final percentage = entry.value /
//                     provider.holdersBySize.values.reduce((a, b) => a + b) *
//                     100;

//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 8.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             entry.key,
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           Text(
//                             '${NumberFormat.compact().format(entry.value)} addresses (${percentage.toStringAsFixed(1)}%)',
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 4),
//                       LinearProgressIndicator(
//                         value: percentage / 100,
//                         backgroundColor: Colors.grey.shade200,
//                         valueColor: AlwaysStoppedAnimation<Color>(
//                           HSLColor.fromAHSL(1.0, (index * 30) % 360, 0.7, 0.5)
//                               .toColor(),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRecentTransactions(AnalyticsProvider provider) {
//     final currencyFormat = NumberFormat.compactCurrency(
//       decimalDigits: 2,
//       symbol: '\$',
//     );

//     return Card(
//       margin: const EdgeInsets.all(16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Recent PYUSD Transactions',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ListView.builder(
//               physics: const NeverScrollableScrollPhysics(),
//               shrinkWrap: true,
//               itemCount: provider.recentTransactions.length > 5
//                   ? 5
//                   : provider.recentTransactions.length,
//               itemBuilder: (context, index) {
//                 final transaction = provider.recentTransactions[index];
//                 final hash = transaction['hash'] as String;
//                 final from = transaction['from'] as String;
//                 final to = transaction['to'] as String;
//                 final value = transaction['value'] as double;
//                 final timestamp = transaction['timestamp'] as DateTime;
//                 final type = transaction['type'] as String;

//                 // Determine icon based on transaction type
//                 IconData typeIcon;
//                 switch (type) {
//                   case 'Transfer':
//                     typeIcon = Icons.swap_horiz;
//                     break;
//                   case 'Bridge':
//                     typeIcon = Icons.pool;
//                     break;
//                   case 'Swap':
//                     typeIcon = Icons.swap_calls;
//                     break;
//                   case 'Mint':
//                     typeIcon = Icons.add_circle;
//                     break;
//                   case 'Burn':
//                     typeIcon = Icons.remove_circle;
//                     break;
//                   default:
//                     typeIcon = Icons.swap_horiz;
//                 }

//                 return ListTile(
//                   leading: CircleAvatar(
//                     backgroundColor:
//                         Theme.of(context).colorScheme.primaryContainer,
//                     child: Icon(typeIcon,
//                         color:
//                             Theme.of(context).colorScheme.onPrimaryContainer),
//                   ),
//                   title: Text(
//                     '${hash.substring(0, 6)}...${hash.substring(hash.length - 4)}',
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Text(
//                     'From: ${from.substring(0, 6)}...${from.substring(from.length - 4)}\n'
//                     'To: ${to.substring(0, 6)}...${to.substring(to.length - 4)}',
//                   ),
//                   trailing: Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         currencyFormat.format(value),
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       Text(
//                         DateFormat('h:mm a').format(timestamp),
//                         style: TextStyle(
//                             color: Colors.grey.shade600, fontSize: 12),
//                       ),
//                     ],
//                   ),
//                   isThreeLine: true,
//                   onTap: () {
//                     // Would open detailed transaction view
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                           content: Text(
//                               'Transaction details for ${hash.substring(0, 6)}...${hash.substring(hash.length - 4)}')),
//                     );
//                     // In a real app, you would navigate to a transaction detail page
//                     // Navigator.push(
//                     //   context,
//                     //   MaterialPageRoute(
//                     //     builder: (context) => TransactionDetailScreen(transaction: transaction),
//                     //   ),
//                     // );
//                   },
//                 );
//               },
//             ),
//             const SizedBox(height: 8),
//             Center(
//               child: TextButton.icon(
//                 icon: const Icon(Icons.list),
//                 label: const Text('View All Transactions'),
//                 onPressed: () {
//                   // Would navigate to a full transaction list screen
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                         content: Text('Navigating to all transactions')),
//                   );
//                   // In a real app, you would navigate to a transaction list page
//                   // Navigator.push(
//                   //   context,
//                   //   MaterialPageRoute(
//                   //     builder: (context) => AllTransactionsScreen(),
//                   //   ),
//                   // );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
