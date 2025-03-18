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

  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'from': from,
      'to': to,
      'amount': amount,
      'gasUsed': gasUsed,
      'gasPrice': gasPrice,
      'status': status.index,
      'direction': direction.index,
      'confirmations': confirmations,
      'tokenSymbol': tokenSymbol,
      'tokenName': tokenName,
      'tokenDecimals': tokenDecimals,
      'tokenContractAddress': tokenContractAddress,
      'network': network.index,
    };
  }

// Create TransactionModel from JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      hash: json['hash'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      from: json['from'],
      to: json['to'],
      amount: json['amount'],
      gasUsed: json['gasUsed'],
      gasPrice: json['gasPrice'],
      status: TransactionStatus.values[json['status']],
      direction: TransactionDirection.values[json['direction']],
      confirmations: json['confirmations'],
      tokenSymbol: json['tokenSymbol'],
      tokenName: json['tokenName'],
      tokenDecimals: json['tokenDecimals'],
      tokenContractAddress: json['tokenContractAddress'],
      network: NetworkType.values[json['network']],
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
  final Map<String, dynamic>? traceData;
  final List<Map<String, dynamic>>? internalTransactions;
  final bool traceDataUnavailable;

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
    this.traceData,
    this.internalTransactions,
    this.errorMessage,
    String? tokenSymbol,
    String? tokenName,
    int? tokenDecimals,
    String? tokenContractAddress,
    String? data,
    this.traceDataUnavailable = false,
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
