import 'dart:async';
import 'package:flutter/material.dart';
import '../provider/auth_provider.dart';
import '../widget/session_timeout_dialog_widget.dart';
import '../widget/session_warning_dialog.dart';

class SessionProvider extends ChangeNotifier {
  final AuthProvider _authProvider;
  int _autoLockDuration = 5; // Default: 5 minutes
  DateTime _lastActivityTime = DateTime.now();
  Timer? _autoLockTimer;
  Timer? _warningTimer;
  Timer? _warningExpiryTimer;
  bool _isActive = true;
  bool _isShowingWarning = false;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

    if (_isShowingWarning) {
      _dismissWarningDialog();
    }

    notifyListeners();
  }

  // Helper method to safely dismiss dialog
  void _dismissWarningDialog() {
    if (_isShowingWarning && navigatorKey.currentContext != null) {
      // Check if the dialog is still in the widget tree before popping
      if (Navigator.of(navigatorKey.currentContext!, rootNavigator: true)
          .canPop()) {
        Navigator.of(navigatorKey.currentContext!, rootNavigator: true).pop();
      }
      _isShowingWarning = false;
    }
  }

  // Set auto-lock duration in minutes
  void setAutoLockDuration(int minutes) {
    _autoLockDuration = minutes;
    _resetAutoLockTimer();
    notifyListeners();
  }

  // Start timer to check for inactivity
  void _startAutoLockTimer() {
    _autoLockTimer?.cancel();
    _warningTimer?.cancel();
    _warningExpiryTimer?.cancel();

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
    if (_autoLockDuration == 0) return;

    final currentTime = DateTime.now();
    final inactiveTime = currentTime.difference(_lastActivityTime).inMinutes;
    final inactiveSeconds = currentTime.difference(_lastActivityTime).inSeconds;

    debugPrint(
        'Inactive time: $inactiveTime minutes of $_autoLockDuration allowed');

    // Show warning 30 seconds before timeout (only if not already showing warning)
    if (inactiveSeconds >= (_autoLockDuration * 60 - 30) &&
        inactiveSeconds < (_autoLockDuration * 60) &&
        _isActive &&
        !_isShowingWarning) {
      _showWarningMessage();
    }

    // Force timeout if we've reached the timeout duration, regardless of warning status
    if (inactiveTime >= _autoLockDuration && _isActive) {
      debugPrint('Auto-locking wallet due to inactivity');

      // Dismiss any existing warning dialog
      if (_isShowingWarning) {
        _dismissWarningDialog();
      }

      _lockWallet();

      // Show timeout message and navigate to login
      _showTimeoutMessageAndNavigate();
    }
  }

  // Show warning message before session expires
  void _showWarningMessage() {
    if (navigatorKey.currentState != null &&
        navigatorKey.currentContext != null) {
      _isShowingWarning = true;

      // Create a new warning expiry timer - this will force logout when warning period ends
      _warningExpiryTimer?.cancel();
      _warningExpiryTimer = Timer(const Duration(seconds: 30), () {
        if (_isActive) {
          debugPrint(
              'Warning period expired without user action, forcing logout');

          _dismissWarningDialog();

          _lockWallet();
          _showTimeoutMessageAndNavigate();
        }
      });

      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => SessionWarningDialog(
          onContinue: () {
            // Cancel the warning expiry timer
            _warningExpiryTimer?.cancel();

            _lastActivityTime = DateTime.now();
            _isActive = true;

            Navigator.of(dialogContext).pop();
            _isShowingWarning = false;

            notifyListeners();
          },
          onLogout: () {
            _warningExpiryTimer?.cancel();

            Navigator.of(dialogContext).pop();
            _isShowingWarning = false;

            lockWallet();
          },
        ),
      ).then((_) {
        // This runs when the dialog is closed (by any means)
        _isShowingWarning = false;
      });
    }
  }

// Show timeout message and navigate to login screen
  void _showTimeoutMessageAndNavigate() {
    if (navigatorKey.currentState != null &&
        navigatorKey.currentContext != null) {
      // First show the timeout message
      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false, // User must respond to dialog
        builder: (BuildContext dialogContext) => SessionTimeoutDialog(
          onConfirm: () {
            // Close dialog using the dialog's context
            Navigator.of(dialogContext).pop();

            Future.delayed(const Duration(milliseconds: 100), () {
              if (navigatorKey.currentState != null) {
                navigatorKey.currentState!.pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              }
            });
          },
        ),
      );
    } else {
      // If can't show dialog for some reason, still navigate to login
      Future.delayed(const Duration(milliseconds: 100), () {
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/',
            (route) => false,
          );
        }
      });
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
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    }
  }

  // Clean up resources
  @override
  void dispose() {
    _autoLockTimer?.cancel();
    _warningTimer?.cancel();
    _warningExpiryTimer?.cancel();
    super.dispose();
  }
}
