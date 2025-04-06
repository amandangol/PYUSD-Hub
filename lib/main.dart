import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:pyusd_hub/screens/insights/provider/insights_provider.dart';
import 'package:pyusd_hub/screens/onboarding/provider/onboarding_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Providers
import 'providers/network_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/walletstate_provider.dart';
import 'providers/gemini_provider.dart';
import 'screens/authentication/provider/auth_provider.dart';
import 'screens/authentication/provider/session_provider.dart';
import 'screens/authentication/provider/security_setting_provider.dart';
import 'screens/insights/service/news_service.dart';
import 'screens/insights/view/insights_screen.dart';
import 'screens/trace/provider/trace_provider.dart';
import 'screens/trace/view/trace_home_screen.dart';
import 'screens/wallet/provider/walletscreen_provider.dart';
import 'screens/networkcongestion/provider/network_congestion_provider.dart';
import 'screens/transactions/provider/transaction_provider.dart';
import 'screens/transactions/provider/transactiondetail_provider.dart';

// Services
import 'screens/authentication/service/wallet_service.dart';
import 'services/market_service.dart';
import 'services/notification_service.dart';

// Screens
import 'screens/wallet/view/wallet_screen.dart';
import 'screens/networkcongestion/view/network_congestion_screen.dart';
import 'screens/settings/view/settings_screen.dart';
import 'screens/insights/provider/news_provider.dart';
import 'services/bigquery_service.dart';
import 'providers/navigation_provider.dart';
import 'widgets/bottom_navigation.dart';
import 'routes/app_routes.dart';

// Theme
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool("theme") ?? false;

  // Create and initialize ThemeProvider
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  // Create and initialize OnboardingProvider
  final onboardingProvider = OnboardingProvider();
  await onboardingProvider.initialize();

  runApp(MyApp(
    initialThemeIsDark: isDarkMode,
    themeProvider: themeProvider,
    onboardingProvider: onboardingProvider,
  ));
}

class MyApp extends StatelessWidget {
  final bool initialThemeIsDark;
  final ThemeProvider themeProvider;
  final OnboardingProvider onboardingProvider;

  const MyApp({
    super.key,
    required this.initialThemeIsDark,
    required this.themeProvider,
    required this.onboardingProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: themeProvider..setDarkMode(initialThemeIsDark),
        ),
        ChangeNotifierProvider.value(value: onboardingProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) => SessionProvider(context.read<AuthProvider>()),
        ),
        ChangeNotifierProvider(create: (_) => WaletScreenProvider()),
        ChangeNotifierProvider(
          create: (context) =>
              SecuritySettingsProvider(context.read<AuthProvider>()),
        ),
        ChangeNotifierProvider(create: (_) => TraceProvider()),
        ChangeNotifierProvider(create: (_) => NetworkProvider()),
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
        ChangeNotifierProvider(
            create: (context) => TransactionDetailProvider()),
        ChangeNotifierProxyProvider4<
            AuthProvider,
            NetworkProvider,
            WalletStateProvider,
            TransactionDetailProvider,
            TransactionProvider>(
          lazy: false,
          create: (context) => TransactionProvider(
            authProvider: context.read<AuthProvider>(),
            networkProvider: context.read<NetworkProvider>(),
            walletProvider: context.read<WalletStateProvider>(),
            detailProvider: context.read<TransactionDetailProvider>(),
            notificationService: NotificationService(),
          ),
          update: (context, authProvider, networkProvider, walletProvider,
                  detailProvider, previous) =>
              TransactionProvider(
            authProvider: authProvider,
            networkProvider: networkProvider,
            walletProvider: walletProvider,
            detailProvider: detailProvider,
            notificationService: NotificationService(),
          ),
        ),
        Provider<MarketService>(
          create: (_) => MarketService(),
        ),
        ChangeNotifierProvider<NetworkCongestionProvider>(
          create: (context) => NetworkCongestionProvider(),
        ),
        ChangeNotifierProxyProvider<MarketService, InsightsProvider>(
          create: (context) => InsightsProvider(
            context.read<MarketService>(),
          ),
          update: (context, marketService, previous) {
            return previous ?? InsightsProvider(marketService);
          },
        ),
        Provider<WalletService>(create: (_) => WalletService()),
        ChangeNotifierProvider<NewsProvider>(
          create: (context) => NewsProvider(
            newsService: NewsService(),
          ),
        ),
        Provider<BigQueryService>(create: (_) => BigQueryService()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => GeminiProvider()),
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
            initialRoute: onboardingProvider.hasCompletedOnboarding
                ? AppRoutes.splash
                : AppRoutes.onboarding,
            onGenerateRoute: AppRoutes.generateRoute,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // Define screens for bottom navigation with metadata
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

  @override
  void initState() {
    super.initState();
    // Ensure we're on the wallet screen when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NavigationProvider>().setWalletScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigationProvider = context.watch<NavigationProvider>();

    return WillPopScope(
      onWillPop: () async {
        if (navigationProvider.currentIndex != 0) {
          navigationProvider.resetToHome();
          return false;
        }
        return true;
      },
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
