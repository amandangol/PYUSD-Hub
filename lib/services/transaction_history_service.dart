import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pyusd_hub/utils/formatter_utils.dart';
import '../providers/network_provider.dart';
import '../screens/transactions/model/transaction_model.dart';
import 'ethereum_rpc_client.dart';
import 'token_service.dart';
import 'blockchain_utils.dart';

/// Service for transaction history and details
class TransactionHistoryService {
  // API key for Etherscan
  static const String _etherscanApiKey = 'YBYI6VWHB8VIE5M8Z3BRPS4689N2VHV3SA';

  final EthereumRpcClient _rpcClient;
  final TokenService _tokenService;
  final BlockchainUtils _blockchainUtils;

  TransactionHistoryService(
      this._rpcClient, this._tokenService, this._blockchainUtils);

  // Get Etherscan API domain based on network type
  String _getEtherscanDomain(NetworkType networkType) {
    switch (networkType) {
      case NetworkType.sepoliaTestnet:
        return 'api-sepolia.etherscan.io';
      default:
        return 'api.etherscan.io';
    }
  }

  // Get transactions from Etherscan API
  Future<List<Map<String, dynamic>>> getTransactions(
    String address,
    NetworkType networkType, {
    int page = 1,
    int perPage = 20,
  }) async {
    final domain = _getEtherscanDomain(networkType);
    final uri = Uri.https(domain, '/api', {
      'module': 'account',
      'action': 'txlist',
      'address': address,
      'page': page.toString(),
      'offset': perPage.toString(),
      'sort': 'desc',
      'apikey': _etherscanApiKey,
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch transactions: ${response.statusCode}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] != '1') {
        // No transactions or error
        if (data['message'] == 'No transactions found') {
          return [];
        }
        throw Exception('Etherscan API error: ${data['message']}');
      }

      return List<Map<String, dynamic>>.from(data['result']);
    } catch (e) {
      print('Error fetching transactions: $e');
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  // Get token transactions for an address (from Etherscan API)
  Future<List<Map<String, dynamic>>> getTokenTransactions(
    String address,
    NetworkType networkType, {
    int page = 1,
    int perPage = 20,
  }) async {
    final domain = _getEtherscanDomain(networkType);
    final uri = Uri.https(domain, '/api', {
      'module': 'account',
      'action': 'tokentx',
      'address': address,
      'page': page.toString(),
      'offset': perPage.toString(),
      'sort': 'desc',
      'apikey': _etherscanApiKey,
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch token transactions: ${response.statusCode}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] != '1') {
        // No transactions or error
        if (data['message'] == 'No transactions found') {
          return [];
        }
        throw Exception('Etherscan API error: ${data['message']}');
      }

      return List<Map<String, dynamic>>.from(data['result']);
    } catch (e) {
      print('Error fetching token transactions: $e');
      throw Exception('Failed to fetch token transactions: $e');
    }
  }

  // Get detailed transaction information
  Future<TransactionDetailModel?> getTransactionDetails(
    String rpcUrl,
    String txHash,
    NetworkType networkType,
    String userAddress,
  ) async {
    try {
      // First get basic transaction information
      final txResponse = await _rpcClient.makeRpcCall(
        rpcUrl,
        'eth_getTransactionByHash',
        [txHash],
      );

      // Check if txResponse or txResponse['result'] is null
      if (txResponse == null || txResponse['result'] == null) {
        print('Transaction not found or returned null result: $txHash');
        return null;
      }

      final txData = txResponse['result'] as Map<String, dynamic>?;
      if (txData == null || txData.isEmpty) {
        print('Transaction data is null or empty: $txHash');
        return null;
      }

      // Get transaction receipt for status and gas used
      final receiptResponse = await _rpcClient.makeRpcCall(
        rpcUrl,
        'eth_getTransactionReceipt',
        [txHash],
      );

      final receiptData =
          receiptResponse != null && receiptResponse['result'] != null
              ? receiptResponse['result'] as Map<String, dynamic>?
              : null;

      // Handle pending transactions
      if (receiptData == null) {
        return TransactionDetailModel(
          hash: txHash,
          timestamp: DateTime.now(),
          from: txData['from'] ?? '',
          to: txData['to'] ?? '',
          amount: txData['value'] != null && txData['value'] != '0x0'
              ? FormatterUtils.parseBigInt(txData['value']).toDouble() / 1e18
              : 0.0,
          gasUsed: txData['gas'] != null
              ? FormatterUtils.parseBigInt(txData['gas']).toDouble()
              : 0.0,
          gasPrice: txData['gasPrice'] != null
              ? FormatterUtils.parseBigInt(txData['gasPrice']).toDouble() / 1e9
              : 0.0,
          status: TransactionStatus.pending,
          direction:
              _blockchainUtils.compareAddresses(txData['from'], userAddress)
                  ? TransactionDirection.outgoing
                  : TransactionDirection.incoming,
          confirmations: 0,
          network: networkType,
          blockNumber: 'Pending',
          nonce: txData['nonce'] != null
              ? int.parse(txData['nonce'].substring(2), radix: 16)
              : 0,
          blockHash: 'Pending',
          isError: false,
          data: txData['input'],
        );
      }

      // Get block for timestamp
      final blockResponse = await _rpcClient.makeRpcCall(
        rpcUrl,
        'eth_getBlockByHash',
        [receiptData['blockHash'], false],
      );

      // Check if blockResponse or blockResponse['result] is null
      if (blockResponse == null || blockResponse['result'] == null) {
        print('Block data not found: ${receiptData['blockHash']}');
        // Return transaction with estimated timestamp since we couldn't get the block
        return TransactionDetailModel(
          hash: txHash,
          timestamp: DateTime.now(), // Use current time as fallback
          from: txData['from'] ?? '',
          to: txData['to'] ?? '',
          amount: txData['value'] != null
              ? FormatterUtils.parseBigInt(txData['value']).toDouble() / 1e18
              : 0.0,
          gasUsed: receiptData['gasUsed'] != null
              ? FormatterUtils.parseBigInt(receiptData['gasUsed']).toDouble()
              : 0.0,
          gasPrice: txData['gasPrice'] != null
              ? FormatterUtils.parseBigInt(txData['gasPrice']).toDouble() / 1e9
              : 0.0,
          status: receiptData['status'] == '0x1'
              ? TransactionStatus.confirmed
              : TransactionStatus.failed,
          direction:
              _blockchainUtils.compareAddresses(txData['from'], userAddress)
                  ? TransactionDirection.outgoing
                  : TransactionDirection.incoming,
          confirmations: 0, // Can't calculate without block data
          network: networkType,
          blockNumber: receiptData['blockNumber'] != null
              ? FormatterUtils.parseBigInt(receiptData['blockNumber'])
                  .toString()
              : '0',
          nonce: txData['nonce'] != null
              ? int.parse(txData['nonce'].substring(2), radix: 16)
              : 0,
          blockHash: receiptData['blockHash'] ?? '',
          isError: receiptData['status'] != '0x1',
          data: txData['input'],
        );
      }

      final blockData = blockResponse['result'] as Map<String, dynamic>;

      // Check if it's a token transfer
      bool isTokenTransfer = txData['input'] != null &&
          txData['input'].toString().startsWith('0xa9059cbb');

      String toAddress = txData['to'] ?? '';
      double amount = 0.0;
      String? tokenSymbol;
      String? tokenName;
      int? tokenDecimals;
      String? tokenContractAddress;

      if (isTokenTransfer) {
        // Get token details
        try {
          tokenContractAddress = toAddress;
          final tokenDetails =
              await _tokenService.getTokenDetails(rpcUrl, toAddress);
          tokenName = tokenDetails['name'];
          tokenSymbol = tokenDetails['symbol'];
          tokenDecimals = tokenDetails['decimals'];

          // Extract token transfer details
          final (actualTo, tokenValue, decimals) = await _tokenService
              .extractTokenTransferData(rpcUrl, txData, toAddress);
          toAddress = actualTo;
          amount = tokenValue;
          tokenDecimals = decimals;
        } catch (e) {
          print('Error getting token details: $e');
        }
      } else {
        // Regular ETH transfer
        amount = txData['value'] != null
            ? FormatterUtils.parseBigInt(txData['value']).toDouble() / 1e18
            : 0.0;
      }

      // Determine transaction status
      final status = receiptData['status'] == '0x1'
          ? TransactionStatus.confirmed
          : TransactionStatus.failed;

      // Calculate confirmations
      final txBlockNumber =
          FormatterUtils.parseBigInt(receiptData['blockNumber']);
      final confirmations =
          await _calculateConfirmations(rpcUrl, txBlockNumber);

      // Determine basic error status for failed transactions
      String? errorMessage;
      if (status == TransactionStatus.failed) {
        errorMessage = 'Transaction failed';

        // Basic failure detection without trace data
        final gasUsed = receiptData['gasUsed'] != null
            ? FormatterUtils.parseBigInt(receiptData['gasUsed']).toDouble()
            : 0.0;
        final gasLimit = txData['gas'] != null
            ? FormatterUtils.parseBigInt(txData['gas']).toDouble()
            : 0.0;

        if (gasUsed >= gasLimit * 0.95) {
          errorMessage = 'Transaction failed. Likely out of gas.';
        }
      }

      return TransactionDetailModel(
        hash: txHash,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            int.parse(blockData['timestamp'].substring(2), radix: 16) * 1000),
        from: txData['from'] ?? '',
        to: toAddress,
        amount: amount,
        gasUsed: receiptData['gasUsed'] != null
            ? FormatterUtils.parseBigInt(receiptData['gasUsed']).toDouble()
            : 0.0,
        gasPrice: txData['gasPrice'] != null
            ? FormatterUtils.parseBigInt(txData['gasPrice']).toDouble() / 1e9
            : 0.0,
        status: status,
        direction:
            _blockchainUtils.compareAddresses(txData['from'], userAddress)
                ? TransactionDirection.outgoing
                : TransactionDirection.incoming,
        confirmations: confirmations,
        tokenSymbol: tokenSymbol,
        tokenName: tokenName,
        tokenDecimals: tokenDecimals,
        tokenContractAddress: tokenContractAddress,
        network: networkType,
        blockNumber: receiptData['blockNumber'] != null
            ? FormatterUtils.parseBigInt(receiptData['blockNumber']).toString()
            : '0',
        nonce: txData['nonce'] != null
            ? int.parse(txData['nonce'].substring(2), radix: 16)
            : 0,
        blockHash: receiptData['blockHash'] ?? '',
        isError: status == TransactionStatus.failed,
        errorMessage: errorMessage,
        data: txData['input'],
      );
    } catch (e) {
      print('Exception in getTransactionDetails: $e');
      // Return null instead of throwing an exception
      return null;
    }
  }

  // Helper method to calculate confirmations
  Future<int> _calculateConfirmations(
      String rpcUrl, BigInt txBlockNumber) async {
    try {
      final response =
          await _rpcClient.makeRpcCall(rpcUrl, 'eth_blockNumber', []);
      final BigInt currentBlock =
          FormatterUtils.parseBigInt(response['result']);
      return (currentBlock - txBlockNumber).toInt();
    } catch (e) {
      print('Error calculating confirmations: $e');
      return 0;
    }
  }
}
