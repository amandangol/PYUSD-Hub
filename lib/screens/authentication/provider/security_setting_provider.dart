import 'package:flutter/material.dart';
import 'auth_provider.dart';

enum PinChangeStep {
  none,
  enterCurrent,
  enterNew,
}

class SecuritySettingsProvider with ChangeNotifier {
  final AuthProvider _authProvider;

  // Add a public getter for authProvider
  AuthProvider get authProvider => _authProvider;

  // Biometrics state
  bool _isBiometricsAvailable = false;
  bool _isBiometricsEnabled = false;
  bool _isCheckingBiometrics = true;

  // PIN state
  PinChangeStep _pinChangeStep = PinChangeStep.none;
  bool _isPinVisible = false;
  bool _isNewPinVisible = false;
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
  bool get isPinVisible => _isPinVisible;
  bool get isNewPinVisible => _isNewPinVisible;
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
    // First validate PIN format
    final validation = _authProvider.validatePIN(pin);
    if (!validation.isValid) {
      _error = validation.error;
      notifyListeners();
      return false;
    }

    // Verify if the entered PIN matches
    final isPinValid = await _authProvider.authenticateWithPIN(pin);
    if (!isPinValid) {
      _error = 'Incorrect PIN';
      notifyListeners();
      return false;
    }

    final success = await _authProvider.enableBiometrics(pin);
    if (success) {
      _isBiometricsEnabled = true;
      _error = null;
    } else {
      _error = 'Failed to enable biometrics';
    }
    notifyListeners();
    return success;
  }

  // Explicitly set biometrics enabled state
  void setIsBiometricsEnabled(bool enabled) {
    _isBiometricsEnabled = enabled;
    notifyListeners();
  }

  // Disable biometrics
  Future<bool> disableBiometrics() async {
    final success = await _authProvider.disableBiometrics();
    if (success) {
      _isBiometricsEnabled = false;
      _error = null;
    } else {
      _error = 'Failed to disable biometrics';
    }
    notifyListeners();
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
  Future<bool> setCurrentPin(String pin) async {
    // First validate PIN format
    final validation = _authProvider.validatePIN(pin);
    if (!validation.isValid) {
      _error = validation.error;
      notifyListeners();
      return false;
    }

    // Verify if the entered PIN matches the current PIN
    final isPinValid = await _authProvider.authenticateWithPIN(pin);
    if (!isPinValid) {
      _error = 'Current PIN is incorrect';
      notifyListeners();
      return false;
    }

    _currentPin = pin;
    _pinChangeStep = PinChangeStep.enterNew;
    _error = null;
    notifyListeners();
    return true;
  }

  // Change PIN
  Future<bool> changePin(String newPin) async {
    if (_currentPin == null) {
      _error = 'Current PIN is required';
      notifyListeners();
      return false;
    }

    // Validate new PIN
    final validation = _authProvider.validatePIN(newPin);
    if (!validation.isValid) {
      _error = validation.error;
      notifyListeners();
      return false;
    }

    // Check if new PIN is same as current PIN
    if (_currentPin == newPin) {
      _error = 'New PIN must be different from current PIN';
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
    _isPinVisible = false;
    _isNewPinVisible = false;
    notifyListeners();
  }

  // Add methods to toggle PIN visibility
  void togglePinVisibility() {
    _isPinVisible = !_isPinVisible;
    notifyListeners();
  }

  void toggleNewPinVisibility() {
    _isNewPinVisible = !_isNewPinVisible;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
