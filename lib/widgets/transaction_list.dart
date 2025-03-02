import 'package:flutter/material.dart';

import 'package:shimmer/shimmer.dart';

import '../models/transaction.dart';
import 'transaction_item.dart';

class TransactionList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String address;
  final bool isLoading;

  const TransactionList({
    Key? key,
    required this.transactions,
    required this.address,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingShimmer();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        return TransactionItem(
          transaction: transactions[index],
          currentAddress: address,
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Container(
              height: 72,
              padding: const EdgeInsets.all(16),
            ),
          );
        },
      ),
    );
  }
}
