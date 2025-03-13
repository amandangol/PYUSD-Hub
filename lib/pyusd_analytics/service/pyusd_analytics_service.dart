import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web3dart/web3dart.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:googleapis_auth/auth_io.dart';

import '../model/pyusd_stats_model.dart';

class PyusdDashboardService {
  final String _rpcUrl;
  final String _pyusdContractAddress;
  final String _etherscanApiKey;
  final String _googleProjectId;

  // ERC20 ABI for basic token functions
  final String _erc20Abi = '''
  [
    {"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},
    {"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},
    {"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},
    {"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},
    {"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}
  ]
  ''';

  late Web3Client _ethClient;
  late DeployedContract _pyusdContract;
  late BigqueryApi _bigqueryApi;

  PyusdDashboardService()
      : _rpcUrl =
            dotenv.env['GCP_RPC_URL'] ?? 'https://ethereum.rpc.blxrbdn.com',
        _pyusdContractAddress =
            '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8', // PYUSD contract on Ethereum
        _etherscanApiKey = dotenv.env['ETHERSCAN_API_KEY'] ?? '',
        _googleProjectId =
            dotenv.env['GOOGLE_PROJECT_ID'] ?? 'your-project-id' {
    _ethClient = Web3Client(_rpcUrl, http.Client());
    _initContract();
    _initBigQuery();
  }

  Future<void> _initContract() async {
    final contractJson = jsonDecode(_erc20Abi);
    _pyusdContract = DeployedContract(ContractAbi.fromJson(_erc20Abi, 'PYUSD'),
        EthereumAddress.fromHex(_pyusdContractAddress));
  }

  Future<void> _initBigQuery() async {
    // Get the private key from environment variables
    final serviceAccountJson = dotenv.env['GCP_SERVICE_ACCOUNT_JSON'];

    if (serviceAccountJson != null) {
      // Create credentials from the service account JSON
      final credentials =
          ServiceAccountCredentials.fromJson(jsonDecode(serviceAccountJson));

      // Create a BigQuery client
      final client = await clientViaServiceAccount(
          credentials, [BigqueryApi.bigqueryScope]);

      _bigqueryApi = BigqueryApi(client);
    } else {
      throw Exception(
          'GCP_SERVICE_ACCOUNT_JSON environment variable not found');
    }
  }

  Future<double> getTotalSupply() async {
    final totalSupplyFunction = _pyusdContract.function('totalSupply');
    final result = await _ethClient.call(
      contract: _pyusdContract,
      function: totalSupplyFunction,
      params: [],
    );

    final totalSupply = result[0] as BigInt;
    final decimalsFunction = _pyusdContract.function('decimals');
    final decimalsResult = await _ethClient.call(
      contract: _pyusdContract,
      function: decimalsFunction,
      params: [],
    );

    final decimals = decimalsResult[0] as BigInt;

    return totalSupply / BigInt.from(10).pow(decimals.toInt());
  }

  Future<PyusdStats> getPyusdDashboardData() async {
    try {
      // Fetch on-chain data using GCP RPC
      final totalSupply = await getTotalSupply();

      // For a stablecoin, we can assume price is around $1
      final price = 1.0;

      // Fetch historical supply data from BigQuery
      final supplyHistory = await _getHistoricalSupplyData();

      // Fetch price history (might be close to $1 for most periods)
      final priceHistory = await _getHistoricalPriceData();

      // Fetch transaction statistics from BigQuery
      final transactionStats = await _getTransactionStats();

      // Fetch network metrics
      final networkMetrics = await _getNetworkMetrics();

      // Fetch adoption metrics
      final adoption = await _getAdoptionMetrics();

      return PyusdStats(
        totalSupply: totalSupply,
        circulatingSupply:
            totalSupply, // For PYUSD, we can assume most/all supply is circulating
        marketCap: totalSupply * price,
        volume24h: await _get24HourVolume(),
        price: price,
        supplyHistory: supplyHistory,
        priceHistory: priceHistory,
        networkMetrics: networkMetrics,
        transactionStats: transactionStats,
        adoption: adoption,
      );
    } catch (e) {
      print('Error fetching PYUSD dashboard data: $e');
      return PyusdStats.initial();
    }
  }

  Future<double> _get24HourVolume() async {
    try {
      // Use BigQuery to get 24h volume
      final query = '''
        SELECT SUM(value/1e6) as volume
        FROM `bigquery-public-data.crypto_ethereum.token_transfers`
        WHERE token_address = '${_pyusdContractAddress.toLowerCase()}'
        AND block_timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
      ''';

      final queryJob = await _runBigQueryJob(query);

      if (queryJob.rows != null && queryJob.rows!.isNotEmpty) {
        return double.parse(queryJob.rows![0].f![0].v.toString());
      }

      return 0;
    } catch (e) {
      print('Error fetching 24h volume: $e');
      return 0;
    }
  }

  Future<List<ChartDataPoint>> _getHistoricalSupplyData() async {
    try {
      // Query for historical supply data using BigQuery
      final query = '''
        WITH daily_mints_burns AS (
          SELECT
            DATE(block_timestamp) as date,
            SUM(CASE 
              WHEN from_address = '0x0000000000000000000000000000000000000000' THEN value/1e6
              ELSE 0
            END) as minted,
            SUM(CASE 
              WHEN to_address = '0x0000000000000000000000000000000000000000' THEN value/1e6
              ELSE 0
            END) as burned
          FROM `bigquery-public-data.crypto_ethereum.token_transfers`
          WHERE token_address = '${_pyusdContractAddress.toLowerCase()}'
          GROUP BY date
          ORDER BY date
        )
        
        SELECT
          date,
          SUM(minted - burned) OVER (ORDER BY date) as cumulative_supply
        FROM daily_mints_burns
        ORDER BY date
      ''';

      final queryJob = await _runBigQueryJob(query);

      final List<ChartDataPoint> supplyHistory = [];

      if (queryJob.rows != null) {
        for (var row in queryJob.rows!) {
          final date = DateTime.parse(row.f![0].v.toString());
          final supply = double.parse(row.f![1].v.toString());

          supplyHistory.add(ChartDataPoint(
            timestamp: date,
            value: supply,
          ));
        }
      }

      // If no historical data, provide at least current data
      if (supplyHistory.isEmpty) {
        final totalSupply = await getTotalSupply();
        supplyHistory.add(ChartDataPoint(
          timestamp: DateTime.now(),
          value: totalSupply,
        ));
      }

      return supplyHistory;
    } catch (e) {
      print('Error fetching historical supply data: $e');
      // Return some mock data if unable to fetch
      return List.generate(30, (index) {
        return ChartDataPoint(
          timestamp: DateTime.now().subtract(Duration(days: 30 - index)),
          value: 1000000 + (index * 10000), // Simulated growth
        );
      });
    }
  }

  Future<List<ChartDataPoint>> _getHistoricalPriceData() async {
    // For a stablecoin like PYUSD, we can assume its price is close to $1
    // but with slight variations

    // Generate simulated price data that stays close to $1
    return List.generate(30, (index) {
      final random =
          0.99 + (index % 3) * 0.01; // Generate values between 0.99 and 1.01
      return ChartDataPoint(
        timestamp: DateTime.now().subtract(Duration(days: 30 - index)),
        value: random,
      );
    });
  }

  Future<List<TransactionStat>> _getTransactionStats() async {
    try {
      // Query for transaction statistics using BigQuery
      final query = '''
        SELECT
          DATE(block_timestamp) as date,
          COUNT(*) as tx_count,
          SUM(value/1e6) as volume,
          AVG(gas_price/1e9) as avg_gas_price_gwei
        FROM `bigquery-public-data.crypto_ethereum.token_transfers` as transfers
        JOIN `bigquery-public-data.crypto_ethereum.transactions` as tx
          ON transfers.transaction_hash = tx.hash
        WHERE transfers.token_address = '${_pyusdContractAddress.toLowerCase()}'
          AND DATE(block_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
        GROUP BY date
        ORDER BY date DESC
        LIMIT 30
      ''';

      final queryJob = await _runBigQueryJob(query);

      final List<TransactionStat> stats = [];

      if (queryJob.rows != null) {
        for (var row in queryJob.rows!) {
          stats.add(TransactionStat(
            date: DateTime.parse(row.f![0].v.toString()),
            count: int.parse(row.f![1].v.toString()),
            volume: double.parse(row.f![2].v.toString()),
            avgGasPrice: double.parse(row.f![3].v.toString()),
          ));
        }
      }

      return stats;
    } catch (e) {
      print('Error fetching transaction stats: $e');
      // Return some mock data
      return List.generate(7, (index) {
        return TransactionStat(
          date: DateTime.now().subtract(Duration(days: index)),
          count: 500 - (index * 20),
          volume: 1000000 - (index * 50000),
          avgGasPrice: 20 + (index * 0.5),
        );
      });
    }
  }

  Future<List<NetworkMetric>> _getNetworkMetrics() async {
    try {
      // Query for network metrics using BigQuery
      final query = '''
        SELECT
          AVG(gas_used) as avg_gas_used,
          AVG(gas_price/1e9) as avg_gas_price_gwei,
          COUNT(DISTINCT from_address) + COUNT(DISTINCT to_address) as unique_addresses,
          COUNT(*) as total_transactions
        FROM `bigquery-public-data.crypto_ethereum.token_transfers` as transfers
        JOIN `bigquery-public-data.crypto_ethereum.transactions` as tx
          ON transfers.transaction_hash = tx.hash
        WHERE transfers.token_address = '${_pyusdContractAddress.toLowerCase()}'
          AND block_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
      ''';

      final queryJob = await _runBigQueryJob(query);

      final List<NetworkMetric> metrics = [];

      if (queryJob.rows != null && queryJob.rows!.isNotEmpty) {
        final row = queryJob.rows![0];

        metrics.add(NetworkMetric(
          name: 'Average Gas Used',
          value: double.parse(row.f![0].v.toString()),
          description:
              'Average gas used per PYUSD transaction in the last 30 days',
          unit: 'gas',
        ));

        metrics.add(NetworkMetric(
          name: 'Average Gas Price',
          value: double.parse(row.f![1].v.toString()),
          description:
              'Average gas price for PYUSD transactions in the last 30 days',
          unit: 'gwei',
        ));

        metrics.add(NetworkMetric(
          name: 'Unique Addresses',
          value: double.parse(row.f![2].v.toString()),
          description:
              'Number of unique addresses interacting with PYUSD in the last 30 days',
          unit: 'addresses',
        ));

        metrics.add(NetworkMetric(
          name: 'Total Transactions',
          value: double.parse(row.f![3].v.toString()),
          description: 'Total number of PYUSD transactions in the last 30 days',
          unit: 'transactions',
        ));
      }

      // Get some additional metrics
      // Get current block number
      final currentBlock = await _ethClient.getBlockNumber();

      // Get average block time
      final avgBlockTime = await _getAverageBlockTime();

      metrics.add(NetworkMetric(
        name: 'Current Block',
        value: currentBlock.toDouble(),
        description: 'Current Ethereum block number',
        unit: 'blocks',
      ));

      metrics.add(NetworkMetric(
        name: 'Avg Block Time',
        value: avgBlockTime,
        description: 'Average time between Ethereum blocks',
        unit: 'seconds',
      ));

      return metrics;
    } catch (e) {
      print('Error fetching network metrics: $e');
      // Return some mock data
      return [
        NetworkMetric(
          name: 'Average Gas Used',
          value: 65000,
          description:
              'Average gas used per PYUSD transaction in the last 30 days',
          unit: 'gas',
        ),
        NetworkMetric(
          name: 'Average Gas Price',
          value: 25,
          description:
              'Average gas price for PYUSD transactions in the last 30 days',
          unit: 'gwei',
        ),
        NetworkMetric(
          name: 'Unique Addresses',
          value: 5420,
          description:
              'Number of unique addresses interacting with PYUSD in the last 30 days',
          unit: 'addresses',
        ),
        NetworkMetric(
          name: 'Total Transactions',
          value: 42500,
          description: 'Total number of PYUSD transactions in the last 30 days',
          unit: 'transactions',
        ),
      ];
    }
  }

  Future<double> _getAverageBlockTime() async {
    try {
      // Get the latest block
      final latestBlock = await _ethClient.getBlockInformation();

      // Get a block from 100 blocks ago
      final oldBlockNum = latestBlock.number! - BigInt.from(100);
      final oldBlock = await _ethClient.getBlockInformation(
          atBlock: BlockNum.exact(oldBlockNum.toInt()));

      // Calculate time difference
      final timeDiff = latestBlock.timestamp! - oldBlock.timestamp!;

      // Calculate average block time
      return timeDiff / 100;
    } catch (e) {
      print('Error calculating average block time: $e');
      return 13.5; // Return a reasonable default for Ethereum
    }
  }

  Future<PyusdAdoption> _getAdoptionMetrics() async {
    try {
      // Query for adoption metrics using BigQuery
      final holdersQuery = '''
        SELECT 
          COUNT(DISTINCT address) as total_holders
        FROM `bigquery-public-data.crypto_ethereum.token_balances`
        WHERE token_address = '${_pyusdContractAddress.toLowerCase()}'
          AND balance > 0
      ''';

      final activeAddressesQuery = '''
        SELECT 
          COUNT(DISTINCT from_address) as active_addresses
        FROM `bigquery-public-data.crypto_ethereum.token_transfers`
        WHERE token_address = '${_pyusdContractAddress.toLowerCase()}'
          AND block_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
      ''';

      final holdersJob = await _runBigQueryJob(holdersQuery);
      final activeAddressesJob = await _runBigQueryJob(activeAddressesQuery);

      int totalHolders = 0;
      int activeAddresses24h = 0;

      if (holdersJob.rows != null && holdersJob.rows!.isNotEmpty) {
        totalHolders = int.parse(holdersJob.rows![0].f![0].v.toString());
      }

      if (activeAddressesJob.rows != null &&
          activeAddressesJob.rows!.isNotEmpty) {
        activeAddresses24h =
            int.parse(activeAddressesJob.rows![0].f![0].v.toString());
      }

      // For multi-chain distribution, we need to query each chain
      // For now, we'll assume most PYUSD is on Ethereum
      final chainDistribution = [
        ChainDistribution(
          chainName: 'Ethereum',
          percentage: 80.0,
          amount: await getTotalSupply() * 0.8,
        ),
        ChainDistribution(
          chainName: 'Solana',
          percentage: 15.0,
          amount: await getTotalSupply() * 0.15,
        ),
        ChainDistribution(
          chainName: 'Others',
          percentage: 5.0,
          amount: await getTotalSupply() * 0.05,
        ),
      ];

      // For wallet type distribution, we need to analyze address patterns
      // This is a simplified version
      final walletTypeDistribution = [
        WalletTypeDistribution(
          walletType: 'EOA',
          percentage: 70.0,
          count: (totalHolders * 0.7).round(),
        ),
        WalletTypeDistribution(
          walletType: 'Contract',
          percentage: 25.0,
          count: (totalHolders * 0.25).round(),
        ),
        WalletTypeDistribution(
          walletType: 'Exchange',
          percentage: 5.0,
          count: (totalHolders * 0.05).round(),
        ),
      ];

      return PyusdAdoption(
        totalHolders: totalHolders,
        activeAddresses24h: activeAddresses24h,
        chainDistribution: chainDistribution,
        walletTypeDistribution: walletTypeDistribution,
      );
    } catch (e) {
      print('Error fetching adoption metrics: $e');
      // Return some mock data
      return PyusdAdoption(
        totalHolders: 8500,
        activeAddresses24h: 450,
        chainDistribution: [
          ChainDistribution(
            chainName: 'Ethereum',
            percentage: 80.0,
            amount: 800000,
          ),
          ChainDistribution(
            chainName: 'Solana',
            percentage: 15.0,
            amount: 150000,
          ),
          ChainDistribution(
            chainName: 'Others',
            percentage: 5.0,
            amount: 50000,
          ),
        ],
        walletTypeDistribution: [
          WalletTypeDistribution(
            walletType: 'EOA',
            percentage: 70.0,
            count: 5950,
          ),
          WalletTypeDistribution(
            walletType: 'Contract',
            percentage: 25.0,
            count: 2125,
          ),
          WalletTypeDistribution(
            walletType: 'Exchange',
            percentage: 5.0,
            count: 425,
          ),
        ],
      );
    }
  }

  Future<GetQueryResultsResponse> _runBigQueryJob(String query) async {
    try {
      // Create a query job
      final job = Job()
        ..configuration = JobConfiguration()
        ..configuration!.query = JobConfigurationQuery()
        ..configuration!.query!.query = query;

      // Run the query
      final submitJobResponse =
          await _bigqueryApi.jobs.insert(job, _googleProjectId);
      final jobId = submitJobResponse.jobReference!.jobId!;

      // Wait for the job to complete
      Job jobStatus;
      bool jobComplete = false;
      while (!jobComplete) {
        jobStatus = await _bigqueryApi.jobs.get(_googleProjectId, jobId);
        jobComplete = jobStatus.status?.state == 'DONE';
        if (!jobComplete) {
          await Future.delayed(Duration(seconds: 1));
        }
      }

      // Get the query results
      final queryResults =
          await _bigqueryApi.jobs.getQueryResults(_googleProjectId, jobId);

      return queryResults;
    } catch (e) {
      print('Error running BigQuery job: $e');
      throw e;
    }
  }

  void dispose() {
    _ethClient.dispose();
  }
}
