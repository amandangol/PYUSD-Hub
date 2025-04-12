import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/authentication/screen/splash_screen.dart';
import '../screens/authentication/screen/login_screen.dart';
import '../screens/authentication/screen/wallet_selection_screen.dart';
import '../screens/authentication/screen/create_wallet_screen.dart';
import '../screens/authentication/screen/import_wallet_screen.dart';
import '../screens/authentication/screen/show_mnemonic_screen.dart';
import '../screens/authentication/screen/verify_mnemonic_screen.dart';
import '../screens/settings/view/settings_screen.dart';
import '../screens/onboarding/view/onboarding_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String main = '/main';
  static const String settings = '/settings';
  static const String wallet = '/wallet';
  static const String network = '/network';
  static const String explore = '/explore';
  static const String insights = '/insights';
  static const String aiInsights = '/ai-insights';
  static const String transactionAnalysis = '/transaction-analysis';
  static const String onboarding = '/onboarding';

  // Authentication routes
  static const String login = '/login';
  static const String walletSelection = '/wallet-selection';
  static const String createWallet = '/create-wallet';
  static const String importWallet = '/import-wallet';
  static const String showMnemonic = '/show-mnemonic';
  static const String verifyMnemonic = '/verify-mnemonic';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final String? routeName = settings.name;

    if (routeName == splash) {
      return MaterialPageRoute(
        builder: (_) => const SplashScreen(),
        settings: settings,
      );
    } else if (routeName == main) {
      return MaterialPageRoute(
        builder: (_) => const MainApp(),
        settings: settings,
      );
    } else if (routeName == settings) {
      return MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
        settings: settings,
      );
    } else if (routeName == wallet) {
      return MaterialPageRoute(
        builder: (_) => const MainApp(),
        settings: settings,
      );
    } else if (routeName == network) {
      return MaterialPageRoute(
        builder: (_) => const MainApp(),
        settings: settings,
      );
    } else if (routeName == explore) {
      return MaterialPageRoute(
        builder: (_) => const MainApp(),
        settings: settings,
      );
    } else if (routeName == insights) {
      return MaterialPageRoute(
        builder: (_) => const MainApp(),
        settings: settings,
      );
    } else if (routeName == login) {
      return MaterialPageRoute(
        builder: (_) => const LoginScreen(),
        settings: settings,
      );
    } else if (routeName == walletSelection) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => WalletSelectionScreen(
          forceNavigateToSelect: args?['forceNavigateToSelect'] ?? false,
        ),
        settings: settings,
      );
    } else if (routeName == createWallet) {
      return MaterialPageRoute(
        builder: (_) => const CreateWalletScreen(),
        settings: settings,
      );
    } else if (routeName == importWallet) {
      return MaterialPageRoute(
        builder: (_) => const ImportWalletScreen(),
        settings: settings,
      );
    } else if (routeName == showMnemonic) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => ShowMnemonicScreen(
          mnemonic: args?['mnemonic'] as String,
          pin: args?['pin'] as String,
        ),
        settings: settings,
      );
    } else if (routeName == verifyMnemonic) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => VerifyMnemonicScreen(
          mnemonic: args?['mnemonic'] as String,
          pin: args?['pin'] as String,
        ),
        settings: settings,
      );
    } else if (routeName == onboarding) {
      return MaterialPageRoute(
        builder: (_) => const FirstTimeOnboardingScreen(),
      );
    } else {
      return MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(
            child: Text('Route not found!'),
          ),
        ),
      );
    }
  }

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      main: (context) => const MainApp(),
      settings: (context) => const SettingsScreen(),
      login: (context) => const LoginScreen(),
      walletSelection: (context) => const WalletSelectionScreen(),
      createWallet: (context) => const CreateWalletScreen(),
      importWallet: (context) => const ImportWalletScreen(),
    };
  }
}
