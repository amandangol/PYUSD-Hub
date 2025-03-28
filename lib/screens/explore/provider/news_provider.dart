import 'package:flutter/material.dart';
import '../service/news_service.dart';
import '../../../utils/provider_utils.dart';

class NewsProvider with ChangeNotifier, ProviderUtils {
  final NewsService _newsService;

  List<Map<String, dynamic>> _news = [];
  NewsLoadingState _loadingState = NewsLoadingState.initial;
  String? _error;
  DateTime? _lastRefresh;

  // Configurable cache duration
  static const Duration _cacheDuration = Duration(minutes: 15);

  // Keywords for news filtering
  static const List<String> _cryptoKeywords = [
    'pyusd',
    'paypal usd',
    'ethereum',
    'eth',
    'solana',
    'sol',
    'crypto',
    'blockchain',
    'defi',
    'web3'
  ];

  NewsProvider({required NewsService newsService}) : _newsService = newsService;

  // Getters
  List<Map<String, dynamic>> get news => _news;
  NewsLoadingState get loadingState => _loadingState;
  bool get isLoading => _loadingState == NewsLoadingState.loading;
  String? get error => _error;

  // Determine if a refresh is needed
  bool _shouldRefresh() {
    if (_lastRefresh == null) return true;
    return DateTime.now().difference(_lastRefresh!) > _cacheDuration;
  }

  // Fetch news with advanced state management
  Future<void> fetchNews({bool forceRefresh = false}) async {
    if (disposed) return;

    // Don't refresh if not forced and cache is still valid
    if (!forceRefresh && !_shouldRefresh() && _news.isNotEmpty) return;

    try {
      // Set loading state
      if (!disposed) {
        _loadingState = NewsLoadingState.loading;
        _error = null;
        notifyListeners();
      }

      // Fetch articles
      final articles = await _newsService.getCryptoNews();

      if (!disposed) {
        // Filter articles to include relevant crypto news
        _news = articles.where((article) {
          final title = article['title']?.toLowerCase() ?? '';
          final description = article['description']?.toLowerCase() ?? '';
          final content = article['content']?.toLowerCase() ?? '';

          return _cryptoKeywords.any((keyword) =>
              title.contains(keyword) ||
              description.contains(keyword) ||
              content.contains(keyword));
        }).toList();

        _lastRefresh = DateTime.now();
        _loadingState = NewsLoadingState.loaded;
        notifyListeners();
      }
    } catch (e) {
      if (!disposed) {
        _error = 'Failed to fetch news: ${e.toString()}';
        _loadingState = NewsLoadingState.error;
        notifyListeners();
      }
    }
  }

  // Refresh method with forced update
  Future<void> refresh() async {
    await fetchNews(forceRefresh: true);
  }

  // Method to reset to initial state
  void reset() {
    _news = [];
    _loadingState = NewsLoadingState.initial;
    _error = null;
    _lastRefresh = null;
    notifyListeners();
  }

  // Filter news based on specific keywords
  List<Map<String, dynamic>> filterNews({
    List<String> keywords = const [
      'pyusd',
      'ethereum',
      'solana',
      'crypto',
      'defi'
    ],
  }) {
    return _news.where((article) {
      final title = article['title']?.toLowerCase() ?? '';
      final description = article['description']?.toLowerCase() ?? '';
      final content = article['content']?.toLowerCase() ?? '';

      return keywords.any((keyword) =>
          title.contains(keyword) ||
          description.contains(keyword) ||
          content.contains(keyword));
    }).toList();
  }
}

// Enum to represent different loading states
enum NewsLoadingState { initial, loading, loaded, error }
