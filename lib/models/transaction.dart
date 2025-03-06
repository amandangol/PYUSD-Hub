import 'package:flutter/foundation.dart';

import '../providers/network_provider.dart';

enum TransactionDirection { incoming, outgoing }

enum TransactionStatus { pending, confirmed, failed }

class TransactionModel {
  final String hash;
  final String from;
  final String to;
  final double value;
  final DateTime timestamp;
  final TransactionDirection direction;
  final TransactionStatus status;
  final NetworkType networkType;
  final String? tokenSymbol;
  final String? tokenContractAddress;
  final int? tokenDecimals;

  TransactionModel({
    required this.hash,
    required this.from,
    required this.to,
    required this.value,
    required this.timestamp,
    required this.direction,
    required this.status,
    required this.networkType,
    this.tokenSymbol,
    this.tokenContractAddress,
    this.tokenDecimals,
  });
}

class TransactionDetailModel extends TransactionModel {
  final int blockNumber;
  final double gasLimit;
  final double gasPrice;
  final double gasUsed;
  final double fee;
  final int nonce;
  final String input;
  final int confirmations;

  TransactionDetailModel({
    required String hash,
    required String from,
    required String to,
    required double value,
    required DateTime timestamp,
    required TransactionDirection direction,
    required TransactionStatus status,
    required NetworkType networkType,
    required this.blockNumber,
    required this.gasLimit,
    required this.gasPrice,
    required this.gasUsed,
    required this.fee,
    required this.nonce,
    required this.input,
    required this.confirmations,
    String? tokenSymbol,
    String? tokenContractAddress,
    int? tokenDecimals,
  }) : super(
          hash: hash,
          from: from,
          to: to,
          value: value,
          timestamp: timestamp,
          direction: direction,
          status: status,
          networkType: networkType,
          tokenSymbol: tokenSymbol,
          tokenContractAddress: tokenContractAddress,
          tokenDecimals: tokenDecimals,
        );
}
