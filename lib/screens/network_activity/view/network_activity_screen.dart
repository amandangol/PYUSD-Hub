import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../network_congestion/provider/network_congestion_provider.dart';
import 'dart:math' as math;
import 'dart:async';

class NetworkActivityScreen extends StatefulWidget {
  const NetworkActivityScreen({super.key});

  @override
  State<NetworkActivityScreen> createState() => _NetworkActivityScreenState();
}

class _NetworkActivityScreenState extends State<NetworkActivityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _updateTimer;
  double _skyOffset = 0;
  List<Building> _buildings = [];
  List<Car> _cars = [];
  List<Transaction> _transactions = [];
  List<Cloud> _clouds = [];
  final _random = math.Random();

  // Gamification elements
  int _score = 0;
  int _pyusdTransactionsCompleted = 0;
  String _currentLevel = "Normal";
  String _statusMessage = "Network running smoothly";
  bool _showTutorial = true;

  // City configuration
  final int _buildingCount = 15;
  final double _cityHeight = 600;
  final double _baseHeight = 120;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize buildings
    _initializeBuildings();
    _initializeClouds();

    // Update animation every 50ms
    _updateTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _skyOffset = (_skyOffset + 0.2) % 100;
        _updateCity();
      });
    });

    // Show the tutorial after a brief delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _showCityTutorial();
      }
    });
  }

  void _showCityTutorial() {
    if (!_showTutorial) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 10),
            Text('Welcome to PYUSD Transaction City'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTutorialItem('Buildings',
                  'Show network activity. Green buildings are PYUSD nodes.'),
              _buildTutorialItem(
                  'Lights', 'Windows light up based on transaction activity.'),
              _buildTutorialItem('Cars',
                  'Represent pending transactions. Green cars are PYUSD transactions.'),
              _buildTutorialItem('Particles',
                  'Glowing dots represent confirmed transactions.'),
              _buildTutorialItem('Sky Color',
                  'Changes with network congestion (blue = low, red = high).'),
              _buildTutorialItem(
                  'Congestion Meter', 'Shows current network load.'),
              _buildTutorialItem(
                  'Score', 'Increases as PYUSD transactions complete.'),
              Divider(),
              Text(
                  'Play with the network by refreshing the data or watching transactions complete!',
                  style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text("Don't show again"),
            onPressed: () {
              setState(() => _showTutorial = false);
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text('Got it!'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(description),
          ),
        ],
      ),
    );
  }

  void _initializeBuildings() {
    _buildings.clear();
    for (int i = 0; i < _buildingCount; i++) {
      // Make about 30% of buildings PYUSD buildings
      final buildingType = _random.nextDouble() < 0.3
          ? BuildingType.pyusd
          : BuildingType
              .values[_random.nextInt(BuildingType.values.length - 1)];

      _buildings.add(Building(
        position: i * 80.0,
        width: 60 + _random.nextDouble() * 20,
        height: 100 + _random.nextDouble() * 200,
        type: buildingType,
        windows: 4 + _random.nextInt(12),
        lightProbability: _random.nextDouble() * 0.7,
      ));
    }
  }

  void _initializeClouds() {
    _clouds.clear();
    for (int i = 0; i < 5; i++) {
      _clouds.add(Cloud(
        position:
            Offset(_random.nextDouble() * 800, 50 + _random.nextDouble() * 100),
        size: 50 + _random.nextDouble() * 100,
        speed: 0.2 + _random.nextDouble() * 0.5,
      ));
    }
  }

  void _updateCity() {
    final provider =
        Provider.of<NetworkCongestionProvider>(context, listen: false);
    final congestionData = provider.congestionData;

    // Update level and status message based on congestion
    _updateNetworkStatus(congestionData.gasUsagePercentage);

    // Update buildings based on gas usage
    for (var building in _buildings) {
      building.activityLevel =
          (congestionData.gasUsagePercentage / 100) * 0.8 + 0.2;

      // Randomly toggle some windows
      if (_random.nextDouble() < 0.05) {
        building.toggleRandomWindow();
      }
    }

    // Update cars based on pending transactions
    final targetCarCount =
        (congestionData.pendingTransactions / 200).clamp(3, 25).toInt();

    while (_cars.length < targetCarCount) {
      _cars.add(Car(
        position: Offset(
            -50,
            400 +
                _random.nextDouble() * 40), // Fixed y-position to stay on road
        speed: 1 + _random.nextDouble() * 3,
        size: 20 + _random.nextDouble() * 15,
        isPyusd: _random.nextDouble() <
            congestionData.confirmedPyusdTxCount /
                (congestionData.pendingTransactions + 1),
      ));
    }

    while (_cars.length > targetCarCount) {
      _cars.removeLast();
    }

    // Move cars
    for (var i = _cars.length - 1; i >= 0; i--) {
      var car = _cars[i];
      car.position = Offset(car.position.dx + car.speed, car.position.dy);

      // Remove cars that have moved off screen and add new ones
      if (car.position.dx > MediaQuery.of(context).size.width) {
        _cars.removeAt(i);
        _cars.add(Car(
          position:
              Offset(-50, 400 + _random.nextDouble() * 40), // Fixed y-position
          speed: 1 + _random.nextDouble() * 3,
          size: 20 + _random.nextDouble() * 15,
          isPyusd: _random.nextDouble() <
              congestionData.confirmedPyusdTxCount /
                  (congestionData.pendingTransactions + 1),
        ));
      }
    }

    // Update transaction particles
    final targetTxCount =
        (congestionData.confirmedPyusdTxCount / 100).clamp(0, 30).toInt();

    while (_transactions.length < targetTxCount) {
      final isPyusd = _random.nextDouble() < 0.7; // 70% PYUSD transactions
      _transactions.add(Transaction(
        position: Offset(
            _random.nextDouble() * 800, 200 + _random.nextDouble() * 300),
        targetBuilding: _buildings[_random.nextInt(_buildings.length)],
        size: 5 + _random.nextDouble() * 10,
        speed: 1 + _random.nextDouble() * 2,
        isPyusd: isPyusd,
      ));
    }

    while (_transactions.length > targetTxCount) {
      _transactions.removeLast();
    }

    // Move transactions
    for (var i = _transactions.length - 1; i >= 0; i--) {
      var tx = _transactions[i];
      // Calculate direction vector to target
      final targetPos = Offset(
          tx.targetBuilding.position + tx.targetBuilding.width / 2,
          _cityHeight - tx.targetBuilding.height / 2);

      final direction = (targetPos - tx.position);
      final normalizedDirection = direction / direction.distance;
      tx.position = tx.position + normalizedDirection * tx.speed * 2;

      // Remove transactions that have reached their target
      if ((targetPos - tx.position).distance < 10) {
        // Update score and counter if it's a PYUSD transaction
        if (tx.isPyusd) {
          _score += 10;
          _pyusdTransactionsCompleted++;

          // Show floating score indicator
          _showFloatingScore(targetPos);
        }

        _transactions.removeAt(i);

        // Add a new transaction
        final isPyusd = _random.nextDouble() < 0.7;
        _transactions.add(Transaction(
          position: Offset(
              _random.nextDouble() * 800, 200 + _random.nextDouble() * 300),
          targetBuilding: _buildings[_random.nextInt(_buildings.length)],
          size: 5 + _random.nextDouble() * 10,
          speed: 1 + _random.nextDouble() * 2,
          isPyusd: isPyusd,
        ));
      }
    }

    // Move clouds
    for (var cloud in _clouds) {
      cloud.position =
          Offset(cloud.position.dx - cloud.speed, cloud.position.dy);

      // Reset cloud position when it moves off screen
      if (cloud.position.dx < -cloud.size) {
        cloud.position =
            Offset(800 + cloud.size, 50 + _random.nextDouble() * 100);
        cloud.size = 50 + _random.nextDouble() * 100;
        cloud.speed = 0.2 + _random.nextDouble() * 0.5;
      }
    }
  }

  void _updateNetworkStatus(double gasUsage) {
    // Update level based on gas usage
    if (gasUsage < 30) {
      _currentLevel = "Low Traffic";
      _statusMessage = "Network running smoothly";
    } else if (gasUsage < 60) {
      _currentLevel = "Moderate Traffic";
      _statusMessage = "Normal network conditions";
    } else if (gasUsage < 80) {
      _currentLevel = "High Traffic";
      _statusMessage = "Network congestion increasing";
    } else {
      _currentLevel = "Peak Traffic";
      _statusMessage = "High network congestion!";
    }
  }

  // Show floating score when transactions complete
  final List<ScoreIndicator> _scoreIndicators = [];

  void _showFloatingScore(Offset position) {
    _scoreIndicators.add(ScoreIndicator(
      position: position,
      value: "+10",
      color: Colors.green,
      createdAt: DateTime.now(),
    ));

    // Remove old indicators after a delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _scoreIndicators.removeWhere((indicator) =>
              DateTime.now().difference(indicator.createdAt).inMilliseconds >
              1400);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _updateTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.currency_exchange, color: Colors.green),
            SizedBox(width: 8),
            Text('PYUSD Transaction City'),
          ],
        ),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          // Help button
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: "Show Tutorial",
            onPressed: _showCityTutorial,
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Network Data",
            onPressed: () {
              Provider.of<NetworkCongestionProvider>(context, listen: false)
                  .refresh();
            },
          ),
        ],
      ),
      body: Consumer<NetworkCongestionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading PYUSD Network Data...'),
                ]));
          }

          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: SizedBox(
              width: screenSize.width,
              height: screenSize.height,
              child: Stack(
                children: [
                  // Full screen city visualization
                  _buildPyusdCity(context, provider),

                  // Stats overlay
                  _buildStatsOverlay(context, provider),

                  // Game overlay (score, level, etc.)
                  _buildGameOverlay(context, provider),

                  // Legend overlay showing what elements mean
                  _buildLegendOverlay(context),

                  // Floating score indicators
                  ..._scoreIndicators
                      .map((indicator) => _buildScoreIndicator(indicator)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPyusdCity(
      BuildContext context, NetworkCongestionProvider provider) {
    final congestionData = provider.congestionData;
    final screenSize = MediaQuery.of(context).size;

    return Container(
      color: Colors.black,
      width: screenSize.width,
      height: screenSize.height,
      child: Stack(
        children: [
          // Sky background with gradient
          _buildSkyBackground(congestionData.gasUsagePercentage),

          // Clouds
          ..._clouds.map((cloud) => _buildCloud(cloud)),

          // Stars
          _buildStars(),

          // City skyline
          _buildCitySkyline(screenSize),

          // Roads
          _buildRoads(screenSize),

          // Cars
          ..._cars.map((car) => _buildCar(car)),

          // Transaction particles
          ..._transactions.map((tx) => _buildTransaction(tx)),

          // Network congestion indicator
          _buildCongestionIndicator(congestionData.gasUsagePercentage),

          // Status message banner
          _buildStatusBanner(),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    Color bannerColor;

    // Determine banner color based on current level
    switch (_currentLevel) {
      case "Low Traffic":
        bannerColor = Colors.green.withOpacity(0.7);
        break;
      case "Moderate Traffic":
        bannerColor = Colors.blue.withOpacity(0.7);
        break;
      case "High Traffic":
        bannerColor = Colors.orange.withOpacity(0.7);
        break;
      case "Peak Traffic":
        bannerColor = Colors.red.withOpacity(0.7);
        break;
      default:
        bannerColor = Colors.blue.withOpacity(0.7);
    }

    return Positioned(
      bottom: _baseHeight + 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: bannerColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            _statusMessage,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkyBackground(double gasUsage) {
    // Sky color changes with gas usage - higher gas = more orange/red
    final topColor = Color.lerp(
      const Color(0xFF0B1026), // Dark blue for low gas
      const Color(0xFF331111), // Dark red for high gas
      gasUsage / 100,
    )!;

    final bottomColor = Color.lerp(
      const Color(0xFF2C3E50), // Navy blue for low gas
      const Color(0xFF662211), // Reddish for high gas
      gasUsage / 100,
    )!;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, bottomColor],
        ),
      ),
      child: CustomPaint(
        painter: StarFieldPainter(
          starCount: 100,
          offset: _skyOffset,
        ),
      ),
    );
  }

  Widget _buildStars() {
    return const SizedBox(); // Stars are drawn in the StarFieldPainter
  }

  Widget _buildCloud(Cloud cloud) {
    return Positioned(
      left: cloud.position.dx,
      top: cloud.position.dy,
      child: Opacity(
        opacity: 0.3,
        child: Container(
          width: cloud.size,
          height: cloud.size * 0.6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(cloud.size / 2),
          ),
        ),
      ),
    );
  }

  Widget _buildCitySkyline(Size screenSize) {
    return Positioned(
      bottom: _baseHeight,
      left: 0,
      right: 0,
      height: _cityHeight - _baseHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children:
              _buildings.map((building) => _buildBuilding(building)).toList(),
        ),
      ),
    );
  }

  Widget _buildBuilding(Building building) {
    // Color based on building type and activity level
    Color buildingColor;
    IconData? buildingIcon;

    switch (building.type) {
      case BuildingType.financial:
        buildingColor = Color.lerp(
          const Color(0xFF1A5276), // Dark blue
          const Color(0xFF2E86C1), // Bright blue
          building.activityLevel,
        )!;
        buildingIcon = Icons.account_balance;
        break;
      case BuildingType.residential:
        buildingColor = Color.lerp(
          const Color(0xFF283747), // Dark gray
          const Color(0xFF5D6D7E), // Light gray
          building.activityLevel,
        )!;
        buildingIcon = Icons.home;
        break;
      case BuildingType.commercial:
        buildingColor = Color.lerp(
          const Color(0xFF7D6608), // Dark gold
          const Color(0xFFF1C40F), // Bright gold
          building.activityLevel,
        )!;
        buildingIcon = Icons.shopping_bag;
        break;
      case BuildingType.pyusd:
        buildingColor = Color.lerp(
          const Color(0xFF145A32), // Dark green
          const Color(0xFF27AE60), // Bright green
          building.activityLevel,
        )!;
        buildingIcon = Icons.currency_exchange;
        break;
    }

    return Container(
      width: building.width,
      height: building.height,
      decoration: BoxDecoration(
        color: buildingColor,
        border: Border.all(color: Colors.black26, width: 1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Stack(
        children: [
          // Building windows
          ...List.generate(building.windows, (i) {
            final row = i ~/ 4;
            final col = i % 4;

            final isLit = building.windowsLit[i];
            final windowColor = isLit
                ? Colors.yellow.withOpacity(0.8)
                : Colors.white.withOpacity(0.1);

            return Positioned(
              left: col * (building.width / 4) + 5,
              top: building.height - (row + 1) * 25,
              child: Container(
                width: (building.width / 4) - 10,
                height: 15,
                decoration: BoxDecoration(
                  color: windowColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),

          // Building type indicator at the top
          Positioned(
            top: 5,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: buildingColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white30,
                    width: 1,
                  ),
                ),
                child: Icon(
                  buildingIcon,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),

          // PYUSD Label for PYUSD buildings
          if (building.type == BuildingType.pyusd)
            Positioned(
              top: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PYUSD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoads(Size screenSize) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: _baseHeight,
      child: Column(
        children: [
          // Main highway
          Container(
            height: 70,
            width: screenSize.width,
            color: const Color(0xFF1C2833),
            child: Stack(
              children: [
                // Road markings
                ...List.generate(
                  (screenSize.width / 50).ceil(),
                  (i) => Positioned(
                    left: i * 50.0,
                    top: 35,
                    child: Container(
                      width: 30,
                      height: 5,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),

                // Road label
                Positioned(
                  right: 20,
                  top: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'TRANSACTION HIGHWAY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sidewalk
          Container(
            height: 50,
            width: screenSize.width,
            color: const Color(0xFF212F3D),
            child: Stack(
              children: [
                // Sidewalk pattern
                ...List.generate(
                  (screenSize.width / 25).ceil(),
                  (i) => Positioned(
                    left: i * 25.0,
                    top: 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCar(Car car) {
    final carWidth = car.size;
    final carHeight = car.size * 0.5;

    return Positioned(
      left: car.position.dx,
      top: car.position.dy,
      child: Stack(
        children: [
          // Car body
          Container(
            width: carWidth,
            height: carHeight,
            decoration: BoxDecoration(
              color: car.isPyusd ? Colors.green : Colors.blue,
              borderRadius: BorderRadius.circular(car.size / 4),
              boxShadow: [
                BoxShadow(
                  color: car.isPyusd
                      ? Colors.green.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Car windshield
                Positioned(
                  left: carWidth * 0.6,
                  top: carHeight * 0.2,
                  child: Container(
                    width: carWidth * 0.3,
                    height: carHeight * 0.4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Car headlights
                Positioned(
                  right: 2,
                  top: carHeight * 0.3,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // PYUSD indicator if applicable
                if (car.isPyusd)
                  Positioned(
                    left: carWidth * 0.2,
                    top: carHeight * 0.2,
                    child: Container(
                      width: carWidth * 0.2,
                      height: carHeight * 0.6,
                      decoration: BoxDecoration(
                        color: Colors.green.shade800,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Text(
                          '\$',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: car.size / 5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Label to show what type of transaction
          Positioned(
            top: -15,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: car.isPyusd
                      ? Colors.green.shade900
                      : Colors.blue.shade900,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  car.isPyusd ? 'PYUSD TX' : 'ETH TX',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransaction(Transaction tx) {
    final color = tx.isPyusd ? Colors.green : Colors.blue;

    return Positioned(
      left: tx.position.dx,
      top: tx.position.dy,
      child: Container(
        width: tx.size,
        height: tx.size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: tx.size * 2,
              spreadRadius: tx.size / 2,
            ),
          ],
        ),
        child: tx.size > 8
            ? Center(
                child: Text(
                  tx.isPyusd ? '\$' : 'E',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: tx.size / 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildScoreIndicator(ScoreIndicator indicator) {
    // Calculate animation progress (0.0 to 1.0)
    final progress =
        DateTime.now().difference(indicator.createdAt).inMilliseconds / 1500;
    final opacity = 1.0 - progress;
    final offsetY = -20.0 * progress; // Move upward as it fades

    return Positioned(
      left: indicator.position.dx,
      top: indicator.position.dy + offsetY,
      child: Opacity(
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: indicator.color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: indicator.color.withOpacity(0.3),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            indicator.value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCongestionIndicator(double gasUsage) {
    final color = _getColorForGasUsage(gasUsage);
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              'NETWORK CONGESTION',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 100,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: gasUsage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${gasUsage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 2,
                          ),
                        ],
                      ),
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

  Color _getColorForGasUsage(double gasUsage) {
    if (gasUsage < 30) {
      return Colors.green;
    } else if (gasUsage < 60) {
      return Colors.yellow;
    } else if (gasUsage < 80) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildStatsOverlay(
      BuildContext context, NetworkCongestionProvider provider) {
    final congestionData = provider.congestionData;
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NETWORK STATS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            _buildStatRow(
                'Gas Price:', '${congestionData.currentGasPrice} Gwei'),
            _buildStatRow(
                'Pending Txns:', congestionData.pendingTransactions.toString()),
            _buildStatRow('Block Time:',
                '${congestionData.blockTime.toStringAsFixed(1)}s'),
            _buildStatRow(
                'PYUSD Txns:', congestionData.confirmedPyusdTxCount.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverlay(
      BuildContext context, NetworkCongestionProvider provider) {
    return Positioned(
      top: 16,
      left: 130, // Position next to stats panel
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.videogame_asset, color: Colors.green, size: 14),
                SizedBox(width: 5),
                Text(
                  'GAME STATS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            _buildStatRow('Score:', _score.toString()),
            _buildStatRow('Level:', _currentLevel),
            _buildStatRow(
                'PYUSD Completed:', _pyusdTransactionsCompleted.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendOverlay(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LEGEND',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            _buildLegendItem(Colors.green, 'PYUSD Transactions'),
            _buildLegendItem(Colors.blue, 'ETH Transactions'),
            _buildLegendItem(Colors.green.shade800, 'PYUSD Nodes'),
            _buildLegendItem(Colors.blue.shade800, 'Financial Nodes'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class Building {
  final double position;
  final double width;
  final double height;
  final BuildingType type;
  final int windows;
  List<bool> windowsLit = [];
  double activityLevel = 0.5;
  double lightProbability;

  Building({
    required this.position,
    required this.width,
    required this.height,
    required this.type,
    required this.windows,
    required this.lightProbability,
  }) {
    // Initialize windows (some on, some off)
    windowsLit = List.generate(
      windows,
      (i) => Random().nextDouble() < lightProbability,
    );
  }

  void toggleRandomWindow() {
    if (windows > 0) {
      final windowIndex = Random().nextInt(windows);
      windowsLit[windowIndex] = !windowsLit[windowIndex];
    }
  }
}

enum BuildingType {
  financial,
  residential,
  commercial,
  pyusd,
}

class Car {
  Offset position;
  final double speed;
  final double size;
  final bool isPyusd;

  Car({
    required this.position,
    required this.speed,
    required this.size,
    required this.isPyusd,
  });
}

class Transaction {
  Offset position;
  final Building targetBuilding;
  final double size;
  final double speed;
  final bool isPyusd;

  Transaction({
    required this.position,
    required this.targetBuilding,
    required this.size,
    required this.speed,
    required this.isPyusd,
  });
}

class Cloud {
  Offset position;
  double size;
  double speed;

  Cloud({
    required this.position,
    required this.size,
    required this.speed,
  });
}

class ScoreIndicator {
  final Offset position;
  final String value;
  final Color color;
  final DateTime createdAt;

  ScoreIndicator({
    required this.position,
    required this.value,
    required this.color,
    required this.createdAt,
  });
}

class StarFieldPainter extends CustomPainter {
  final int starCount;
  final double offset;
  final Random _random = Random(42);

  StarFieldPainter({
    required this.starCount,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stars = List.generate(
      starCount,
      (i) => Star(
        x: _random.nextDouble() * size.width,
        y: _random.nextDouble() * size.height / 2, // Stars only in top half
        size: 1 + _random.nextDouble() * 2,
        brightness: 0.3 + _random.nextDouble() * 0.7,
      ),
    );

    for (var star in stars) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(
            star.brightness * (0.3 + sin(offset / 10 + star.x / 50) * 0.1))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(star.x, star.y),
        star.size / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StarFieldPainter oldDelegate) {
    return offset != oldDelegate.offset;
  }
}

class Star {
  final double x;
  final double y;
  final double size;
  final double brightness;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.brightness,
  });
}
