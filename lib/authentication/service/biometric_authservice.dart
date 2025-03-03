import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:async';

import 'package:local_auth/local_auth.dart';

// Authentication Service for biometric authentication
class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  Future<bool> authenticate(
      {String reason = 'Please authenticate to access your wallet'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }
}

// Secure PIN authentication service
class PinAuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _pinKey = 'wallet_pin_hash';
  static const String _pinSaltKey = 'wallet_pin_salt';

  // Check if PIN is set up
  Future<bool> isPinSetup() async {
    return await _secureStorage.read(key: _pinKey) != null;
  }

  // Set up PIN
  Future<void> setupPin(String pin) async {
    // Generate a random salt
    final salt = List<int>.generate(
        32, (_) => DateTime.now().millisecondsSinceEpoch % 255);
    final saltStr = base64Encode(salt);

    // Hash the PIN with the salt
    String hashedPin = _hashPin(pin, saltStr);

    // Store both the hashed PIN and salt
    await _secureStorage.write(key: _pinKey, value: hashedPin);
    await _secureStorage.write(key: _pinSaltKey, value: saltStr);
  }

  // Verify PIN
  Future<bool> verifyPin(String pin) async {
    String? storedHashedPin = await _secureStorage.read(key: _pinKey);
    String? salt = await _secureStorage.read(key: _pinSaltKey);

    if (storedHashedPin == null || salt == null) return false;

    String hashedInputPin = _hashPin(pin, salt);
    return hashedInputPin == storedHashedPin;
  }

  // Update PIN
  Future<bool> updatePin(String currentPin, String newPin) async {
    if (await verifyPin(currentPin)) {
      await setupPin(newPin);
      return true;
    }
    return false;
  }

  // Hash PIN with salt
  String _hashPin(String pin, String salt) {
    var bytes = utf8.encode(pin + salt);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Reset PIN (for forgotten PIN, requires alternative authentication)
  Future<void> resetPin() async {
    await _secureStorage.delete(key: _pinKey);
    await _secureStorage.delete(key: _pinSaltKey);
  }
}

// Session management
class SessionManager {
  Timer? _sessionTimer;
  final int _sessionTimeoutMinutes;

  SessionManager({int sessionTimeoutMinutes = 5})
      : _sessionTimeoutMinutes = sessionTimeoutMinutes;

  void startSession(VoidCallback onTimeout) {
    _resetTimer(onTimeout);
  }

  void resetSession(VoidCallback onTimeout) {
    _resetTimer(onTimeout);
  }

  void _resetTimer(VoidCallback onTimeout) {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(Duration(minutes: _sessionTimeoutMinutes), onTimeout);
  }

  void endSession() {
    _sessionTimer?.cancel();
  }
}
