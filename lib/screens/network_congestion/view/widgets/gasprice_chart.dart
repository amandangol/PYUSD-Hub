import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GasPriceChart extends StatelessWidget {
  final List<double> gasPrices;

  const GasPriceChart({
    Key? key,
    required this.gasPrices,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (gasPrices.isEmpty) {
      return const Center(
        child: Text('No gas price data available'),
      );
    }

    final maxY =
        gasPrices.reduce((curr, next) => curr > next ? curr : next) * 1.2;
    final minY =
        gasPrices.reduce((curr, next) => curr < next ? curr : next) * 0.8;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: maxY / 5,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: gasPrices.length > 10 ? 3 : 1,
              getTitlesWidget: (value, meta) {
                if (value % 3 != 0 && gasPrices.length > 10) {
                  return const SizedBox();
                }

                // Show time offsets (most recent to oldest)
                final int valueInt = value.toInt();
                if (valueInt >= 0 && valueInt < gasPrices.length) {
                  final int timeOffset = (gasPrices.length - 1 - valueInt) *
                      15; // 15 sec intervals
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      timeOffset == 0 ? 'Now' : '${timeOffset}s',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        minX: 0,
        maxX: gasPrices.length.toDouble() - 1,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(gasPrices.length, (index) {
              return FlSpot(index.toDouble(), gasPrices[index]);
            }),
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.8),
                Theme.of(context).primaryColor,
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: gasPrices.length < 10,
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.3),
                  Theme.of(context).primaryColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
