import 'package:flutter/material.dart';
import 'auth_provider.dart';

enum PinChangeStep {
  none,
  enterCurrent,
  enterNew,
}

class SecuritySettingsProvider with ChangeNotifier {
  final AuthProvider _authProvider;

  // Biometrics state
  bool _isBiometricsAvailable = false;
  bool _isBiometricsEnabled = false;
  bool _isCheckingBiometrics = true;

  // PIN state
  PinChangeStep _pinChangeStep = PinChangeStep.none;
  String? _currentPin;
  String? _error;

  SecuritySettingsProvider(this._authProvider) {
    _initializeSettings();
  }

  // Getters
  bool get isBiometricsAvailable => _isBiometricsAvailable;
  bool get isBiometricsEnabled => _isBiometricsEnabled;
  bool get isCheckingBiometrics => _isCheckingBiometrics;
  PinChangeStep get pinChangeStep => _pinChangeStep;
  String? get currentPin => _currentPin;
  String? get error => _error;

  // Initialize settings
  Future<void> _initializeSettings() async {
    await _checkBiometrics();
  }

  // Check biometrics availability and status
  Future<void> _checkBiometrics() async {
    _isBiometricsAvailable = await _authProvider.checkBiometrics();

    if (_isBiometricsAvailable) {
      _isBiometricsEnabled = await _authProvider.isBiometricsEnabled();
    } else {
      _isBiometricsEnabled = false;
    }

    _isCheckingBiometrics = false;
    notifyListeners();
  }

  // Enable biometrics
  Future<bool> enableBiometrics(String pin) async {
    final success = await _authProvider.enableBiometrics(pin);

    if (success) {
      _isBiometricsEnabled = true;
      notifyListeners();
    }

    return success;
  }

  // Disable biometrics - fixed to directly call AuthProvider's disableBiometrics
  Future<bool> disableBiometrics() async {
    final success = await _authProvider.disableBiometrics();

    if (success) {
      _isBiometricsEnabled = false;
      notifyListeners();
    }

    return success;
  }

  // Start PIN change process
  void startPinChange() {
    _pinChangeStep = PinChangeStep.enterCurrent;
    _currentPin = null;
    _error = null;
    notifyListeners();
  }

  // Set current PIN and move to next step
  void setCurrentPin(String pin) {
    _currentPin = pin;
    _pinChangeStep = PinChangeStep.enterNew;
    notifyListeners();
  }

  // Change PIN
  Future<bool> changePin(String newPin) async {
    if (_currentPin == null) {
      _error = 'Current PIN is required';
      notifyListeners();
      return false;
    }

    final success = await _authProvider.changePIN(_currentPin!, newPin);

    if (!success) {
      _error = _authProvider.error ?? 'Failed to change PIN';
    } else {
      resetPinChangeProcess();
    }

    notifyListeners();
    return success;
  }

  // Reset PIN change process
  void resetPinChangeProcess() {
    _pinChangeStep = PinChangeStep.none;
    _currentPin = null;
    _error = null;
    notifyListeners();
  }
}
