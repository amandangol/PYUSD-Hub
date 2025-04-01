import 'package:flutter/material.dart';
import '../../../../utils/formatter_utils.dart';

class TransactionVehicle extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final bool isPending;
  final String speed; // 'fast', 'medium', 'slow', 'waiting'

  const TransactionVehicle({
    super.key,
    required this.transaction,
    required this.isPending,
    required this.speed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showTransactionDetails(context);
      },
      child: Container(
        width: 40,
        height: 20,
        decoration: BoxDecoration(
          color: _getVehicleColor(),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Vehicle body
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.lightBlue.shade100,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Wheels
            Positioned(
              bottom: 0,
              left: 5,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 5,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),

            // Status indicator
            if (isPending)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getVehicleColor() {
    if (isPending) {
      return Colors.orange;
    }

    switch (speed) {
      case 'fast':
        return Colors.green;
      case 'medium':
        return Colors.blue;
      case 'slow':
        return Colors.red;
      case 'waiting':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  void _showTransactionDetails(BuildContext context) {
    final String hash = transaction['hash']?.toString() ?? 'Unknown';
    final String from = transaction['from']?.toString() ?? 'Unknown';
    final String to = transaction['to']?.toString() ?? 'Unknown';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPending ? 'Pending Transaction' : 'Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hash: ${FormatterUtils.formatHash(hash)}'),
            const SizedBox(height: 8),
            if (from != 'Unknown')
              Text('From: ${FormatterUtils.formatAddress(from)}'),
            if (to != 'Unknown')
              Text('To: ${FormatterUtils.formatAddress(to)}'),
            const SizedBox(height: 8),
            Text('Status: ${isPending ? "Pending" : "Confirmed"}'),
            Text('Speed: ${speed.toUpperCase()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
