// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../provider/network_congestion_provider.dart';

// class AIAnalysisTab extends StatefulWidget {
//   const AIAnalysisTab({super.key});

//   @override
//   State<AIAnalysisTab> createState() => _AIAnalysisTabState();
// }

// class _AIAnalysisTabState extends State<AIAnalysisTab> {
//   final TextEditingController _txHashController = TextEditingController();
//   final TextEditingController _walletController = TextEditingController();
//   String? _txAnalysis;
//   String? _walletAnalysis;
//   bool _isAnalyzingTx = false;
//   bool _isAnalyzingWallet = false;

//   @override
//   void dispose() {
//     _txHashController.dispose();
//     _walletController.dispose();
//     super.dispose();
//   }

//   Future<void> _analyzeTransaction() async {
//     if (_txHashController.text.isEmpty) return;

//     setState(() => _isAnalyzingTx = true);
//     try {
//       final provider =
//           Provider.of<NetworkCongestionProvider>(context, listen: false);
//       final analysis =
//           await provider.analyzeTransactionWithAI(_txHashController.text);
//       setState(() => _txAnalysis = analysis);
//     } catch (e) {
//       setState(() => _txAnalysis = 'Error analyzing transaction: $e');
//     } finally {
//       setState(() => _isAnalyzingTx = false);
//     }
//   }

//   Future<void> _analyzeWallet() async {
//     if (_walletController.text.isEmpty) return;

//     setState(() => _isAnalyzingWallet = true);
//     try {
//       final provider =
//           Provider.of<NetworkCongestionProvider>(context, listen: false);
//       final analysis =
//           await provider.analyzeWalletWithAI(_walletController.text);
//       setState(() => _walletAnalysis = analysis);
//     } catch (e) {
//       setState(() => _walletAnalysis = 'Error analyzing wallet: $e');
//     } finally {
//       setState(() => _isAnalyzingWallet = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'AI-Powered Network Analysis',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 24),

//           // Transaction Analysis Section
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Transaction Analysis',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   TextField(
//                     controller: _txHashController,
//                     decoration: const InputDecoration(
//                       labelText: 'Transaction Hash',
//                       hintText: 'Enter transaction hash to analyze',
//                       border: OutlineInputBorder(),
//                     ),
//                     onSubmitted: (_) => _analyzeTransaction(),
//                   ),
//                   const SizedBox(height: 16),
//                   if (_isAnalyzingTx)
//                     const Center(child: CircularProgressIndicator())
//                   else
//                     ElevatedButton(
//                       onPressed: _analyzeTransaction,
//                       child: const Text('Analyze Transaction'),
//                     ),
//                   if (_txAnalysis != null) ...[
//                     const SizedBox(height: 16),
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Text(_txAnalysis!),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 24),

//           // Wallet Analysis Section
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Wallet Analysis',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   TextField(
//                     controller: _walletController,
//                     decoration: const InputDecoration(
//                       labelText: 'Wallet Address',
//                       hintText: 'Enter wallet address to analyze',
//                       border: OutlineInputBorder(),
//                     ),
//                     onSubmitted: (_) => _analyzeWallet(),
//                   ),
//                   const SizedBox(height: 16),
//                   if (_isAnalyzingWallet)
//                     const Center(child: CircularProgressIndicator())
//                   else
//                     ElevatedButton(
//                       onPressed: _analyzeWallet,
//                       child: const Text('Analyze Wallet'),
//                     ),
//                   if (_walletAnalysis != null) ...[
//                     const SizedBox(height: 16),
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Text(_walletAnalysis!),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
