import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/bigquery/v2.dart' as bq;

class BigQueryService {
  // GCP project details
  static const String projectId = 't-bounty-433704-e4';

  // Timeout duration for network requests
  static const Duration _timeout = Duration(seconds: 15);

  // Service account credentials
  ServiceAccountCredentials? _credentials;
  AutoRefreshingAuthClient? _client;
  bq.BigqueryApi? _bigQueryApi;

  // Flag to track if BigQuery API is available
  bool _apiAvailable = false;

  // Initialize service account credentials
  Future<bool> _initializeCredentials() async {
    if (_client != null) return _apiAvailable;

    try {
      // Load service account JSON from assets
      final String jsonString =
          await rootBundle.loadString('assets/keys/bigquery-service.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      _credentials = ServiceAccountCredentials.fromJson(jsonMap);
      _client = await clientViaServiceAccount(
          _credentials!, [bq.BigqueryApi.bigqueryScope]);

      _bigQueryApi = bq.BigqueryApi(_client!);
      _apiAvailable = true;

      print('BigQuery client initialized successfully');
      return true;
    } catch (e) {
      print('Error initializing BigQuery credentials: $e');
      _apiAvailable = false;
      return false;
    }
  }

  // Query daily supply metrics with optimized query
  Future<Map<String, dynamic>> queryDailySupplyMetrics(int days) async {
    final String endDate = DateTime.now().toIso8601String();
    final String startDate =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();

    // Simplified query to get daily supply changes
    final String query = '''
      WITH daily_activity AS (
        SELECT
          DATE(block_timestamp) AS date,
          CASE 
            WHEN from_address = '0x0000000000000000000000000000000000000000' THEN SUM(CAST(value AS FLOAT64)/1000000)
            ELSE 0
          END AS minted,
          CASE 
            WHEN to_address = '0x0000000000000000000000000000000000000000' THEN SUM(CAST(value AS FLOAT64)/1000000)
            ELSE 0
          END AS burned
        FROM
          `bigquery-public-data.crypto_ethereum.token_transfers`
        WHERE
          token_address = '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8'
          AND block_timestamp BETWEEN TIMESTAMP('$startDate') AND TIMESTAMP('$endDate')
        GROUP BY
          date, from_address, to_address
        HAVING
          from_address = '0x0000000000000000000000000000000000000000' OR
          to_address = '0x0000000000000000000000000000000000000000'
      )
      SELECT
        date,
        SUM(minted) AS minted,
        SUM(burned) AS burned,
        SUM(minted) - SUM(burned) AS net_change
      FROM
        daily_activity
      GROUP BY
        date
      ORDER BY
        date
    ''';

    return _executeQuery(query);
  }

  // Query holder distribution with optimized categories
  Future<Map<String, dynamic>> queryHolderDistribution() async {
    // Simplified query to categorize holders
    final String query = '''
      WITH holder_balances AS (
        SELECT
          address,
          SUM(value) AS balance
        FROM (
          SELECT
            to_address AS address,
            CAST(value AS FLOAT64)/1000000 AS value
          FROM
            `bigquery-public-data.crypto_ethereum.token_transfers`
          WHERE
            token_address = '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8'
          UNION ALL
          SELECT
            from_address AS address,
            -CAST(value AS FLOAT64)/1000000 AS value
          FROM
            `bigquery-public-data.crypto_ethereum.token_transfers`
          WHERE
            token_address = '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8'
        )
        GROUP BY address
        HAVING balance > 0
      ),
      categorized_holders AS (
        SELECT
          CASE
            WHEN balance > 1000000 THEN 'whale'
            WHEN balance > 100000 THEN 'large'
            WHEN balance > 10000 THEN 'medium'
            ELSE 'small'
          END AS category,
          COUNT(*) AS holder_count,
          SUM(balance) AS total_balance
        FROM holder_balances
        GROUP BY category
      )
      SELECT
        category,
        holder_count,
        total_balance,
        total_balance / SUM(total_balance) OVER() * 100 AS percentage
      FROM categorized_holders
      ORDER BY total_balance DESC
    ''';

    return _executeQuery(query);
  }

  // Helper method to execute BigQuery queries with retry logic
  Future<Map<String, dynamic>> _executeQuery(String query) async {
    final bool initialized = await _initializeCredentials();

    // If API isn't available, return mock data immediately
    if (!initialized || !_apiAvailable) {
      return _getMockData(_getMockDataTypeFromQuery(query));
    }

    int retries = 2;
    while (retries >= 0) {
      try {
        // Create the query job request
        final bq.QueryRequest queryRequest = bq.QueryRequest()
          ..query = query
          ..useLegacySql = false
          ..timeoutMs = _timeout.inMilliseconds;

        // Execute the query
        final bq.QueryResponse response =
            await _bigQueryApi!.jobs.query(queryRequest, projectId);

        // Format the response to match the expected structure
        final Map<String, dynamic> formattedResponse = {
          'schema': {
            'fields': response.schema?.fields
                    ?.map((field) => {
                          'name': field.name,
                          'type': field.type,
                        })
                    .toList() ??
                [],
          },
          'rows': response.rows
                  ?.map((row) => {
                        'f': row.f
                                ?.map((cell) => {
                                      'v': cell.v,
                                    })
                                .toList() ??
                            [],
                      })
                  .toList() ??
              [],
        };

        return formattedResponse;
      } catch (e) {
        retries--;
        print('BigQuery attempt failed ($retries retries left): $e');

        if (retries < 0) {
          print('BigQuery error after retries: $e');
          return _getMockData(_getMockDataTypeFromQuery(query));
        }

        // Wait before retrying
        await Future.delayed(Duration(seconds: 2));
      }
    }

    // This should never be reached due to the return in the catch block above
    return {'error': 'Failed to execute query'};
  }

  // Helper method to determine the type of mock data to return based on the query
  String _getMockDataTypeFromQuery(String query) {
    if (query.contains('daily_activity') || query.contains('net_change')) {
      return 'supply';
    } else if (query.contains('holder_balances') ||
        query.contains('categorized_holders')) {
      return 'holders';
    } else {
      return 'default';
    }
  }

  // Method to get offline/mock data when network is unavailable
  Map<String, dynamic> _getMockData(String queryType) {
    switch (queryType) {
      case 'supply':
        return {
          'rows': List.generate(
            30,
            (i) => {
              'f': [
                {
                  'v': DateTime.now()
                      .subtract(Duration(days: 29 - i))
                      .toIso8601String()
                      .split('T')[0]
                },
                {'v': (i * 500000 + 100000).toString()},
                {'v': ((i * 100000) % 500000).toString()},
                {'v': (i * 400000 + 100000).toString()}
              ]
            },
          ),
          'isOfflineData': true
        };
      case 'holders':
        return {
          'rows': [
            {
              'f': [
                {'v': 'small'},
                {'v': '9500'},
                {'v': '5000000'},
                {'v': '10.5'}
              ]
            },
            {
              'f': [
                {'v': 'medium'},
                {'v': '400'},
                {'v': '10000000'},
                {'v': '21.0'}
              ]
            },
            {
              'f': [
                {'v': 'large'},
                {'v': '80'},
                {'v': '15000000'},
                {'v': '31.6'}
              ]
            },
            {
              'f': [
                {'v': 'whale'},
                {'v': '20'},
                {'v': '17500000'},
                {'v': '36.9'}
              ]
            }
          ],
          'isOfflineData': true
        };
      default:
        return {'rows': [], 'isOfflineData': true};
    }
  }
}
