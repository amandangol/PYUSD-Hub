import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class BalanceCard extends StatelessWidget {
  final String address;
  final double balance;
  final bool isLoading;

  BalanceCard({
    Key? key,
    required this.address,
    required this.balance,
    this.isLoading = false,
  }) : super(key: key);

  String get shortenedAddress {
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  final formatter = NumberFormat.currency(
    symbol: '',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    String formattedBalance;
    if (balance >= 1000000) {
      formattedBalance = formatter.format(balance);
    } else {
      // For smaller numbers, show exact value with 2 decimal places
      formattedBalance = balance.toStringAsFixed(2);
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Balance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: address)).then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Address copied to clipboard')),
                      );
                    });
                  },
                  child: Row(
                    children: [
                      Text(
                        shortenedAddress,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.copy,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 200,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            else
              Text(
                formattedBalance,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
