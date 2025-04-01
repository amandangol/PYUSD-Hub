import 'package:flutter/material.dart';

class CityBuilding extends StatelessWidget {
  final int blockNumber;
  final int height;
  final int width;
  final int transactionCount;
  final double utilization;

  const CityBuilding({
    super.key,
    required this.blockNumber,
    required this.height,
    required this.width,
    required this.transactionCount,
    required this.utilization,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showBlockDetails(context);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: height.toDouble(),
            width: width.toDouble(),
            decoration: BoxDecoration(
              color: _getBuildingColor(),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Windows
                ..._generateWindows(),

                // Block number on top
                Positioned(
                  top: 5,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#$blockNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Transaction count indicator
          Container(
            width: width.toDouble(),
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Center(
              child: Text(
                '$transactionCount tx',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _generateWindows() {
    final List<Widget> windows = [];
    final int rows = height ~/ 20;
    final int cols = width ~/ 15;

    for (int r = 1; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Randomly light up some windows
        final bool isLit = (r + c) % 3 == 0;

        windows.add(
          Positioned(
            top: r * 20.0,
            left: c * 15.0 + 5,
            child: Container(
              width: 10,
              height: 15,
              decoration: BoxDecoration(
                color: isLit
                    ? Colors.yellow.withOpacity(0.8)
                    : Colors.black.withOpacity(0.3),
                border: Border.all(
                  color: Colors.black.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
          ),
        );
      }
    }

    return windows;
  }

  Color _getBuildingColor() {
    if (utilization > 0.9) {
      return Colors.red.shade300;
    } else if (utilization > 0.7) {
      return Colors.orange.shade300;
    } else if (utilization > 0.5) {
      return Colors.blue.shade300;
    } else {
      return Colors.blue.shade200;
    }
  }

  void _showBlockDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block #$blockNumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transactions: $transactionCount'),
            Text('Gas Utilization: ${(utilization * 100).toStringAsFixed(1)}%'),
            Text('Building Height: $height units'),
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
