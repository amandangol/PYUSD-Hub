import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../pyusd_data_provider.dart';
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
  final PyusdDashboardProvider _pyusdProvider = PyusdDashboardProvider();
  double _skyOffset = 0;
  List<Building> _buildings = [];
  List<Car> _cars = [];
  List<Transaction> _transactions = [];
  List<Cloud> _clouds = [];
  final _random = math.Random();

  // Enhanced gamification elements
  int _score = 0;
  int _pyusdTransactionsCompleted = 0;
  String _currentLevel = "Normal";
  String _statusMessage = "Network running smoothly";
  bool _showTutorial = true;
  bool _showInfoPanel = false;
  bool _showTimeControls = false;
  double _simulationSpeed = 1.0;
  double _timeElapsed = 0; // Seconds

  // Education panels
  bool _showCongestionExplainer = false;

  // Transaction history
  List<TransactionEvent> _transactionHistory = [];

  // City configuration
  final int _buildingCount = 15;
  final double _cityHeight = 600;
  final double _baseHeight = 120;

  // Tutorial step tracking
  int _tutorialStep = 0;
  bool _tutorialActive = false;

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
        _skyOffset = (_skyOffset + 0.2 * _simulationSpeed) % 100;
        _updateCity();
        _timeElapsed += 0.05 * _simulationSpeed;
      });
    });

    // Load real transaction data
    _loadRealTransactionData();

    // Show the welcome splash after a brief delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _showWelcomeSplash();
      }
    });
  }

  Future<void> _loadRealTransactionData() async {
    try {
      await _pyusdProvider.initialize();

      // Get the current period data which includes mint and burn events
      final currentData = _pyusdProvider.currentPeriodData;
      final mintEvents = currentData['mintEvents'] as List<dynamic>;
      final burnEvents = currentData['burnEvents'] as List<dynamic>;

      setState(() {
        _transactionHistory = [
          ...mintEvents.map((tx) => TransactionEvent(
                type: 'PYUSD',
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                  int.parse(tx['timeStamp']) * 1000,
                ),
                destination: 'Mint',
                amount: (_pyusdProvider.formatAmount(BigInt.parse(tx['data']))),
                confirmationTime: '1',
                position: Offset(
                  _random.nextDouble() * 800,
                  200 + _random.nextDouble() * 300,
                ),
              )),
          ...burnEvents.map((tx) => TransactionEvent(
                type: 'PYUSD',
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                  int.parse(tx['timeStamp']) * 1000,
                ),
                destination: 'Burn',
                amount: (_pyusdProvider.formatAmount(BigInt.parse(tx['data']))),
                confirmationTime: '1',
                position: Offset(
                  _random.nextDouble() * 800,
                  200 + _random.nextDouble() * 300,
                ),
              )),
        ];
      });

      // Update network status based on real data
      _updateNetworkStatus(_pyusdProvider.pyusdNetFlowRate);
    } catch (e) {
      print('Error loading PYUSD transaction data: $e');
    }
  }

  void _showWelcomeSplash() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade800,
                Colors.blue.shade900,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 15,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.currency_exchange,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome to PYUSD City',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A live visualization of PYUSD transactions on the blockchain',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Explore how transactions move through the network, see congestion levels in real-time, and learn about blockchain mechanics.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.school),
                    label: Text('Start Tutorial'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green.shade800,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _startInteractiveTutorial();
                    },
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    child: Text('Explore on My Own'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white, width: 1),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startInteractiveTutorial() {
    setState(() {
      _tutorialActive = true;
      _tutorialStep = 0;
    });

    _showTutorialStep();
  }

  void _showTutorialStep() {
    if (!_tutorialActive) return;

    Widget tutorialContent;
    Offset targetPosition = Offset(0, 0);

    switch (_tutorialStep) {
      case 0:
        tutorialContent = _buildTutorialCard(
          'Welcome to PYUSD City!',
          'This visualization helps you understand blockchain transactions and network congestion. Let me guide you through the key elements.',
          Icons.currency_exchange,
          Colors.green.shade50,
          Colors.green.shade700,
        );
        targetPosition = Offset(MediaQuery.of(context).size.width / 2, 200);
        break;
      case 1:
        tutorialContent = _buildTutorialCard(
          'The Buildings',
          'The skyline represents nodes on the network. Green buildings are PYUSD nodes, while others represent different transaction types.',
          Icons.location_city,
          Colors.green.shade50,
          Colors.green.shade700,
        );
        targetPosition = Offset(MediaQuery.of(context).size.width / 3, 250);
        break;
      case 2:
        tutorialContent = _buildTutorialCard(
          'Transaction Highway',
          'Cars on the road represent pending transactions. Green cars are PYUSD transactions, blue cars are other Ethereum transactions.',
          Icons.directions_car,
          Colors.blue.shade50,
          Colors.blue.shade700,
        );
        targetPosition = Offset(MediaQuery.of(context).size.width / 2, 400);
        break;
      case 3:
        tutorialContent = _buildTutorialCard(
          'Network Congestion',
          'The sky color changes with network congestion - blue means low congestion, while red indicates heavy network traffic.',
          Icons.cloud,
          Colors.blue.shade50,
          Colors.blue.shade700,
        );
        targetPosition = Offset(MediaQuery.of(context).size.width / 2, 100);
        break;
      case 4:
        tutorialContent = _buildTutorialCard(
          'Transaction Speed',
          'Particles moving to buildings are confirmed transactions. Their speed depends on network congestion.',
          Icons.speed,
          Colors.purple.shade50,
          Colors.purple.shade700,
        );
        targetPosition = Offset(MediaQuery.of(context).size.width / 2, 300);
        break;
      case 5:
        tutorialContent = _buildTutorialCard(
          'Controls',
          'Use the controls in the toolbar to adjust simulation speed, view detailed statistics, or learn more about network congestion.',
          Icons.settings,
          Colors.orange.shade50,
          Colors.orange.shade700,
        );
        targetPosition = Offset(MediaQuery.of(context).size.width - 100, 60);
        break;
      case 6:
        tutorialContent = _buildTutorialCard(
          'You are Ready!',
          'Now you understand the basics of PYUSD City. Explore the visualization and learn how blockchain transactions work in real-time!',
          Icons.emoji_events,
          Colors.green.shade50,
          Colors.green.shade700,
        );
        targetPosition = Offset(MediaQuery.of(context).size.width / 2, 200);
        break;
      default:
        setState(() {
          _tutorialActive = false;
        });
        return;
    }

    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: targetPosition.dx - 150, // Center the tooltip
        top: targetPosition.dy,
        child: Material(
          color: Colors.transparent,
          child: tutorialContent,
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Auto-advance after delay or wait for user action
    if (_tutorialStep < 6) {
      Future.delayed(Duration(seconds: 6), () {
        if (_tutorialActive && mounted) {
          overlayEntry.remove();
          setState(() {
            _tutorialStep++;
          });
          _showTutorialStep();
        }
      });
    } else {
      // Final step - provide button to close
      Future.delayed(Duration(seconds: 5), () {
        if (mounted && _tutorialActive) {
          overlayEntry.remove();
          setState(() {
            _tutorialActive = false;
          });
        }
      });
    }
  }

  void _showCityTutorial() {
    if (!_showTutorial) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 800,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.location_city,
                          size: 28,
                          color: Colors.green.shade700,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guide to PYUSD City',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                            Text(
                              'Understanding the blockchain visualization',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey.shade600),
                        onPressed: () {
                          setState(() => _showTutorial = false);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Main Content - Responsive Layout
                  MediaQuery.of(context).size.width > 600
                      ? _buildTutorialGrid()
                      : _buildTutorialList(),

                  SizedBox(height: 24),

                  // Network Status Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Network Status Indicators',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            _buildStatusIndicator(
                                'Low Congestion', Colors.green),
                            _buildStatusIndicator(
                                'Medium Congestion', Colors.orange),
                            _buildStatusIndicator(
                                'High Congestion', Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Footer Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: Icon(Icons.check_circle_outline),
                        label: Text("Don't show again"),
                        onPressed: () {
                          setState(() => _showTutorial = false);
                          Navigator.of(context).pop();
                        },
                      ),
                      SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: Icon(Icons.check),
                        label: Text('Got it!'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// Responsive grid for larger screens
  Widget _buildTutorialGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      return GridView(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          mainAxisExtent: 150, // Fixed height for each item
        ),
        children: _buildTutorialItems(),
      );
    });
  }

// List layout for smaller screens
  Widget _buildTutorialList() {
    return Column(
      children: _buildTutorialItems().map((widget) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: widget,
        );
      }).toList(),
    );
  }

// Common items for both layouts
  List<Widget> _buildTutorialItems() {
    return [
      _buildTutorialCard(
        'Buildings',
        'Green buildings represent PYUSD nodes, while other colors indicate different network participants. The height and activity of buildings reflect network importance.',
        Icons.location_city,
        Colors.green.shade50,
        Colors.green.shade700,
      ),
      _buildTutorialCard(
        'Transaction Highway',
        'Cars on the road symbolize pending transactions. Green cars are PYUSD transactions, while blue cars represent other Ethereum transactions.',
        Icons.directions_car,
        Colors.blue.shade50,
        Colors.blue.shade700,
      ),
      _buildTutorialCard(
        'Building Activity',
        'Windows light up based on transaction activity. More lit windows indicate higher network participation and transaction processing.',
        Icons.light,
        Colors.orange.shade50,
        Colors.orange.shade700,
      ),
      _buildTutorialCard(
        'Transaction Particles',
        'Moving particles show confirmed transactions reaching their destinations. Their speed and density reflect network congestion levels.',
        Icons.blur_on,
        Colors.purple.shade50,
        Colors.purple.shade700,
      ),
    ];
  }

  Widget _buildTutorialCard(
    String title,
    String description,
    IconData icon,
    Color backgroundColor,
    Color iconColor,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Flexible(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.3,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
      ],
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

    // Update level and status message based on real congestion data
    _updateNetworkStatus(congestionData.gasUsagePercentage);

    // Update buildings based on real gas usage
    for (var building in _buildings) {
      building.activityLevel =
          (congestionData.gasUsagePercentage / 100) * 0.8 + 0.2;

      // Randomly toggle some windows based on real transaction activity
      if (_random.nextDouble() < 0.05 * _simulationSpeed) {
        building.toggleRandomWindow();
      }
    }

    // Update cars based on real pending transactions
    final targetCarCount =
        (congestionData.pendingTransactions / 200).clamp(3, 25).toInt();

    while (_cars.length < targetCarCount) {
      _cars.add(Car(
        position: Offset(-50, 400 + _random.nextDouble() * 40),
        speed: (1 + _random.nextDouble() * 3) * _simulationSpeed,
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
          position: Offset(-50, 400 + _random.nextDouble() * 40),
          speed: (1 + _random.nextDouble() * 3) * _simulationSpeed,
          size: 20 + _random.nextDouble() * 15,
          isPyusd: _random.nextDouble() <
              congestionData.confirmedPyusdTxCount /
                  (congestionData.pendingTransactions + 1),
        ));
      }
    }

    // Update transaction particles based on real transaction count
    final targetTxCount =
        (congestionData.confirmedPyusdTxCount / 100).clamp(0, 30).toInt();

    while (_transactions.length < targetTxCount) {
      _transactions.add(Transaction(
        position: Offset(
          _random.nextDouble() * 800,
          200 + _random.nextDouble() * 300,
        ),
        targetBuilding: _buildings[_random.nextInt(_buildings.length)],
        size: 5 + _random.nextDouble() * 10,
        speed: (1 + _random.nextDouble() * 2) * _simulationSpeed,
        isPyusd: true, // All transactions are PYUSD now
      ));
    }

    while (_transactions.length > targetTxCount) {
      _transactions.removeLast();
    }

    // Move transactions
    for (var i = _transactions.length - 1; i >= 0; i--) {
      var tx = _transactions[i];
      final targetPos = Offset(
        tx.targetBuilding.position + tx.targetBuilding.width / 2,
        _cityHeight - tx.targetBuilding.height / 2,
      );

      final direction = (targetPos - tx.position);
      final normalizedDirection = direction / direction.distance;
      tx.position = tx.position + normalizedDirection * tx.speed * 2;

      // Remove transactions that have reached their target
      if ((targetPos - tx.position).distance < 10) {
        _score += 10;
        _pyusdTransactionsCompleted++;

        // Add to transaction history with real data
        _addTransactionToHistory(tx, targetPos);

        // Show floating score indicator
        _showFloatingScore(targetPos);

        _transactions.removeAt(i);

        // Add a new transaction
        _transactions.add(Transaction(
          position: Offset(
            _random.nextDouble() * 800,
            200 + _random.nextDouble() * 300,
          ),
          targetBuilding: _buildings[_random.nextInt(_buildings.length)],
          size: 5 + _random.nextDouble() * 10,
          speed: (1 + _random.nextDouble() * 2) * _simulationSpeed,
          isPyusd: true,
        ));
      }
    }

    // Move clouds - affected by simulation speed
    for (var cloud in _clouds) {
      cloud.position = Offset(
          cloud.position.dx - cloud.speed * _simulationSpeed,
          cloud.position.dy);

      // Reset cloud position when it moves off screen
      if (cloud.position.dx < -cloud.size) {
        cloud.position =
            Offset(800 + cloud.size, 50 + _random.nextDouble() * 100);
        cloud.size = 50 + _random.nextDouble() * 100;
        cloud.speed = 0.2 + _random.nextDouble() * 0.5;
      }
    }

    // Prune transaction history to keep only recent ones
    if (_transactionHistory.length > 20) {
      _transactionHistory.removeRange(0, _transactionHistory.length - 20);
    }
  }

  void _addTransactionToHistory(Transaction tx, Offset targetPos) {
    final txType = tx.isPyusd ? "PYUSD" : "ETH";
    final buildingType = tx.targetBuilding.type.toString().split('.').last;

    // Use real PYUSD data for transaction amounts
    final amount = _pyusdProvider.formatAmount(BigInt.from(
            _random.nextInt(1000) *
                1000000) // Random amount between 0-1000 PYUSD
        );

    _transactionHistory.add(TransactionEvent(
      type: txType,
      timestamp: DateTime.now(),
      destination: buildingType,
      amount: amount,
      confirmationTime: '1',
      position: targetPos,
    ));
  }

  void _updateNetworkStatus(double netFlowRate) {
    // Update level based on PYUSD net flow rate
    if (netFlowRate > 1000) {
      _currentLevel = "High Activity";
      _statusMessage = "Strong PYUSD growth";
    } else if (netFlowRate > 0) {
      _currentLevel = "Moderate Activity";
      _statusMessage = "Normal PYUSD activity";
    } else if (netFlowRate > -1000) {
      _currentLevel = "Low Activity";
      _statusMessage = "Reduced PYUSD activity";
    } else {
      _currentLevel = "Negative Growth";
      _statusMessage = "PYUSD supply decreasing";
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

  void _showCongestionExplainerPanel() {
    setState(() {
      _showCongestionExplainer = true;
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 600,
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      size: 24,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Understanding Network Congestion',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'How blockchain transaction processing works',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _buildExplainerSection(
                'What is Network Congestion?',
                'Network congestion occurs when there are more pending transactions than the blockchain can process immediately. Like traffic congestion on a highway, transactions must wait their turn.',
              ),
              _buildExplainerSection(
                'Gas Fees and Congestion',
                'When congestion increases, gas fees (transaction costs) rise as users compete to have their transactions processed sooner. This creates a fee market where higher fees get processed faster.',
              ),
              _buildExplainerSection(
                'Impact on PYUSD Transactions',
                'PYUSD transactions are affected by overall network congestion just like other transactions. During high congestion periods, PYUSD transfers may take longer or cost more in gas fees.',
              ),
              _buildExplainerSection(
                'Visual Indicators in PYUSD City',
                'In our visualization, congestion is represented by:\n• Sky color (blue to red)\n• Number of cars on the highway\n• Speed of transactions\n• Congestion meter in the top corner',
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Got it!'),
                    onPressed: () {
                      setState(() {
                        _showCongestionExplainer = false;
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplainerSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleInfoPanel() {
    setState(() {
      _showInfoPanel = !_showInfoPanel;
    });
  }

  void _toggleTimeControls() {
    setState(() {
      _showTimeControls = !_showTimeControls;
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final surfaceColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor =
        isDarkMode ? const Color(0xFFB3B3B3) : const Color(0xFF757575);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.green[900] : Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.currency_exchange,
                size: 20, // Reduced icon size for better spacing
                color: isDarkMode ? Colors.green[300] : Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PYUSD Transaction City',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // Slightly reduced
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis, // Prevents overflow
                  ),
                  Text(
                    'Live Network Visualization',
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        elevation: isDarkMode ? 0 : 1,
        actions: [
          // Simulation time indicator (Keep it compact)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: secondaryTextColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Elapsed: ${((_timeElapsed ?? 0) / 60).floor()}:${((_timeElapsed ?? 0) % 60).floor().toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 12, color: secondaryTextColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Essential Buttons
          IconButton(
            icon: const Icon(Icons.speed),
            tooltip: 'Time Controls',
            onPressed: _toggleTimeControls,
          ),

          // Grouping Less-Used Buttons into a Popup Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String value) {
              switch (value) {
                case 'stats':
                  _toggleInfoPanel();
                  break;
                case 'help':
                  _showCityTutorial();
                  break;
                case 'learn':
                  _showCongestionExplainerPanel();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'stats',
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('Statistics'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'help',
                child: ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('Help'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'learn',
                child: ListTile(
                  leading: Icon(Icons.school),
                  title: Text('Learn About Network Congestion'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main visualization canvas
          CustomPaint(
            size: Size(screenSize.width, screenSize.height),
            painter: CityPainter(
              skyOffset: _skyOffset,
              buildings: _buildings,
              cars: _cars,
              transactions: _transactions,
              clouds: _clouds,
              gasUsage: Provider.of<NetworkCongestionProvider>(context)
                  .congestionData
                  .gasUsagePercentage,
              baseHeight: _baseHeight,
              cityHeight: _cityHeight,
              isDarkMode: isDarkMode,
            ),
          ),

          // Floating score indicators
          ..._scoreIndicators.map((indicator) => Positioned(
                left: indicator.position.dx,
                top: indicator.position.dy,
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 1200),
                  opacity: DateTime.now()
                              .difference(indicator.createdAt)
                              .inMilliseconds <
                          1000
                      ? 1.0
                      : 0.0,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 1200),
                    transform: Matrix4.translationValues(
                      0,
                      -30 *
                          DateTime.now()
                              .difference(indicator.createdAt)
                              .inMilliseconds /
                          1000,
                      0,
                    ),
                    child: Text(
                      indicator.value,
                      style: TextStyle(
                        color: indicator.color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )),

          // Network status widget in top-left corner
          Positioned(
            top: 20,
            left: 20,
            child: _buildNetworkStatusWidget(),
          ),

          // Score widget in top-right corner
          Positioned(
            top: 20,
            right: 20,
            child: _buildScoreWidget(),
          ),

          // Info panel (shown when toggled)
          if (_showInfoPanel) _buildInfoPanel(),

          // Time controls panel (shown when toggled)
          if (_showTimeControls) _buildTimeControlsPanel(),

          // Recent transactions panel (always visible)
          Positioned(
            bottom: 20,
            left: 20,
            child: _buildRecentTransactionsPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkStatusWidget() {
    final provider = Provider.of<NetworkCongestionProvider>(context);
    final gasUsage = provider.congestionData.gasUsagePercentage;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor =
        isDarkMode ? const Color(0xFFB3B3B3) : const Color(0xFF757575);

    // Determine color based on PYUSD activity
    Color statusColor;
    if (_pyusdProvider.pyusdNetFlowRate > 0) {
      statusColor = Colors.green;
    } else if (_pyusdProvider.pyusdNetFlowRate > -1000) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Container(
      width: 220,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black26 : Colors.black12,
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.currency_exchange,
                  size: 16,
                  color: statusColor,
                ),
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PYUSD Network Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  Text(
                    _currentLevel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_pyusdProvider.pyusdNetFlowRate.abs() / 5000)
                  .clamp(0.0, 1.0),
              backgroundColor:
                  isDarkMode ? Colors.grey[700] : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_pyusdProvider.formatRate(_pyusdProvider.pyusdNetFlowRate)} PYUSD/hr',
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              ),
              Text(
                '${_pyusdProvider.formatPyusdSupply()} Total',
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreWidget() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor =
        isDarkMode ? const Color(0xFFB3B3B3) : const Color(0xFF757575);

    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black26 : Colors.black12,
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.green[900] : Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.currency_exchange,
                  size: 16,
                  color: isDarkMode ? Colors.green[300] : Colors.green.shade700,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'PYUSD Activity',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mint Rate',
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                  Text(
                    '${_pyusdProvider.formatRate(_pyusdProvider.pyusdMintRate)}/hr',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? Colors.green[300]
                          : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Burn Rate',
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                  Text(
                    '${_pyusdProvider.formatRate(_pyusdProvider.pyusdBurnRate)}/hr',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    final provider = Provider.of<NetworkCongestionProvider>(context);
    final congestionData = provider.congestionData;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor =
        isDarkMode ? const Color(0xFFB3B3B3) : const Color(0xFF757575);

    return Positioned(
      right: 20,
      top: 100,
      child: Container(
        width: 300,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black26 : Colors.black26,
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PYUSD Statistics',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textColor),
                  onPressed: _toggleInfoPanel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 20,
                ),
              ],
            ),
            Divider(color: isDarkMode ? Colors.grey[700] : Colors.grey[300]),
            SizedBox(height: 8),
            _buildStatRow('Total Supply',
                '${_pyusdProvider.formatPyusdSupply()} PYUSD', isDarkMode),
            _buildStatRow(
                'Mint Rate',
                '${_pyusdProvider.formatRate(_pyusdProvider.pyusdMintRate)}/hr',
                isDarkMode),
            _buildStatRow(
                'Burn Rate',
                '${_pyusdProvider.formatRate(_pyusdProvider.pyusdBurnRate)}/hr',
                isDarkMode),
            _buildStatRow(
                'Net Flow',
                '${_pyusdProvider.formatRate(_pyusdProvider.pyusdNetFlowRate)}/hr',
                isDarkMode),
            _buildStatRow(
                'Period Change',
                '${_pyusdProvider.getNetChangePercentage().toStringAsFixed(2)}%',
                isDarkMode),
            _buildStatRow(
                'Time Period', _pyusdProvider.getPeriodDuration(), isDarkMode),
            SizedBox(height: 8),
            Divider(color: isDarkMode ? Colors.grey[700] : Colors.grey[300]),
            SizedBox(height: 8),
            Text(
              'Network Activity',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            SizedBox(height: 8),
            _buildStatRow(
                'Simulation Time',
                '${(_timeElapsed / 60).floor()}:${(_timeElapsed % 60).floor().toString().padLeft(2, '0')}',
                isDarkMode),
            _buildStatRow('Speed Multiplier',
                '${_simulationSpeed.toStringAsFixed(1)}x', isDarkMode),
            _buildStatRow(
                'Active Buildings', _buildings.length.toString(), isDarkMode),
            _buildStatRow(
                'Active Txs', _transactions.length.toString(), isDarkMode),
            _buildStatRow('Vehicle Count', _cars.length.toString(), isDarkMode),
            _buildStatRow(
                'PYUSD Buildings',
                _buildings
                    .where((b) => b.type == BuildingType.pyusd)
                    .length
                    .toString(),
                isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, bool isDarkMode) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor =
        isDarkMode ? const Color(0xFFB3B3B3) : const Color(0xFF757575);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeControlsPanel() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor =
        isDarkMode ? const Color(0xFFB3B3B3) : const Color(0xFF757575);

    return Positioned(
      right: 80,
      top: 80,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black26 : Colors.black26,
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Simulation Speed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textColor),
                  onPressed: _toggleTimeControls,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  iconSize: 20,
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.fast_rewind, color: textColor),
                  onPressed: () {
                    setState(() {
                      _simulationSpeed = max(0.25, _simulationSpeed - 0.25);
                    });
                  },
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.blue[900] : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_simulationSpeed.toStringAsFixed(2)}x',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          isDarkMode ? Colors.blue[300] : Colors.blue.shade800,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.fast_forward, color: textColor),
                  onPressed: () {
                    setState(() {
                      _simulationSpeed = min(3.0, _simulationSpeed + 0.25);
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSpeedPresetButton('0.5x', 0.5, isDarkMode),
                _buildSpeedPresetButton('1x', 1.0, isDarkMode),
                _buildSpeedPresetButton('1.5x', 1.5, isDarkMode),
                _buildSpeedPresetButton('2x', 2.0, isDarkMode),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedPresetButton(String label, double speed, bool isDarkMode) {
    final isSelected = (_simulationSpeed - speed).abs() < 0.01;
    final selectedColor =
        isDarkMode ? const Color(0xFF1976D2) : const Color(0xFF2196F3);
    final unselectedColor =
        isDarkMode ? const Color(0xFF424242) : const Color(0xFFE0E0E0);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor =
        isDarkMode ? const Color(0xFFB3B3B3) : const Color(0xFF757575);

    return InkWell(
      onTap: () {
        setState(() {
          _simulationSpeed = speed;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : secondaryTextColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsPanel() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor =
        isDarkMode ? const Color(0xFFB3B3B3) : const Color(0xFF757575);

    return Container(
      width: 350,
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black26 : Colors.black26,
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Transactions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _transactionHistory.isEmpty
                ? Center(
                    child: Text(
                      'No transactions yet...',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _transactionHistory.length,
                    reverse: true,
                    itemBuilder: (context, index) {
                      final tx = _transactionHistory[
                          _transactionHistory.length - 1 - index];
                      return _buildTransactionItem(tx, isDarkMode);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionEvent tx, bool isDarkMode) {
    final isPyusd = tx.type == "PYUSD";
    final backgroundColor = isDarkMode
        ? (isPyusd ? const Color(0xFF1B5E20) : const Color(0xFF0D47A1))
        : (isPyusd ? Colors.green.shade50 : Colors.blue.shade50);
    final borderColor = isDarkMode
        ? (isPyusd ? const Color(0xFF388E3C) : const Color(0xFF1565C0))
        : (isPyusd ? Colors.green.shade200 : Colors.blue.shade200);
    final iconColor = isDarkMode
        ? (isPyusd ? const Color(0xFF81C784) : const Color(0xFF64B5F6))
        : (isPyusd ? Colors.green.shade700 : Colors.blue.shade700);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor =
        isDarkMode ? const Color(0xFFB3B3B3) : const Color(0xFF757575);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? (isPyusd
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF0D47A1))
                  : (isPyusd ? Colors.green.shade100 : Colors.blue.shade100),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPyusd ? Icons.currency_exchange : Icons.swap_horiz,
              size: 14,
              color: iconColor,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tx.type} Transaction - ${tx.amount} USD',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: textColor,
                  ),
                ),
                Text(
                  'To: ${tx.destination} • Confirmed in ${tx.confirmationTime}s',
                  style: TextStyle(
                    fontSize: 10,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${tx.timestamp.hour.toString().padLeft(2, '0')}:${tx.timestamp.minute.toString().padLeft(2, '0')}:${tx.timestamp.second.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 10,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class CityPainter extends CustomPainter {
  final double skyOffset;
  final List<Building> buildings;
  final List<Car> cars;
  final List<Transaction> transactions;
  final List<Cloud> clouds;
  final double gasUsage;
  final double baseHeight;
  final double cityHeight;
  final bool isDarkMode;

  CityPainter({
    required this.skyOffset,
    required this.buildings,
    required this.cars,
    required this.transactions,
    required this.clouds,
    required this.gasUsage,
    required this.baseHeight,
    required this.cityHeight,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw sky with gradient based on network congestion
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _getSkyColor(),
          isDarkMode ? const Color(0xFF121212) : Colors.white,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, cityHeight));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, cityHeight), skyPaint);

    // Draw clouds
    for (var cloud in clouds) {
      _drawCloud(canvas, cloud);
    }

    // Draw highway
    final roadPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF424242) : Colors.grey.shade800;
    canvas.drawRect(Rect.fromLTWH(0, 400, size.width, 50), roadPaint);

    // Draw road markings
    final markingPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF757575) : Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < size.width; i += 40) {
      canvas.drawLine(
          Offset(i.toDouble(), 425), Offset(i + 20, 425), markingPaint);
    }

    // Draw buildings
    for (var building in buildings) {
      _drawBuilding(canvas, building);
    }

    // Draw cars
    for (var car in cars) {
      _drawCar(canvas, car);
    }

    // Draw transaction particles
    for (var transaction in transactions) {
      _drawTransaction(canvas, transaction);
    }
  }

  Color _getSkyColor() {
    // Transition from blue to red based on gas usage percentage
    if (gasUsage <= 30) {
      return isDarkMode
          ? const Color(0xFF1565C0)
          : Colors.blue.shade300; // Low congestion: blue
    } else if (gasUsage <= 60) {
      return isDarkMode
          ? const Color(0xFF1976D2)
          : Colors.blue.shade200; // Medium congestion: lighter blue
    } else if (gasUsage <= 80) {
      return isDarkMode
          ? const Color(0xFFF57C00)
          : Colors.orange.shade300; // High congestion: orange
    } else {
      return isDarkMode
          ? const Color(0xFFD32F2F)
          : Colors.red.shade300; // Very high congestion: red
    }
  }

  void _drawBuilding(Canvas canvas, Building building) {
    final buildingPaint = Paint();

    // Set building color based on type
    switch (building.type) {
      case BuildingType.pyusd:
        buildingPaint.color =
            isDarkMode ? const Color(0xFF2E7D32) : Colors.green.shade600;
        break;
      case BuildingType.ethereum:
        buildingPaint.color =
            isDarkMode ? const Color(0xFF1565C0) : Colors.blue.shade700;
        break;
      case BuildingType.defi:
        buildingPaint.color =
            isDarkMode ? const Color(0xFF7B1FA2) : Colors.purple.shade700;
        break;
      case BuildingType.exchange:
        buildingPaint.color =
            isDarkMode ? const Color(0xFFE65100) : Colors.orange.shade800;
        break;
      default:
        buildingPaint.color =
            isDarkMode ? const Color(0xFF424242) : Colors.grey.shade700;
    }

    // Draw building body
    canvas.drawRect(
      Rect.fromLTWH(
        building.position,
        cityHeight - building.height,
        building.width,
        building.height,
      ),
      buildingPaint,
    );

    // Draw windows
    final windowPaint = Paint()
      ..color =
          isDarkMode ? const Color(0xFFFFEB3B) : Colors.yellow.withOpacity(0.8);
    final darkWindowPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF212121) : Colors.black54;

    final windowWidth = building.width / 4;
    final windowHeight = 15.0;
    final numFloorsPerBuilding = (building.height / 30).floor();

    for (var floor = 0; floor < numFloorsPerBuilding; floor++) {
      for (var window = 0; window < 3; window++) {
        final windowX = building.position + windowWidth * (window + 0.5);
        final windowY = cityHeight - building.height + 10 + floor * 30.0;

        // Check if window is lit based on building activity and random factors
        final windowIndex = floor * 3 + window;
        final isLit = windowIndex < building.windowStates.length
            ? building.windowStates[windowIndex]
            : false;

        canvas.drawRect(
          Rect.fromLTWH(
            windowX,
            windowY,
            windowWidth * 0.6,
            windowHeight,
          ),
          isLit ? windowPaint : darkWindowPaint,
        );
      }
    }
  }

  void _drawCar(Canvas canvas, Car car) {
    final carPaint = Paint()
      ..color = car.isPyusd
          ? (isDarkMode ? const Color(0xFF4CAF50) : Colors.green.shade500)
          : (isDarkMode ? const Color(0xFF2196F3) : Colors.blue.shade500);

    final shadowPaint = Paint()
      ..color = isDarkMode ? const Color(0x40000000) : Colors.black26
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);

    // Draw car shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(car.position.dx, car.position.dy + 4),
          width: car.size,
          height: car.size * 0.5,
        ),
        Radius.circular(4),
      ),
      shadowPaint,
    );

    // Draw car body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: car.position,
          width: car.size,
          height: car.size * 0.5,
        ),
        Radius.circular(4),
      ),
      carPaint,
    );

    // Draw car top
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(car.position.dx, car.position.dy - car.size * 0.15),
          width: car.size * 0.6,
          height: car.size * 0.3,
        ),
        Radius.circular(3),
      ),
      carPaint,
    );

    // Draw windows
    final windowPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF212121) : Colors.black54;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(car.position.dx, car.position.dy - car.size * 0.15),
          width: car.size * 0.5,
          height: car.size * 0.2,
        ),
        Radius.circular(2),
      ),
      windowPaint,
    );

    // Draw lights
    final lightPaint = Paint()
      ..color = isDarkMode ? const Color(0xFFFFEB3B) : Colors.yellow;
    canvas.drawCircle(
      Offset(
          car.position.dx + car.size * 0.4, car.position.dy + car.size * 0.1),
      2,
      lightPaint,
    );
  }

  void _drawTransaction(Canvas canvas, Transaction transaction) {
    final txPaint = Paint()
      ..color = transaction.isPyusd
          ? (isDarkMode
              ? const Color(0xFF4CAF50)
              : Colors.green.withOpacity(0.8))
          : (isDarkMode
              ? const Color(0xFF2196F3)
              : Colors.blue.withOpacity(0.8));

    // Draw glowing effect
    final glowPaint = Paint()
      ..color = transaction.isPyusd
          ? (isDarkMode
              ? const Color(0x1A4CAF50)
              : Colors.green.withOpacity(0.3))
          : (isDarkMode
              ? const Color(0x1A2196F3)
              : Colors.blue.withOpacity(0.3))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(transaction.position, transaction.size * 1.5, glowPaint);
    canvas.drawCircle(transaction.position, transaction.size, txPaint);

    // Draw a smaller inner circle for detail
    final innerPaint = Paint()
      ..color =
          isDarkMode ? const Color(0xCCFFFFFF) : Colors.white.withOpacity(0.8);
    canvas.drawCircle(transaction.position, transaction.size * 0.5, innerPaint);
  }

  void _drawCloud(Canvas canvas, Cloud cloud) {
    final cloudPaint = Paint()
      ..color =
          isDarkMode ? const Color(0xCCFFFFFF) : Colors.white.withOpacity(0.8);

    canvas.drawCircle(Offset(cloud.position.dx, cloud.position.dy),
        cloud.size * 0.5, cloudPaint);
    canvas.drawCircle(
        Offset(cloud.position.dx + cloud.size * 0.4,
            cloud.position.dy - cloud.size * 0.1),
        cloud.size * 0.4,
        cloudPaint);
    canvas.drawCircle(
        Offset(cloud.position.dx - cloud.size * 0.4, cloud.position.dy),
        cloud.size * 0.45,
        cloudPaint);
    canvas.drawCircle(
        Offset(cloud.position.dx + cloud.size * 0.2,
            cloud.position.dy + cloud.size * 0.2),
        cloud.size * 0.35,
        cloudPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

enum BuildingType { pyusd, ethereum, defi, exchange, other }

class Building {
  final double position;
  final double width;
  final double height;
  final BuildingType type;
  final int windows;
  double activityLevel;
  final double lightProbability;
  List<bool> windowStates = [];

  Building({
    required this.position,
    required this.width,
    required this.height,
    required this.type,
    required this.windows,
    required this.lightProbability,
    this.activityLevel = 0.5,
  }) {
    // Initialize window states
    windowStates = List.generate(
      windows,
      (_) => Random().nextDouble() < lightProbability * activityLevel,
    );
  }

  void toggleRandomWindow() {
    if (windowStates.isEmpty) return;

    final index = Random().nextInt(windowStates.length);
    windowStates[index] = Random().nextDouble() < activityLevel;
  }
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

class TransactionEvent {
  final String type;
  final DateTime timestamp;
  final String destination;
  final String amount;
  final String confirmationTime;
  final Offset position;

  TransactionEvent({
    required this.type,
    required this.timestamp,
    required this.destination,
    required this.amount,
    required this.confirmationTime,
    required this.position,
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
