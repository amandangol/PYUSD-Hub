import 'package:web3dart/web3dart.dart';

class WalletModel {
  final String address;
  final String privateKey;
  final String mnemonic;
  final EthPrivateKey credentials;

  WalletModel({
    required this.address,
    required this.privateKey,
    required this.mnemonic,
    required this.credentials,
  });
}
