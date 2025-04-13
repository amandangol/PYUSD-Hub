import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../providers/network_provider.dart';

enum TransactionDirection { incoming, outgoing }

enum TransactionStatus { pending, confirmed, failed }

@immutable
class TransactionModel {
  final String hash;
  final DateTime timestamp;
  final String from;
  final String to;
  final double amount;
  final double gasUsed;
  final double gasLimit;
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
    required this.gasLimit,
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

  late final double fee = gasUsed * gasPrice / 1e9;

  late final String formattedDate =
      DateFormat('MMM dd, yyyy HH:mm').format(timestamp);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModel &&
          hash == other.hash &&
          network == other.network;

  @override
  int get hashCode => hash.hashCode ^ network.hashCode;

  TransactionModel copyWith({
    String? hash,
    DateTime? timestamp,
    String? from,
    String? to,
    double? amount,
    double? gasUsed,
    double? gasLimit,
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
      gasLimit: gasLimit ?? this.gasLimit,
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

  Map<String, dynamic> toJson() => {
        'hash': hash,
        'timestamp': timestamp.toIso8601String(),
        'from': from,
        'to': to,
        'amount': amount,
        'gasUsed': gasUsed,
        'gasLimit': gasLimit,
        'gasPrice': gasPrice,
        'status': status.toString(),
        'direction': direction.toString(),
        'confirmations': confirmations,
        'network': network.toString(),
        'tokenSymbol': tokenSymbol,
        'tokenName': tokenName,
        'tokenDecimals': tokenDecimals,
        'tokenContractAddress': tokenContractAddress,
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        hash: json['hash'] as String,
        timestamp: DateTime.parse(json['timestamp']),
        from: json['from'] as String,
        to: json['to'] as String,
        amount: json['amount'] as double,
        gasUsed: json['gasUsed'] as double,
        gasLimit: json['gasLimit'] as double,
        gasPrice: json['gasPrice'] as double,
        status: TransactionStatus.values.firstWhere(
          (e) => e.toString() == json['status'],
        ),
        direction: TransactionDirection.values.firstWhere(
          (e) => e.toString() == json['direction'],
        ),
        confirmations: json['confirmations'] as int,
        network: NetworkType.values.firstWhere(
          (e) => e.toString() == json['network'],
        ),
        tokenSymbol: json['tokenSymbol'] as String?,
        tokenName: json['tokenName'] as String?,
        tokenDecimals: json['tokenDecimals'] as int?,
        tokenContractAddress: json['tokenContractAddress'] as String?,
      );
}

@immutable
class TransactionDetailModel extends TransactionModel {
  final String blockNumber;
  final int nonce;
  final String blockHash;
  final bool isError;
  final String? errorMessage;
  final Map<String, dynamic>? traceData;
  final List<Map<String, dynamic>>? internalTransactions;
  final bool traceDataUnavailable;
  final Map<String, dynamic>? transactionAnalysis;
  final Map<String, dynamic>? transactionTrace;
  final Map<String, dynamic>? receipt;

  TransactionDetailModel({
    required super.hash,
    required super.timestamp,
    required super.from,
    required super.to,
    required super.amount,
    required super.gasUsed,
    required super.gasLimit,
    required super.gasPrice,
    required super.status,
    required super.direction,
    required super.confirmations,
    required super.network,
    required this.blockNumber,
    required this.nonce,
    required this.blockHash,
    required this.isError,
    this.traceData,
    this.internalTransactions,
    this.errorMessage,
    this.receipt,
    super.tokenSymbol,
    super.tokenName,
    super.tokenDecimals,
    super.tokenContractAddress,
    super.data,
    this.traceDataUnavailable = false,
    this.transactionAnalysis,
    this.transactionTrace,
  });

  @override
  TransactionDetailModel copyWith({
    String? hash,
    DateTime? timestamp,
    String? from,
    String? to,
    double? amount,
    double? gasUsed,
    double? gasLimit,
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
    String? blockNumber,
    int? nonce,
    String? blockHash,
    bool? isError,
    String? errorMessage,
    Map<String, dynamic>? traceData,
    List<Map<String, dynamic>>? internalTransactions,
    bool? traceDataUnavailable,
    Map<String, dynamic>? transactionAnalysis,
    Map<String, dynamic>? transactionTrace,
    Map<String, dynamic>? receipt,
  }) {
    return TransactionDetailModel(
      hash: hash ?? this.hash,
      timestamp: timestamp ?? this.timestamp,
      from: from ?? this.from,
      to: to ?? this.to,
      amount: amount ?? this.amount,
      gasUsed: gasUsed ?? this.gasUsed,
      gasLimit: gasLimit ?? this.gasLimit,
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
      blockNumber: blockNumber ?? this.blockNumber,
      nonce: nonce ?? this.nonce,
      blockHash: blockHash ?? this.blockHash,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      traceData: traceData ?? this.traceData,
      internalTransactions: internalTransactions ?? this.internalTransactions,
      traceDataUnavailable: traceDataUnavailable ?? this.traceDataUnavailable,
      transactionAnalysis: transactionAnalysis ?? this.transactionAnalysis,
      transactionTrace: transactionTrace ?? this.transactionTrace,
      receipt: receipt ?? this.receipt,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['traceData'] = traceData;
    json['receipt'] = receipt;
    return json;
  }

  factory TransactionDetailModel.fromJson(Map<String, dynamic> json) {
    return TransactionDetailModel(
      hash: json['hash'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      from: json['from'] as String,
      to: json['to'] as String,
      amount: json['amount'] as double,
      gasUsed: json['gasUsed'] as double,
      gasLimit: json['gasLimit'] as double,
      gasPrice: json['gasPrice'] as double,
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      direction: TransactionDirection.values.firstWhere(
        (e) => e.toString() == json['direction'],
      ),
      confirmations: json['confirmations'] as int,
      network: NetworkType.values.firstWhere(
        (e) => e.toString() == json['network'],
      ),
      blockNumber: json['blockNumber'] as String,
      nonce: json['nonce'] as int,
      blockHash: json['blockHash'] as String,
      isError: json['isError'] as bool,
      errorMessage: json['errorMessage'] as String?,
      tokenSymbol: json['tokenSymbol'] as String?,
      tokenName: json['tokenName'] as String?,
      tokenDecimals: json['tokenDecimals'] as int?,
      tokenContractAddress: json['tokenContractAddress'] as String?,
      data: json['data'] as String?,
      traceData: json['traceData'] as Map<String, dynamic>?,
      receipt: json['receipt'] as Map<String, dynamic>?,
    );
  }
}
