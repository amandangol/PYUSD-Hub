import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/network_congestion_provider.dart';
import 'tabs/blocks_tab.dart';
import 'tabs/gas_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/transactions_tab.dart';
import '../../network_activity/view/network_activity_screen.dart';

class NetworkDashboardScreen extends StatefulWidget {
  const NetworkDashboardScreen({super.key});

  @override
  State<NetworkDashboardScreen> createState() => _NetworkDashboardScreenState();
}

class _NetworkDashboardScreenState extends State<NetworkDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize tab controller with 4 tabs
    _tabController = TabController(length: 4, vsync: this);

    // Fetch data when screen is first loaded
    Future.microtask(() =>
        Provider.of<NetworkCongestionProvider>(context, listen: false)
            .initialize());
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
            const SizedBox(
              width: 8,
            ),
            const Text('PYUSD Network Activity'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NetworkActivityScreen(),
                ),
              );
            },
            tooltip: 'View Network Activity Visualization',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<NetworkCongestionProvider>(context, listen: false)
                  .refresh();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.local_gas_station), text: 'Gas'),
            Tab(icon: Icon(Icons.storage), text: 'Blocks'),
            Tab(icon: Icon(Icons.swap_horiz), text: 'Transactions'),
          ],
          isScrollable: false,
          indicatorWeight: 3,
        ),
      ),
      body: Consumer<NetworkCongestionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.refresh();
            },
            child: TabBarView(
              controller: _tabController,
              children: [
                // Overview Tab
                OverviewTab(congestionData: provider.congestionData),

                // Gas Tab
                GasTab(congestionData: provider.congestionData),

                // Blocks Tab
                BlocksTab(provider: provider),

                // Transactions Tab
                TransactionsTab(
                  provider: provider,
                  tabController: _tabController,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
