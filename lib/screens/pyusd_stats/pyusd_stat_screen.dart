import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import our data provider
import 'provider/pyusd_stat_provider.dart';

class PyusdStatsScreen extends StatefulWidget {
  const PyusdStatsScreen({Key? key}) : super(key: key);

  @override
  State<PyusdStatsScreen> createState() => _PyusdStatsScreenState();
}

class _PyusdStatsScreenState extends State<PyusdStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'PYUSD Insights',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh data
              context.read<PyusdStatsProvider>().loadAllData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: textColor.withOpacity(0.6),
          indicatorColor: primaryColor,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Market Data'),
            Tab(text: 'Network Impact'),
          ],
        ),
      ),
      body: Consumer<PyusdStatsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading real-time PYUSD data...')
              ],
            ));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Overview Tab
              _buildOverviewTab(context, provider),

              // Market Data Tab
              _buildMarketDataTab(context, provider),

              // Network Impact Tab
              _buildNetworkImpactTab(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, PyusdStatsProvider provider) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'PYUSD at a Glance',
            content: Column(
              children: [
                _buildKeyMetric(
                  icon: Icons.monetization_on,
                  label: 'PYUSD Price',
                  value: '\$ ${provider.formatNumber(provider.pyusdPrice)}',
                  color: Colors.indigoAccent,
                ),
                const Divider(),
                _buildKeyMetric(
                  icon: Icons.account_balance_wallet,
                  label: 'Total Market Cap',
                  value: provider.formatNumber(provider.marketCap),
                  color: Colors.blue,
                ),
                const Divider(),
                _buildKeyMetric(
                  icon: Icons.people,
                  label: 'Total Holders',
                  value: '${(provider.holders / 1000).toStringAsFixed(1)}K',
                  color: Colors.green,
                ),
                const Divider(),
                _buildKeyMetric(
                  icon: Icons.arrow_upward,
                  label: 'Monthly Growth',
                  value: '${(provider.growthRate * 100).toStringAsFixed(1)}%',
                  color: Colors.orange,
                ),
                const Divider(),
                _buildKeyMetric(
                  icon: Icons.compare_arrows,
                  label: 'Daily Transactions',
                  value: provider.dailyTransactions.toString(),
                  color: Colors.purple,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Key Impact Metrics',
            content: Column(
              children: [
                ListTile(
                  title: const Text('Ethereum Gas Savings'),
                  subtitle: Text(
                    'PYUSD transactions save approximately ${(provider.ethereumGasImpact * 100).toStringAsFixed(1)}% on gas costs compared to other stablecoins',
                    style: TextStyle(color: textColor.withOpacity(0.7)),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber.withOpacity(0.2),
                    child: const Icon(Icons.local_gas_station,
                        color: Colors.amber, size: 20),
                  ),
                ),
                ListTile(
                  title: const Text('Network Benefits'),
                  subtitle: Text(
                    'Estimated monthly savings of ${provider.formatNumber(provider.monthlySavingsFee)} in fees across the ecosystem',
                    style: TextStyle(color: textColor.withOpacity(0.7)),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.2),
                    child: const Icon(Icons.savings,
                        color: Colors.green, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Why PYUSD Matters',
            content: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'PYUSD is a regulated stablecoin that combines compliance with the benefits of blockchain technology. It significantly improves cross-border transactions while reducing costs and settlement times.',
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PYUSD is fully backed 1:1 with cash and cash equivalents, ensuring stability and security for holders',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketDataTab(
      BuildContext context, PyusdStatsProvider provider) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Historical Growth',
            content: SizedBox(
              height: 250,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < provider.monthlyData.length) {
                              return Text(
                                provider.monthlyData[value.toInt()]['month'],
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              );
                            }
                            return const Text('');
                          },
                          reservedSize: 22,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          provider.monthlyData.length,
                          (index) => FlSpot(
                            index.toDouble(),
                            provider.monthlyData[index]['marketCap'] /
                                1000000000,
                          ),
                        ),
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withOpacity(0.2),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((touchedSpot) {
                            final index = touchedSpot.x.toInt();
                            return LineTooltipItem(
                              '${provider.monthlyData[index]['month']}: ${provider.formatNumber(provider.monthlyData[index]['marketCap'])}',
                              TextStyle(color: textColor),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Market Share Comparison',
            content: SizedBox(
              height: 250,
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: provider.networkShare
                            .asMap()
                            .entries
                            .map<PieChartSectionData>((entry) {
                          final colors = [
                            Colors.blue,
                            Colors.green,
                            Colors.orange,
                            Colors.purple
                          ];
                          return PieChartSectionData(
                            color: colors[entry.key % colors.length],
                            value: entry.value['value'].toDouble(),
                            title: '${entry.value['value']}%',
                            radius: 100,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: provider.networkShare
                          .asMap()
                          .entries
                          .map<Widget>((entry) {
                        final colors = [
                          Colors.blue,
                          Colors.green,
                          Colors.orange,
                          Colors.purple
                        ];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                color: colors[entry.key % colors.length],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.value['name'],
                                style: TextStyle(color: textColor),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'PYUSD Growth Metrics',
            content: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Circulating Supply'),
                    subtitle:
                        Text(provider.formatNumber(provider.circulatingSupply)),
                    leading:
                        const Icon(Icons.attach_money, color: Colors.green),
                  ),
                  ListTile(
                    title: const Text('Average Transaction'),
                    subtitle: Text(
                        '\$${provider.averageTransactionValue.toStringAsFixed(2)}'),
                    leading: const Icon(Icons.swap_horiz, color: Colors.orange),
                  ),
                  ListTile(
                    title: const Text('Growth Rate (Monthly)'),
                    subtitle: Text(
                        '+${(provider.growthRate * 100).toStringAsFixed(2)}%'),
                    leading: const Icon(Icons.trending_up, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImpactTab(
      BuildContext context, PyusdStatsProvider provider) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Chain Distribution',
            content: SizedBox(
              height: 250,
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: provider.chainDistribution
                            .asMap()
                            .entries
                            .map<PieChartSectionData>((entry) {
                          final colors = [
                            Colors.indigo,
                            Colors.teal,
                            Colors.amber,
                            Colors.deepPurple
                          ];
                          return PieChartSectionData(
                            color: colors[entry.key % colors.length],
                            value: entry.value['value'].toDouble(),
                            title: '${entry.value['value']}%',
                            radius: 100,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: provider.chainDistribution
                          .asMap()
                          .entries
                          .map<Widget>((entry) {
                        final colors = [
                          Colors.indigo,
                          Colors.teal,
                          Colors.amber,
                          Colors.deepPurple
                        ];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                color: colors[entry.key % colors.length],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.value['name'],
                                style: TextStyle(color: textColor),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Transaction Growth',
            content: SizedBox(
              height: 250,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < provider.monthlyData.length) {
                              return Text(
                                provider.monthlyData[value.toInt()]['month'],
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              );
                            }
                            return const Text('');
                          },
                          reservedSize: 22,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          provider.monthlyData.length,
                          (index) => FlSpot(
                            index.toDouble(),
                            provider.monthlyData[index]['transactions'] / 1000,
                          ),
                        ),
                        isCurved: true,
                        color: Colors.purple,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.purple.withOpacity(0.2),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((touchedSpot) {
                            final index = touchedSpot.x.toInt();
                            return LineTooltipItem(
                              '${provider.monthlyData[index]['month']}: ${provider.monthlyData[index]['transactions']} txs',
                              TextStyle(color: textColor),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Blockchain Impact',
            content: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildProgressIndicator(
                        label: 'Gas Efficiency',
                        value: 0.82,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _buildProgressIndicator(
                        label: 'Transaction Speed',
                        value: 0.75,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _buildProgressIndicator(
                        label: 'Network Adoption',
                        value: 0.65,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      _buildProgressIndicator(
                        label: 'Cross-chain Integration',
                        value: 0.58,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'PYUSD Environmental Impact',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'PYUSD uses approximately ${(provider.ethereumGasImpact * 100).toStringAsFixed(1)}% less gas than traditional stablecoins, reducing the carbon footprint of transactions on the Ethereum network.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Estimated annual CO₂ reduction: 28.5 metric tons',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget content}) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          content,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildKeyMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator({
    required String label,
    required double value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
