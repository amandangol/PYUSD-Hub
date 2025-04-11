import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/market_service.dart';
import '../../model/networkcongestion_model.dart';
import '../widgets/gasprice_chart.dart';
import '../../provider/network_congestion_provider.dart';
import '../../../settings/view/notification_settings_screen.dart';

class GasTab extends StatefulWidget {
  final NetworkCongestionData congestionData;

  const GasTab({super.key, required this.congestionData});

  @override
  State<GasTab> createState() => _GasTabState();
}

class _GasTabState extends State<GasTab> {
  late NetworkCongestionData _congestionData;
  bool _isRefreshing = false;
  late NetworkCongestionProvider _provider;

  @override
  void initState() {
    super.initState();
    _congestionData = widget.congestionData;
    _provider = context.read<NetworkCongestionProvider>();
  }

  @override
  void didUpdateWidget(GasTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.congestionData != oldWidget.congestionData) {
      setState(() {
        _congestionData = widget.congestionData;
      });
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Wait for a short delay to show refresh animation
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _congestionData = widget.congestionData;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gas Price Overview Card
            _buildGasOverviewCard(colorScheme),

            const SizedBox(height: 16),

            // Gas Price Trend Chart
            _buildGasPriceSection(colorScheme),

            const SizedBox(height: 16),

            // Gas Price Alert Settings Card
            _buildGasPriceAlertCard(colorScheme),

            const SizedBox(height: 16),

            // Gas Fee Estimator
            GasFeeEstimator(
              currentGasPrice: _congestionData.currentGasPrice,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Color _getGasPriceColor(double current, double average) {
    if (average == 0) return Colors.grey; // Prevent division by zero

    final diff = current - average;
    final diffPercentage = (diff / average * 100);

    if (diffPercentage <= -5) return Colors.green; // Lower than average → good
    if (diffPercentage < 10) return Colors.orange; // Slightly higher → warning
    return Colors.red; // Much higher → alert
  }

  // Gas Overview Card
  Widget _buildGasOverviewCard(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Gas Prices',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPriorityGasCard(
                    'Low Priority',
                    (_congestionData.currentGasPrice * 0.8).toStringAsFixed(3),
                    'Slower',
                    Colors.green,
                    colorScheme,
                  ),
                  _buildPriorityGasCard(
                    'Medium Priority',
                    _congestionData.currentGasPrice.toStringAsFixed(3),
                    'Standard',
                    Colors.blue,
                    colorScheme,
                  ),
                  _buildPriorityGasCard(
                    'High Priority',
                    (_congestionData.currentGasPrice * 1.2).toStringAsFixed(3),
                    'Faster',
                    Colors.orange,
                    colorScheme,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityGasCard(String title, String price, String speed,
      Color color, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$price Gwei',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            speed,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // Gas Price Section
  Widget _buildGasPriceSection(ColorScheme colorScheme) {
    final priceDiff =
        _congestionData.currentGasPrice - _congestionData.averageGasPrice;
    final priceDiffPercentage =
        (priceDiff / _congestionData.averageGasPrice * 100).abs();

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gas Price Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Recent gas prices (Gwei) - lower is better',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: GasPriceChart(
                  gasPrices: _congestionData.historicalGasPrices,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildGasInfoItem(
                    'Current',
                    '${_congestionData.currentGasPrice.toStringAsFixed(3)} Gwei',
                    _getGasPriceColor(priceDiffPercentage, priceDiff),
                    colorScheme,
                  ),
                  _buildGasInfoItem(
                    'Average (24h)',
                    '${_congestionData.averageGasPrice.toStringAsFixed(3)} Gwei',
                    Colors.blue,
                    colorScheme,
                  ),
                  _buildGasInfoItem(
                    'Change',
                    '${(priceDiff >= 0 ? "+" : "")}${priceDiffPercentage.toStringAsFixed(1)}%',
                    _getGasPriceColor(priceDiffPercentage, priceDiff),
                    colorScheme,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getGasPriceColor(priceDiffPercentage, priceDiff)
                          .withOpacity(0.1),
                      _getGasPriceColor(priceDiffPercentage, priceDiff)
                          .withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      priceDiff >= 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: _getGasPriceColor(priceDiffPercentage, priceDiff),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${priceDiffPercentage.toStringAsFixed(1)}% ${priceDiff >= 0 ? 'higher' : 'lower'} than average',
                      style: TextStyle(
                        color:
                            _getGasPriceColor(priceDiffPercentage, priceDiff),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Update the gas price alert card to be more compact
  Widget _buildGasPriceAlertCard(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gas Price Alerts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _provider.gasPriceNotificationsEnabled
                            ? 'Enabled'
                            : 'Disabled',
                        style: TextStyle(
                          color: _provider.gasPriceNotificationsEnabled
                              ? Colors.green
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.settings,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const NotificationSettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_provider.gasPriceNotificationsEnabled) ...[
                Text(
                  'Alert threshold: ${_provider.gasPriceThreshold.round()} Gwei',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You will be notified when gas price drops below ${_provider.gasPriceThreshold.round()} Gwei',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else
                Text(
                  'Enable notifications in Settings to get alerts when gas prices are low',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Gas Fee Estimator
class GasFeeEstimator extends StatefulWidget {
  final double currentGasPrice;
  final ColorScheme colorScheme;

  const GasFeeEstimator({
    super.key,
    required this.currentGasPrice,
    required this.colorScheme,
  });

  @override
  State<GasFeeEstimator> createState() => _GasFeeEstimatorState();
}

class _GasFeeEstimatorState extends State<GasFeeEstimator> {
  // Market service instance
  final MarketService _marketService = MarketService();

  // ETH price state
  double _ethPrice = 0.0;
  bool _isLoading = true;
  bool _mounted = true; // Track if widget is mounted

  @override
  void initState() {
    super.initState();
    _fetchEthPrice();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  // Fetch current ETH price
  Future<void> _fetchEthPrice() async {
    if (!_mounted) return;

    try {
      final prices = await _marketService.getCurrentPrices(['ETH']);
      if (!_mounted) return;

      setState(() {
        _ethPrice = prices['ETH'] ?? 0.0;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching ETH price: $e');
      if (!_mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // These are estimates - we use the current gas price from congestion data
    final lowGwei = widget.currentGasPrice * 0.8;
    final mediumGwei = widget.currentGasPrice;
    final highGwei = widget.currentGasPrice * 1.2;

    // Assume average ETH transfer gas usage
    const gasUsed = 21000;

    // Convert gwei to ETH
    const gweiToEth = 0.000000001;

    // Calculate costs in ETH
    final lowCostEth = lowGwei * gasUsed * gweiToEth;
    final mediumCostEth = mediumGwei * gasUsed * gweiToEth;
    final highCostEth = highGwei * gasUsed * gweiToEth;

    // Calculate costs in USD
    final lowCostUsd = lowCostEth * _ethPrice;
    final mediumCostUsd = mediumCostEth * _ethPrice;
    final highCostUsd = highCostEth * _ethPrice;

    if (_isLoading) {
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Fee Estimator',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // IconButton(
                //   icon: const Icon(Icons.refresh),
                //   onPressed: _fetchEthPrice,
                // ),
              ],
            ),
            const Text(
              'Estimated costs for a standard ETH transfer',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current ETH Price: \$${_ethPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(3),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                const TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Priority',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Text('Gas Price',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Time', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Cost (USD)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('Low', style: TextStyle(color: Colors.green)),
                    ),
                    Text('${lowGwei.toStringAsFixed(2)} Gwei'),
                    const Text('~5 min'),
                    Text('\$${lowCostUsd.toStringAsFixed(4)}'),
                  ],
                ),
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child:
                          Text('Medium', style: TextStyle(color: Colors.blue)),
                    ),
                    Text('${mediumGwei.toStringAsFixed(2)} Gwei'),
                    const Text('~2 min'),
                    Text('\$${mediumCostUsd.toStringAsFixed(4)}'),
                  ],
                ),
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child:
                          Text('High', style: TextStyle(color: Colors.orange)),
                    ),
                    Text('${highGwei.toStringAsFixed(2)} Gwei'),
                    const Text('<1 min'),
                    Text('\$${highCostUsd.toStringAsFixed(4)}'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildGasInfoItem(
    String label, String value, Color color, ColorScheme colorScheme) {
  return Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}
