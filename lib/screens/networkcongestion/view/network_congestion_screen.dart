import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/network_congestion_provider.dart';
import 'tabs/blocks_tab.dart';
import 'tabs/gas_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/transactions_tab.dart';
import 'tabs/analysis_tab.dart';
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
  final List<bool> _loadedTabs = [false, false, false, false, false];
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Initialize provider and load first tab
    Future.microtask(() async {
      final provider =
          Provider.of<NetworkCongestionProvider>(context, listen: false);
      await provider.initialize();
      setState(() => _isInitialLoading = false);
      _loadTab(0);
    });

    // Listen for tab changes
    _tabController.addListener(() {
      _loadTab(_tabController.index);
    });
  }

  void _loadTab(int index) {
    if (!_loadedTabs[index]) {
      setState(() => _loadedTabs[index] = true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/pyusdlogo.png',
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.paid, size: 24);
              },
            ),
            const SizedBox(width: 8),
            const Text('ETH/PYUSD Network Activity'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.local_gas_station), text: 'Gas'),
            Tab(icon: Icon(Icons.storage), text: 'Blocks'),
            Tab(icon: Icon(Icons.swap_horiz), text: 'Transactions'),
            Tab(icon: Icon(Icons.analytics), text: 'Analysis'),
          ],
          isScrollable: false,
          indicatorWeight: 3,
        ),
      ),
      body: Consumer<NetworkCongestionProvider>(
        builder: (context, provider, child) {
          if (_isInitialLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading network data...'),
                ],
              ),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                // Data Source Info Card - Always visible
                const DataSourceInfoCard(),

                // Tab content - Takes remaining space
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Overview Tab
                      _loadedTabs[0]
                          ? SingleChildScrollView(
                              child: OverviewTab(
                                  congestionData: provider.congestionData),
                            )
                          : const Center(child: CircularProgressIndicator()),

                      // Gas Tab
                      _loadedTabs[1]
                          ? GasTab(congestionData: provider.congestionData)
                          : const Center(child: CircularProgressIndicator()),

                      // Blocks Tab
                      _loadedTabs[2]
                          ? SingleChildScrollView(
                              child: BlocksTab(provider: provider),
                            )
                          : const Center(child: CircularProgressIndicator()),

                      // Transactions Tab
                      _loadedTabs[3]
                          ? SingleChildScrollView(
                              child: TransactionsTab(
                                provider: provider,
                                tabController: _tabController,
                              ),
                            )
                          : const Center(child: CircularProgressIndicator()),

                      // Analysis Tab
                      _loadedTabs[4]
                          ? SingleChildScrollView(
                              child: AnalysisTab(
                                provider: provider,
                                congestionData: provider.congestionData,
                              ),
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
