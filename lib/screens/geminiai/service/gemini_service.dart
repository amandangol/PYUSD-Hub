import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class GeminiService {
  late final GenerativeModel _model;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null) {
        throw Exception('GEMINI_API_KEY not found in environment variables');
      }
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.2,
          topP: 0.8,
          topK: 40,
          maxOutputTokens: 2048,
        ),
      );
      _isInitialized = true;
    }
  }

  Future<Map<String, dynamic>> analyzeTransactionTraceStructured(
      Map<String, dynamic> traceData,
      Map<String, dynamic> transactionData,
      Map<String, dynamic> tokenDetails) async {
    await initialize();

    // Format the data for the AI
    final formattedData = {
      'transaction': transactionData,
      'trace': traceData,
      'tokenDetails': tokenDetails,
    };

    // Create a prompt for the AI
    final prompt = """
    Analyze this Ethereum transaction and its trace data:
    
    ${jsonEncode(formattedData)}
    
    Respond with a JSON object containing the following fields:
    
    {
      "summary": "A concise summary of what this transaction is doing",
      "type": "The transaction type (e.g., 'Token Transfer', 'Contract Deployment', 'Contract Interaction', 'Swap', etc.)",
      "riskLevel": "A risk assessment (Low, Medium, High) based on the transaction patterns",
      "riskFactors": ["List of any risk factors or suspicious patterns"],
      "gasAnalysis": "Analysis of gas usage and potential optimizations",
      "contractInteractions": ["List of contracts interacted with and what they do"],
      "technicalInsights": "Technical details about the execution flow",
      "humanReadable": "A human-readable explanation of the transaction in simple terms"
    }
    
    Ensure your response is valid JSON that can be parsed. Only return the JSON object, nothing else.
    """;

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text ?? "{}";

      // Try to parse the JSON response
      try {
        return jsonDecode(responseText);
      } catch (e) {
        // If parsing fails, try to extract JSON from the text
        final jsonPattern = RegExp(r'{[\s\S]*}');
        final match = jsonPattern.firstMatch(responseText);
        if (match != null) {
          return jsonDecode(match.group(0)!);
        } else {
          // Return a formatted error if we can't parse JSON
          return {
            "summary": "Failed to parse AI response",
            "humanReadable": responseText,
            "error": true
          };
        }
      }
    } catch (e) {
      return {
        "summary": "Error generating AI analysis",
        "error": true,
        "errorMessage": e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> analyzeBlockStructured(
      Map<String, dynamic> blockData,
      List<Map<String, dynamic>> transactions,
      List<Map<String, dynamic>> pyusdTransactions,
      List<Map<String, dynamic>> traces) async {
    await initialize();

    // Format the data for the AI
    final formattedData = {
      'blockData': blockData,
      'transactions': transactions,
      'pyusdTransactions': pyusdTransactions,
      'traces': traces,
    };

    final prompt = """
    You are a blockchain analysis expert. Analyze this Ethereum block data and provide insights.
    
    Block Data:
    ${jsonEncode(formattedData)}
    
    Provide a structured analysis in JSON format with the following fields:
    {
      "summary": "A comprehensive summary of the block's activity",
      "blockActivity": "Description of overall block activity (Normal, High, Low)",
      "pyusdActivity": "Description of PYUSD-related activity in this block",
      "gasAnalysis": "Analysis of gas usage patterns in this block",
      "notableTransactions": [
        {
          "hash": "transaction hash",
          "description": "what makes this transaction notable"
        }
      ],
      "insights": "Technical insights about this block's execution and any patterns observed"
    }
    
    Ensure your response is valid JSON that can be parsed. Only return the JSON object, nothing else.
    """;

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text ?? "{}";

      // Try to parse the JSON response
      try {
        return jsonDecode(responseText);
      } catch (e) {
        // If parsing fails, try to extract JSON from the text
        final jsonPattern = RegExp(r'{[\s\S]*}');
        final match = jsonPattern.firstMatch(responseText);
        if (match != null) {
          return jsonDecode(match.group(0)!);
        } else {
          // Return a formatted error if we can't parse JSON
          return {
            "summary": "Failed to parse AI response",
            "blockActivity": "Unknown",
            "error": true
          };
        }
      }
    } catch (e) {
      return {
        "summary": "Error generating AI analysis",
        "error": true,
        "errorMessage": e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> analyzeAdvancedTraceStructured(
      Map<String, dynamic> traceData) async {
    await initialize();

    final prompt = """
    You are a blockchain trace analysis expert. Analyze this Ethereum trace data and provide insights.
    
    Trace Method: ${traceData['method']}
    Trace Data:
    ${jsonEncode(traceData['result'])}
    
    Provide a structured analysis in JSON format with the following fields:
    {
      "summary": "A comprehensive summary of what this trace shows",
      "technicalDetails": "Technical explanation of the trace execution flow",
      "insights": "Key insights derived from this trace data",
      "recommendations": "Recommendations for developers or users based on this trace"
    }
    
    Ensure your response is valid JSON that can be parsed. Only return the JSON object, nothing else.
    """;

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text ?? "{}";

      // Try to parse the JSON response
      try {
        return jsonDecode(responseText);
      } catch (e) {
        // If parsing fails, try to extract JSON from the text
        final jsonPattern = RegExp(r'{[\s\S]*}');
        final match = jsonPattern.firstMatch(responseText);
        if (match != null) {
          return jsonDecode(match.group(0)!);
        } else {
          // Return a formatted error if we can't parse JSON
          return {
            "summary": "Failed to parse AI response",
            "technicalDetails": responseText,
            "error": true
          };
        }
      }
    } catch (e) {
      return {
        "summary": "Error generating AI analysis",
        "error": true,
        "errorMessage": e.toString()
      };
    }
  }
}
