import 'dart:async';
import 'package:intl/intl.dart';

import '../../../providers/network_provider.dart';

enum TransactionDirection { incoming, outgoing }

enum TransactionStatus { pending, confirmed, failed }

class TransactionModel {
  final String hash;
  final DateTime timestamp;
  final String from;
  final String to;
  final double amount;
  final double gasUsed;
  final double gasPrice;
  final TransactionStatus status;
  final TransactionDirection direction;
  final int confirmations;
  final String? tokenSymbol;
  final String? tokenName;
  final int? tokenDecimals;
  final String? tokenContractAddress;
  final String? data;
  final NetworkType network;

  TransactionModel({
    required this.hash,
    required this.timestamp,
    required this.from,
    required this.to,
    required this.amount,
    required this.gasUsed,
    required this.gasPrice,
    required this.status,
    required this.direction,
    required this.confirmations,
    required this.network,
    this.tokenSymbol,
    this.tokenName,
    this.tokenDecimals,
    this.tokenContractAddress,
    this.data,
  });

  // Fee calculation in ETH
  double get fee => gasUsed * gasPrice / 1e9;

  // Format timestamp to readable date
  String get formattedDate =>
      DateFormat('MMM dd, yyyy HH:mm').format(timestamp);

  // Clone with updated values
  TransactionModel copyWith({
    String? hash,
    DateTime? timestamp,
    String? from,
    String? to,
    double? amount,
    double? gasUsed,
    double? gasPrice,
    TransactionStatus? status,
    TransactionDirection? direction,
    int? confirmations,
    String? tokenSymbol,
    String? tokenName,
    int? tokenDecimals,
    String? tokenContractAddress,
    String? data,
    NetworkType? network,
  }) {
    return TransactionModel(
      hash: hash ?? this.hash,
      timestamp: timestamp ?? this.timestamp,
      from: from ?? this.from,
      to: to ?? this.to,
      amount: amount ?? this.amount,
      gasUsed: gasUsed ?? this.gasUsed,
      gasPrice: gasPrice ?? this.gasPrice,
      status: status ?? this.status,
      direction: direction ?? this.direction,
      confirmations: confirmations ?? this.confirmations,
      tokenSymbol: tokenSymbol ?? this.tokenSymbol,
      tokenName: tokenName ?? this.tokenName,
      tokenDecimals: tokenDecimals ?? this.tokenDecimals,
      tokenContractAddress: tokenContractAddress ?? this.tokenContractAddress,
      data: data ?? this.data,
      network: network ?? this.network,
    );
  }
}

// Add this model for transaction details
class TransactionDetailModel extends TransactionModel {
  final String blockNumber;
  final int nonce;
  final String blockHash;
  final bool isError;
  final String? errorMessage;

  TransactionDetailModel({
    required String hash,
    required DateTime timestamp,
    required String from,
    required String to,
    required double amount,
    required double gasUsed,
    required double gasPrice,
    required TransactionStatus status,
    required TransactionDirection direction,
    required int confirmations,
    required NetworkType network,
    required this.blockNumber,
    required this.nonce,
    required this.blockHash,
    required this.isError,
    this.errorMessage,
    String? tokenSymbol,
    String? tokenName,
    int? tokenDecimals,
    String? tokenContractAddress,
    String? data,
  }) : super(
          hash: hash,
          timestamp: timestamp,
          from: from,
          to: to,
          amount: amount,
          gasUsed: gasUsed,
          gasPrice: gasPrice,
          status: status,
          direction: direction,
          confirmations: confirmations,
          network: network,
          tokenSymbol: tokenSymbol,
          tokenName: tokenName,
          tokenDecimals: tokenDecimals,
          tokenContractAddress: tokenContractAddress,
          data: data,
        );
}
