import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../utils/formatter_utils.dart';

class TransactionVehicle extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final bool isPending;
  final String speed; // 'fast', 'medium', 'slow', 'waiting'
  final String transactionType; // 'pyusd', 'other'
  final double animationValue;

  const TransactionVehicle({
    super.key,
    required this.transaction,
    required this.isPending,
    required this.speed,
    required this.transactionType,
    required this.animationValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Calculate vehicle color based on type and speed
    Color vehicleColor;
    if (transactionType == 'pyusd') {
      vehicleColor = isPending ? Colors.orange : Colors.green;
    } else {
      vehicleColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;
    }

    // Calculate vehicle size based on speed
    double vehicleSize;
    switch (speed) {
      case 'fast':
        vehicleSize = 30.0;
        break;
      case 'medium':
        vehicleSize = 25.0;
        break;
      case 'slow':
        vehicleSize = 20.0;
        break;
      default:
        vehicleSize = 25.0;
    }

    // Calculate vehicle opacity based on animation
    final opacity = 0.8 + (0.2 * (1 - animationValue));

    return Transform.translate(
      offset: Offset(0, 5 * sin(animationValue * 2 * 3.14159)),
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: vehicleSize,
          height: vehicleSize,
          decoration: BoxDecoration(
            color: vehicleColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: vehicleColor.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Vehicle body
              Center(
                child: Icon(
                  _getVehicleIcon(),
                  size: vehicleSize * 0.7,
                  color: Colors.white,
                ),
              ),
              // Pending indicator
              if (isPending)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.access_time,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
              // Speed indicator
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _getSpeedColor(),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    _getSpeedIcon(),
                    size: 8,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getVehicleIcon() {
    if (transactionType == 'pyusd') {
      return Icons.local_shipping;
    } else {
      return Icons.directions_car;
    }
  }

  IconData _getSpeedIcon() {
    switch (speed) {
      case 'fast':
        return Icons.flash_on;
      case 'medium':
        return Icons.speed;
      case 'slow':
        return Icons.slow_motion_video;
      default:
        return Icons.speed;
    }
  }

  Color _getSpeedColor() {
    switch (speed) {
      case 'fast':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'slow':
        return Colors.red;
      default:
        return Colors.grey;
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
