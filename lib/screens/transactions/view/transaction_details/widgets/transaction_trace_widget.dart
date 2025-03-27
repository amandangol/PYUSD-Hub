// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../model/transaction_model.dart';
// import '../../../provider/transaction_trace_provider.dart';

// class TransactionTraceWidget extends StatefulWidget {
//   final TransactionDetailModel transaction;
//   final bool isDarkMode;
//   final Color cardColor;
//   final Color textColor;
//   final Color subtitleColor;
//   final Color primaryColor;
//   final Function(Map<String, dynamic> traceData)? onShowRawTraceData;

//   const TransactionTraceWidget({
//     Key? key,
//     required this.transaction,
//     required this.isDarkMode,
//     required this.cardColor,
//     required this.textColor,
//     required this.subtitleColor,
//     required this.primaryColor,
//     this.onShowRawTraceData,
//   }) : super(key: key);

//   @override
//   State<TransactionTraceWidget> createState() => _TransactionTraceWidgetState();
// }

// class _TransactionTraceWidgetState extends State<TransactionTraceWidget> {
//   late TransactionTraceProvider _traceProvider;

//   @override
//   void initState() {
//     super.initState();
//     _traceProvider =
//         Provider.of<TransactionTraceProvider>(context, listen: false);
//     _fetchTrace();
//   }

//   Future<void> _fetchTrace() async {
//     await _traceProvider.fetchTransactionTrace(
//       widget.transaction.network.name,
//       widget.transaction.hash,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<TransactionTraceProvider>(
//       builder: (context, provider, _) {
//         if (provider.isLoading) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (provider.error != null) {
//           return _buildErrorView(provider.error!);
//         }

//         final traceData = provider.traceData;
//         if (traceData == null || traceData.isEmpty) {
//           return Center(
//             child: Text(
//               'No trace data available',
//               style: TextStyle(color: widget.subtitleColor),
//             ),
//           );
//         }

//         return Card(
//           color: widget.cardColor,
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildHeader(traceData),
//                 const SizedBox(height: 16),
//                 _buildTraceContent(traceData),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildErrorView(String error) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.error_outline, color: Colors.red, size: 48),
//           const SizedBox(height: 16),
//           Text(
//             'Error loading trace data',
//             style: TextStyle(color: widget.textColor),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             error,
//             style: TextStyle(color: widget.subtitleColor, fontSize: 12),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: _fetchTrace,
//             child: const Text('Retry'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader(Map<String, dynamic> traceData) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           'Transaction Trace',
//           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                 color: widget.textColor,
//               ),
//         ),
//         IconButton(
//           icon: Icon(Icons.code, color: widget.primaryColor),
//           onPressed: () => widget.onShowRawTraceData?.call(traceData),
//           tooltip: 'View Raw Trace Data',
//         ),
//       ],
//     );
//   }

//   Widget _buildTraceContent(Map<String, dynamic> traceData) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildTraceItem('Type', traceData['type']?.toString() ?? 'N/A'),
//         _buildTraceItem('From', traceData['from']?.toString() ?? 'N/A'),
//         _buildTraceItem('To', traceData['to']?.toString() ?? 'N/A'),
//         _buildTraceItem(
//           'Value',
//           _formatValue(traceData['value']?.toString() ?? '0x0'),
//         ),
//         if (traceData['error'] != null)
//           _buildErrorItem(traceData['error'].toString()),
//         if (traceData['calls'] != null) _buildCallsTree(traceData['calls']),
//       ],
//     );
//   }

//   Widget _buildTraceItem(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 80,
//             child: Text(
//               label,
//               style: TextStyle(
//                 color: widget.subtitleColor,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: TextStyle(color: widget.textColor),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorItem(String error) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: Colors.red.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(4),
//         border: Border.all(color: Colors.red),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.error_outline, color: Colors.red, size: 16),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               error,
//               style: const TextStyle(color: Colors.red),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCallsTree(List<dynamic> calls) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 8),
//         Text(
//           'Internal Calls',
//           style: TextStyle(
//             color: widget.textColor,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 8),
//         ...calls.map((call) => _buildCallItem(call)),
//       ],
//     );
//   }

//   Widget _buildCallItem(Map<String, dynamic> call) {
//     return Card(
//       color: widget.isDarkMode ? Colors.black12 : Colors.grey[100],
//       margin: const EdgeInsets.only(bottom: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(8),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildTraceItem('Type', call['type']?.toString() ?? 'N/A'),
//             _buildTraceItem('To', call['to']?.toString() ?? 'N/A'),
//             _buildTraceItem(
//               'Value',
//               _formatValue(call['value']?.toString() ?? '0x0'),
//             ),
//             if (call['error'] != null)
//               _buildErrorItem(call['error'].toString()),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatValue(String hexValue) {
//     try {
//       final value = BigInt.parse(hexValue.replaceFirst('0x', ''), radix: 16);
//       return '${value.toString()} Wei (${value / BigInt.from(1e18)} ETH)';
//     } catch (e) {
//       return hexValue;
//     }
//   }
// }
