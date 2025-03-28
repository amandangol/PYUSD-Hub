import 'dart:convert';

import 'package:googleapis/bigquery/v2.dart' as bq;
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/foundation.dart';

class BigQueryService {
  late bq.BigqueryApi _bigQueryApi;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('BigQuery service already initialized');
      return;
    }

    debugPrint('Initializing BigQuery service...');
    try {
      final credentials = ServiceAccountCredentials.fromJson({
        "type": "service_account",
        "project_id": "oceanic-impact-451616-f5",
        "private_key_id": "a63b386e893a4939fcb25338a2645719d004d290",
        "private_key":
            "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQC8nhynx+BFXbGK\nPQ1ynqwZyxyPFX0W1+4EoR+rQBcWatHbrUnTC3zk6TFQH8ME4cm6Eo1vcbM9dEd4\nuNDBhsoWk5YAUzQp8UoaxywShISZ3QpK5AColIRG6uDuq8GlaPI2Xz0806135kmW\nKoEqm1oIX++BUh/lDtgum8wrww4hRwi1Ik4nHaDTL83SXXWRcj8UHI7n0P8GaFm3\ncJE6fPUPsHwche9QPseMCEtN1OdZYaAXS4u3VgIaPo9EjBt7dtwz4Wj7NNaLMe/F\nXSl37ttVQCsnjNeI4QDiqOYq4Cw9f9xKNROtOrE+cVT3aO4fObIQrCUaV0dgDS0J\ncC3vbrcrAgMBAAECggEAHDIyrG43u4bfFIA982V+6rgvQ8B9m52Z6j0/47TH/sTn\nLETCZXcxK3MkuQqWd7NdGaDOXduMZOJuEMDoDBYfPbLAWLoXcTGt10Tw9K+0tt+R\nO1LMOmdBQuy3xVYNs7F1i+U+3Unzg5n8ZCNkfb8NfXUB874YIIDQll8Z7WzSPu0C\nH0yBMVWgQYGEMcBhcc3I+z9cKfQYPzK9y1SQEruvL99N240O/kFZrNN9LIKLctZg\nvQh74tta5On5eOKQoKhGoc0kwBgcGVVwXq1f8UyrSKdtw1ZYRWFoeJ4xa8lc38vu\nlLgsyXnUXSV7Tu5ZZ9XzaEHnV8Z6XsX4KfAOUtb6mQKBgQD+CIb/OhVaD8cCjOfJ\nZPvnNpU64fHWUXRAhJU4E3yEyXLGnNzgHK6Elmbc6xqvgPHG4/uYYnEThYGREKhU\nUW4xvIcXSB1a27XwKTsWQPXMqUdT13PeqrGT4N71lhlFlXj2BBBTiHG/dPd7BdIG\nRHI7LipMKSz6N7cx9J41AoJwBQKBgQC+E++rsXWrT1FWMy3weU5RJiLfPN6a46Yg\nGGCaXcBXuS0SKTkaMbMEUfinldHeBm5YDZL6KzxsVv7U5OV9PD/R18D/VId/1CGe\n+flmXs5K644Pp/9f4Z3iEhpeRv4E2+alCQ6UJi4MIIvypv75djGZlKFfBpjNomiP\nqVcFk0mhbwKBgFcdAX5AotXRl0NOoqWzlZbCZwZcORxvrlf5n1othIPcuRlW7X+F\nFmutT/TuQqZwp3i28a5eA7zYCYh/l9niWtF/fywCtN5Vfdyvpu2ItUHLwwQDXF69\nVkwJzyuUn3H3QhXLavXaUnd/Wua7Jjyz+CBHQoX/kMb1mELvSdmP1L8pAoGAQMsC\n8//2IINVMpEXo9V2AOuDD53sM9hOFLq6k2RJ4J1a48nxkSBH6b0XiejkNU7z5kga\nRfTfD/9HtsKgB+S1zI5DV8Y0ujpRi6OihGbk410Qe/3Ea6a47wtEucZxaK6dHLzN\nn2q0X6XojrqmR9smZTfpGj9hbxdhlTcgVuIyQzkCgYAaeMzXveDfB/OuU52dbmeB\nIE0wmBxLUGl85nC6+b7o+qMN5greuRjm/SmDUcUEjdzXWqhzCK72s/PYCEUuwJaJ\nPQ6cKzzu5MDchy3SP9uYUdhP1wAcpO1mI+CYzthC2e+PPYXPscNOZAP7WapYG3Yb\n8QzEGvMhAQ/7O+bM/VQSJQ==\n-----END PRIVATE KEY-----\n",
        "client_email":
            "flutter-bigquery-client@oceanic-impact-451616-f5.iam.gserviceaccount.com",
        "client_id": "101376136133634723687",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":
            "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url":
            "https://www.googleapis.com/robot/v1/metadata/x509/flutter-bigquery-client%40oceanic-impact-451616-f5.iam.gserviceaccount.com",
        "universe_domain": "googleapis.com"
      });

      final client = await clientViaServiceAccount(
        credentials,
        [bq.BigqueryApi.cloudPlatformScope],
      );

      _bigQueryApi = bq.BigqueryApi(client);
      _isInitialized = true;
      debugPrint('BigQuery service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing BigQuery service: $e');
      rethrow;
    }
  }

  String _getFieldValue(bq.TableRow row, int index) {
    if (row.f == null || index >= row.f!.length) {
      debugPrint('Warning: Invalid field index $index or null fields');
      return '0';
    }
    final value = row.f![index].v;
    debugPrint('Field $index value: $value');
    return value?.toString() ?? '0';
  }

  Future<Map<String, dynamic>> getAllPYUSDData() async {
    debugPrint('Fetching all PYUSD data...');
    await initialize();

    // First, check if we can find any transactions at all
    final checkQuery = '''
      SELECT 
        token_address,
        COUNT(*) as transaction_count,
        MIN(block_timestamp) as earliest_tx,
        MAX(block_timestamp) as latest_tx,
        COUNT(DISTINCT from_address) as unique_senders,
        COUNT(DISTINCT to_address) as unique_receivers,
        SUM(CAST(value AS NUMERIC)) as total_volume
      FROM \`bigquery-public-data.crypto_ethereum.token_transfers\`
      WHERE token_address = '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8'
      GROUP BY token_address
    ''';

    try {
      debugPrint('Checking for PYUSD transactions...');
      final checkResponse = await _bigQueryApi.jobs.query(
        bq.QueryRequest(
          query: checkQuery,
          useLegacySql: false,
          maximumBytesBilled: '1000000000000',
        ),
        "oceanic-impact-451616-f5",
      );

      debugPrint(
          'Check query response: ${checkResponse.rows?.length ?? 0} rows');
      if (checkResponse.rows != null && checkResponse.rows!.isNotEmpty) {
        final checkRow = checkResponse.rows![0];
        debugPrint(
            'Found token data: ${checkRow.f?.map((f) => '${f.v}').join(', ')}');
      } else {
        debugPrint('No transactions found for this token address');
        // Let's try to find any recent transactions to verify the dataset is working
        final sampleQuery = '''
          SELECT 
            token_address,
            COUNT(*) as transaction_count,
            MIN(block_timestamp) as earliest_tx,
            MAX(block_timestamp) as latest_tx
          FROM \`bigquery-public-data.crypto_ethereum.token_transfers\`
          WHERE block_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
          GROUP BY token_address
          ORDER BY transaction_count DESC
          LIMIT 5
        ''';

        final sampleResponse = await _bigQueryApi.jobs.query(
          bq.QueryRequest(
            query: sampleQuery,
            useLegacySql: false,
            maximumBytesBilled: '1000000000000',
          ),
          "oceanic-impact-451616-f5",
        );

        debugPrint(
            'Sample query response: ${sampleResponse.rows?.length ?? 0} rows');
        if (sampleResponse.rows != null && sampleResponse.rows!.isNotEmpty) {
          debugPrint(
              'Sample data: ${sampleResponse.rows!.map((row) => row.f?.map((f) => '${f.v}').join(', ')).join('\n')}');
        }
      }

      // Now get the actual data with a longer time window
      final query = '''
        WITH base_transactions AS (
          SELECT
            from_address,
            to_address,
            CAST(value AS NUMERIC) as value,
            block_timestamp
          FROM \`bigquery-public-data.crypto_ethereum.token_transfers\`
          WHERE token_address = '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8'
          AND block_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 DAY)
          AND value != '0'
          AND from_address != '0x0000000000000000000000000000000000000000'
          AND to_address != '0x0000000000000000000000000000000000000000'
        ),
        stats AS (
          SELECT
            COUNT(DISTINCT from_address) as unique_senders,
            COUNT(DISTINCT to_address) as unique_receivers,
            COALESCE(SUM(value), 0) as total_volume,
            COUNT(*) as total_transactions,
            MIN(block_timestamp) as earliest_tx,
            MAX(block_timestamp) as latest_tx
          FROM base_transactions
        ),
        top_holders AS (
          SELECT
            to_address as address,
            SUM(value) as balance
          FROM base_transactions
          WHERE to_address != ''
          GROUP BY to_address
          HAVING balance > 0
          ORDER BY balance DESC
          LIMIT 10
        )
        SELECT
          s.unique_senders,
          s.unique_receivers,
          s.total_volume,
          s.total_transactions,
          s.earliest_tx,
          s.latest_tx,
          CASE 
            WHEN COUNT(th.address) > 0 THEN ARRAY_AGG(STRUCT(th.address, th.balance))
            ELSE []
          END as top_holders
        FROM stats s
        LEFT JOIN top_holders th ON TRUE
        GROUP BY s.unique_senders, s.unique_receivers, s.total_volume, s.total_transactions, s.earliest_tx, s.latest_tx
      ''';

      debugPrint('Executing main query...');
      final response = await _bigQueryApi.jobs.query(
        bq.QueryRequest(
          query: query,
          useLegacySql: false,
          maximumBytesBilled: '1000000000000',
        ),
        "oceanic-impact-451616-f5",
      );

      debugPrint(
          'BigQuery response received: ${response.rows?.length ?? 0} rows');

      if (response.rows == null || response.rows!.isEmpty) {
        debugPrint('No data found for PYUSD');
        return {
          'stats': {
            'uniqueSenders': 0,
            'uniqueReceivers': 0,
            'totalVolume': 0.0,
            'totalTransactions': 0,
          },
          'topHolders': [],
        };
      }

      final row = response.rows![0];
      debugPrint('Raw row data: ${row.f?.map((f) => '${f.v}').join(', ')}');

      final stats = {
        'uniqueSenders': int.tryParse(_getFieldValue(row, 0)) ?? 0,
        'uniqueReceivers': int.tryParse(_getFieldValue(row, 1)) ?? 0,
        'totalVolume': double.tryParse(_getFieldValue(row, 2)) ?? 0.0,
        'totalTransactions': int.tryParse(_getFieldValue(row, 3)) ?? 0,
        'earliestTx': _getFieldValue(row, 4),
        'latestTx': _getFieldValue(row, 5),
      };

      debugPrint('Parsed stats: $stats');

      // Parse top holders
      final topHoldersStr = _getFieldValue(row, 6);
      debugPrint('Raw top holders string: $topHoldersStr');
      final topHolders = _parseTopHolders(topHoldersStr);
      debugPrint('Parsed top holders: $topHolders');

      final result = {
        'stats': stats,
        'topHolders': topHolders,
      };

      debugPrint('Final result: $result');
      return result;
    } catch (e) {
      debugPrint('Error fetching PYUSD data: $e');
      if (e.toString().contains('Query exceeded limit for bytes billed')) {
        throw Exception(
            'Query requires more data scanning than allowed. Reducing time range or sampling data might help.');
      }
      if (e.toString().contains('Quota exceeded')) {
        throw Exception(
            'BigQuery quota exceeded. Please try again later or adjust query parameters.');
      }
      rethrow;
    }
  }

  List<Map<String, dynamic>> _parseTopHolders(String jsonStr) {
    try {
      debugPrint('Parsing top holders JSON: $jsonStr');

      // Handle empty array case
      if (jsonStr == '[]' || jsonStr.isEmpty) {
        debugPrint('Empty top holders array');
        return [];
      }

      // Remove the outer array brackets
      final content = jsonStr.substring(1, jsonStr.length - 1);
      debugPrint('Content after removing brackets: $content');

      // Split by }, { to handle multiple items
      final items = content.split('}, {');
      debugPrint('Split items: $items');

      return items
          .map((item) {
            // Clean up the item string
            final cleanItem = item
                .replaceAll('{', '')
                .replaceAll('}', '')
                .replaceAll('"', '');

            debugPrint('Cleaned item: $cleanItem');

            // Split into key-value pairs
            final pairs = cleanItem.split(', ');

            // Extract address and balance
            String address = '';
            double balance = 0.0;

            for (final pair in pairs) {
              final parts = pair.split(':');
              if (parts.length == 2) {
                final key = parts[0].trim();
                final value = parts[1].trim();

                if (key == 'address' && value.isNotEmpty) {
                  address = value;
                } else if (key == 'balance') {
                  balance = double.tryParse(value) ?? 0.0;
                }
              }
            }

            debugPrint(
                'Extracted values - address: $address, balance: $balance');

            // Only return holders with valid addresses
            if (address.isEmpty) {
              return null;
            }

            return {
              'address': address,
              'balance': balance,
            };
          })
          .where((holder) => holder != null)
          .map((holder) => holder!)
          .toList();
    } catch (e) {
      debugPrint('Error parsing top holders: $e');
      debugPrint('Problematic JSON string: $jsonStr');
      return [];
    }
  }
}
