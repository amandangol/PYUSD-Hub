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

      final marketData = detailData['market_data'];

      return {
        'current_price': simpleData[_pyusdId]['usd'] ?? 1.0,
        'market_cap': simpleData[_pyusdId]['usd_market_cap'] ?? 0.0,
        'total_volume': simpleData[_pyusdId]['usd_24h_vol'] ?? 0.0,
        'price_change_24h': simpleData[_pyusdId]['usd_24h_change'] ?? 0.0,
        'circulating_supply': marketData['circulating_supply'] ?? 0.0,
        'total_supply': marketData['total_supply'] ?? 0.0,
        'price_change_7d': marketData['price_change_percentage_7d'] ?? 0.0,
        'price_change_30d': marketData['price_change_percentage_30d'] ?? 0.0,
        'sparkline_7d':
            detailData['market_data']['sparkline_7d']['price'] ?? [],
        'supported_chains': ['Ethereum', 'Solana'],
        'last_updated': DateTime.now().toIso8601String(),
        'data_source': 'CoinGecko',
        'is_real_data': true,
      };
    } catch (e) {
      debugPrint('PYUSD market data fetch error: $e');
      rethrow; // Let the provider handle the error
    }
  }

  Future<List<Map<String, dynamic>>> fetchExchangeData() async {
    try {
      // Fetch the tickers first
      final tickersData = await _apiGet('coins/paypal-usd/tickers');

      if (tickersData == null || !tickersData.containsKey('tickers')) {
        return [];
      }

      final List<dynamic> tickers = tickersData['tickers'];

      // Extract unique exchange IDs from tickers
      final Set<String> exchangeIds = tickers
          .map<String>((ticker) => ticker['market']['identifier'].toString())
          .toSet();

      // Create a map to store exchange data
      final Map<String, Map<String, dynamic>> exchangeInfo = {};

      // For each exchange ID, fetch detailed info
      for (String id in exchangeIds) {
        try {
          final exchangeData = await _apiGet('exchanges/$id');

          if (exchangeData != null) {
            exchangeInfo[id] = {
              'name': exchangeData['name'],
              'logo': exchangeData['image'],
              'url': exchangeData['url'],
              'trust_score': exchangeData['trust_score'],
            };
          } else {
            // Fallback to hardcoded logos if API fails
            exchangeInfo[id] = {
              'name': id,
              'logo': _getFallbackLogoUrl(id),
              'trust_score': null,
            };
          }

          // Add a small delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          debugPrint('Error fetching exchange $id: $e');
          // Fallback to hardcoded logos
          exchangeInfo[id] = {
            'name': id,
            'logo': _getFallbackLogoUrl(id),
            'trust_score': null,
          };
        }
      }

      // Map tickers with exchange info
      return tickers.map<Map<String, dynamic>>((ticker) {
        final exchangeId = ticker['market']['identifier'];
        final exchangeName = ticker['market']['name'];
        final exchangeData = exchangeInfo[exchangeId] ?? {};

        return {
          'exchange': exchangeName,
          'pair': '${ticker['base']}/${ticker['target']}',
          'price': ticker['last'],
          'volume': ticker['converted_volume']['usd'] ?? ticker['volume'],
          'trust_score': exchangeData['trust_score']?.toString() ?? 'N/A',
          'logo_url': exchangeData['logo'] ?? _getFallbackLogoUrl(exchangeName),
          'last_updated': DateTime.now().toIso8601String(),
          'is_real_data': true,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching exchange data: $e');
      return [];
    }
  }

  // Fallback logo URLs for common exchanges
  String _getFallbackLogoUrl(String exchangeName) {
    final Map<String, String> logoUrls = {
      'binance':
          'https://assets.coingecko.com/markets/images/52/small/binance.jpg?1519353250',
      'coinbase':
          'https://assets.coingecko.com/markets/images/23/small/Coinbase_Coin_Primary.png?1621471875',
      'kraken':
          'https://assets.coingecko.com/markets/images/29/small/kraken.jpg?1584251255',
      'kucoin':
          'https://assets.coingecko.com/markets/images/61/small/kucoin.png?1640584259',
      'ftx':
          'https://assets.coingecko.com/markets/images/451/small/FTX_Exchange.jpg?1564414329',
      'huobi':
          'https://assets.coingecko.com/markets/images/25/small/huobi.jpg?1605065662',
      'htx':
          'https://chainwire.org/wp-content/uploads/2025/02/featured_image_ID__Logo_1739290805eVbm1g3Gqv_1739290805Th3KKbad7S.jpg',
      'okex':
          'https://assets.coingecko.com/markets/images/96/small/okex.jpg?1519349636',
      'bitfinex':
          'https://assets.coingecko.com/markets/images/4/small/BItfinex.png?1615895883',
      'gemini':
          'https://assets.coingecko.com/markets/images/50/small/gemini.png?1605704107',
      'bitstamp':
          'https://assets.coingecko.com/markets/images/9/small/bitstamp.jpg?1519627979',
      'gate.io':
          'https://assets.coingecko.com/markets/images/60/small/gate_io_logo.jpg?1519353563',
      'bittrex':
          'https://assets.coingecko.com/markets/images/10/small/BG-color-250x250_icon.png?1596167574',
      'bybit':
          'https://assets.coingecko.com/markets/images/698/small/bybit_spot.png?1646064509',
      'mexc':
          'https://assets.coingecko.com/markets/images/405/small/MEXC_logo.jpg?1629378483',
      'crypto.com':
          'https://assets.coingecko.com/markets/images/589/small/crypto_com.jpg?1629861084',
      'bullish':
          'https://pbs.twimg.com/profile_images/1675741304209408000/SMMO4Sd1_400x400.jpg',
      'curve':
          'https://assets.coingecko.com/markets/images/517/small/curve.png?1591605481',
      'curve (ethereum)':
          'https://assets.coingecko.com/markets/images/517/small/curve.png?1591605481',
      'uniswap': 'https://cryptologos.cc/logos/uniswap-uni-logo.png?v=040',
      'uniswap v3': 'https://cryptologos.cc/logos/uniswap-uni-logo.png?v=040',
      'uniswap v3 (ethereum)':
          'https://assets.coingecko.com/markets/images/535/small/uniswap-v3.png?1620778969',
      'orca': 'https://cryptologos.cc/logos/orca-orca-logo.png?v=040',
      'bitget':
          'https://cryptologos.cc/logos/bitget-token-new-bgb-logo.svg?v=040',
      'raydium': 'https://cryptologos.cc/logos/raydium-ray-logo.svg?v=040',
    };

    // Try exact match first
    if (logoUrls.containsKey(exchangeName.toLowerCase())) {
      return logoUrls[exchangeName.toLowerCase()]!;
    }

    // Try partial match
    for (var key in logoUrls.keys) {
      if (exchangeName.toLowerCase().contains(key)) {
        return logoUrls[key]!;
      }
    }

    return '';
  }
}
