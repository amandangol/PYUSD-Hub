// import 'package:flutter/material.dart';
// import '../../../services/ethereum_rpc_service.dart';
// import '../../../utils/provider_utils.dart';

// class TransactionTraceProvider with ChangeNotifier, ProviderUtils {
//   final EthereumRpcService _rpcService = EthereumRpcService();

//   Map<String, dynamic>? _traceData;
//   bool _isLoading = false;
//   String? _error;

//   Map<String, dynamic>? get traceData => _traceData;
//   bool get isLoading => _isLoading;
//   String? get error => _error;

//   // Cache for trace data
//   final Map<String, Map<String, dynamic>> _traceCache = {};

//   Future<void> fetchTransactionTrace(String rpcUrl, String txHash) async {
//     if (disposed) return;

//     // Check cache first
//     if (_traceCache.containsKey(txHash)) {
//       _traceData = _traceCache[txHash];
//       notifyListeners();
//       return;
//     }

//     try {
//       _isLoading = true;
//       _error = null;
//       notifyListeners();

//       final trace = await _rpcService.getTransactionTrace(rpcUrl, txHash);

//       if (!disposed) {
//         _traceData = trace;
//         _traceCache[txHash] = trace;
//         _isLoading = false;
//         notifyListeners();
//       }
//     } catch (e) {
//       if (!disposed) {
//         _error = e.toString();
//         _isLoading = false;
//         notifyListeners();
//       }
//     }
//   }

//   void clearTrace() {
//     _traceData = null;
//     _error = null;
//     _isLoading = false;
//     notifyListeners();
//   }

//   @override
//   void dispose() {
//     _traceCache.clear();
//     markDisposed();
//     super.dispose();
//   }
// }
