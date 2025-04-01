import 'package:flutter/material.dart';

class GasStationWidget extends StatelessWidget {
  final double gasPrice;
  final bool darkMode;

  const GasStationWidget({
    super.key,
    required this.gasPrice,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 100,
      decoration: BoxDecoration(
        color: darkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_gas_station,
            size: 32,
            color: _getGasPriceColor(gasPrice),
          ),
          const SizedBox(height: 8),
          Text(
            gasPrice.toStringAsFixed(3),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkMode ? Colors.white : Colors.black,
            ),
          ),
          Text(
            'Gwei',
            style: TextStyle(
              fontSize: 12,
              color: darkMode ? Colors.white70 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Color _getGasPriceColor(double price) {
    if (price < 20) {
      return Colors.green;
    } else if (price < 50) {
      return Colors.orange;
    } else if (price < 100) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }
}
