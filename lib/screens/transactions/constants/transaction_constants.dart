import '../../../providers/network_provider.dart';

class TransactionConstants {
  // Transaction tracking
  static const int maxTransactionCheckRetries = 20;
  static const Duration transactionCheckInterval = Duration(seconds: 15);

  // State
  static const int perPage = 20;
  static const Duration cacheValidDuration = Duration(minutes: 2);

  // Token contract addresses
  static final Map<NetworkType, String> tokenContractAddresses = {
    NetworkType.sepoliaTestnet: '0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9',
    NetworkType.ethereumMainnet: '0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9',
  };
}
