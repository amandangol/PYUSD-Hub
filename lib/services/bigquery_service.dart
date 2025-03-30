import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class BigQueryService {
  static const String baseUrl =
      'http://localhost:8080'; // Using computer's IP address
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('BigQuery service already initialized');
      return;
    }

    _isInitialized = true;
    debugPrint('BigQuery service initialized successfully');
  }

  Future<Map<String, dynamic>> getAllPYUSDData() async {
    debugPrint('Fetching all PYUSD data...');
    await initialize();

    try {
      debugPrint('Making request to: $baseUrl/api/pyusd/stats');
      final response = await http.get(Uri.parse('$baseUrl/api/pyusd/stats'));

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response headers: ${response.headers}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Successfully decoded data: $data');
        return data;
      } else {
        String errorMessage =
            'Failed to fetch PYUSD data: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          errorMessage +=
              '\nError details: ${errorData['detail'] ?? 'No details available'}';
        } catch (e) {
          errorMessage += '\nRaw response: ${response.body}';
        }
        debugPrint('Error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error fetching PYUSD data: $e');
      rethrow;
    }
  }
}
