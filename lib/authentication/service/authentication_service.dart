import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';

class AuthenticationService {
  // Keys for secure storage
  static const String _pinHashKey = 'pin_hash_key';
  static const String _saltKey = 'pin_salt_key';
  static const String _authMethodKey = 'auth_method';
  static const String _sessionTokenKey = 'session_token';
  static const String _sessionExpiryKey = 'session_expiry';
  static const String _lastActiveTimeKey = 'last_active_time';
  static const String _failedAttemptsKey = 'failed_attempts';
  static const String _lockoutTimeKey = 'lockout_time';

  // Authentication methods
  static const String AUTH_METHOD_PIN = 'pin';
  static const String AUTH_METHOD_BIOMETRIC = 'biometric';
  static const String AUTH_METHOD_BOTH = 'both';

  // Configuration
  static const int _sessionTimeoutMinutes = 15;
  static const int _maxFailedAttempts = 5;
  static const int _lockoutTimeMinutes = 15;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();
  Stream<bool> get authStateStream => _authStateController.stream;

  // Auto-invalidate session after inactivity
  Timer? _sessionTimer;

  // Check if PIN has been set up
  Future<bool> isPinSetup() async {
    final pinHash = await _secureStorage.read(key: _pinHashKey);
    return pinHash != null;
  }

  // Check if biometric authentication is available and enrolled
  Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return canAuthenticate && availableBiometrics.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  // Set up PIN authentication
  Future<void> setupPin(String pin) async {
    // Generate a random salt
    final salt = _generateRandomString(16);

    // Hash the PIN with the salt
    final hashedPin = _hashPin(pin, salt);

    // Store the hash and salt
    await _secureStorage.write(key: _pinHashKey, value: hashedPin);
    await _secureStorage.write(key: _saltKey, value: salt);

    // Set authentication method (PIN by default)
    final currentMethod = await _secureStorage.read(key: _authMethodKey);
    if (currentMethod == null || currentMethod == AUTH_METHOD_BIOMETRIC) {
      await _secureStorage.write(key: _authMethodKey, value: AUTH_METHOD_PIN);
    } else if (currentMethod == AUTH_METHOD_BIOMETRIC) {
      await _secureStorage.write(key: _authMethodKey, value: AUTH_METHOD_BOTH);
    }

    // Reset failed attempts
    await _secureStorage.write(key: _failedAttemptsKey, value: '0');
    await _secureStorage.delete(key: _lockoutTimeKey);
  }

  // Enable biometric authentication
  Future<bool> enableBiometrics() async {
    if (!await isBiometricAvailable()) {
      return false;
    }

    // Authenticate first to ensure the user has the correct credentials
    final authenticated = await _authenticateWithBiometrics(
        'Enable Biometric Authentication',
        'Authenticate to enable biometric login');

    if (authenticated) {
      final isPinSet = await isPinSetup();
      final method = isPinSet ? AUTH_METHOD_BOTH : AUTH_METHOD_BIOMETRIC;
      await _secureStorage.write(key: _authMethodKey, value: method);
      return true;
    }

    return false;
  }

  // Authenticate user with PIN
  Future<bool> authenticateWithPin(String pin) async {
    // Check if user is locked out
    if (await _isLockedOut()) {
      return false;
    }

    final storedHash = await _secureStorage.read(key: _pinHashKey);
    final salt = await _secureStorage.read(key: _saltKey);

    if (storedHash == null || salt == null) {
      return false;
    }

    final hashedInputPin = _hashPin(pin, salt);

    if (hashedInputPin == storedHash) {
      // Reset failed attempts
      await _secureStorage.write(key: _failedAttemptsKey, value: '0');
      await _secureStorage.delete(key: _lockoutTimeKey);

      // Create session
      await _createSession();
      _authStateController.add(true);

      return true;
    } else {
      // Increment failed attempts
      await _incrementFailedAttempts();
      return false;
    }
  }

  // Authenticate user with biometrics
  Future<bool> authenticateWithBiometrics() async {
    final authenticated = await _authenticateWithBiometrics(
        'Authentication Required', 'Use your biometric to access the wallet');

    if (authenticated) {
      await _createSession();
      _authStateController.add(true);
    }

    return authenticated;
  }

  // Get preferred authentication method
  Future<String> getAuthMethod() async {
    return await _secureStorage.read(key: _authMethodKey) ?? AUTH_METHOD_PIN;
  }

  // Set preferred authentication method
  Future<void> setAuthMethod(String method) async {
    if ([AUTH_METHOD_PIN, AUTH_METHOD_BIOMETRIC, AUTH_METHOD_BOTH]
        .contains(method)) {
      await _secureStorage.write(key: _authMethodKey, value: method);
    }
  }

  // Check if the user is authenticated (has a valid session)
  Future<bool> isAuthenticated() async {
    final sessionToken = await _secureStorage.read(key: _sessionTokenKey);
    final expiryString = await _secureStorage.read(key: _sessionExpiryKey);

    if (sessionToken == null || expiryString == null) {
      return false;
    }

    final expiry = DateTime.parse(expiryString);

    // Check if the session is still valid
    if (DateTime.now().isBefore(expiry)) {
      // Update last active time
      await updateLastActiveTime();
      return true;
    } else {
      // Session expired, clear it
      await _clearSession();
      _authStateController.add(false);
      return false;
    }
  }

  // Update last active time to prevent session timeout during active use
  Future<void> updateLastActiveTime() async {
    final now = DateTime.now();
    await _secureStorage.write(
        key: _lastActiveTimeKey, value: now.toIso8601String());

    // Reset session timer if it's running
    _resetSessionTimer();
  }

  // Logout user and clear session
  Future<void> logout() async {
    await _clearSession();
    _authStateController.add(false);
  }

  // Change PIN
  Future<bool> changePin(String currentPin, String newPin) async {
    // First verify current PIN
    final authenticated = await authenticateWithPin(currentPin);

    if (authenticated) {
      await setupPin(newPin);
      return true;
    }

    return false;
  }

  // Reset authentication (for complete reset)
  Future<void> resetAuthentication() async {
    await _secureStorage.delete(key: _pinHashKey);
    await _secureStorage.delete(key: _saltKey);
    await _secureStorage.delete(key: _authMethodKey);
    await _secureStorage.delete(key: _failedAttemptsKey);
    await _secureStorage.delete(key: _lockoutTimeKey);
    await _clearSession();
    _authStateController.add(false);
  }

  // Get remaining lockout time in seconds, 0 if not locked out
  Future<int> getRemainingLockoutTime() async {
    if (!await _isLockedOut()) {
      return 0;
    }

    final lockoutTimeStr = await _secureStorage.read(key: _lockoutTimeKey);
    if (lockoutTimeStr == null) {
      return 0;
    }

    final lockoutTime = DateTime.parse(lockoutTimeStr);
    final now = DateTime.now();

    final unlockTime = lockoutTime.add(Duration(minutes: _lockoutTimeMinutes));

    if (now.isAfter(unlockTime)) {
      // Lockout period expired
      await _secureStorage.delete(key: _lockoutTimeKey);
      await _secureStorage.write(key: _failedAttemptsKey, value: '0');
      return 0;
    }

    return unlockTime.difference(now).inSeconds;
  }

  // Dispose resources
  void dispose() {
    _sessionTimer?.cancel();
    _authStateController.close();
  }

  // PRIVATE METHODS

  // Create a new session
  Future<void> _createSession() async {
    final now = DateTime.now();
    final expiry = now.add(Duration(minutes: _sessionTimeoutMinutes));

    // Generate a random session token
    final sessionToken = _generateRandomString(32);

    await _secureStorage.write(key: _sessionTokenKey, value: sessionToken);
    await _secureStorage.write(
        key: _sessionExpiryKey, value: expiry.toIso8601String());
    await _secureStorage.write(
        key: _lastActiveTimeKey, value: now.toIso8601String());

    // Start the session timer
    _resetSessionTimer();
  }

  // Clear session data
  Future<void> _clearSession() async {
    await _secureStorage.delete(key: _sessionTokenKey);
    await _secureStorage.delete(key: _sessionExpiryKey);
    await _secureStorage.delete(key: _lastActiveTimeKey);

    // Cancel the session timer
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  // Reset the session timer
  void _resetSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(Duration(minutes: _sessionTimeoutMinutes), () async {
      // Check if the user has been active recently
      final lastActiveStr = await _secureStorage.read(key: _lastActiveTimeKey);

      if (lastActiveStr != null) {
        final lastActive = DateTime.parse(lastActiveStr);
        final now = DateTime.now();

        if (now.difference(lastActive).inMinutes >= _sessionTimeoutMinutes) {
          // User has been inactive, logout
          await _clearSession();
          _authStateController.add(false);
        } else {
          // User has been active, reset the timer
          _resetSessionTimer();
        }
      }
    });
  }

  // Generate a random string for salt or session token
  String _generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(List.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  // Hash PIN with salt using SHA-256
  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Authenticate with biometrics
  Future<bool> _authenticateWithBiometrics(String title, String message) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: message,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  // Increment failed attempts counter
  Future<void> _incrementFailedAttempts() async {
    final attemptsStr =
        await _secureStorage.read(key: _failedAttemptsKey) ?? '0';
    final attempts = int.parse(attemptsStr) + 1;

    await _secureStorage.write(
        key: _failedAttemptsKey, value: attempts.toString());

    // Set lockout time if max attempts reached
    if (attempts >= _maxFailedAttempts) {
      await _secureStorage.write(
          key: _lockoutTimeKey, value: DateTime.now().toIso8601String());
    }
  }

  // Check if user is locked out due to too many failed attempts
  Future<bool> _isLockedOut() async {
    final attemptsStr =
        await _secureStorage.read(key: _failedAttemptsKey) ?? '0';
    final attempts = int.parse(attemptsStr);

    if (attempts < _maxFailedAttempts) {
      return false;
    }

    final lockoutTimeStr = await _secureStorage.read(key: _lockoutTimeKey);
    if (lockoutTimeStr == null) {
      return false;
    }

    final lockoutTime = DateTime.parse(lockoutTimeStr);
    final now = DateTime.now();

    // Check if lockout period is over
    if (now.difference(lockoutTime).inMinutes >= _lockoutTimeMinutes) {
      // Reset failed attempts
      await _secureStorage.write(key: _failedAttemptsKey, value: '0');
      await _secureStorage.delete(key: _lockoutTimeKey);
      return false;
    }

    return true;
  }
}
