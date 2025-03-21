import 'dart:async';
import 'package:flutter/material.dart';
import '../provider/auth_provider.dart';

class SessionProvider extends ChangeNotifier {
  final AuthProvider _authProvider;
  int _autoLockDuration = 5; // Default: 5 minutes
  DateTime _lastActivityTime = DateTime.now();
  Timer? _autoLockTimer;
  bool _isActive = true;

  // Constructor
  SessionProvider(this._authProvider) {
    _startAutoLockTimer();
  }

  // Getters
  int get autoLockDuration => _autoLockDuration;
  bool get isActive => _isActive;

  // Update last activity time (call this when user interacts with the app)
  void updateActivity() {
    _lastActivityTime = DateTime.now();
    _isActive = true;
    notifyListeners();
  }

  // Set auto-lock duration in minutes
  void setAutoLockDuration(int minutes) {
    _autoLockDuration = minutes;
    _resetAutoLockTimer();
    notifyListeners();
  }

  // Start timer to check for inactivity
  void _startAutoLockTimer() {
    // Cancel any existing timer
    _autoLockTimer?.cancel();

    // Don't set timer if duration is 0 (never auto-lock)
    if (_autoLockDuration == 0) return;

    debugPrint("Starting auto-lock timer: $_autoLockDuration minute(s)");

    // Create new timer that fires more frequently
    _autoLockTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkInactivity();
    });
  }

  // Reset the auto-lock timer (e.g., when duration changes)
  void _resetAutoLockTimer() {
    _startAutoLockTimer();
    updateActivity();
  }

  // Check if the app has been inactive for longer than the auto-lock duration
  void _checkInactivity() {
    if (_autoLockDuration == 0) return; // Skip if auto-lock is disabled

    final currentTime = DateTime.now();
    final inactiveTime = currentTime.difference(_lastActivityTime).inMinutes;

    // Add logging to debug session timeout issues
    debugPrint(
        'Inactive time: $inactiveTime minutes of $_autoLockDuration allowed');

    if (inactiveTime >= _autoLockDuration && _isActive) {
      debugPrint('Auto-locking wallet due to inactivity');
      _lockWallet();
    }
  }

  // Lock the wallet and set inactive state
  void _lockWallet() {
    _authProvider.lockWallet();
    _isActive = false;
    notifyListeners();
  }

  // Manually lock the wallet
  void lockWallet() {
    _lockWallet();
  }

  // Clean up resources
  @override
  void dispose() {
    _autoLockTimer?.cancel();
    super.dispose();
  }
}
