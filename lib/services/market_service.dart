import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class MarketService {
  // Coingecko API for fetching current prices
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';
  static const String _pyusdId = 'paypal-usd';

  // Standard headers for API requests
  static final Map<String, String> _headers = {
    'Accept': 'application/json',
    'User-Agent': 'PYUSD Hub App',
  };

  // Utility method for API calls
  Future<Map<String, dynamic>?> _apiGet(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      debugPrint('API error: ${response.statusCode} for $endpoint');
      return null;
    } catch (e) {
      debugPrint('API exception: $e for $endpoint');
      return null;
    }
  }

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

      final data =
          await _apiGet('simple/price?ids=${ids.join(',')}&vs_currencies=usd');

      if (data != null) {
        // Map back to original token names
        return {
          for (var token in tokens)
            token: data[tokenIds[token] ?? token.toLowerCase()]?['usd'] ?? 0.0
        };
      }

      return {for (var token in tokens) token: 0.0};
    } catch (e) {
      debugPrint('Market price fetch error: $e');
      return {for (var token in tokens) token: 0.0};
    }
  }

  Future<Map<String, dynamic>> getPYUSDMarketData() async {
    try {
      debugPrint('Fetching PYUSD market data from CoinGecko...');

      final simpleData = await _apiGet(
          'simple/price?ids=$_pyusdId&vs_currencies=usd&include_market_cap=true&include_24hr_vol=true&include_24hr_change=true&include_last_updated_at=true');

      if (simpleData == null) {
        throw Exception('Failed to fetch basic PYUSD data');
      }

      // Get detailed coin data
      final detailData = await _apiGet(
          'coins/$_pyusdId?localization=false&tickers=false&market_data=true&sparkline=true');

      if (detailData == null) {
        throw Exception('Failed to fetch detailed PYUSD data');
      }

      // Fetch market chart data for different time frames
      final dayData =
          await _apiGet('coins/$_pyusdId/market_chart?vs_currency=usd&days=1');
      final weekData =
          await _apiGet('coins/$_pyusdId/market_chart?vs_currency=usd&days=7');
      final monthData =
          await _apiGet('coins/$_pyusdId/market_chart?vs_currency=usd&days=30');
      final threeMonthsData =
          await _apiGet('coins/$_pyusdId/market_chart?vs_currency=usd&days=90');

      final marketData = detailData['market_data'];

      // Process price history data
      final Map<String, List<double>> priceHistory = {
        'day': _processPriceData(dayData),
        'week': _processPriceData(weekData),
        'month': _processPriceData(monthData),
        'three_months': _processPriceData(threeMonthsData),
      };

      return {
        'current_price': simpleData[_pyusdId]['usd'] ?? 1.0,
        'market_cap': simpleData[_pyusdId]['usd_market_cap'] ?? 0.0,
        'total_volume': simpleData[_pyusdId]['usd_24h_vol'] ?? 0.0,
        'price_change_24h': simpleData[_pyusdId]['usd_24h_change'] ?? 0.0,
        'circulating_supply': marketData['circulating_supply'] ?? 0.0,
        'total_supply': marketData['total_supply'] ?? 0.0,
        'price_change_7d': marketData['price_change_percentage_7d'] ?? 0.0,
        'price_change_30d': marketData['price_change_percentage_30d'] ?? 0.0,
        'sparkline_7d': marketData['sparkline_7d']['price'] ?? [],
        'supported_chains': ['Ethereum', 'Solana'],
        'last_updated': DateTime.now().toIso8601String(),
        'data_source': 'CoinGecko',
        'is_real_data': true,
        'price_history': priceHistory,
      };
    } catch (e) {
      debugPrint('PYUSD market data fetch error: $e');
      rethrow; // Let the provider handle the error
    }
  }

  // Helper method to process price data from market chart API
  List<double> _processPriceData(Map<String, dynamic>? chartData) {
    if (chartData == null || !chartData.containsKey('prices')) {
      return [];
    }

    final List<dynamic> prices = chartData['prices'];
    return prices.map<double>((price) => (price[1] as num).toDouble()).toList();
  }

  Future<List<Map<String, dynamic>>> fetchExchangeData() async {
    try {
      // Fetch the tickers first
      final tickersData = await _apiGet('coins/paypal-usd/tickers');

      if (tickersData == null || !tickersData.containsKey('tickers')) {
        return [];
      }

      final List<dynamic> tickers = tickersData['tickers'];

      // Instead of fetching each exchange individually (which causes rate limiting),
      // we'll use the data we already have and supplement with fallback logos
      return tickers.map<Map<String, dynamic>>((ticker) {
        final exchangeName = ticker['market']['name'];

        // Use fallback logo URLs directly instead of making additional API calls
        final logoUrl = _getFallbackLogoUrl(exchangeName);
        final exchangeUrl = _getExchangeUrl(exchangeName, ticker['trade_url']);

        return {
          'exchange': exchangeName,
          'pair': '${ticker['base']}/${ticker['target']}',
          'price': ticker['last'],
          'volume': ticker['converted_volume']['usd'] ?? ticker['volume'],
          'trust_score':
              'N/A', // We don't have this without additional API calls
          'logo_url': logoUrl,
          'url': exchangeUrl,
          'last_updated': DateTime.now().toIso8601String(),
          'is_real_data': true,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching exchange data: $e');
      return [];
    }
  }

  // Expanded fallback logo URLs for common exchanges using more reliable sources
  String _getFallbackLogoUrl(String exchangeName) {
    final Map<String, String> logoUrls = {
      // Major exchanges using Cryptoicons.org (very reliable)
      'binance': 'https://cryptoicons.org/api/icon/bnb/200',
      'coinbase':
          'https://assets.coingecko.com/markets/images/23/small/Coinbase_Coin_Primary.png?1621471875',
      'kraken':
          'https://altcoinsbox.com/wp-content/uploads/photo-gallery/imported_from_media_libray/thumb/kraken-logo.webp?bwg=1678268855',
      'huobi': 'https://cryptoicons.org/api/icon/ht/200',
      'okex': 'https://cryptoicons.org/api/icon/okb/200',
      'okx':
          'https://altcoinsbox.com/wp-content/uploads/photo-gallery/imported_from_media_libray/thumb/full-okx-logo.webp?bwg=1678268855',
      'hotcoin':
          'https://play-lh.googleusercontent.com/HbJkWMMZCwJQcA6LARySFQ-oimSubel1f2b0YCXyDgPYeny4rkZKq0cAX208wNZofBDO=w240-h480-rw',

      // Using Cryptologos.cc (very stable CDN)
      'uniswap': 'https://cryptologos.cc/logos/uniswap-uni-logo.png',
      'curve': 'https://cryptologos.cc/logos/curve-dao-token-crv-logo.png',
      'orca': 'https://cryptologos.cc/logos/orca-orca-logo.png',
      'raydium': 'https://cryptologos.cc/logos/raydium-ray-logo.png',
      'bitget':
          'https://cryptologos.cc/logos/bitget-token-new-bgb-logo.png?v=040',
      'htx': 'https://img.cryptorank.io/exchanges/150x150.htx1694688626857.png',
      'latoken': 'https://cryptologos.cc/logos/latoken-la-logo.png?v=040',
      'kucoin': 'https://cryptologos.cc/logos/kucoin-token-kcs-logo.png?v=040',
      'grovex':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTPGzinAdxmz_eOFtSfwN8BOe3XDvAJs0WxWQ&s',
      // Using CDN-hosted logos from exchange websites (most reliable)
      'bullish':
          'https://pbs.twimg.com/profile_images/1675741304209408000/SMMO4Sd1_400x400.jpg',
      'bybit':
          'https://assets.coingecko.com/markets/images/698/small/bybit_spot.png?1646064509',
      'mexc': 'https://www.mexc.com/assets/images/logo/mexc-logo.svg',
      'crypto.com':
          'https://assets.coingecko.com/markets/images/589/small/crypto_com.jpg?1629861084',
      'gate.io': 'https://www.gate.io/images/logo/gate-logo-black.svg',
      'bitfinex': 'https://www.bitfinex.com/assets/bfx-stacked-darkmode.svg',
      'changenow':
          'https://images.seeklogo.com/logo-png/45/1/changenow-now-logo-png_seeklogo-452688.png',

      // Using GitHub repositories for logos (also reliable)
      'gemini':
          'https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/0xd0d6D6C5Fe4a677D343cC433536BB717bAe167dD/logo.png',
      'bitstamp':
          'https://raw.githubusercontent.com/trustwallet/assets/master/dapps/bitstamp.com.png',
      'bittrex':
          'https://raw.githubusercontent.com/trustwallet/assets/master/dapps/bittrex.com.png',
    };

    // Try exact match first
    final lowerName = exchangeName.toLowerCase();
    if (logoUrls.containsKey(lowerName)) {
      return logoUrls[lowerName]!;
    }

    // Try partial match
    for (var key in logoUrls.keys) {
      if (lowerName.contains(key)) {
        return logoUrls[key]!;
      }
    }

    // Default to a generic cryptocurrency icon from a reliable source
    return 'https://cryptoicons.org/api/icon/generic/200';
  }

  // Get exchange URL - first try the trade_url from API, then fallback to known URLs
  String _getExchangeUrl(String exchangeName, String? tradeUrl) {
    // If we have a valid trade URL from the API, use it
    if (tradeUrl != null && tradeUrl.startsWith('http')) {
      return tradeUrl;
    }

    // Fallback to known exchange URLs
    final Map<String, String> exchangeUrls = {
      'binance': 'https://www.binance.com/en/trade/PYUSD_USDT',
      'coinbase': 'https://www.coinbase.com/price/paypal-usd',
      'kraken': 'https://www.kraken.com/prices/pyusd-paypal-usd-price-chart',
      'kucoin': 'https://www.kucoin.com/trade/PYUSD-USDT',
      'bullish': 'https://exchange.bullish.com/trade/PYUSDUSDC',
      'htx': 'https://www.htx.com/price/pyusd/',
      'okx': 'https://www.okx.com/trade-spot/pyusd-usdt',
      'bybit': 'https://www.bybit.com/en-US/trade/spot/PYUSD/USDT',
      'gate.io': 'https://www.gate.io/trade/PYUSD_USDT',
      'mexc': 'https://www.mexc.com/exchange/PYUSD_USDT',
      'bitget': 'https://www.bitget.com/spot/PYUSDUSD',
      'crypto.com': 'https://crypto.com/exchange/trade/spot/PYUSD_USDT',
      'uniswap':
          'https://app.uniswap.org/explore/tokens/ethereum/0x6c3ea9036406852006290770bedfcaba0e23a0e8',
      'curve': 'https://curve.fi/dex/ethereum/pools/?search=pyusd',
      'orca': 'https://www.orca.so/pools',
      'raydium': 'https://raydium.io/swap/',
      'bitfinex': 'https://trading.bitfinex.com/t/PYUSD:USD',
      'gemini': 'https://www.gemini.com/prices/paypal-usd',
      'bitstamp': 'https://www.bitstamp.net/markets/pyusd/usd/',
      'bittrex': 'https://global.bittrex.com/Market/Index?MarketName=USD-PYUSD',
    };

    // Try exact match first
    final lowerName = exchangeName.toLowerCase();
    if (exchangeUrls.containsKey(lowerName)) {
      return exchangeUrls[lowerName]!;
    }

    // Try partial match
    for (var key in exchangeUrls.keys) {
      if (lowerName.contains(key)) {
        return exchangeUrls[key]!;
      }
    }

    // Default to a search for the exchange
    return 'https://www.google.com/search?q=${Uri.encodeComponent("$exchangeName PYUSD trading")}';
  }
}
