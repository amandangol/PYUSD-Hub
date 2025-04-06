import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../pyusdcity/view/pyusd_city_screen.dart';
import '../provider/network_congestion_provider.dart';
import 'tabs/blocks_tab.dart';
import 'tabs/gas_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/transactions_tab.dart';
import 'widgets/data_source_info_card.dart';

class NetworkCongestionScreen extends StatefulWidget {
  const NetworkCongestionScreen({super.key});

  @override
  State<NetworkCongestionScreen> createState() =>
      _NetworkCongestionScreenState();
}

class _NetworkCongestionScreenState extends State<NetworkCongestionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<bool> _loadedTabs = [
    false,
    false,
    false,
    false,
  ];
  bool _isInitialLoading = true;
  bool _isDisposed = false;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    print('NetworkCongestionScreen: initState called');
    _tabController = TabController(length: 4, vsync: this);

    // Initialize provider and load first tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializeScreen();
    });

    // Listen for tab changes
    _tabController.addListener(() {
      if (!mounted) return;
      _handleTabChange();
    });
  }

  Future<void> _initializeScreen() async {
    if (!mounted) return;

    print('NetworkCongestionScreen: Initializing screen');
    final provider =
        Provider.of<NetworkCongestionProvider>(context, listen: false);

    try {
      // Initialize both providers
      await Future.wait([
        provider.initialize(),
      ]);

      if (!mounted) return;

      setState(() => _isInitialLoading = false);
      _loadTab(0);
    } catch (e) {
      print('NetworkCongestionScreen: Error during initialization: $e');
    }
  }

  void _handleTabChange() {
    if (!mounted) return;
    final currentIndex = _tabController.index;

    // Mark the current tab as loaded
    setState(() {
      _loadedTabs[currentIndex] = true;
    });

    // Force data cleanup when switching tabs
    final provider =
        Provider.of<NetworkCongestionProvider>(context, listen: false);

    // Only keep data relevant to the current tab
    if (currentIndex != 2) {
      // Not on Blocks tab
      provider.trimBlocksData();
    }

    if (currentIndex != 3) {
      // Not on Transactions tab
      provider.trimTransactionsData();
    }
  }

  void _loadTab(int index) {
    if (!mounted) return;
    print('NetworkCongestionScreen: _loadTab called for index $index');

    if (!_loadedTabs[index]) {
      setState(() => _loadedTabs[index] = true);
    }
  }

  Future<void> _handleRefresh() async {
    if (!mounted) return;

    final provider =
        Provider.of<NetworkCongestionProvider>(context, listen: false);
    try {
      await provider.reconnectWebSocket();
      await provider.refreshData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    print('NetworkCongestionScreen: dispose called');
    _isDisposed = true;

    // Clean up provider before disposing the screen
    if (!_isDisposed) {
      final provider =
          Provider.of<NetworkCongestionProvider>(context, listen: false);
      provider.dispose();
    }

    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onSurface;

    return WillPopScope(
      onWillPop: () async {
        if (!_isDisposed) {
          final provider =
              Provider.of<NetworkCongestionProvider>(context, listen: false);
          provider.dispose();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          foregroundColor: theme.appBarTheme.foregroundColor,
          title: Row(
            children: [
              Image.asset(
                'assets/images/pyusdlogo.png',
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.paid, size: 24, color: primaryColor);
                },
              ),
              const SizedBox(width: 8),
              Text(
                'ETH/PYUSD Network Activity',
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.location_city, color: theme.iconTheme.color),
              tooltip: 'PYUSD City View',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PyusdCityScreen(),
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                  icon: Icon(Icons.dashboard,
                      color: theme.tabBarTheme.labelColor),
                  text: 'Overview'),
              Tab(
                  icon: Icon(Icons.local_gas_station,
                      color: theme.tabBarTheme.labelColor),
                  text: 'Gas'),
              Tab(
                  icon:
                      Icon(Icons.storage, color: theme.tabBarTheme.labelColor),
                  text: 'Blocks'),
              Tab(
                  icon: Icon(Icons.swap_horiz,
                      color: theme.tabBarTheme.labelColor),
                  text: 'Transactions'),
            ],
            isScrollable: false,
            indicatorWeight: 3,
            indicatorColor: primaryColor,
            labelColor: theme.tabBarTheme.labelColor,
            unselectedLabelColor: theme.tabBarTheme.unselectedLabelColor,
          ),
        ),
        body: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          child: Consumer<NetworkCongestionProvider>(
            builder: (context, provider, child) {
              if (_isInitialLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: primaryColor),
                      const SizedBox(height: 16),
                      Text(
                        'Loading network data...',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              if (provider.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading data\nPull down to refresh',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              return SafeArea(
                child: Column(
                  children: [
                    const DataSourceInfoCard(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTabContent(0, provider),
                          _buildTabContent(1, provider),
                          _buildTabContent(2, provider),
                          _buildTabContent(3, provider),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(int index, NetworkCongestionProvider provider) {
    final theme = Theme.of(context);

    if (!_loadedTabs[index]) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    switch (index) {
      case 0:
        return SingleChildScrollView(
          child: OverviewTab(
            congestionData: provider.congestionData,
            onRefresh: () async {
              await _handleRefresh();
            },
          ),
        );
      case 1:
        return GasTab(congestionData: provider.congestionData);
      case 2:
        return SingleChildScrollView(
          child: BlocksTab(provider: provider),
        );
      case 3:
        return SingleChildScrollView(
          child: TransactionsTab(
            provider: provider,
            tabController: _tabController,
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
