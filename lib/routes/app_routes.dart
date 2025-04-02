import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/authentication/screen/splash_screen.dart';
import '../screens/authentication/widget/activity_aware_widget.dart';
import '../screens/authentication/screen/login_screen.dart';
import '../screens/authentication/screen/onboarding_screen.dart';
import '../screens/authentication/screen/create_wallet_screen.dart';
import '../screens/authentication/screen/import_wallet_screen.dart';
import '../screens/authentication/screen/mnemonic_screen.dart';
import '../screens/settings/view/settings_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String main = '/main';
  static const String settings = '/settings';
  static const String wallet = '/wallet';
  static const String network = '/network';
  static const String explore = '/explore';
  static const String insights = '/insights';
  static const String aiInsights = '/ai-insights';
  static const String transactionAnalysis = '/transaction-analysis';

  // Authentication routes
  static const String login = '/login';
  static const String onboarding = '/onboarding';
  static const String createWallet = '/create-wallet';
  static const String importWallet = '/import-wallet';
  static const String mnemonic = '/mnemonic';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final String? routeName = settings.name;

    if (routeName == splash) {
      return MaterialPageRoute(
        builder: (_) => const ActivityAwareWidget(child: SplashScreen()),
        settings: settings,
      );
    } else if (routeName == main) {
      return MaterialPageRoute(
        builder: (_) => const ActivityAwareWidget(child: MainApp()),
        settings: settings,
      );
    } else if (routeName == settings) {
      return MaterialPageRoute(
        builder: (_) => const ActivityAwareWidget(child: SettingsScreen()),
        settings: settings,
      );
    } else if (routeName == wallet) {
      return MaterialPageRoute(
        builder: (_) => const ActivityAwareWidget(child: MainApp()),
        settings: settings,
      );
    } else if (routeName == network) {
      return MaterialPageRoute(
        builder: (_) => const ActivityAwareWidget(child: MainApp()),
        settings: settings,
      );
    } else if (routeName == explore) {
      return MaterialPageRoute(
        builder: (_) => const ActivityAwareWidget(child: MainApp()),
        settings: settings,
      );
    } else if (routeName == insights) {
      return MaterialPageRoute(
        builder: (_) => const ActivityAwareWidget(child: MainApp()),
        settings: settings,
      );
    } else if (routeName == login) {
      return MaterialPageRoute(
        builder: (_) => const ActivityAwareWidget(child: LoginScreen()),
        settings: settings,
      );
    } else if (routeName == onboarding) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => ActivityAwareWidget(
          child: OnboardingScreen(
            forceOnboarding: args?['forceOnboarding'] ?? false,
          ),
        ),
        settings: settings,
      );
    } else if (routeName == createWallet) {
      return MaterialPageRoute(
        builder: (_) => const ActivityAwareWidget(child: CreateWalletScreen()),
        settings: settings,
      );
    } else if (routeName == importWallet) {
      return MaterialPageRoute(
        builder: (_) => const ActivityAwareWidget(child: ImportWalletScreen()),
        settings: settings,
      );
    } else if (routeName == mnemonic) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => ActivityAwareWidget(
          child: MnemonicConfirmationScreen(
            mnemonic: args?['mnemonic'] as String,
            pin: args?['pin'] as String,
          ),
        ),
        settings: settings,
      );
    } else {
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('No route defined for ${settings.name}'),
          ),
        ),
      );
    }
  }

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const ActivityAwareWidget(child: SplashScreen()),
      main: (context) => const ActivityAwareWidget(child: MainApp()),
      settings: (context) => const ActivityAwareWidget(child: SettingsScreen()),
      login: (context) => const ActivityAwareWidget(child: LoginScreen()),
      onboarding: (context) =>
          const ActivityAwareWidget(child: OnboardingScreen()),
    };
  }
}
