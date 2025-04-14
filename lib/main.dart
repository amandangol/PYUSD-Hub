import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_hub/screens/authentication/services/wallet_service.dart';
import 'package:pyusd_hub/screens/geminiai/provider/gemini_provider.dart';
import 'package:pyusd_hub/screens/insights/provider/insights_provider.dart';
import 'package:pyusd_hub/screens/onboarding/provider/onboarding_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Providers
import 'providers/network_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/walletstate_provider.dart';
import 'screens/authentication/provider/auth_provider.dart';
import 'screens/authentication/provider/session_provider.dart';
import 'screens/authentication/provider/security_setting_provider.dart';
import 'screens/news/service/news_service.dart';
import 'screens/insights/view/insights_screen.dart';
import 'screens/settings/view/settings_screen.dart';
import 'screens/trace/provider/trace_provider.dart';
import 'screens/trace/view/trace_home_screen.dart';
import 'screens/wallet/provider/walletscreen_provider.dart';
import 'screens/networkcongestion/provider/network_congestion_provider.dart';
import 'screens/transactions/provider/transaction_provider.dart';
import 'screens/transactions/provider/transactiondetail_provider.dart';

// Services
import 'services/market_service.dart';
import 'services/notification_service.dart';

// Screens
import 'screens/wallet/view/wallet_screen.dart';
import 'screens/networkcongestion/view/network_congestion_screen.dart';
import 'screens/news/provider/news_provider.dart';
import 'providers/navigation_provider.dart';
import 'widgets/bottom_navigation.dart';
import 'routes/app_routes.dart';

// Theme
import 'theme/app_theme.dart';
import 'package:pyusd_hub/screens/trace/provider/mev_analysis_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize shared preferences
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool("theme") ?? false;

  // Initialize providers that need early setup
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  // Initialize onboarding provider but don't check status yet
  final onboardingProvider = OnboardingProvider();

  // Initialize notification service
  final notificationService = NotificationService();

  runApp(
    MultiProvider(
      providers: [
        // Theme providers
        ChangeNotifierProvider.value(
          value: themeProvider..setDarkMode(isDarkMode),
        ),
        ChangeNotifierProvider.value(value: onboardingProvider),

        // Core providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) => SessionProvider(context.read<AuthProvider>()),
        ),
        ChangeNotifierProvider(create: (_) => NetworkProvider()),

        // Wallet providers
        ChangeNotifierProvider(create: (_) => WaletScreenProvider()),
        ChangeNotifierProvider(
          create: (context) =>
              SecuritySettingsProvider(context.read<AuthProvider>()),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, NetworkProvider,
            WalletStateProvider>(
          create: (context) => WalletStateProvider(
            authProvider: context.read<AuthProvider>(),
            networkProvider: context.read<NetworkProvider>(),
          ),
          update: (context, authProvider, networkProvider, previous) =>
              WalletStateProvider(
            authProvider: authProvider,
            networkProvider: networkProvider,
          ),
        ),

        // Transaction providers
        ChangeNotifierProvider(create: (_) => TransactionDetailProvider()),
        ChangeNotifierProxyProvider4<
            AuthProvider,
            NetworkProvider,
            WalletStateProvider,
            TransactionDetailProvider,
            TransactionProvider>(
          create: (context) => TransactionProvider(
            authProvider: context.read<AuthProvider>(),
            networkProvider: context.read<NetworkProvider>(),
            walletProvider: context.read<WalletStateProvider>(),
            detailProvider: context.read<TransactionDetailProvider>(),
            notificationService: notificationService,
          ),
          update: (context, authProvider, networkProvider, walletProvider,
                  detailProvider, previous) =>
              TransactionProvider(
            authProvider: authProvider,
            networkProvider: networkProvider,
            walletProvider: walletProvider,
            detailProvider: detailProvider,
            notificationService: notificationService,
          ),
        ),

        // Network and market providers
        Provider<MarketService>(create: (_) => MarketService()),
        ChangeNotifierProvider<NetworkCongestionProvider>(
          create: (_) => NetworkCongestionProvider(
            prefs,
            notificationService,
          ),
        ),

        // Insights provider
        ChangeNotifierProxyProvider<MarketService, InsightsProvider>(
          create: (context) => InsightsProvider(context.read<MarketService>()),
          update: (context, marketService, previous) =>
              previous ?? InsightsProvider(marketService),
        ),

        // Service providers
        Provider<WalletService>(create: (_) => WalletService()),
        ChangeNotifierProvider<NewsProvider>(
          create: (_) => NewsProvider(newsService: NewsService()),
        ),

        // Navigation and other providers
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(
          create: (_) => GeminiProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider(create: (_) => TraceProvider()),
        ChangeNotifierProvider(create: (_) => MevAnalysisProvider()),
      ],
      child: Consumer2<ThemeProvider, SessionProvider>(
        builder: (context, themeProvider, sessionProvider, child) {
          return MaterialApp(
            title: 'PYUSD Wallet & Analytics',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            navigatorKey: sessionProvider.navigatorKey,
            // Always start with splash screen
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.generateRoute,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final List<Map<String, dynamic>> _screens = [
    {
      'label': 'Network',
      'icon': Icons.network_check,
      'color': Colors.blue,
      'screen': const NetworkCongestionScreen(),
    },
    {
      'label': 'Explore',
      'icon': Icons.explore,
      'color': Colors.green,
      'screen': const InsightsScreen(),
    },
    {
      'label': 'Wallet',
      'icon': Icons.account_balance_wallet,
      'color': Colors.orange,
      'screen': const WalletScreen(),
    },
    {
      'label': 'Tracer',
      'icon': Icons.account_tree_outlined,
      'color': Colors.purple,
      'screen': const TraceHomeScreen(),
    },
    {
      'label': 'Settings',
      'icon': Icons.settings,
      'color': Colors.grey,
      'screen': const SettingsScreen(),
    },
  ];

  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NavigationProvider>().setWalletScreen();
    });
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    final navigationProvider = context.read<NavigationProvider>();

    if (navigationProvider.currentIndex != 2) {
      // If not on wallet screen, navigate to wallet screen
      navigationProvider.setWalletScreen();
      return false;
    }

    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final navigationProvider = context.watch<NavigationProvider>();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: [
          Scaffold(
            body: IndexedStack(
              index: navigationProvider.currentIndex,
              children:
                  _screens.map((screen) => screen['screen'] as Widget).toList(),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                navigationProvider.setWalletScreen();
              },
              backgroundColor: Colors.blue,
              child:
                  const Icon(Icons.account_balance_wallet, color: Colors.white),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: const AppBottomNavigation(),
          ),
        ],
      ),
    );
  }
}
