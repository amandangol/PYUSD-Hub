// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';

// import '../provider/pyusd_analytics_provider.dart';

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // Initialize data loading when the app starts
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final dataProvider =
//           Provider.of<PyusdDataProvider>(context, listen: false);
//       dataProvider.initializeData();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('PYUSD Dashboard'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               Provider.of<PyusdDataProvider>(context, listen: false)
//                   .refreshData();
//             },
//           ),
//         ],
//       ),
//       body: Consumer<PyusdDataProvider>(
//         builder: (context, dataProvider, child) {
//           if (dataProvider.isLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           return RefreshIndicator(
//             onRefresh: () async {
//               await Provider.of<PyusdDataProvider>(context, listen: false)
//                   .refreshData();
//             },
//             child: SingleChildScrollView(
//               physics: const AlwaysScrollableScrollPhysics(),
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildSummaryCards(dataProvider),
//                   const SizedBox(height: 24),
//                   _buildSupplyGraph(dataProvider),
//                   const SizedBox(height: 24),
//                   _buildHoldersDistribution(dataProvider),
//                   const SizedBox(height: 24),
//                   _buildRecentTransactions(dataProvider),
//                   const SizedBox(height: 24),
//                   _buildNetworkImpact(dataProvider),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildSummaryCards(PyusdDataProvider dataProvider) {
//     final formatter = NumberFormat("#,###");

//     return GridView.count(
//       crossAxisCount: 2,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       mainAxisSpacing: 16,
//       crossAxisSpacing: 16,
//       childAspectRatio: 1.5,
//       children: [
//         _buildMetricCard(
//           'Total Supply',
//           '${formatter.format(dataProvider.totalSupply)} PYUSD',
//           Icons.account_balance,
//         ),
//         _buildMetricCard(
//           'Market Cap',
//           '\$${formatter.format(dataProvider.marketCap)}',
//           Icons.attach_money,
//         ),
//         _buildMetricCard(
//           'Holders',
//           formatter.format(dataProvider.totalHolders),
//           Icons.people,
//         ),
//         _buildMetricCard(
//           '24h Volume',
//           '\$${formatter.format(dataProvider.volume24h)}',
//           Icons.swap_horiz,
//         ),
//       ],
//     );
//   }

//   Widget _buildMetricCard(String title, String value, IconData icon) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, size: 24),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSupplyGraph(PyusdDataProvider dataProvider) {
//     // Extract supply data from the supplyHistory list of maps
//     // We'll use netChange to calculate a running total
//     double runningTotal = dataProvider.totalSupply;
//     final supplyData = <double>[];

//     // Calculate supply backwards using netChange
//     for (int i = dataProvider.supplyHistory.length - 1; i >= 0; i--) {
//       final entry = dataProvider.supplyHistory[i];
//       runningTotal -= entry['netChange'] as double;
//       supplyData.insert(0, runningTotal);
//     }

//     // Add current total supply
//     supplyData.add(dataProvider.totalSupply);

//     // Ensure we have data
//     if (supplyData.isEmpty) {
//       supplyData.add(dataProvider.totalSupply);
//     }

//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'PYUSD Supply Growth',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               height: 200,
//               child: LineChart(
//                 LineChartData(
//                   gridData: FlGridData(show: true),
//                   titlesData: FlTitlesData(
//                     leftTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         reservedSize: 40,
//                       ),
//                     ),
//                     bottomTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         reservedSize: 30,
//                       ),
//                     ),
//                     rightTitles: AxisTitles(
//                       sideTitles: SideTitles(showTitles: false),
//                     ),
//                     topTitles: AxisTitles(
//                       sideTitles: SideTitles(showTitles: false),
//                     ),
//                   ),
//                   borderData: FlBorderData(show: true),
//                   minX: 0,
//                   maxX: supplyData.length.toDouble() - 1,
//                   minY: supplyData.isEmpty
//                       ? 0
//                       : supplyData.reduce((a, b) => a < b ? a : b) * 0.9,
//                   maxY: supplyData.isEmpty
//                       ? 1
//                       : supplyData.reduce((a, b) => a > b ? a : b) * 1.1,
//                   lineBarsData: [
//                     LineChartBarData(
//                       spots: List.generate(
//                         supplyData.length,
//                         (index) => FlSpot(
//                           index.toDouble(),
//                           supplyData[index],
//                         ),
//                       ),
//                       isCurved: true,
//                       color: Colors.green,
//                       barWidth: 2,
//                       isStrokeCapRound: true,
//                       dotData: FlDotData(show: false),
//                       belowBarData: BarAreaData(
//                         show: true,
//                         color: Colors.green.withOpacity(0.3),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//                 'Growth rate: ${dataProvider.supplyGrowthRate.toStringAsFixed(2)}% (30d)'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHoldersDistribution(PyusdDataProvider dataProvider) {
//     // Prepare data for the pie chart
//     final sections = <PieChartSectionData>[];

//     // Define colors for different categories
//     final categoryColors = {
//       'exchange': Colors.blue,
//       'treasury': Colors.green,
//       'whale': Colors.orange,
//       'individual': Colors.purple,
//     };

//     // Add sections for each category in the holder distribution
//     dataProvider.holderDistribution.forEach((category, percentage) {
//       sections.add(
//         PieChartSectionData(
//           value: percentage,
//           title: _capitalizeFirstLetter(category),
//           color: categoryColors[category] ?? Colors.grey,
//           radius: 80,
//           titleStyle: const TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//       );
//     });

//     // If no data, show placeholder
//     if (sections.isEmpty) {
//       sections.add(
//         PieChartSectionData(
//           value: 100,
//           title: 'No Data',
//           color: Colors.grey,
//           radius: 80,
//         ),
//       );
//     }

//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Holder Distribution',
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
//                   sections: sections,
//                   sectionsSpace: 2,
//                   centerSpaceRadius: 40,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _capitalizeFirstLetter(String text) {
//     if (text.isEmpty) return text;
//     return text[0].toUpperCase() + text.substring(1);
//   }

//   Widget _buildRecentTransactions(PyusdDataProvider dataProvider) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Recent Transactions',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ListView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: dataProvider.recentTransactions.length,
//               itemBuilder: (context, index) {
//                 final tx = dataProvider.recentTransactions[index];

//                 // Calculate time passed since transaction
//                 // If tx has blockNumber, we can calculate relative time
//                 String timeDisplay = tx['time'] ?? 'Recent';
//                 if (timeDisplay == null && tx.containsKey('blockNumber')) {
//                   // Logic to calculate time based on block number if needed
//                   timeDisplay = 'Recent';
//                 }

//                 return ListTile(
//                   title: Text(
//                     '${tx['amount']} PYUSD',
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Text(
//                     '${_shortenAddress(tx['from'])} → ${_shortenAddress(tx['to'])}',
//                   ),
//                   trailing: Text(timeDisplay),
//                   onTap: () {
//                     // Optional: Add functionality to open the transaction in a block explorer
//                     if (tx.containsKey('txHash')) {
//                       // Launch URL to view transaction details
//                       launchUrl(
//                           Uri.parse('https://etherscan.io/tx/${tx['txHash']}'));
//                     }
//                   },
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNetworkImpact(PyusdDataProvider dataProvider) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Network Impact',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildNetworkMetricRow(
//               'Gas Used (24h)',
//               '${dataProvider.networkMetrics['gasUsed24h']} ETH',
//             ),
//             _buildNetworkMetricRow(
//               'Transactions (24h)',
//               dataProvider.networkMetrics['txCount24h'].toString(),
//             ),
//             _buildNetworkMetricRow(
//               'Avg TX fee',
//               '${dataProvider.networkMetrics['avgTxFee']} ETH',
//             ),
//             _buildNetworkMetricRow(
//               'ETH Network %',
//               '${dataProvider.networkMetrics['networkPercentage']}%',
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNetworkMetricRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 16,
//             ),
//           ),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _shortenAddress(String address) {
//     if (address.length < 10) return address;
//     return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
//   }
// }
