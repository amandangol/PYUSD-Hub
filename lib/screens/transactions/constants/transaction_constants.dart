// 📂constants/📜transaction_constants.dart

enum NetworkType {
  ethereumMainnet,
  sepoliaTestnet,
}

class TransactionConstants {
  // Token contract addresses
  static const Map<NetworkType, String> tokenContractAddresses = {
    NetworkType.sepoliaTestnet: '0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9',
    NetworkType.ethereumMainnet: '0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9',
  };

  // Transaction tracking constants
  static const int maxTransactionCheckRetries = 20;
  static const Duration transactionCheckInterval = Duration(seconds: 15);

  // Cache constants
  static const Duration cacheValidDuration = Duration(minutes: 2);

  // Pagination
  static const int transactionsPerPage = 20;

  // Default gas values
  static const int defaultEthGasLimit = 21000;
  static const int defaultTokenGasLimit = 100000;
  static const double defaultGasPrice = 20.0; // in Gwei

  // Wallet constants
  static const int pyusdTokenDecimals = 6;
  static const String pyusdTokenSymbol = 'PYUSD';
  static const String pyusdTokenName = 'PayPal USD';

  // Storage keys
  static String pendingTransactionsKey(NetworkType network) =>
      'pending_transactions_${network.toString()}';
}
