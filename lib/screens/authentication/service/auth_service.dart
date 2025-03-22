import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  static const String _pinHashKey = 'pin_hash';
  static const String _pinSaltKey = 'pin_salt';
  static const String _biometricSecretKey = 'biometric_secret';
  static const String _biometricEnabledKey = 'biometric_enabled';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Check if biometrics is available on device
  Future<bool> checkBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } catch (e) {
      print('Error checking biometrics: $e');
      return false;
    }
  }

  // Check if PIN is set
  Future<bool> isPINSet() async {
    final pinHash = await _secureStorage.read(key: _pinHashKey);
    return pinHash != null;
  }

  // Check if biometrics is enabled
  Future<bool> isBiometricsEnabled() async {
    final enabled = await _secureStorage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  // Set PIN
  Future<void> setPIN(String pin) async {
    // Generate a random salt
    final salt = const Uuid().v4();

    // Hash the PIN with salt
    final hash = _hashPin(pin, salt);

    // Store the hash and salt
    await _secureStorage.write(key: _pinHashKey, value: hash);
    await _secureStorage.write(key: _pinSaltKey, value: salt);
  }

  // Verify PIN
  Future<bool> verifyPIN(String pin) async {
    final storedHash = await _secureStorage.read(key: _pinHashKey);
    final salt = await _secureStorage.read(key: _pinSaltKey);

    if (storedHash == null || salt == null) {
      return false;
    }

    final inputHash = _hashPin(pin, salt);
    return storedHash == inputHash;
  }

  // Enable biometric authentication
  Future<bool> enableBiometrics(String pin) async {
    try {
      // Check if device supports biometrics
      bool canCheckBiometrics = await checkBiometrics();
      if (!canCheckBiometrics) {
        return false;
      }

      // Authenticate user with biometrics
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint/face to enable biometric login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        // Store PIN securely with biometric protection
        await _secureStorage.write(key: _biometricSecretKey, value: pin);
        await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
        return true;
      }

      return false;
    } catch (e) {
      print('Error enabling biometrics: $e');
      return false;
    }
  }

  Future<bool> disableBiometrics() async {
    try {
      // Simply delete the biometric secret and set enabled to false
      // No need to authenticate with biometrics to disable it
      await _secureStorage.delete(key: _biometricSecretKey);
      await _secureStorage.write(key: _biometricEnabledKey, value: 'false');
      return true;
    } catch (e) {
      print('Error disabling biometrics: $e');
      return false;
    }
  }

  // Update biometric secret (when PIN changes)
  Future<bool> updateBiometricSecret(String newPin) async {
    try {
      if (await isBiometricsEnabled()) {
        bool authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to update your wallet security',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (authenticated) {
          await _secureStorage.write(key: _biometricSecretKey, value: newPin);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error updating biometric secret: $e');
      return false;
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint/face to access your wallet',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print('Error authenticating: $e');
      return false;
    }
  }

  // Get secret key after biometric authentication
  Future<String?> getBiometricSecret() async {
    if (await isBiometricsEnabled()) {
      return await _secureStorage.read(key: _biometricSecretKey);
    }
    return null;
  }

  // Delete authentication data
  Future<void> deleteAuthData() async {
    await _secureStorage.delete(key: _pinHashKey);
    await _secureStorage.delete(key: _pinSaltKey);
    await _secureStorage.delete(key: _biometricSecretKey);
    await _secureStorage.delete(key: _biometricEnabledKey);
  }

  // Helper method to hash PIN
  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
