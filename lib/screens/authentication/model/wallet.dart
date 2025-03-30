import 'package:web3dart/web3dart.dart';

class WalletInfo {
  final String name;
  final String address;
  final DateTime createdAt;
  final bool isActive;

  WalletInfo({
    required this.name,
    required this.address,
    required this.createdAt,
    this.isActive = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'createdAt': createdAt.toIso8601String(),
        'isActive': isActive,
      };

  factory WalletInfo.fromJson(Map<String, dynamic> json) => WalletInfo(
        name: json['name'] as String,
        address: json['address'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isActive: json['isActive'] as bool? ?? false,
      );
}

class WalletModel {
  final String address;
  final String privateKey;
  final String mnemonic;
  final EthPrivateKey? credentials;
  final Map<String, dynamic>? userInfo;
  final WalletInfo? walletInfo;

  WalletModel({
    required this.address,
    required this.privateKey,
    required this.mnemonic,
    required this.credentials,
    this.userInfo,
    this.walletInfo,
  });

  WalletModel copyWith({
    String? address,
    String? privateKey,
    String? mnemonic,
    EthPrivateKey? credentials,
    Map<String, dynamic>? userInfo,
    WalletInfo? walletInfo,
  }) {
    return WalletModel(
      address: address ?? this.address,
      privateKey: privateKey ?? this.privateKey,
      mnemonic: mnemonic ?? this.mnemonic,
      credentials: credentials ?? this.credentials,
      userInfo: userInfo ?? this.userInfo,
      walletInfo: walletInfo ?? this.walletInfo,
    );
  }
}
