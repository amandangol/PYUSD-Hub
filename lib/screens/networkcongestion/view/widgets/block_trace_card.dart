// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../../utils/formatter_utils.dart';
// import '../../provider/network_congestion_provider.dart';

// class BlockTraceCard extends StatelessWidget {
//   final String blockHash;

//   const BlockTraceCard({
//     Key? key,
//     required this.blockHash,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<NetworkCongestionProvider>(
//       builder: (context, provider, child) {
//         final analysis = provider.analyzeBlockTrace(blockHash);
//         if (analysis.isEmpty) {
//           return Card(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   const Text('Block Trace Analysis'),
//                   const SizedBox(height: 8),
//                   ElevatedButton(
//                     onPressed: () => provider.fetchBlockTrace(blockHash),
//                     child: const Text('Load Block Trace'),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }

//         return Card(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Block Trace Analysis',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 _buildTransactionStats(analysis),
//                 const SizedBox(height: 16),
//                 _buildGasUsageStats(analysis),
//                 const SizedBox(height: 16),
//                 _buildErrorTypes(analysis),
//                 const SizedBox(height: 16),
//                 _buildTopGasUsers(analysis),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildTransactionStats(Map<String, dynamic> analysis) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Transaction Statistics',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             _buildStatItem('Total', analysis['totalTransactions']),
//             _buildStatItem('Successful', analysis['successfulTransactions']),
//             _buildStatItem('Failed', analysis['failedTransactions']),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildGasUsageStats(Map<String, dynamic> analysis) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Gas Usage Statistics',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             _buildStatItem(
//               'Total Gas',
//               FormatterUtils.formatEther(analysis['totalGasUsed']),
//             ),
//             _buildStatItem(
//               'Avg Gas',
//               FormatterUtils.formatEther(analysis['averageGasUsed']),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildErrorTypes(Map<String, dynamic> analysis) {
//     final errorTypes = analysis['errorTypes'] as Map<String, int>;
//     if (errorTypes.isEmpty) return const SizedBox.shrink();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Error Types',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         ...errorTypes.entries.map((entry) => Padding(
//               padding: const EdgeInsets.symmetric(vertical: 4),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     child: Text(
//                       entry.key,
//                       style: const TextStyle(fontSize: 12),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   Text('${entry.value}'),
//                 ],
//               ),
//             )),
//       ],
//     );
//   }

//   Widget _buildTopGasUsers(Map<String, dynamic> analysis) {
//     final topUsers = analysis['topGasUsers'] as List<Map<String, dynamic>>;
//     if (topUsers.isEmpty) return const SizedBox.shrink();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Top Gas Users',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         ...topUsers.map((user) => Padding(
//               padding: const EdgeInsets.symmetric(vertical: 4),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     child: Text(
//                       FormatterUtils.formatAddress(user['address']),
//                       style: const TextStyle(fontSize: 12),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   Text(
//                     '${FormatterUtils.formatEther(user['gasUsed'])} (${user['count']} tx)',
//                   ),
//                 ],
//               ),
//             )),
//       ],
//     );
//   }

//   Widget _buildStatItem(String label, dynamic value) {
//     return Column(
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 12),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           value.toString(),
//           style: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     );
//   }
// }
