import 'package:flutter/material.dart';
import '../service/news_service.dart';
import '../../../utils/provider_utils.dart';

enum NewsCategory { all, pyusd, ethereum, solana, defi, other }

extension NewsCategoryExtension on NewsCategory {
  String get displayName {
    switch (this) {
      case NewsCategory.all:
        return 'All News';
      case NewsCategory.pyusd:
        return 'PYUSD';
      case NewsCategory.ethereum:
        return 'Ethereum';
      case NewsCategory.solana:
        return 'Solana';
      case NewsCategory.defi:
        return 'DeFi';
      case NewsCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case NewsCategory.all:
        return Icons.article;
      case NewsCategory.pyusd:
        return Icons.attach_money;
      case NewsCategory.ethereum:
        return Icons.currency_exchange;
      case NewsCategory.solana:
        return Icons.bolt;
      case NewsCategory.defi:
        return Icons.account_balance;
      case NewsCategory.other:
        return Icons.more_horiz;
    }
  }

  Color get color {
    switch (this) {
      case NewsCategory.all:
        return Colors.blue;
      case NewsCategory.pyusd:
        return Colors.green;
      case NewsCategory.ethereum:
        return Colors.purple;
      case NewsCategory.solana:
        return Colors.deepOrange;
      case NewsCategory.defi:
        return Colors.teal;
      case NewsCategory.other:
        return Colors.grey;
    }
  }
}

class NewsProvider with ChangeNotifier, ProviderUtils {
  final NewsService _newsService;

  List<Map<String, dynamic>> _news = [];
  NewsLoadingState _loadingState = NewsLoadingState.initial;
  String? _error;
  DateTime? _lastRefresh;
  Set<NewsCategory> _selectedCategories = {NewsCategory.all};

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
    'web3',
    'stablecoin',
    'google cloud',
    'gcp',
    'bounty',
    'stackup'
  ];

  NewsProvider({required NewsService newsService}) : _newsService = newsService;

  // Getters
  List<Map<String, dynamic>> get news => _news;
  NewsLoadingState get loadingState => _loadingState;
  @override
  bool get isLoading => _loadingState == NewsLoadingState.loading;
  @override
  String? get error => _error;
  Set<NewsCategory> get selectedCategories => _selectedCategories;

  bool _shouldRefresh() {
    if (_lastRefresh == null) return true;
    return DateTime.now().difference(_lastRefresh!) > _cacheDuration;
  }

  // Fetch news with advanced state management
  Future<void> fetchNews({bool forceRefresh = false}) async {
    if (disposed) return;

    if (!forceRefresh && !_shouldRefresh() && _news.isNotEmpty) return;

    try {
      // Set loading state
      if (!disposed) {
        _loadingState = NewsLoadingState.loading;
        _error = null;
        notifyListeners();
      }

      // Fetch articles from all sources
      final allArticles = await _newsService.getAllNews();

      if (!disposed) {
        // Filter articles to include relevant crypto news
        _news = allArticles.where((article) {
          final title = article['title']?.toLowerCase() ?? '';
          final description = article['description']?.toLowerCase() ?? '';
          final content = article['content']?.toLowerCase() ?? '';

          return _cryptoKeywords.any((keyword) =>
              title.contains(keyword) ||
              description.contains(keyword) ||
              content.contains(keyword));
        }).toList();

        // Sort by published date (newest first)
        _news.sort((a, b) {
          final dateA = DateTime.parse(a['publishedAt']);
          final dateB = DateTime.parse(b['publishedAt']);
          return dateB.compareTo(dateA);
        });

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

  void toggleCategory(NewsCategory category) {
    if (category == NewsCategory.all) {
      _selectedCategories = {NewsCategory.all};
    } else {
      _selectedCategories.remove(NewsCategory.all);
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
        if (_selectedCategories.isEmpty) {
          _selectedCategories = {NewsCategory.all};
        }
      } else {
        _selectedCategories.add(category);
      }
    }
    notifyListeners();
  }

  // Filter news based on selected categories
  List<Map<String, dynamic>> filterNews() {
    if (_selectedCategories.contains(NewsCategory.all)) {
      return _news;
    }

    return _news.where((article) {
      final title = article['title']?.toLowerCase() ?? '';
      final description = article['description']?.toLowerCase() ?? '';
      final content = article['content']?.toLowerCase() ?? '';

      return _selectedCategories.any((category) {
        switch (category) {
          case NewsCategory.pyusd:
            return title.contains('pyusd') ||
                title.contains('paypal usd') ||
                description.contains('pyusd') ||
                description.contains('paypal usd') ||
                content.contains('pyusd') ||
                content.contains('paypal usd');
          case NewsCategory.ethereum:
            return title.contains('ethereum') ||
                title.contains('eth') ||
                description.contains('ethereum') ||
                description.contains('eth') ||
                content.contains('ethereum') ||
                content.contains('eth');
          case NewsCategory.solana:
            return title.contains('solana') ||
                title.contains('sol') ||
                description.contains('solana') ||
                description.contains('sol') ||
                content.contains('solana') ||
                content.contains('sol');
          case NewsCategory.defi:
            return title.contains('defi') ||
                title.contains('blockchain') ||
                description.contains('defi') ||
                description.contains('blockchain') ||
                content.contains('defi') ||
                content.contains('blockchain');
          case NewsCategory.other:
            return title.contains('crypto') ||
                title.contains('web3') ||
                title.contains('stablecoin') ||
                description.contains('crypto') ||
                description.contains('web3') ||
                description.contains('stablecoin') ||
                content.contains('crypto') ||
                content.contains('web3') ||
                content.contains('stablecoin');
          case NewsCategory.all:
            return true;
        }
      });
    }).toList();
  }
}

enum NewsLoadingState { initial, loading, loaded, error }
