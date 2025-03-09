import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import all providers
import 'providers/network_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/transactiondetail_provider.dart';
import 'screens/network_congestion/provider/network_congestion_provider.dart';
import 'screens/pyusd_dashboard/provider/pyusd_analytics_provider.dart';

// Import all screens
import 'screens/homescreen/home_screen.dart';
import 'screens/network_congestion/network_congestion_dashboard.dart';
import 'screens/pyusd_stats/provider/pyusd_stat_provider.dart';
import 'screens/pyusd_stats/pyusd_stat_screen.dart';
import 'screens/settingscreen/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/wallet_selection_screen.dart';
import 'services/wallet_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool("theme") ?? false;

  // Create and initialize ThemeProvider
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  runApp(MyApp(
    initialThemeIsDark: isDarkMode,
    themeProvider: themeProvider,
  ));
}

class MyApp extends StatelessWidget {
  final bool initialThemeIsDark;
  final ThemeProvider themeProvider;

  const MyApp({
    Key? key,
    required this.initialThemeIsDark,
    required this.themeProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get RPC URLs from environment or use defaults
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NetworkProvider>(
          create: (_) => NetworkProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => WalletProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => TransactionDetailProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => PYUSDAnalyticsProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => NetworkCongestionProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => PyusdStatsProvider(),
        ),
        Provider<WalletService>(
          create: (_) => WalletService(),
        ),
        ChangeNotifierProvider.value(
          value: themeProvider,
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'PYUSD Wallet & Analytics',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
            routes: {
              '/main': (context) => const MainApp(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Define all screens
    final List<Widget> _screens = [
      const HomeScreen(),
      const PyusdStatsScreen(),
      const NetworkCongestionDashboard(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.network_check),
            label: 'Network',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
