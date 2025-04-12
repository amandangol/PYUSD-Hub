import 'package:http/http.dart' as http;
import 'dart:convert';

class NewsService {
  static const String _cryptoCompareBaseUrl =
      'https://min-api.cryptocompare.com/data/v2';
  static const String _newsApiBaseUrl = 'https://newsapi.org/v2';
  static const String _newsApiKey = '84219bc9ca0e4a23a31fd60244709fe5';

  NewsService();

  Future<List<Map<String, dynamic>>> getCryptoNews() async {
    try {
      // CryptoCompare's free news endpoint
      final response = await http.get(
        Uri.parse(
            '$_cryptoCompareBaseUrl/news/?lang=EN&categories=Stablecoin,PayPal,PYUSD,PaypalUSD,Google Cloud,GCP,Bounty,Stackup'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> articles = data['Data'];

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
      print('CryptoCompare news fetch error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getNewsApiNews() async {
    try {
      // NewsAPI's endpoint for crypto news
      final response = await http.get(
        Uri.parse(
          '$_newsApiBaseUrl/everything?q=(crypto OR cryptocurrency OR blockchain OR "PYUSD" OR "PayPal USD" OR ethereum OR solana)&language=en&sortBy=publishedAt&pageSize=50',
        ),
        headers: {'X-Api-Key': _newsApiKey},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> articles = data['articles'];

        return articles.map<Map<String, dynamic>>((article) {
          return {
            'title': article['title'] ?? '',
            'description': article['description'] ?? '',
            'content': article['content'] ?? '',
            'url': article['url'] ?? '',
            'urlToImage': article['urlToImage'],
            'publishedAt':
                article['publishedAt'] ?? DateTime.now().toIso8601String(),
            'source': {
              'name': article['source']['name'] ?? 'NewsAPI',
            }
          };
        }).toList();
      }

      throw Exception('Failed to fetch NewsAPI news: ${response.statusCode}');
    } catch (e) {
      print('NewsAPI fetch error: $e');
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

        return events.map<Map<String, dynamic>>((event) {
          return {
            'title': event['name'] ?? 'Ethereum Event',
            'description': event['description'] ?? '',
            'content': event['description'] ?? '',
            'url': event['link'] ?? '',
            'urlToImage': 'https://cryptologos.cc/logos/ethereum-eth-logo.png',
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

  // Method to fetch news from all sources and combine them
  Future<List<Map<String, dynamic>>> getAllNews() async {
    try {
      final cryptoCompareNews = await getCryptoNews();
      final newsApiNews = await getNewsApiNews();
      final coinpaprikaNews = await getCoinpaprikaNews();

      // Combine all news sources
      final allNews = [
        ...cryptoCompareNews,
        ...newsApiNews,
        ...coinpaprikaNews,
      ];

      // Remove duplicates based on title
      final Map<String, Map<String, dynamic>> uniqueNews = {};
      for (var article in allNews) {
        final title = article['title'].toString().toLowerCase();
        if (!uniqueNews.containsKey(title)) {
          uniqueNews[title] = article;
        }
      }

      return uniqueNews.values.toList();
    } catch (e) {
      print('Error fetching combined news: $e');
      return [];
    }
  }
}
