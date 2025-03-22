import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'pyusd_data_provider.dart';

class PyusdDashboard extends StatelessWidget {
  const PyusdDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PyusdDashboardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(provider.error),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.initialize(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('PYUSD Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.initialize(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time period selection
                _buildPeriodSelector(provider),
                const SizedBox(height: 24),

                // Supply header
                _buildSupplyHeader(provider),
                const SizedBox(height: 32),

                // Main stats cards
                _buildStatsCards(provider),
                const SizedBox(height: 32),

                // Supply chart
                _buildSupplyChart(provider),
                const SizedBox(height: 32),

                // Flow rates
                _buildFlowRatesSection(provider),
                const SizedBox(height: 32),

                // Activity cards
                _buildActivityCards(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector(PyusdDashboardProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Period',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPeriodButton(provider, 'day', 'Last 24h'),
                _buildPeriodButton(provider, 'week', 'Last Week'),
                _buildPeriodButton(provider, 'month', 'Last Month'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(
      PyusdDashboardProvider provider, String period, String label) {
    final isSelected = provider.selectedPeriod == period;

    return ElevatedButton(
      onPressed: () => provider.setTimePeriod(period),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  Widget _buildSupplyHeader(PyusdDashboardProvider provider) {
    final formattedSupply = provider.formatPyusdSupply();
    final netChangePercent = provider.getNetChangePercentage();
    final isPositive = netChangePercent >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'PYUSD Total Supply',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$$formattedSupply',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 18,
                ),
                Text(
                  '${netChangePercent.abs().toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          provider.getPeriodDuration(),
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards(PyusdDashboardProvider provider) {
    final data = provider.currentPeriodData;
    if (data.isEmpty) {
      return const SizedBox();
    }

    final mintedAmount = provider.formatAmount(data['totalMinted'] as BigInt);
    final burnedAmount = provider.formatAmount(data['totalBurned'] as BigInt);
    final netChange = provider.formatAmount(data['netChange'] as BigInt);
    final isPositiveChange = (data['netChange'] as BigInt) >= BigInt.zero;

    return Row(
      children: [
        _buildStatsCard(
          'Minted',
          '\$$mintedAmount',
          Icons.add_circle_outline,
          Colors.green,
        ),
        const SizedBox(width: 16),
        _buildStatsCard(
          'Burned',
          '\$$burnedAmount',
          Icons.remove_circle_outline,
          Colors.red,
        ),
        const SizedBox(width: 16),
        _buildStatsCard(
          'Net Change',
          '\$$netChange',
          isPositiveChange ? Icons.trending_up : Icons.trending_down,
          isPositiveChange ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatsCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupplyChart(PyusdDashboardProvider provider) {
    final data = provider.currentPeriodData;
    if (data.isEmpty || (data['supplyHistory'] as List).isEmpty) {
      return const SizedBox();
    }

    final supplyHistory = data['supplyHistory'] as List<Map<String, dynamic>>;
    final spots = supplyHistory.map((point) {
      // Convert timestamp to x-axis point (days from start)
      final timestamp = point['timestamp'] as int;
      final startTime = data['startTime'] as int;
      final xValue = (timestamp - startTime) / (24 * 60 * 60); // days

      // Convert supply to y-axis point (in millions)
      final supply = point['supply'] as BigInt;
      final yValue = (supply / BigInt.from(10).pow(6)).toDouble();

      return FlSpot(xValue, yValue);
    }).toList();

    // Find min and max for the y-axis
    double minY = double.infinity;
    double maxY = 0;
    for (final spot in spots) {
      if (spot.y < minY) minY = spot.y;
      if (spot.y > maxY) maxY = spot.y;
    }

    // Add some padding
    minY = (minY * 0.99).roundToDouble();
    maxY = (maxY * 1.01).roundToDouble();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Supply Over Time',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          // Format X-axis based on time period
                          final period = provider.selectedPeriod;
                          String title = '';
                          if (period == 'day') {
                            // Show hours
                            title = '${(value * 24).round()}h';
                          } else if (period == 'week') {
                            // Show days
                            title = 'D${value.round() + 1}';
                          } else {
                            // Show week number for month
                            title = 'W${(value / 7).round() + 1}';
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(title,
                                style: const TextStyle(fontSize: 12)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          final displayValue =
                              NumberFormat.compact().format(value);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text('$displayValue',
                                style: const TextStyle(fontSize: 12)),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: spots.isEmpty ? 1 : spots.last.x,
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowRatesSection(PyusdDashboardProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Flow Rates (per hour)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            _buildFlowRateBar(
              'Mint Rate',
              provider.pyusdMintRate,
              Colors.green,
              Icons.arrow_upward,
            ),
            const SizedBox(height: 12),
            _buildFlowRateBar(
              'Burn Rate',
              provider.pyusdBurnRate,
              Colors.red,
              Icons.arrow_downward,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Net Flow Rate:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Icon(
                  provider.pyusdNetFlowRate >= 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: provider.pyusdNetFlowRate >= 0
                      ? Colors.green
                      : Colors.red,
                ),
                Text(
                  '\$${provider.formatRate(provider.pyusdNetFlowRate.abs())}/hour',
                  style: TextStyle(
                    color: provider.pyusdNetFlowRate >= 0
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowRateBar(
      String label, double rate, Color color, IconData icon) {
    // Max width will represent 100K PYUSD/hour
    const maxRate = 100000.0;
    final barWidth = (rate / maxRate).clamp(0.01, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              '\$${rate.toStringAsFixed(2)}/hour',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: barWidth,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCards(PyusdDashboardProvider provider) {
    final data = provider.currentPeriodData;
    if (data.isEmpty) {
      return const SizedBox();
    }

    // Get recent mint and burn events
    final List<dynamic> mintEvents = data['mintEvents'] ?? [];
    final List<dynamic> burnEvents = data['burnEvents'] ?? [];

    // Sort by most recent
    mintEvents.sort((a, b) =>
        int.parse(b['blockNumber'].substring(2), radix: 16)
            .compareTo(int.parse(a['blockNumber'].substring(2), radix: 16)));
    burnEvents.sort((a, b) =>
        int.parse(b['blockNumber'].substring(2), radix: 16)
            .compareTo(int.parse(a['blockNumber'].substring(2), radix: 16)));

    // Take only most recent 5
    final recentMints = mintEvents.take(5).toList();
    final recentBurns = burnEvents.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildActivityList(
                'Recent Mints',
                recentMints,
                Colors.green.shade100,
                Icons.add_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActivityList(
                'Recent Burns',
                recentBurns,
                Colors.red.shade100,
                Icons.remove_circle,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityList(String title, List<dynamic> events, Color bgColor,
      IconData icon, Color iconColor) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
          border: Border.all(color: bgColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: events.isEmpty
                  ? [
                      const SizedBox(height: 30),
                      Center(
                        child: Text(
                          'No recent activity',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ]
                  : events.map((event) {
                      final blockNumber = int.parse(
                          event['blockNumber'].substring(2),
                          radix: 16);
                      final value =
                          BigInt.parse(event['data']) / BigInt.from(10).pow(6);

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, color: iconColor, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Block #${blockNumber.toString()}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    '\$${value.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
