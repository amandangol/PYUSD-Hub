import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_forensics/main.dart';
import 'package:pyusd_forensics/widgets/loading_overlay.dart';

import '../provider/authentication_provider.dart';
import '../service/authentication_service.dart';

class AuthenticationScreen extends StatefulWidget {
  final String authReason;
  final bool isSessionAuth;

  const AuthenticationScreen({
    Key? key,
    this.authReason = 'Enter PIN',
    this.isSessionAuth = false,
  }) : super(key: key);

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final List<String> _enteredPin = [];
  final int _pinLength = 6;
  bool _isLoading = false;
  bool _setupMode = false;
  String _confirmPin = '';
  String? _error;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
      _tryBiometricAuth();
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);

    // Check if PIN is set up
    final isPinSetup = await authProvider.authService.isPinSetup();
    if (!isPinSetup) {
      setState(() {
        _setupMode = true;
      });
    }

    // Check if in lockout
    final lockoutTime = authProvider.remainingLockoutTime;
    if (lockoutTime > 0) {
      _startLockoutTimer(lockoutTime);
    }
  }

  Future<void> _tryBiometricAuth() async {
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);

    // Only try biometric auth if PIN is already set up
    if (!_setupMode) {
      final authMethod = await authProvider.authService.getAuthMethod();
      final canUseBiometric =
          await authProvider.authService.isBiometricAvailable();

      if (canUseBiometric &&
          (authMethod == AuthenticationService.AUTH_METHOD_BIOMETRIC ||
              authMethod == AuthenticationService.AUTH_METHOD_BOTH)) {
        // Slight delay to make sure UI is ready
        await Future.delayed(const Duration(milliseconds: 500));

        setState(() => _isLoading = true);
        final success = await authProvider.authenticateWithBiometrics();

        if (mounted) {
          setState(() => _isLoading = false);

          if (success) {
            _onAuthenticationSuccess();
          }
        }
      }
    }
  }

  void _startLockoutTimer(int remainingSeconds) {
    _lockoutTimer?.cancel();

    setState(() {
      _error =
          'Too many failed attempts. Try again in ${_formatDuration(remainingSeconds)}';
    });

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final authProvider =
          Provider.of<AuthenticationProvider>(context, listen: false);
      final remaining = authProvider.remainingLockoutTime - 1;

      if (mounted) {
        if (remaining <= 0) {
          setState(() {
            _error = null;
          });
          timer.cancel();
        } else {
          setState(() {
            _error =
                'Too many failed attempts. Try again in ${_formatDuration(remaining)}';
          });
        }
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _addDigit(String digit) {
    if (_enteredPin.length < _pinLength) {
      setState(() {
        _enteredPin.add(digit);
        _error = null;
      });

      // Process PIN when complete
      if (_enteredPin.length == _pinLength) {
        _processPin();
      }
    }
  }

  void _removeDigit() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin.removeLast();
        _error = null;
      });
    }
  }

  void _onAuthenticationSuccess() {
    // If this is a session auth (temporary authentication for an action),
    // just return true to the caller
    if (widget.isSessionAuth) {
      Navigator.of(context).pop(true);
    } else {
      // Otherwise, navigate to the main app
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainApp()),
        (route) => false,
      );
    }
  }

  Future<void> _processPin() async {
    final pin = _enteredPin.join();
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);

    setState(() => _isLoading = true);

    if (_setupMode) {
      if (_confirmPin.isEmpty) {
        // First entry - store for confirmation
        setState(() {
          _confirmPin = pin;
          _enteredPin.clear();
          _error = 'Confirm your PIN';
          _isLoading = false;
        });
      } else {
        // Confirmation entry - verify match
        if (_confirmPin == pin) {
          // Setup PIN
          final success = await authProvider.setupPin(pin);

          if (mounted) {
            if (success) {
              _onAuthenticationSuccess();
            } else {
              setState(() {
                _enteredPin.clear();
                _confirmPin = '';
                _error = authProvider.errorMessage;
                _isLoading = false;
              });
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _enteredPin.clear();
              _confirmPin = '';
              _error = 'PINs do not match. Try again.';
              _isLoading = false;
            });
          }
        }
      }
    } else {
      // Authentication mode
      final success = await authProvider.authenticateWithPin(pin);

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          _onAuthenticationSuccess();
        } else {
          setState(() {
            _enteredPin.clear();
            _error = authProvider.errorMessage;
          });

          if (authProvider.status == AuthStatus.locked) {
            _startLockoutTimer(authProvider.remainingLockoutTime);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthenticationProvider>(context);

    final backgroundColor = isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;
    final primaryColor =
        isDarkMode ? theme.colorScheme.primary : const Color(0xFF3D56F0);

    final isLocked = authProvider.status == AuthStatus.locked;

    return LoadingOverlay(
      isLoading: _isLoading,
      loadingText: 'Authenticating...',
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            _setupMode ? 'Set PIN' : widget.authReason,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          leading: widget.isSessionAuth
              ? IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                )
              : null,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // App logo or icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 36,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 32),

                // Title and instructions
                Text(
                  _setupMode
                      ? (_confirmPin.isEmpty
                          ? 'Create a new PIN'
                          : 'Confirm your PIN')
                      : 'Enter your PIN',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  _setupMode
                      ? 'Choose a secure $_pinLength-digit PIN code'
                      : 'Enter your $_pinLength-digit PIN to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),

                const SizedBox(height: 40),

                // PIN dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pinLength, (index) {
                    final filled = index < _enteredPin.length;
                    return Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? primaryColor : Colors.transparent,
                        border: Border.all(
                          color: filled
                              ? primaryColor
                              : isDarkMode
                                  ? Colors.white54
                                  : Colors.black38,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const Spacer(),

                // Numpad
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildNumberButton('1'),
                          _buildNumberButton('2'),
                          _buildNumberButton('3'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildNumberButton('4'),
                          _buildNumberButton('5'),
                          _buildNumberButton('6'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildNumberButton('7'),
                          _buildNumberButton('8'),
                          _buildNumberButton('9'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Biometric button or empty space
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: !_setupMode && !isLocked
                                ? _buildBiometricButton()
                                : const SizedBox(),
                          ),
                          _buildNumberButton('0'),
                          _buildBackspaceButton(),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthenticationProvider>(context);
    final isLocked = authProvider.status == AuthStatus.locked;

    return GestureDetector(
      onTap: isLocked ? null : () => _addDigit(number),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
        child: Center(
          child: Text(
            number,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isLocked
                  ? (isDarkMode ? Colors.white30 : Colors.black26)
                  : (isDarkMode ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthenticationProvider>(context);
    final isLocked = authProvider.status == AuthStatus.locked;

    return GestureDetector(
      onTap: isLocked ? null : _removeDigit,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 24,
            color: isLocked
                ? (isDarkMode ? Colors.white30 : Colors.black26)
                : (isDarkMode ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return FutureBuilder<bool>(
      future: Provider.of<AuthenticationProvider>(context, listen: false)
          .authService
          .isBiometricAvailable(),
      builder: (context, snapshot) {
        final canUseBiometric = snapshot.data ?? false;

        if (!canUseBiometric) {
          return const SizedBox();
        }

        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;
        final authProvider = Provider.of<AuthenticationProvider>(context);
        final isLocked = authProvider.status == AuthStatus.locked;

        return FutureBuilder<String>(
          future: authProvider.authService.getAuthMethod(),
          builder: (context, methodSnapshot) {
            final authMethod = methodSnapshot.data ?? '';
            final canShowBiometric = canUseBiometric &&
                (authMethod == AuthenticationService.AUTH_METHOD_BIOMETRIC ||
                    authMethod == AuthenticationService.AUTH_METHOD_BOTH);

            if (!canShowBiometric) {
              return const SizedBox();
            }

            return GestureDetector(
              onTap: isLocked ? null : _tryBiometricAuth,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                ),
                child: Center(
                  child: Icon(
                    Icons.fingerprint,
                    size: 28,
                    color: isLocked
                        ? (isDarkMode ? Colors.white30 : Colors.black26)
                        : (isDarkMode ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
