import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../settings/view/pyusd_info_screen.dart';
import '../provider/insights_provider.dart';
import '../../../widgets/pyusd_components.dart';
import '../widgets/exchangelist_screen.dart';
import '../widgets/exchange_list_item.dart';
import '../../news/view/news_explore_screen.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PyusdAppBar(
        title: 'PYUSD Insights',
        isDarkMode: isDarkMode,
        showLogo: true,
        onRefreshPressed: context.read<InsightsProvider>().refresh,
        hasWallet: true,
      ),
      body: Consumer<InsightsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading &&
              provider.marketData['is_real_data'] != true) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading market data...'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchAllData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildDataSourceBanner(provider, theme),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPriceCard(context, provider, theme),
                        const SizedBox(height: 16),
                        // _buildNewsSection(context, theme),
                        // const SizedBox(height: 16),
                        _buildPyusdInfoSection(context, theme),
                        const SizedBox(height: 16),
                        _buildMarketStatsGrid(context, provider, theme),
                        const SizedBox(height: 16),
                        _buildPriceChart(context, provider, theme),
                        const SizedBox(height: 16),
                        _buildSupportedChains(context, provider, theme),
                        const SizedBox(height: 16),
                        _buildExchangeList(context, provider, theme),
                        const SizedBox(height: 24),
                        _buildDataDisclaimer(theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDataSourceBanner(InsightsProvider provider, ThemeData theme) {
    final isRealData = provider.marketData['is_real_data'] ?? false;
    final lastUpdated =
        provider.getTimeAgo(provider.marketData['last_updated']);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: isRealData
          ? (isDarkMode
              ? Colors.green.shade900.withOpacity(0.3)
              : Colors.green.withOpacity(0.1))
          : (isDarkMode
              ? Colors.orange.shade900.withOpacity(0.3)
              : Colors.orange.withOpacity(0.1)),
      child: Row(
        children: [
          Icon(
            isRealData ? Icons.verified : Icons.warning,
            color: isRealData
                ? (isDarkMode ? Colors.green.shade300 : Colors.green.shade700)
                : (isDarkMode
                    ? Colors.orange.shade300
                    : Colors.orange.shade700),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isRealData ? 'Updated $lastUpdated' : 'Pull down to refresh',
              style: TextStyle(
                color: isRealData ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(
      BuildContext context, InsightsProvider provider, ThemeData theme) {
    final marketData = provider.marketData;
    final currentPrice =
        marketData['current_price']?.toStringAsFixed(3) ?? '1.00';
    final priceChange = marketData['price_change_24h'] ?? 0.0;
    final color = provider.getPriceChangeColor(priceChange);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    theme.colorScheme.primary.withOpacity(0.2),
                    theme.colorScheme.primary.withOpacity(0.05),
                  ]
                : [
                    theme.colorScheme.primary.withOpacity(0.1),
                    theme.colorScheme.primary.withOpacity(0.1),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/pyusdlogo.png',
                    width: 36,
                    height: 36,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PayPal USD',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'PYUSD',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        priceChange >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: color,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        provider.formatPercentage(priceChange),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '\$$currentPrice',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '24h Change: ${priceChange >= 0 ? '+' : ''}${priceChange.toStringAsFixed(4)}',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketStatsGrid(
      BuildContext context, InsightsProvider provider, ThemeData theme) {
    final marketData = provider.marketData;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Market Stats',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  'Market Cap',
                  '\$${provider.formatNumber(marketData['market_cap'])}',
                  Icons.pie_chart,
                  theme,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Volume 24h',
                  '\$${provider.formatNumber(marketData['total_volume'])}',
                  Icons.bar_chart,
                  theme,
                  Colors.green,
                ),
                _buildStatCard(
                  'Circulating Supply',
                  provider.formatNumber(marketData['circulating_supply']),
                  Icons.autorenew,
                  theme,
                  Colors.purple,
                ),
                _buildStatCard(
                  'Total Supply',
                  provider.formatNumber(marketData['total_supply']),
                  Icons.all_inclusive,
                  theme,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, ThemeData theme, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChart(
      BuildContext context, InsightsProvider provider, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    final selectedTimeFrame = provider.selectedTimeFrame;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price History',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    _buildTimeFrameButton(
                        context, '1D', TimeFrame.day, provider, theme),
                    _buildTimeFrameButton(
                        context, '1W', TimeFrame.week, provider, theme),
                    _buildTimeFrameButton(
                        context, '1M', TimeFrame.month, provider, theme),
                    _buildTimeFrameButton(
                        context, '3M', TimeFrame.threeMonths, provider, theme),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: provider.getChartData(selectedTimeFrame).isEmpty
                  ? Center(
                      child: Text(
                        'No chart data available',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: 0.005,
                          verticalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: theme.dividerColor.withOpacity(0.3),
                              strokeWidth: 1,
                            );
                          },
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                              color: theme.dividerColor.withOpacity(0.3),
                              strokeWidth: 1,
                            );
                          },
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
                              interval:
                                  provider.getXAxisInterval(selectedTimeFrame),
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                final data =
                                    provider.getChartData(selectedTimeFrame);
                                if (index < 0 || index >= data.length) {
                                  return const SizedBox();
                                }
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    provider.getFormattedDateForChart(
                                        index, selectedTimeFrame, data.length),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 0.01,
                              getTitlesWidget: (value, meta) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    '\$${value.toStringAsFixed(2)}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                );
                              },
                              reservedSize: 42,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        minX: 0,
                        maxX: provider
                                .getChartData(selectedTimeFrame)
                                .length
                                .toDouble() -
                            1,
                        minY: provider.getChartMinMax(selectedTimeFrame)[0],
                        maxY: provider.getChartMinMax(selectedTimeFrame)[1],
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              provider.getChartData(selectedTimeFrame).length,
                              (index) => FlSpot(
                                index.toDouble(),
                                provider.getChartData(selectedTimeFrame)[index],
                              ),
                            ),
                            isCurved: true,
                            color: theme.colorScheme.primary,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: theme.colorScheme.primary.withOpacity(0.2),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            tooltipRoundedRadius: 8,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((touchedSpot) {
                                final index = touchedSpot.x.toInt();
                                final data =
                                    provider.getChartData(selectedTimeFrame);
                                if (index < 0 || index >= data.length) {
                                  return null;
                                }
                                return LineTooltipItem(
                                  '\$${touchedSpot.y.toStringAsFixed(4)}',
                                  TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          '\n${provider.getFormattedDateForTooltip(index, selectedTimeFrame)}',
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.black54,
                                        fontWeight: FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFrameButton(BuildContext context, String text,
      TimeFrame timeFrame, InsightsProvider provider, ThemeData theme) {
    final isSelected = provider.selectedTimeFrame == timeFrame;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => provider.setTimeFrame(timeFrame),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isSelected ? theme.colorScheme.primary : theme.dividerColor,
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportedChains(
      BuildContext context, InsightsProvider provider, ThemeData theme) {
    final chains = provider.marketData['supported_chains'] as List? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.link,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Supported Chains',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: chains.map((chain) {
                String chainName = chain.toString();
                String svgAsset;
                Color chainColor;

                switch (chainName.toLowerCase()) {
                  case 'ethereum':
                    svgAsset = 'assets/svg/ethereum_logo.svg';
                    chainColor = Colors.purple;
                    break;
                  case 'solana':
                    svgAsset = 'assets/svg/solana.svg';
                    chainColor = Colors.blue;
                    break;
                  default:
                    svgAsset = 'assets/svg/link.svg';
                    chainColor = theme.colorScheme.primary;
                }

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: chainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: chainColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        svgAsset,
                        height: 20,
                        width: 20,
                        placeholderBuilder: (BuildContext context) => Icon(
                          chainName.toLowerCase() == 'ethereum'
                              ? Icons.currency_bitcoin
                              : chainName.toLowerCase() == 'solana'
                                  ? Icons.currency_exchange
                                  : Icons.link,
                          size: 18,
                          color: chainColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        chainName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: chainColor,
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

  Widget _buildExchangeList(
      BuildContext context, InsightsProvider provider, ThemeData theme) {
    final exchanges = provider.tickers;

    if (exchanges.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Available on Exchanges',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.business,
                      size: 48,
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Exchange data not available',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Available on Exchanges',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exchanges.length > 5 ? 5 : exchanges.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return ExchangeListItem(
                  exchange: exchanges[index],
                  isCompact: true,
                );
              },
            ),
            if (exchanges.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.more_horiz),
                    label: const Text('View More Exchanges'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExchangeListScreen(
                            exchanges: exchanges,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataDisclaimer(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Disclaimer',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Market data is provided for informational purposes only and is not financial advice. Data may be delayed or inaccurate.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPyusdInfoSection(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PYUSD Information',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PyusdInfoScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PyusdInfoScreen.qaItems.take(3).map((item) {
                return Container(
                  width: 250,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PyusdInfoScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: item.iconColor.withOpacity(0.2),
                              child: Icon(
                                item.icon,
                                color: item.iconColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.question,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.answer,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsSection(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewsExploreScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.newspaper,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Latest News',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Stay updated with the latest news about PYUSD and the crypto market',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Chip(
                    label: const Text('PYUSD'),
                    backgroundColor: Colors.green.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text('Ethereum'),
                    backgroundColor: Colors.purple.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text('Market'),
                    backgroundColor: Colors.orange.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
