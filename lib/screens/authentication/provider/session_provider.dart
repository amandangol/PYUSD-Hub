import 'package:flutter/material.dart';
import '../provider/auth_provider.dart';

class SessionProvider extends ChangeNotifier {
  final AuthProvider _authProvider;
  bool _isActive = true;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  SessionProvider(this._authProvider);

  // Getters
  bool get isActive => _isActive;

  // Lock the wallet and set inactive state
  void _lockWallet() {
    _authProvider.lockWallet();
    _isActive = false;
    notifyListeners();
  }

  // Manually lock the wallet
  void lockWallet() {
    _lockWallet();
    if (navigatorKey.currentState != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/',
            (route) => false,
          );
        }
      });
    }
  }
}
