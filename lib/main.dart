import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_forensics/authentication/provider/authentication_provider.dart';
import 'package:pyusd_forensics/providers/transactiondetail_provider.dart';
import 'package:pyusd_forensics/services/pyUSDBalanceTransferService.dart';
import 'package:pyusd_forensics/services/transaction_service.dart';
import 'package:pyusd_forensics/services/wallet_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'authentication/screen/authentication_screen.dart';
import 'providers/network_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/homescreen/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/ethereum_rpc_service.dart';
import 'theme/app_theme.dart';

// Modify your main function:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    WalletService walletService = WalletService();
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
          create: (context) => AuthenticationProvider(WalletService()),
        ),
        // Provide the already initialized ThemeProvider
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
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, _) {
        // Show a loading indicator while checking initial status
        if (authProvider.status == AuthStatus.initial) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Handle different authentication states
        switch (authProvider.status) {
          case AuthStatus.noWallet:
            return const WalletSelectionScreen();

          case AuthStatus.unauthenticated:
          case AuthStatus.locked:
            // Direct users to AuthenticationScreen for both unauthenticated and locked states
            // The AuthenticationScreen will handle showing the lockout message
            return FutureBuilder<bool>(
              future: authProvider.authService.isPinSetup(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                return const AuthenticationScreen();
              },
            );

          case AuthStatus.authenticating:
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Authenticating..."),
                  ],
                ),
              ),
            );

          case AuthStatus.authenticated:
            // Successfully authenticated, show the home screen
            return const HomeScreen();

          default:
            // Fallback for any other states
            return const Scaffold(
              body: Center(
                child: Text("Unexpected authentication state"),
              ),
            );
        }
      },
    );
  }

  // Format lockout time from seconds to minutes and seconds
  String _formatLockoutTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
