import 'package:http/http.dart' as http;
import 'dart:convert';

class NewsService {
  static const String _baseUrl = 'https://newsapi.org/v2';
  final String _apiKey;

  NewsService({required String apiKey}) : _apiKey = apiKey;

  Future<List<Map<String, dynamic>>> getCryptoNews() async {
    const apiKey = '84219bc9ca0e4a23a31fd60244709fe5';

    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/everything?q=Ethereum PayPal USD&sortBy=publishedAt&language=en&apiKey=$apiKey'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> articles = data['articles'];
        return articles.cast<Map<String, dynamic>>();
      }

      throw Exception('Failed to fetch news: ${response.statusCode}');
    } catch (e) {
      print('News fetch error: $e');
      return [];
    }
  }
}
