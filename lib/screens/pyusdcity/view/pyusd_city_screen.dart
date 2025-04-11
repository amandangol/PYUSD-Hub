import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../networkcongestion/model/networkcongestion_model.dart';
import '../../networkcongestion/provider/network_congestion_provider.dart';
import '../../networkcongestion/view/widgets/stats_card.dart';
import '../widgets/city_building.dart';
import '../widgets/cloud_widget.dart';
import '../widgets/transaction_vehicle.dart';
import '../../../utils/formatter_utils.dart';

class PyusdCityScreen extends StatefulWidget {
  const PyusdCityScreen({super.key});

  @override
  State<PyusdCityScreen> createState() => _PyusdCityScreenState();
}

class _PyusdCityScreenState extends State<PyusdCityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final Random _random = Random();
  bool _isInitialized = false;
  bool _showLegend = false;
  bool _showWeatherEffects = true;
  bool _showNightMode = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<NetworkCongestionProvider>(context, listen: false);
      if (provider.isLoading) {
        provider.fastInitialize().then((_) {
          provider.completeInitialization().then((_) {
            setState(() {
              _isInitialized = true;
            });

            // Scroll to the middle of the city to show the most recent blocks
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent * 0.7,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              );
            }
          });
        });
      } else {
        setState(() {
          _isInitialized = true;
        });

        // Scroll to the middle of the city
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent * 0.7,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PYUSD City'),
        actions: [
          IconButton(
            icon: Icon(_showLegend ? Icons.map_outlined : Icons.map),
            tooltip: 'Toggle Legend',
            onPressed: () {
              setState(() {
                _showLegend = !_showLegend;
              });
            },
          ),
          IconButton(
            icon:
                Icon(_showNightMode ? Icons.wb_sunny : Icons.nightlight_round),
            tooltip: 'Toggle Day/Night',
            onPressed: () {
              setState(() {
                _showNightMode = !_showNightMode;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () {
              final provider = Provider.of<NetworkCongestionProvider>(context,
                  listen: false);
              provider.refresh();

              // Scroll to show the most recent blocks after refresh
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent * 0.7,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About PYUSD City',
            onPressed: () {
              _showInfoDialog(context);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _showWeatherEffects = !_showWeatherEffects;
          });
        },
        tooltip: 'Toggle Weather Effects',
        child: Icon(_showWeatherEffects ? Icons.cloud : Icons.cloud_off),
      ),
      body: Consumer<NetworkCongestionProvider>(
        builder: (context, provider, child) {
          if (!_isInitialized || provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Building PYUSD City...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Loading network data and constructing visualization',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            );
          }

          final data = provider.congestionData;
          final congestionLevel = data.congestionLevel;

          return Stack(
            children: [
              // Sky background
              Container(
                color: _getSkyColor(congestionLevel),
              ),

              // Stars in night mode
              if (_showNightMode)
                SizedBox.expand(
                  child: CustomPaint(
                    painter: StarsPainter(density: 0.0003),
                  ),
                ),

              // City visualization
              Stack(
                children: [
                  Column(
                    children: [
                      // Data summary bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        color: Colors.black.withOpacity(0.7),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Showing last ${provider.recentBlocks.length} blocks',
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              'PYUSD Txs: ${data.confirmedPyusdTxCount}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),

                      // City layout with proper alignment
                      Expanded(
                        child: Stack(
                          children: [
                            // Weather effects
                            if (_showWeatherEffects)
                              ...(_buildWeatherEffects(congestionLevel)),

                            Column(
                              children: [
                                // Upper part of the city (buildings)
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: SingleChildScrollView(
                                      controller: _scrollController,
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: _buildCityBlocks(provider),
                                      ),
                                    ),
                                  ),
                                ),

                                // Road with vehicles
                                Container(
                                  height: 120,
                                  color: Colors.grey.shade800,
                                  child: Stack(
                                    children: [
                                      // Road markings
                                      SizedBox.expand(
                                        child: CustomPaint(
                                          painter: RoadMarkingsPainter(
                                            animationValue:
                                                _animationController.value,
                                            congestionLevel: congestionLevel,
                                          ),
                                        ),
                                      ),

                                      // Vehicles
                                      _buildVehicles(data),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Control panel
                      _buildControlPanel(context, data),
                    ],
                  ),

                  // Network status indicators - now in a Stack
                  Positioned(
                    top: 40,
                    left: 16,
                    child: SizedBox(
                      width: 200,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNetworkStatusBadge(
                            'Network: ${congestionLevel < 30 ? "Low Traffic" : congestionLevel < 60 ? "Moderate" : congestionLevel < 80 ? "High Traffic" : "Congested"}',
                            _getCongestionColor(congestionLevel),
                          ),
                          const SizedBox(height: 8),
                          _buildCongestionIndicator(
                            'Congestion',
                            '$congestionLevel%',
                            congestionLevel / 100,
                          ),
                          const SizedBox(height: 8),
                          // GasStationWidget(
                          //   gasPrice: data.currentGasPrice,
                          //   darkMode: true,
                          // ),
                          _buildCongestionIndicator(
                            'Gas Price',
                            '${data.currentGasPrice.toStringAsFixed(1)} Gwei',
                            min(data.currentGasPrice / 150, 1.0),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Last updated indicator
                  Positioned(
                    top: 40,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Updated: ${data.refreshTimeAgo}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Legend overlay
              if (_showLegend) _buildLegendOverlay(context),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildCityBlocks(NetworkCongestionProvider provider) {
    final List<Widget> buildings = [];
    final blocks = provider.recentBlocks;

    // Add empty space at the beginning for scrolling
    buildings.add(const SizedBox(width: 100));

    // If no blocks available, show placeholder buildings
    if (blocks.isEmpty) {
      for (int i = 0; i < 10; i++) {
        final height = 100 + _random.nextInt(150).toDouble();
        buildings.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: CityBuilding(
              blockNumber: 0,
              height: height.toInt(),
              width: 60,
              transactionCount: 0,
              utilization: 0.5,
            ),
          ),
        );
      }
    } else {
      // Create buildings from actual block data
      for (int i = 0; i < blocks.length; i++) {
        final block = blocks[i];

        // Extract block data
        int blockNumber = 0;
        int txCount = 0;
        double utilization = 0.5;

        if (block['number'] != null) {
          final numStr = block['number'].toString();
          blockNumber = int.tryParse(
                  numStr.startsWith('0x') ? numStr.substring(2) : numStr,
                  radix: numStr.startsWith('0x') ? 16 : 10) ??
              0;
        }

        if (block['transactions'] != null) {
          if (block['transactions'] is List) {
            txCount = (block['transactions'] as List).length;
          }
        }

        if (block['gasUsed'] != null && block['gasLimit'] != null) {
          final gasUsed = int.tryParse(
                  block['gasUsed'].toString().startsWith('0x')
                      ? block['gasUsed'].toString().substring(2)
                      : block['gasUsed'].toString(),
                  radix:
                      block['gasUsed'].toString().startsWith('0x') ? 16 : 10) ??
              0;

          final gasLimit = int.tryParse(
                  block['gasLimit'].toString().startsWith('0x')
                      ? block['gasLimit'].toString().substring(2)
                      : block['gasLimit'].toString(),
                  radix: block['gasLimit'].toString().startsWith('0x')
                      ? 16
                      : 10) ??
              1;

          utilization = gasLimit > 0 ? gasUsed / gasLimit : 0.5;
        }

        // Calculate building height based on gas utilization and transaction count
        // Limit the maximum height to prevent layout issues
        final height = min(100 + (utilization * 200) + min(txCount, 50), 400);

        buildings.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => _showBlockDetails(block),
              child: CityBuilding(
                blockNumber: blockNumber,
                height: height.toInt(),
                width: 60 + min(txCount, 20),
                transactionCount: txCount,
                utilization: utilization,
              ),
            ),
          ),
        );
      }
    }

    // Add empty space at the end for scrolling
    buildings.add(const SizedBox(width: 100));

    return buildings;
  }

  Widget _buildVehicles(NetworkCongestionData data) {
    final provider =
        Provider.of<NetworkCongestionProvider>(context, listen: false);
    final pyusdTransactions = provider.recentPyusdTransactions;
    final screenWidth = MediaQuery.of(context).size.width;

    final List<Widget> vehicles = [];

    // Add PYUSD transactions with improved animation
    for (int i = 0; i < min(pyusdTransactions.length, 12); i++) {
      final position = (_animationController.value + (i * 0.08)) % 1.0;
      final isFastLane = i % 2 == 0;
      final laneOffset = isFastLane ? 10.0 : 60.0;
      final transaction = pyusdTransactions[i];

      // Correctly check transaction status
      final isPending = transaction['status'] == null ||
          transaction['status'] == 'pending' ||
          (transaction['status'] is String && transaction['status'] == '0x0');

      vehicles.add(
        Positioned(
          left: position * (screenWidth + 100) - 50,
          top: laneOffset + (_random.nextDouble() * 20),
          child: GestureDetector(
            onTap: () => _showTransactionDetails(pyusdTransactions[i]),
            child: TransactionVehicle(
              transaction: pyusdTransactions[i],
              isPending: isPending,
              speed: _getTransactionSpeed(pyusdTransactions[i]),
              transactionType: 'pyusd',
              animationValue: _animationController.value,
            ),
          ),
        ),
      );
    }

    // Add other transactions with improved animation
    final otherTxCount = min(data.pendingTransactions ~/ 50, 20);
    for (int i = 0; i < otherTxCount; i++) {
      final position = (_animationController.value + 0.5 + (i * 0.05)) % 1.0;
      final isFastLane = i % 2 == 0;
      final laneOffset = isFastLane ? 10.0 : 60.0;

      // Create a mock transaction with proper status
      final Map<String, dynamic> otherTx = {
        'hash': '0x${_generateRandomHash()}',
        'from': '0x${_generateRandomHash().substring(0, 40)}',
        'to': '0x${_generateRandomHash().substring(0, 40)}',
        'gasPrice': '0x${_random.nextInt(100000000).toRadixString(16)}',
        'status': '0x1', // Set as confirmed by default
      };

      vehicles.add(
        Positioned(
          left: position * (screenWidth + 100) - 50,
          top: laneOffset + (_random.nextDouble() * 20),
          child: GestureDetector(
            onTap: () => _showTransactionDetails(otherTx),
            child: TransactionVehicle(
              transaction: otherTx,
              isPending:
                  false, // Other transactions are always shown as confirmed
              speed: _getTransactionSpeed(otherTx),
              transactionType: 'other',
              animationValue: _animationController.value,
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(children: vehicles);
      },
    );
  }

  String _generateRandomHash() {
    const chars = '0123456789abcdef';
    return List.generate(64, (index) => chars[_random.nextInt(chars.length)])
        .join();
  }

  String _getTransactionSpeed(Map<String, dynamic> transaction) {
    // Determine transaction speed based on gas price
    if (transaction['gasPrice'] != null) {
      final gasPrice = int.tryParse(
              transaction['gasPrice'].toString().startsWith('0x')
                  ? transaction['gasPrice'].toString().substring(2)
                  : transaction['gasPrice'].toString(),
              radix: transaction['gasPrice'].toString().startsWith('0x')
                  ? 16
                  : 10) ??
          0;

      final gasPriceGwei = gasPrice / 1e9;

      if (gasPriceGwei > 50) {
        return 'fast';
      } else if (gasPriceGwei > 30) {
        return 'medium';
      } else {
        return 'slow';
      }
    }

    return 'medium';
  }

  List<Widget> _buildWeatherEffects(int congestionLevel) {
    final List<Widget> effects = [];

    // Add clouds based on congestion level
    if (congestionLevel > 20) {
      final cloudCount = (congestionLevel / 20).round();

      for (int i = 0; i < cloudCount; i++) {
        final size = 30.0 + _random.nextDouble() * 30;
        final opacity = 0.3 + (_random.nextDouble() * 0.5);
        final left = _random.nextDouble() * MediaQuery.of(context).size.width;
        final top = 20.0 + _random.nextDouble() * 100;

        effects.add(
          Positioned(
            left: left,
            top: top,
            child: CloudWidget(
              size: size,
              opacity: opacity,
              darkMode: _showNightMode,
            ),
          ),
        );
      }
    }

    // Add rain for high congestion
    if (congestionLevel > 80) {
      effects.add(
        Positioned.fill(
          child: CustomPaint(
            painter: RainPainter(
              density: congestionLevel / 500,
              animationValue: _animationController.value,
            ),
            size: Size.infinite,
          ),
        ),
      );
    } else if (congestionLevel > 70) {
      // Fog
      effects.add(
        Positioned.fill(
          child: Container(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
      );
    }

    return effects;
  }

  Widget _buildControlPanel(BuildContext context, NetworkCongestionData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 3 - 20,
                child: StatsCard(
                  title: 'Blocks/Hour',
                  value: data.blocksPerHour.toString(),
                  icon: Icons.storage,
                  color: Colors.blue,
                  description: 'Block rate',
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 3 - 20,
                child: StatsCard(
                  title: 'PYUSD Txs',
                  value:
                      '${data.confirmedPyusdTxCount}/${data.pendingPyusdTxCount}',
                  icon: Icons.swap_horiz,
                  color: Colors.green,
                  description: 'Confirmed/Pending',
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 3 - 20,
                child: StatsCard(
                  title: 'Gas Price',
                  value: '${data.currentGasPrice.toStringAsFixed(1)} Gwei',
                  icon: Icons.local_gas_station,
                  color: Colors.orange,
                  description: 'Current',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 2 - 20,
                child: StatsCard(
                  title: 'Network Health',
                  value: '${data.gasUsagePercentage.toStringAsFixed(1)}%',
                  icon: Icons.health_and_safety,
                  color: _getCongestionColor(data.gasUsagePercentage.toInt()),
                  description: 'Gas Usage',
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 2 - 20,
                child: StatsCard(
                  title: 'Est. Wait',
                  value:
                      '${data.estimatedConfirmationMinutes.toStringAsFixed(1)}m',
                  icon: Icons.timer,
                  color: Colors.purple,
                  description: 'For confirmation',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PYUSD City Legend',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Buildings section
          const Text(
            'Buildings (Blocks)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildLegendItem(
            Colors.blue.shade200,
            'Low Gas Usage (<50%)',
          ),
          _buildLegendItem(
            Colors.blue.shade300,
            'Medium Gas Usage (50-70%)',
          ),
          _buildLegendItem(
            Colors.orange.shade300,
            'High Gas Usage (70-90%)',
          ),
          _buildLegendItem(
            Colors.red.shade300,
            'Very High Gas Usage (>90%)',
          ),
          const SizedBox(height: 16),

          // Vehicles section
          const Text(
            'Vehicles (Transactions)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              TransactionVehicle(
                transaction: {'hash': '0x0'},
                isPending: false,
                speed: 'fast',
                transactionType: 'pyusd',
                animationValue: 0.0,
              ),
              SizedBox(width: 8),
              Text(
                'PYUSD Transaction (Fast)',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              TransactionVehicle(
                transaction: {'hash': '0x0'},
                isPending: false,
                speed: 'medium',
                transactionType: 'pyusd',
                animationValue: 0.0,
              ),
              SizedBox(width: 8),
              Text(
                'PYUSD Transaction (Medium)',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              TransactionVehicle(
                transaction: {'hash': '0x0'},
                isPending: false,
                speed: 'slow',
                transactionType: 'pyusd',
                animationValue: 0.0,
              ),
              SizedBox(width: 8),
              Text(
                'PYUSD Transaction (Slow)',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              TransactionVehicle(
                transaction: {'hash': '0x0'},
                isPending: false,
                speed: 'medium',
                transactionType: 'other',
                animationValue: 0.0,
              ),
              SizedBox(width: 8),
              Text(
                'Other Transaction',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              TransactionVehicle(
                transaction: {'hash': '0x0'},
                isPending: true,
                speed: 'medium',
                transactionType: 'pyusd',
                animationValue: 0.0,
              ),
              SizedBox(width: 8),
              Text(
                'Pending Transaction',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showLegend = false;
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.3),
                foregroundColor: Colors.white,
              ),
              child: const Text('Close Legend'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCongestionIndicator(String label, String value, double level) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 100,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: level,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.yellow, Colors.red],
                    stops: [0.3, 0.7, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
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

  Color _getCongestionColor(int level) {
    if (level < 30) {
      return Colors.green;
    } else if (level < 60) {
      return Colors.orange;
    } else if (level < 80) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }

  Color _getSkyColor(int level) {
    if (_showNightMode) {
      // Night mode colors
      if (level < 30) {
        return Colors.indigo.shade900; // Clear night
      } else if (level < 60) {
        return Colors.indigo.shade800; // Slightly cloudy night
      } else if (level < 80) {
        return Colors.grey.shade900; // Cloudy night
      } else {
        return Colors.black; // Stormy night
      }
    } else {
      // Day mode colors
      if (level < 30) {
        return Colors.blue.shade400; // Clear sky
      } else if (level < 60) {
        return Colors.blue.shade300; // Slightly cloudy
      } else if (level < 80) {
        return Colors.grey.shade400; // Cloudy
      } else {
        return Colors.grey.shade700; // Stormy
      }
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About PYUSD City'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome to PYUSD City!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'This is a visual representation of Ethereum network activity related to PYUSD transactions:',
              ),
              SizedBox(height: 8),
              Text('• Buildings represent blocks on the Ethereum blockchain'),
              Text('• Vehicles represent PYUSD transactions'),
              Text('• Road congestion shows network load'),
              Text(
                'The taller a building, the higher the gas utilization in that block. More vehicles on the road means more PYUSD transactions are happening.',
              ),
              SizedBox(height: 16),
              Text(
                'Interactive Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Tap on buildings to see block details'),
              Text('• Tap on vehicles to see transaction details'),
              Text('• Toggle day/night mode in the app bar'),
              Text('• Toggle the legend to understand the visualization'),
              Text('• Use the floating button to toggle weather effects'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    final gasPrice = int.tryParse(
          transaction['gasPrice'].toString().startsWith('0x')
              ? transaction['gasPrice'].toString().substring(2)
              : transaction['gasPrice'].toString(),
          radix: transaction['gasPrice'].toString().startsWith('0x') ? 16 : 10,
        ) ??
        0;

    final gasPriceGwei = gasPrice / 1e9;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          transaction['to']?.toString().toLowerCase() ==
                  '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8'
              ? 'PYUSD Transaction'
              : 'Other Transaction',
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Hash:',
                  FormatterUtils.formatHash(transaction['hash'] ?? '')),
              _buildDetailRow('From:',
                  FormatterUtils.formatAddress(transaction['from'] ?? '')),
              _buildDetailRow(
                  'To:', FormatterUtils.formatAddress(transaction['to'] ?? '')),
              _buildDetailRow(
                  'Gas Price:', '${gasPriceGwei.toStringAsFixed(2)} Gwei'),
              if (transaction['tokenValue'] != null)
                _buildDetailRow(
                    'Amount:', '${transaction['tokenValue']} PYUSD'),
              _buildDetailRow('Status:',
                  transaction['status'] == '0x1' ? 'Confirmed' : 'Pending'),
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockDetails(Map<String, dynamic> block) {
    final blockNumber = FormatterUtils.parseHexSafely(block['number']);
    final timestamp = FormatterUtils.parseHexSafely(block['timestamp']);
    final gasUsed = FormatterUtils.parseHexSafely(block['gasUsed']);
    final gasLimit = FormatterUtils.parseHexSafely(block['gasLimit']);
    final txCount = (block['transactions'] as List?)?.length ?? 0;
    final miner = block['miner']?.toString() ?? 'Unknown';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block #$blockNumber'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                  'Timestamp:',
                  DateTime.fromMillisecondsSinceEpoch(timestamp! * 1000)
                      .toString()),
              _buildDetailRow('Transactions:', txCount.toString()),
              _buildDetailRow('Gas Used:', '${gasUsed! / 1e6}M'),
              _buildDetailRow('Gas Limit:', '${gasLimit! / 1e6}M'),
              _buildDetailRow('Utilization:',
                  '${((gasUsed / gasLimit) * 100).toStringAsFixed(1)}%'),
              _buildDetailRow('Miner:', FormatterUtils.formatAddress(miner)),
            ],
          ),
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

// Custom painter for road markings
class RoadMarkingsPainter extends CustomPainter {
  final double animationValue;
  final int congestionLevel;

  RoadMarkingsPainter({
    required this.animationValue,
    required this.congestionLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw center dashed line
    _drawDashedLine(
      canvas,
      size,
      paint,
      size.height / 2,
      animationValue,
      dashWidth: 20.0,
      dashSpace: 20.0,
    );

    // Draw side lines with different styles based on congestion
    if (congestionLevel > 30) {
      // Draw left lane marker
      _drawDashedLine(
        canvas,
        size,
        paint,
        size.height / 4,
        animationValue,
        dashWidth: 10.0,
        dashSpace: 15.0,
      );

      // Draw right lane marker
      _drawDashedLine(
        canvas,
        size,
        paint,
        size.height * 3 / 4,
        animationValue,
        dashWidth: 10.0,
        dashSpace: 15.0,
      );
    }

    // Add additional markings for high congestion
    if (congestionLevel > 70) {
      final additionalPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      // Draw additional lane markers
      _drawDashedLine(
        canvas,
        size,
        additionalPaint,
        size.height / 6,
        animationValue,
        dashWidth: 5.0,
        dashSpace: 10.0,
      );

      _drawDashedLine(
        canvas,
        size,
        additionalPaint,
        size.height * 5 / 6,
        animationValue,
        dashWidth: 5.0,
        dashSpace: 10.0,
      );
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Size size,
    Paint paint,
    double y,
    double animationValue, {
    required double dashWidth,
    required double dashSpace,
  }) {
    final dashCount = (size.width / (dashWidth + dashSpace)).ceil();
    final startX = -(animationValue * (dashWidth + dashSpace));

    for (int i = 0; i < dashCount + 1; i++) {
      final x = startX + i * (dashWidth + dashSpace);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + dashWidth, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RoadMarkingsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.congestionLevel != congestionLevel;
  }
}

// Custom painter for stars in night mode
class StarsPainter extends CustomPainter {
  final double density;
  final Random _random = Random(42); // Fixed seed for consistent star pattern

  StarsPainter({required this.density});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final starCount = (size.width * size.height * density).round();

    for (int i = 0; i < starCount; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      final radius = 1.0 + _random.nextDouble();

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarsPainter oldDelegate) {
    return false; // Stars don't change
  }
}

// Custom painter for rain effect
class RainPainter extends CustomPainter {
  final double density;
  final double animationValue;
  final Random _random = Random();

  RainPainter({
    required this.density,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dropCount = (size.width * density).round();
    const dropLength = 20.0;

    for (int i = 0; i < dropCount; i++) {
      final x = _random.nextDouble() * size.width;
      final startY = (animationValue + _random.nextDouble()) * size.height;
      final endY = startY + dropLength;

      if (startY < size.height) {
        canvas.drawLine(
          Offset(x, startY),
          Offset(x, min(endY, size.height)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant RainPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
