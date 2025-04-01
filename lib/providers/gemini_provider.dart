import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

class GeminiProvider with ChangeNotifier {
  final GeminiService _service = GeminiService();
  bool _isLoading = false;
  Map<String, dynamic> _lastAnalysis = {};

  bool get isLoading => _isLoading;
  Map<String, dynamic> get lastAnalysis => _lastAnalysis;

  Future<Map<String, dynamic>> analyzeTransactionTraceStructured(
      Map<String, dynamic> traceData,
      Map<String, dynamic> transactionData,
      Map<String, dynamic> tokenDetails) async {
    try {
      _isLoading = true;
      notifyListeners();

      final analysis = await _service.analyzeTransactionTraceStructured(
          traceData, transactionData, tokenDetails);
      _lastAnalysis = analysis;

      _isLoading = false;
      notifyListeners();
      return analysis;
    } catch (e) {
      _isLoading = false;
      _lastAnalysis = {
        "summary": "Error analyzing transaction",
        "error": true,
        "errorMessage": e.toString()
      };
      notifyListeners();
      return _lastAnalysis;
    }
  }

  Future<Map<String, dynamic>> analyzeBlockStructured(
      Map<String, dynamic> blockData,
      List<Map<String, dynamic>> transactions,
      List<Map<String, dynamic>> pyusdTransactions,
      List<Map<String, dynamic>> traces) async {
    try {
      _isLoading = true;
      notifyListeners();

      final analysis = await _service.analyzeBlockStructured(
          blockData, transactions, pyusdTransactions, traces);
      _lastAnalysis = analysis;

      _isLoading = false;
      notifyListeners();
      return analysis;
    } catch (e) {
      _isLoading = false;
      _lastAnalysis = {
        "summary": "Error analyzing block",
        "error": true,
        "errorMessage": e.toString()
      };
      notifyListeners();
      return _lastAnalysis;
    }
  }

  Future<Map<String, dynamic>> analyzeAdvancedTraceStructured(
      Map<String, dynamic> traceData) async {
    try {
      _isLoading = true;
      notifyListeners();

      final analysis = await _service.analyzeAdvancedTraceStructured(traceData);
      _lastAnalysis = analysis;

      _isLoading = false;
      notifyListeners();
      return analysis;
    } catch (e) {
      _isLoading = false;
      _lastAnalysis = {
        "summary": "Error analyzing trace",
        "error": true,
        "errorMessage": e.toString()
      };
      notifyListeners();
      return _lastAnalysis;
    }
  }
}
