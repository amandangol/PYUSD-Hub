import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pyusd_forensics/services/wallet_service.dart';

import '../service/authentication_service.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  authenticating,
  authenticated,
  locked,
  noWallet,
}

class AuthenticationProvider with ChangeNotifier {
  final AuthenticationService _authService = AuthenticationService();
  final WalletService _walletService;

  AuthStatus _status = AuthStatus.initial;
  int _remainingLockoutTime = 0;
  String _errorMessage = '';
  Timer? _lockoutTimer;

  DateTime? _lastAuthTime;
  static const int _sessionTimeoutMinutes = 5;

  AuthenticationProvider(this._walletService) {
    _init();

    // Listen to authentication state changes
    _authService.authStateStream.listen((isAuthenticated) {
      if (isAuthenticated) {
        _status = AuthStatus.authenticated;
      } else {
        _checkStatus();
      }
      notifyListeners();
    });
  }

  // Getters
  AuthStatus get status => _status;
  int get remainingLockoutTime => _remainingLockoutTime;
  String get errorMessage => _errorMessage;
  AuthenticationService get authService => _authService;

  // Initialize authentication state
  Future<void> _init() async {
    await _checkStatus();
    notifyListeners();
  }

  // Check the current authentication status
  Future<void> _checkStatus() async {
    // First check if a wallet exists
    final hasWallet = await _walletService.walletExists();
    if (!hasWallet) {
      _status = AuthStatus.noWallet;
      return;
    }

    // Check if user is locked out
    _remainingLockoutTime = await _authService.getRemainingLockoutTime();
    if (_remainingLockoutTime > 0) {
      _status = AuthStatus.locked;
      return;
    }

    // Check if user is authenticated
    final isAuthenticated = await _authService.isAuthenticated();
    _status =
        isAuthenticated ? AuthStatus.authenticated : AuthStatus.unauthenticated;
  }

  // Set up PIN for first time
  Future<bool> setupPin(String pin) async {
    try {
      await _authService.setupPin(pin);
      _status = AuthStatus.authenticated;
      _lastAuthTime = DateTime.now();

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Authenticate with PIN
  Future<bool> authenticateWithPin(String pin) async {
    _status = AuthStatus.authenticating;
    _errorMessage = '';
    notifyListeners();

    try {
      final success = await _authService.authenticateWithPin(pin);

      if (success) {
        _status = AuthStatus.authenticated;
        _lastAuthTime = DateTime.now();
      } else {
        // Check if locked out after failed attempt
        _remainingLockoutTime = await _authService.getRemainingLockoutTime();
        _status = _remainingLockoutTime > 0
            ? AuthStatus.locked
            : AuthStatus.unauthenticated;
        _errorMessage = 'Incorrect PIN';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    _status = AuthStatus.authenticating;
    _errorMessage = '';
    notifyListeners();

    try {
      final success = await _authService.authenticateWithBiometrics();

      if (success) {
        _status = AuthStatus.authenticated;
        _lastAuthTime = DateTime.now();
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Biometric authentication failed';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Enable biometric authentication
  Future<bool> enableBiometrics() async {
    try {
      final success = await _authService.enableBiometrics();
      _lastAuthTime = DateTime.now();

      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Change PIN
  Future<bool> changePin(String currentPin, String newPin) async {
    try {
      final success = await _authService.changePin(currentPin, newPin);
      if (!success) {
        _errorMessage = 'Current PIN is incorrect';
      }
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    await _authService.logout();
    _lastAuthTime = DateTime.now();

    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // Update activity timestamp to keep session alive
  Future<void> updateActivity() async {
    if (_status == AuthStatus.authenticated) {
      _lastAuthTime = DateTime.now();

      await _authService.updateLastActiveTime();
    }
  }

  // Reset authentication (e.g., when wallet is deleted)
  Future<void> resetAuthentication() async {
    await _authService.resetAuthentication();
    _status = AuthStatus.noWallet;
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}
