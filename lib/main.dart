import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_hub/screens/authentication/provider/session_provider.dart';
import 'package:pyusd_hub/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import all providers
import 'providers/network_provider.dart';
import 'screens/authentication/provider/auth_provider.dart';
import 'screens/authentication/provider/security_setting_provider.dart';
import 'screens/authentication/screen/splash_screen.dart';
import 'screens/authentication/service/wallet_service.dart';
import 'screens/authentication/widget/activity_aware_widget.dart';
import 'screens/homescreen/provider/homescreen_provider.dart';
import 'screens/transactions/provider/transaction_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/theme_provider.dart';

// Import all screens
import 'screens/homescreen/view/home_screen.dart';
import 'screens/network_congestion/provider/network_congestion_provider.dart';
import 'screens/network_congestion/view/network_congestion_screen.dart';
import 'screens/settingscreen/settings_screen.dart';
import 'screens/transactions/provider/transactiondetail_provider.dart';
import 'services/market_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get the singleton instance
  final notificationService = NotificationService();
  await Future.delayed(const Duration(seconds: 1));

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize SharedPreferences with dark mode as default
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool("theme") ?? true;

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
    super.key,
    required this.initialThemeIsDark,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => SessionProvider(context.read<AuthProvider>()),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeScreenProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              SecuritySettingsProvider(context.read<AuthProvider>()),
        ),
        ChangeNotifierProvider(
          create: (_) => NetworkProvider(),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, NetworkProvider,
            WalletProvider>(
          create: (context) => WalletProvider(
            authProvider: context.read<AuthProvider>(),
            networkProvider: context.read<NetworkProvider>(),
          ),
          update: (context, authProvider, networkProvider, previous) =>
              WalletProvider(
            authProvider: authProvider,
            networkProvider: networkProvider,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => TransactionDetailProvider(),
        ),
        ChangeNotifierProvider<TransactionProvider>(
          lazy: false,
          create: (context) {
            final provider = TransactionProvider(
              authProvider: context.read<AuthProvider>(),
              networkProvider: context.read<NetworkProvider>(),
              walletProvider: context.read<WalletProvider>(),
              detailProvider: context.read<TransactionDetailProvider>(),
              notificationService: NotificationService(),
            );
            return provider;
          },
        ),
        Provider<MarketService>(
          create: (_) => MarketService(),
        ),
        ChangeNotifierProvider<NetworkCongestionProvider>(
          create: (context) => NetworkCongestionProvider(),
        ),
        Provider<WalletService>(
          create: (_) => WalletService(),
        ),
        ChangeNotifierProvider.value(
          value: themeProvider..setDarkMode(true),
        ),
      ],
      child: Consumer2<ThemeProvider, SessionProvider>(
        builder: (context, themeProvider, sessionProvider, child) {
          return MaterialApp(
            title: 'PYUSD Wallet & Analytics',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            // Use the navigator key from SessionProvider
            navigatorKey: sessionProvider.navigatorKey,
            // Define initial route
            initialRoute: '/',
            routes: {
              '/': (context) => const ActivityAwareWidget(
                    child: SplashScreen(),
                  ),
              '/main': (context) => const ActivityAwareWidget(
                    child: MainApp(),
                  ),
            },
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
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Define all screens
    final List<Widget> screens = [
      const HomeScreen(),
      const NetworkCongestionScreen(),
      const NetworkCongestionScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
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
            icon: Icon(Icons.speed),
            label: 'Network',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Insights',
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
