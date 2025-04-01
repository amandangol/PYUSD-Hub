import 'package:flutter/material.dart';
import '../../../../utils/formatter_utils.dart';

class TransactionVehicle extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final bool isPending;
  final String speed; // 'fast', 'medium', 'slow', 'waiting'
  final String transactionType; // 'pyusd', 'other'

  const TransactionVehicle({
    super.key,
    required this.transaction,
    required this.isPending,
    required this.speed,
    this.transactionType = 'pyusd',
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
          borderRadius: BorderRadius.circular(6),
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
            // Vehicle body details
            Positioned(
              top: 5,
              left: 0,
              right: 0,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Transaction type indicator
            Positioned(
              top: 2,
              left: 2,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color:
                      transactionType == 'pyusd' ? Colors.green : Colors.purple,
                  shape: BoxShape.circle,
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

            // Headlights
            Positioned(
              top: 7,
              right: 2,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.yellow.withOpacity(0.8),
                  shape: BoxShape.circle,
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
      return Colors.orange.withOpacity(0.8);
    }

    if (transactionType == 'pyusd') {
      switch (speed) {
        case 'fast':
          return Colors.green.shade400;
        case 'medium':
          return Colors.blue.shade400;
        case 'slow':
          return Colors.red.shade400;
        case 'waiting':
          return Colors.grey.shade400;
        default:
          return Colors.blue.shade400;
      }
    } else {
      // Other transaction types
      switch (speed) {
        case 'fast':
          return Colors.teal.shade400;
        case 'medium':
          return Colors.purple.shade400;
        case 'slow':
          return Colors.deepOrange.shade400;
        case 'waiting':
          return Colors.grey.shade400;
        default:
          return Colors.purple.shade400;
      }
    }
  }

  void _showTransactionDetails(BuildContext context) {
    final String hash = transaction['hash']?.toString() ?? 'Unknown';
    final String from = transaction['from']?.toString() ?? 'Unknown';
    final String to = transaction['to']?.toString() ?? 'Unknown';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(transactionType == 'pyusd'
            ? (isPending ? 'Pending PYUSD Transaction' : 'PYUSD Transaction')
            : (isPending ? 'Pending Transaction' : 'Other Transaction')),
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
            Text('Type: ${transactionType.toUpperCase()}'),
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
