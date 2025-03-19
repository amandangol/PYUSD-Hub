import 'package:web3dart/web3dart.dart';

class WalletModel {
  final String address;
  final String privateKey;
  final String mnemonic;
  final EthPrivateKey? credentials;
  final Map<String, dynamic>? userInfo;

  WalletModel({
    required this.address,
    required this.privateKey,
    required this.mnemonic,
    required this.credentials,
    this.userInfo,
  });

  // Check if this is a social login wallet (via Web3Auth)
  bool get isSocialLogin =>
      userInfo != null && userInfo!['typeOfLogin'] != null && mnemonic.isEmpty;

  // Get display name for UI (if available from social login)
  String? get displayName => userInfo?['name'] as String?;

  // Get profile image for UI (if available from social login)
  String? get profileImage => userInfo?['profileImage'] as String?;

  // Get email for UI (if available from social login)
  String? get email => userInfo?['email'] as String?;

  // Get short address format for display
  String get shortAddress {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  @override
  String toString() {
    return 'WalletModel{address: $shortAddress, isSocialLogin: $isSocialLogin}';
  }
}
