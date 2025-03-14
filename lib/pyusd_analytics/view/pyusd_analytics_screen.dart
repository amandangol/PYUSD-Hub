import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../provider/pyusd_analytics_provider.dart';

class PyusdInsightsScreen extends StatefulWidget {
  const PyusdInsightsScreen({Key? key}) : super(key: key);

  @override
  State<PyusdInsightsScreen> createState() => _PyusdInsightsScreenState();
}

class _PyusdInsightsScreenState extends State<PyusdInsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final compactFormat = NumberFormat.compact();
  final percentFormat = NumberFormat.percentPattern();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PyusdInsightsProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PYUSD Insights'),
          centerTitle: false,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Holders'),
              Tab(text: 'Transactions'),
              Tab(text: 'Network'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                Provider.of<PyusdInsightsProvider>(context, listen: false)
                    .refreshData();
              },
            ),
          ],
        ),
        body: Consumer<PyusdInsightsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage.isNotEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading data',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(provider.errorMessage),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => provider.refreshData(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(provider, context),
                _buildHoldersTab(provider, context),
                _buildTransactionsTab(provider, context),
                _buildNetworkTab(provider, context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
      PyusdInsightsProvider provider, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSection(
          title: 'PYUSD at a Glance',
          children: [
            _buildMetricCard(
              icon: Icons.account_balance,
              title: 'Total Supply',
              value: currencyFormat.format(provider.totalSupply),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.people,
                    title: 'Unique Holders',
                    value: compactFormat.format(provider.uniqueHolders),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.swap_horiz,
                    title: 'Total Transfers',
                    value: compactFormat.format(provider.totalTransfers),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildChartCard(
              title: 'Supply History',
              height: 250,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LineChart(
                  _buildSupplyLineChart(provider),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: 'Volume',
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.calendar_today,
                    title: 'Daily Volume',
                    value: currencyFormat.format(provider.dailyVolume),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.calendar_view_week,
                    title: 'Weekly Volume',
                    value: currencyFormat.format(provider.weeklyVolume),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricCard(
              icon: Icons.calendar_month,
              title: 'Monthly Volume',
              value: currencyFormat.format(provider.monthlyVolume),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: 'Chain Distribution',
          children: [
            _buildChartCard(
              title: 'PYUSD Across Chains',
              height: 300,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: PieChart(
                  _buildChainDistributionPieChart(provider),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHoldersTab(
      PyusdInsightsProvider provider, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSection(
          title: 'Top Holders',
          children: [
            _buildTopHoldersTable(provider),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: 'Holder Distribution',
          children: [
            _buildChartCard(
              title: 'Wallet Size Distribution',
              height: 300,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: BarChart(
                  _buildWalletDistributionBarChart(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionsTab(
      PyusdInsightsProvider provider, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSection(
          title: 'Transaction Activity',
          children: [
            _buildChartCard(
              title: 'Daily Transactions',
              height: 250,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: BarChart(
                  _buildTransactionActivityBarChart(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: 'Recent Transactions',
          children: [
            _buildRecentTransactionsTable(provider),
          ],
        ),
      ],
    );
  }

  Widget _buildNetworkTab(
      PyusdInsightsProvider provider, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSection(
          title: 'Network Impact',
          children: [
            _buildMetricCard(
              icon: Icons.local_fire_department,
              title: 'ETH Burned from PYUSD',
              value: '${provider.ethBurned} ETH',
            ),
            const SizedBox(height: 16),
            _buildMetricCard(
              icon: Icons.pie_chart,
              title: 'Stablecoin Market Share',
              value: '${provider.marketShare}%',
            ),
            const SizedBox(height: 16),
            _buildChartCard(
              title: 'Gas Used by PYUSD Transactions',
              height: 250,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LineChart(
                  _buildGasUsageLineChart(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: 'PYUSD vs Other Stablecoins',
          children: [
            _buildChartCard(
              title: 'Market Share Comparison',
              height: 300,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: PieChart(
                  _buildStablecoinMarketSharePieChart(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required double height,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: height,
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildTopHoldersTable(PyusdInsightsProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: provider.topHolders.map((holder) {
            int index = provider.topHolders.indexOf(holder);
            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                child: Text('${index + 1}'),
              ),
              title: Text(
                holder['label'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${holder['address'].toString().substring(0, 6)}...${holder['address'].toString().substring(holder['address'].toString().length - 4)}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currencyFormat.format(holder['balance']),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${holder['percentage']}%',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(), // Convert the iterable to a List
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsTable(PyusdInsightsProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            for (var tx in provider.recentTransactions.take(10))
              ListTile(
                title: Row(
                  children: [
                    Text(
                      'From: ${tx['from'].toString().substring(0, 6)}...${tx['from'].toString().substring(38)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Icon(Icons.arrow_right_alt),
                    Text(
                      'To: ${tx['to'].toString().substring(0, 6)}...${tx['to'].toString().substring(38)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Tx: ${tx['hash'].toString().substring(0, 10)}...',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currencyFormat.format(tx['value']),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatTimestamp(tx['timestamp']),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final now = DateTime.now();
    final txTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(txTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  LineChartData _buildSupplyLineChart(PyusdInsightsProvider provider) {
    List<FlSpot> spots = [];

    for (var i = 0; i < provider.supplyHistory.length; i++) {
      spots.add(FlSpot(
          i.toDouble(), provider.supplyHistory[i]['supply'] / 1000000000));
    }

    return LineChartData(
      gridData: const FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 0.5,
        verticalInterval: 5,
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 5,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= provider.supplyHistory.length ||
                  value % 5 != 0) {
                return const SizedBox.shrink();
              }
              final date =
                  DateTime.parse(provider.supplyHistory[value.toInt()]['date']);
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${date.month}/${date.day}',
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 0.5,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toStringAsFixed(1)}B',
                style: const TextStyle(fontSize: 10),
              );
            },
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d), width: 1),
      ),
      minX: 0,
      maxX: (provider.supplyHistory.length - 1).toDouble(),
      minY: spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 0.2,
      maxY: spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 0.2,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Theme.of(context).colorScheme.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
        ),
      ],
    );
  }

  PieChartData _buildChainDistributionPieChart(PyusdInsightsProvider provider) {
    final chains = provider.chainDistribution.keys.toList();
    final values = provider.chainDistribution.values.toList();
    final colorList = [
      const Color(0xff0088ff),
      const Color(0xff8c52ff),
      const Color(0xffff5c77),
      const Color(0xffffa600),
      const Color(0xff36d39a),
    ];

    return PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 50,
      sections: List.generate(chains.length, (i) {
        return PieChartSectionData(
          color: colorList[i % colorList.length],
          value: values[i],
          title: '${chains[i]}\n${values[i]}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }),
    );
  }

  BarChartData _buildWalletDistributionBarChart() {
    // Sample data for wallet distribution
    final walletSizes = ['0-100', '100-1K', '1K-10K', '10K-100K', '100K+'];
    final walletCounts = [15000.0, 18000.0, 7500.0, 1800.0, 280.0];

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: walletCounts.reduce((a, b) => a > b ? a : b) * 1.2,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              '${walletSizes[groupIndex]}: ${compactFormat.format(rod.toY)}',
              const TextStyle(color: Colors.white),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value < 0 || value >= walletSizes.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  walletSizes[value.toInt()],
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                compactFormat.format(value),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d), width: 1),
      ),
      barGroups: List.generate(walletSizes.length, (index) {
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: walletCounts[index],
              color: Theme.of(context).colorScheme.primary,
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        );
      }),
    );
  }

  BarChartData _buildTransactionActivityBarChart() {
    // Sample data for transaction activity
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final txCounts = [2340.0, 3120.0, 2890.0, 3250.0, 3580.0, 2470.0, 1980.0];

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: txCounts.reduce((a, b) => a > b ? a : b) * 1.2,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              '${days[groupIndex]}: ${compactFormat.format(rod.toY)}',
              const TextStyle(color: Colors.white),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value < 0 || value >= days.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  days[value.toInt()],
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                compactFormat.format(value),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d), width: 1),
      ),
      barGroups: List.generate(days.length, (index) {
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: txCounts[index],
              color: Theme.of(context).colorScheme.secondary,
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        );
      }),
    );
  }

  LineChartData _buildGasUsageLineChart() {
    // Sample data for gas usage
    final spots = [
      const FlSpot(0, 1.2),
      const FlSpot(1, 1.8),
      const FlSpot(2, 2.3),
      const FlSpot(3, 1.9),
      const FlSpot(4, 2.1),
      const FlSpot(5, 2.6),
      const FlSpot(6, 2.8),
    ];

    return LineChartData(
      gridData: const FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 0.5,
        verticalInterval: 1,
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              if (value.toInt() >= days.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  days[value.toInt()],
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 0.5,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toStringAsFixed(1)}M',
                style: const TextStyle(fontSize: 10),
              );
            },
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d), width: 1),
      ),
      minX: 0,
      maxX: 6,
      minY: 1,
      maxY: 3,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.amber,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.amber.withOpacity(0.2),
          ),
        ),
      ],
    );
  }

  PieChartData _buildStablecoinMarketSharePieChart() {
    // Sample data for stablecoin market share
    final stablecoins = ['USDT', 'USDC', 'BUSD', 'DAI', 'PYUSD', 'Others'];
    final marketShares = [37.5, 28.6, 12.4, 10.3, 8.2, 3.0];
    final colorList = [
      const Color(0xff26a17b), // USDT green
      const Color(0xff2775ca), // USDC blue
      const Color(0xfff0b90b), // BUSD yellow
      const Color(0xfff4b731), // DAI gold
      const Color(0xff0066ff), // PYUSD blue
      const Color(0xff888888), // Others gray
    ];

    return PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 50,
      sections: List.generate(stablecoins.length, (i) {
        return PieChartSectionData(
          color: colorList[i],
          value: marketShares[i],
          title: '${stablecoins[i]}\n${marketShares[i]}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }),
    );
  }
}
