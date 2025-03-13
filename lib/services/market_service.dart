import 'package:http/http.dart' as http;
import 'dart:convert';

class MarketService {
  // Coingecko API for fetching current prices
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';

  Future<Map<String, double>> getCurrentPrices(List<String> tokens) async {
    try {
      // Map of known token IDs for Coingecko
      final tokenIds = {
        'ETH': 'ethereum',
        'PYUSD': 'paypal-usd',
      };

      // Convert tokens to their Coingecko IDs
      final ids = tokens
          .map((token) => tokenIds[token] ?? token.toLowerCase())
          .toList();

      final response = await http.get(
        Uri.parse(
            '$_baseUrl/simple/price?ids=${ids.join(',')}&vs_currencies=usd'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Map back to original token names
        return {
          for (var token in tokens)
            token: data[tokenIds[token] ?? token.toLowerCase()]?['usd'] ?? 0.0
        };
      }

      return {for (var token in tokens) token: 0.0};
    } catch (e) {
      print('Market price fetch error: $e');
      return {for (var token in tokens) token: 0.0};
    }
  }
}
