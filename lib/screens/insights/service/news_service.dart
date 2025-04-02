import 'package:http/http.dart' as http;
import 'dart:convert';

class NewsService {
  // CryptoCompare API provides crypto news for free
  static const String _baseUrl = 'https://min-api.cryptocompare.com/data/v2';

  // No API key needed in the constructor since we'll use a free endpoint
  NewsService();

  Future<List<Map<String, dynamic>>> getCryptoNews() async {
    try {
      // CryptoCompare's free news endpoint
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/news/?lang=EN&categories=Stablecoin,PayPal,PYUSD,PaypalUSD,Google Cloud,GCP,Bounty,Stackup'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> articles = data['Data'];

        // Transform CryptoCompare data format to match our existing structure
        return articles.map<Map<String, dynamic>>((article) {
          return {
            'title': article['title'],
            'description': article['body'],
            'content': article['body'],
            'url': article['url'],
            'urlToImage': article['imageurl'],
            'publishedAt': DateTime.fromMillisecondsSinceEpoch(
                    article['published_on'] * 1000)
                .toIso8601String(),
            'source': {
              'name': article['source'] ?? 'CryptoCompare',
            }
          };
        }).toList();
      }

      throw Exception('Failed to fetch news: ${response.statusCode}');
    } catch (e) {
      print('News fetch error: $e');
      return [];
    }
  }

  // Alternative method using Coinpaprika API
  Future<List<Map<String, dynamic>>> getCoinpaprikaNews() async {
    try {
      // Coinpaprika's free news endpoint
      final response = await http.get(
        Uri.parse('https://api.coinpaprika.com/v1/coins/eth-ethereum/events'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> events = json.decode(response.body);

        // Transform Coinpaprika data format to match our existing structure
        return events.map<Map<String, dynamic>>((event) {
          return {
            'title': event['name'] ?? 'Ethereum Event',
            'description': event['description'] ?? '',
            'content': event['description'] ?? '',
            'url': event['link'] ?? '',
            'urlToImage':
                'https://cryptologos.cc/logos/ethereum-eth-logo.png', // Default ETH logo
            'publishedAt': event['date'] ?? DateTime.now().toIso8601String(),
            'source': {
              'name': 'Coinpaprika',
            }
          };
        }).toList();
      }

      throw Exception('Failed to fetch events: ${response.statusCode}');
    } catch (e) {
      print('Events fetch error: $e');
      return [];
    }
  }
}
