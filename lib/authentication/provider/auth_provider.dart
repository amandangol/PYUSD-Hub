import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../service/biometric_authservice.dart';

class AuthProvider extends ChangeNotifier {
  final BiometricAuthService _bioAuthService = BiometricAuthService();
  final PinAuthService _pinAuthService = PinAuthService();
  final SessionManager _sessionManager;

  bool _isAuthenticated = false;
  bool _isBiometricAvailable = false;
  bool _isPinSetup = false;
  bool _isFirstLaunch = false;
  String _authError = '';
  bool _isLoading = false;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isBiometricAvailable => _isBiometricAvailable;
  bool get isPinSetup => _isPinSetup;
  bool get isFirstLaunch => _isFirstLaunch;
  String get authError => _authError;
  bool get isLoading => _isLoading;

  AuthProvider({int sessionTimeoutMinutes = 5})
      : _sessionManager =
            SessionManager(sessionTimeoutMinutes: sessionTimeoutMinutes) {
    _checkAuthStatus();
  }

  // Initialize authentication status
  Future<void> _checkAuthStatus() async {
    _setLoading(true);

    try {
      // Check if this is first launch
      final storage = const FlutterSecureStorage();
      String? firstLaunch = await storage.read(key: 'first_launch');
      _isFirstLaunch = firstLaunch == null;

      if (_isFirstLaunch) {
        await storage.write(key: 'first_launch', value: 'false');
      }

      // Check if biometric is available
      _isBiometricAvailable = await _bioAuthService.isBiometricAvailable();

      // Check if PIN is set up
      _isPinSetup = await _pinAuthService.isPinSetup();
    } catch (e) {
      print('Error checking auth status: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Authenticate with biometric
  Future<bool> authenticateWithBiometric() async {
    _setLoading(true);
    _authError = '';

    try {
      final success = await _bioAuthService.authenticate();

      if (success) {
        _isAuthenticated = true;
        _startSessionTimer();
        notifyListeners();
      } else {
        _authError = 'Biometric authentication failed';
      }

      return success;
    } catch (e) {
      _authError = 'Authentication error: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Authenticate with PIN
  Future<bool> authenticateWithPin(String pin) async {
    _setLoading(true);
    _authError = '';

    try {
      final success = await _pinAuthService.verifyPin(pin);

      if (success) {
        _isAuthenticated = true;
        _startSessionTimer();
        notifyListeners();
      } else {
        _authError = 'Incorrect PIN';
      }

      return success;
    } catch (e) {
      _authError = 'Authentication error: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Set up PIN
  Future<bool> setupPin(String pin) async {
    _setLoading(true);
    _authError = '';

    try {
      await _pinAuthService.setupPin(pin);
      _isPinSetup = true;
      notifyListeners();
      return true;
    } catch (e) {
      _authError = 'Error setting up PIN: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update PIN
  Future<bool> updatePin(String currentPin, String newPin) async {
    _setLoading(true);
    _authError = '';

    try {
      final success = await _pinAuthService.updatePin(currentPin, newPin);

      if (!success) {
        _authError = 'Current PIN is incorrect';
      }

      return success;
    } catch (e) {
      _authError = 'Error updating PIN: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset PIN (requires alternative authentication)
  Future<bool> resetPin() async {
    _setLoading(true);
    _authError = '';

    try {
      // First authenticate with biometric if available
      if (_isBiometricAvailable) {
        final authenticated = await _bioAuthService.authenticate(
            reason: 'Authenticate to reset your PIN');

        if (authenticated) {
          await _pinAuthService.resetPin();
          _isPinSetup = false;
          notifyListeners();
          return true;
        } else {
          _authError = 'Authentication required to reset PIN';
          return false;
        }
      } else {
        _authError = 'Biometric authentication not available';
        return false;
      }
    } catch (e) {
      _authError = 'Error resetting PIN: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  void logout() {
    _isAuthenticated = false;
    _sessionManager.endSession();
    notifyListeners();
  }

  // Reset session timer
  void resetSession() {
    if (_isAuthenticated) {
      _sessionManager.resetSession(() {
        logout();
      });
    }
  }

  // Start session timer
  void _startSessionTimer() {
    _sessionManager.startSession(() {
      logout();
    });
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    if (_authError.isNotEmpty) {
      _authError = '';
      notifyListeners();
    }
  }
}
