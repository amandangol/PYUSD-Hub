import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/market_service.dart';
import '../../../utils/provider_utils.dart';
import 'dart:math' as math;

enum TimeFrame { day, week, month, threeMonths }

class InsightsProvider with ChangeNotifier, ProviderUtils {
  final MarketService _marketService;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetchTime;

  TimeFrame _selectedTimeFrame = TimeFrame.week;

  // Market Data with default values
  Map<String, dynamic> _marketData = {
    'current_price': 1.0,
    'market_cap': 0.0,
    'total_volume': 0.0,
    'circulating_supply': 0.0,
    'total_supply': 0.0,
    'price_change_24h': 0.0,
    'price_change_7d': 0.0,
    'price_change_30d': 0.0,
    'supported_chains': ['Ethereum', 'Solana'],
    'last_updated': DateTime.now().toIso8601String(),
    'data_source': 'Default Values',
    'is_real_data': false,
    'price_history': {
      'day': [],
      'week': [],
      'month': [],
      'three_months': [],
    },
  };

  List<Map<String, dynamic>> _tickers = [];
  static const Duration _cacheDuration = Duration(minutes: 5);

  InsightsProvider(this._marketService) {
    debugPrint('InsightsProvider initialized');
    fetchAllData(); // Fetch data immediately
  }

  // Getters
  @override
  bool get isLoading => _isLoading;
  @override
  String? get error => _error;
  Map<String, dynamic> get marketData => _marketData;
  List<Map<String, dynamic>> get tickers => _tickers;
  DateTime? get lastFetchTime => _lastFetchTime;
  TimeFrame get selectedTimeFrame => _selectedTimeFrame;
  bool get isDataStale =>
      _lastFetchTime == null ||
      DateTime.now().difference(_lastFetchTime!) > _cacheDuration;

  // Setter for time frame
  void setTimeFrame(TimeFrame timeFrame) {
    _selectedTimeFrame = timeFrame;
    notifyListeners();
  }

  // Get chart data based on selected time frame
  List<double> getChartData(TimeFrame timeFrame) {
    final priceHistory = _marketData['price_history'] as Map<String, dynamic>?;
    if (priceHistory == null) return [];

    switch (timeFrame) {
      case TimeFrame.day:
        return List<double>.from(priceHistory['day'] ?? []);
      case TimeFrame.week:
        return List<double>.from(priceHistory['week'] ?? []);
      case TimeFrame.month:
        return List<double>.from(priceHistory['month'] ?? []);
      case TimeFrame.threeMonths:
        return List<double>.from(priceHistory['three_months'] ?? []);
    }
  }

  // Get min and max values for chart scaling based on time frame
  List<double> getChartMinMax(TimeFrame timeFrame) {
    final data = getChartData(timeFrame);

    if (data.isEmpty) {
      return [0.99, 1.01];
    }

    double min = double.infinity;
    double max = -double.infinity;

    for (final point in data) {
      if (point < min) min = point;
      if (point > max) max = point;
    }

    final padding = (max - min) * 0.1;
    return [min - padding, max + padding];
  }

  // Get interval for x-axis based on time frame
  double getXAxisInterval(TimeFrame timeFrame) {
    final data = getChartData(timeFrame);
    if (data.isEmpty) return 1;

    switch (timeFrame) {
      case TimeFrame.day:
        return data.length / 6; // Show 6 labels (every 4 hours) for day
      case TimeFrame.week:
        return data.length / 7; // Show 7 labels for week
      case TimeFrame.month:
        return data.length / 10; // Show 10 labels for month
      case TimeFrame.threeMonths:
        return data.length / 12; // Show 12 labels for 3 months
    }
  }

  // Format date for chart x-axis based on time frame
  String getFormattedDateForChart(
      int index, TimeFrame timeFrame, int totalPoints) {
    final now = DateTime.now();
    DateTime date;

    switch (timeFrame) {
      case TimeFrame.day:
        // For day view, show hours in 4-hour intervals
        final hoursAgo = (totalPoints - 1 - index) * (24 / totalPoints).round();
        date = now.subtract(Duration(hours: hoursAgo));
        if (date.hour % 4 == 0) {
          return DateFormat('HH:mm').format(date);
        }
        return '';

      case TimeFrame.week:
        // For week view, show day of week
        final daysAgo = (totalPoints - 1 - index) ~/ (totalPoints / 7);
        date = now.subtract(Duration(days: daysAgo));
        return DateFormat('E').format(date); // Mon, Tue, etc.

      case TimeFrame.month:
        // For month view, show day/month
        final daysAgo = (totalPoints - 1 - index) ~/ (totalPoints / 30);
        date = now.subtract(Duration(days: daysAgo));
        return DateFormat('d/M').format(date);

      case TimeFrame.threeMonths:
        // For 3 months view, show month
        final daysAgo = (totalPoints - 1 - index) ~/ (totalPoints / 90);
        date = now.subtract(Duration(days: daysAgo));
        return DateFormat('MMM').format(date);
    }
  }

  // Format date for tooltip
  String getFormattedDateForTooltip(int index, TimeFrame timeFrame) {
    final data = getChartData(timeFrame);
    final totalPoints = data.length;
    final now = DateTime.now();
    DateTime date;

    switch (timeFrame) {
      case TimeFrame.day:
        final hoursAgo = (totalPoints - 1 - index) * (24 / totalPoints).round();
        date = now.subtract(Duration(hours: hoursAgo));
        return DateFormat('MMM d, HH:mm').format(date);

      case TimeFrame.week:
        final daysAgo = (totalPoints - 1 - index) ~/ (totalPoints / 7);
        date = now.subtract(Duration(days: daysAgo));
        return DateFormat('MMM d').format(date);

      case TimeFrame.month:
        final daysAgo = (totalPoints - 1 - index) ~/ (totalPoints / 30);
        date = now.subtract(Duration(days: daysAgo));
        return DateFormat('MMM d').format(date);

      case TimeFrame.threeMonths:
        final daysAgo = (totalPoints - 1 - index) ~/ (totalPoints / 90);
        date = now.subtract(Duration(days: daysAgo));
        return DateFormat('MMM d, yyyy').format(date);
    }
  }

  Future<void> fetchAllData() async {
    // Skip if data is still fresh
    if (!isDataStale && _marketData['is_real_data'] == true) {
      debugPrint('Using cached data');
      return;
    }

    try {
      _isLoading = true;
      safeNotifyListeners(this);

      debugPrint('Fetching fresh PYUSD data...');

      // Fetch market data and exchange data concurrently
      final results = await Future.wait([
        _marketService.getPYUSDMarketData(),
        _marketService.fetchExchangeData(),
      ]);

      if (disposed) return;

      _marketData = results[0] as Map<String, dynamic>;
      _tickers = results[1] as List<Map<String, dynamic>>;

      // Sort exchanges by volume
      _tickers.sort((a, b) => (b['volume'] ?? 0).compareTo(a['volume'] ?? 0));

      _lastFetchTime = DateTime.now();
      _error = null;

      // debugPrint('Data fetched successfully: ${_marketData['is_real_data']}');
    } catch (e) {
      debugPrint('Error fetching data: $e');
      _error = e.toString();

      // Only set default values if we don't have any real data
      if (_marketData['is_real_data'] != true) {
        _setDefaultValues();
      }
    } finally {
      _isLoading = false;
      safeNotifyListeners(this);
    }
  }

  Future<void> refresh() async {
    _lastFetchTime = null; // Force refresh
    await fetchAllData();
  }

  void _setDefaultValues() {
    _marketData = {
      'current_price': 1.0,
      'market_cap': 0.0,
      'total_volume': 0.0,
      'circulating_supply': 0.0,
      'total_supply': 0.0,
      'price_change_24h': 0.0,
      'price_change_7d': 0.0,
      'price_change_30d': 0.0,
      'supported_chains': ['Ethereum', 'Solana'],
      'last_updated': DateTime.now().toIso8601String(),
      'is_real_data': false,
      'price_history': {
        'day': _generatePlaceholderPriceData(24),
        'week': _generatePlaceholderPriceData(168),
        'month': _generatePlaceholderPriceData(30),
        'three_months': _generatePlaceholderPriceData(90),
      },
    };
    _tickers = [];
  }

  // Generate placeholder price data for different time frames
  List<double> _generatePlaceholderPriceData(int points) {
    final random = math.Random();
    final List<double> data = [];
    double value = 1.0;

    for (int i = 0; i < points; i++) {
      // Small random fluctuation (±0.5%)
      value += (random.nextDouble() - 0.5) * 0.01;
      // Keep it close to 1.0
      value = 0.995 + (value - 0.995) * 0.9;
      data.add(value);
    }

    return data;
  }

  String formatNumber(dynamic number) {
    if (number == null) return '0';

    if (number is String) {
      number = double.tryParse(number) ?? 0;
    }

    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(2)}B';
    }
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)}K';
    }
    return number.toStringAsFixed(2);
  }

  String formatPercentage(dynamic number) {
    if (number == null) return '0%';

    if (number is String) {
      number = double.tryParse(number) ?? 0;
    }

    final isPositive = number >= 0;
    return '${isPositive ? '+' : ''}${number.toStringAsFixed(2)}%';
  }

  Color getPriceChangeColor(dynamic change) {
    if (change == null) return Colors.grey;

    if (change is String) {
      change = double.tryParse(change) ?? 0;
    }

    if (change > 0) return Colors.green;
    if (change < 0) return Colors.red;
    return Colors.grey; // For exactly 0
  }

  String getTimeAgo(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final date = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      }
      if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      }
      if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      }
      return 'Just now';
    } catch (e) {
      return 'N/A';
    }
  }

  // Helper method to get price change color with opacity
  Color getPriceChangeColorWithOpacity(dynamic change, {double opacity = 0.1}) {
    final color = getPriceChangeColor(change);
    return color.withOpacity(opacity);
  }

  // Get min and max values from sparkline data for chart scaling
  List<double> getSparklineMinMax() {
    final sparklineData = _marketData['sparkline_7d'] as List<dynamic>?;

    if (sparklineData == null || sparklineData.isEmpty) {
      return [0.99, 1.01]; // Default range for stablecoin
    }

    double min = double.infinity;
    double max = -double.infinity;

    for (final point in sparklineData) {
      final value = point is double ? point : 1.0;
      if (value < min) min = value;
      if (value > max) max = value;
    }

    final padding = (max - min) * 0.1;
    return [min - padding, max + padding];
  }

  // Get formatted date for chart x-axis
  String getFormattedDateForIndex(int index, int totalPoints) {
    final now = DateTime.now();
    final daysAgo = (totalPoints - index) ~/ 24; // Assuming hourly data points
    final date = now.subtract(Duration(days: daysAgo));
    return '${date.day}/${date.month}';
  }

  Future<void> fetchExchangeData() async {
    try {
      final exchanges = await _marketService.fetchExchangeData();
      _tickers = exchanges;
      notifyListeners();
    } catch (e) {
      debugPrint('Error in fetchExchangeData: $e');
    }
  }
}
