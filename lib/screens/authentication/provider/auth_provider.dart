import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/credentials.dart';
import '../model/wallet.dart';
import '../service/auth_service.dart';
import '../service/wallet_service.dart';

class AuthProvider extends ChangeNotifier {
  static AuthProvider? _instance;
  static AuthProvider get instance {
    assert(_instance != null, 'AuthProvider not initialized');
    return _instance!;
  }

  final WalletService _walletService = WalletService();
  final AuthService _authService = AuthService();

  WalletModel? _wallet;
  bool _isLoading = false;
  String? _error;
  bool _isWalletConnected = false;
  String? _walletConnectAddress;
  bool _isAuthenticated = false;
  bool _isBiometricsAvailable = false;

  // Getters
  WalletModel? get wallet => _wallet;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasWallet => _wallet != null || _isWalletConnected;
  bool get isWalletConnected => _isWalletConnected;
  String? get walletConnectAddress => _walletConnectAddress;
  bool get isAuthenticated => _isAuthenticated;
  bool get isBiometricsAvailable => _isBiometricsAvailable;
  WalletService get walletService => _walletService;

  // Constructor with dependency injection
  AuthProvider() {
    _instance = this;
    initWallet();
  }

  // Get current address (wallet or walletconnect)
  String? getCurrentAddress() {
    if (!_isAuthenticated) return null;

    if (_isWalletConnected && _walletConnectAddress != null) {
      return _walletConnectAddress;
    }
    return _wallet?.address;
  }

  Future<void> saveAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', _isAuthenticated);
  }

  // Initialize wallet and authentication on startup
  Future<void> initWallet() async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      // Check if biometrics is available
      _isBiometricsAvailable = await _authService.checkBiometrics();

      // Check if PIN is set
      bool hasPIN = await _authService.isPINSet();

      // Check if there's a saved authentication state
      final prefs = await SharedPreferences.getInstance();
      bool savedAuthState = prefs.getBool('isAuthenticated') ?? false;

      if (hasPIN) {
        // Load wallet metadata - just address, not sensitive data yet
        _wallet = await _walletService.loadWalletMetadata();

        // If we have a saved auth state and biometrics is enabled, attempt auto-authentication
        if (savedAuthState) {
          if (_isBiometricsAvailable &&
              await _authService.isBiometricsEnabled()) {
            try {
              String? secretKey = await _authService.getBiometricSecret();
              if (secretKey != null) {
                // Load full wallet with the secret key
                _wallet =
                    await _walletService.decryptAndLoadWalletWithKey(secretKey);
                if (_wallet?.privateKey.isNotEmpty == true) {
                  _isAuthenticated = true;
                  notifyListeners();
                  return;
                }
              }
            } catch (e) {
              print('Failed to auto-load wallet with biometrics: $e');
            }
          }
          // If biometric auth failed or isn't available, clear the saved state
          await prefs.setBool('isAuthenticated', false);
        }

        // Keep the wallet metadata even if not authenticated
        return;
      }

      // Clear wallet if no PIN is set
      _wallet = null;
      _isAuthenticated = false;
    } catch (e) {
      _setError('Failed to initialize wallet: $e');
      // Clear saved auth state on error
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAuthenticated', false);
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Create a new wallet with PIN protection
  Future<void> createWallet(String pin) async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      // Validate PIN first
      final validation = _authService.validatePIN(pin);
      if (!validation.isValid) {
        throw Exception(validation.error);
      }

      // Create the wallet first
      _wallet = await _walletService.createWallet();

      // Set PIN for authentication
      final pinResult = await _authService.setPIN(pin);
      if (!pinResult.isValid) {
        throw Exception(pinResult.error);
      }

      // Encrypt wallet data with PIN
      await _walletService.encryptAndStoreWallet(_wallet!, pin);

      // Set authenticated state
      _isAuthenticated = true;
    } catch (e) {
      _setError('Failed to create wallet: $e');
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  // Import wallet from mnemonic with PIN protection
  Future<void> importWalletFromMnemonic(String mnemonic, String pin) async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      // Validate PIN first
      final validation = _authService.validatePIN(pin);
      if (!validation.isValid) {
        throw Exception(validation.error);
      }

      // Validate the mnemonic first
      final isValid = await _walletService.validateMnemonic(mnemonic);
      if (!isValid) {
        throw Exception('Invalid recovery phrase. Please check and try again.');
      }

      // Delete any existing authentication data first
      await _authService.deleteAuthData();

      // Import the wallet
      _wallet = await _walletService.importWalletFromMnemonic(mnemonic);

      // Set a new PIN for authentication
      await _authService.setPIN(pin);

      // Encrypt and store wallet data with the new PIN
      await _walletService.encryptAndStoreWallet(_wallet!, pin);

      // Set authenticated state
      _isAuthenticated = true;
      await saveAuthState(); // Save authentication state
    } catch (e) {
      _setError('Failed to import wallet: $e');
      throw e; // Re-throw to allow the UI to handle it
    } finally {
      _setLoading(false);
    }
  }

  // Import wallet from private key with PIN protection
  Future<void> importWalletFromPrivateKey(String privateKey, String pin) async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      // Delete any existing authentication data first
      await _authService.deleteAuthData();

      // Import the wallet
      _wallet = await _walletService.importWalletFromPrivateKey(privateKey);

      // Set a new PIN for authentication
      await _authService.setPIN(pin);

      // Encrypt wallet data with the new PIN
      await _walletService.encryptAndStoreWallet(_wallet!, pin);

      // Set authenticated state
      _isAuthenticated = true;
      await saveAuthState(); // Save authentication state
    } catch (e) {
      _setError('Failed to import wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Authenticate with PIN
  Future<bool> authenticateWithPIN(String pin) async {
    if (_isLoading) return false;

    _setLoading(true);
    try {
      // Verify PIN
      bool isPINValid = await _authService.verifyPIN(pin);

      if (isPINValid) {
        // Decrypt and load wallet with PIN
        _wallet = await _walletService.decryptAndLoadWallet(pin);

        // If wallet data is incomplete after loading, try to load just with the address
        if (_wallet == null) {
          _setError('Failed to load wallet data');
          return false;
        }

        _isAuthenticated = true;
        await saveAuthState();
        return true;
      } else {
        _setError('Invalid PIN');
        return false;
      }
    } catch (e) {
      _setError('Authentication failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    if (_isLoading || !_isBiometricsAvailable) return false;

    _setLoading(true);
    try {
      // Verify biometrics
      bool isAuthenticated = await _authService.authenticateWithBiometrics();

      if (isAuthenticated) {
        // Get secret key stored after biometrics authentication
        String? secretKey = await _authService.getBiometricSecret();

        if (secretKey != null) {
          // Load wallet with the secret key
          _wallet = await _walletService.decryptAndLoadWalletWithKey(secretKey);
          _isAuthenticated = true;
          await saveAuthState(); // Save authentication state
          return true;
        } else {
          _setError('Failed to retrieve wallet key');
          return false;
        }
      } else {
        _setError('Biometric authentication failed');
        return false;
      }
    } catch (e) {
      _setError('Authentication failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Enable biometric authentication
  Future<bool> enableBiometrics(String pin) async {
    if (_isLoading || !_isBiometricsAvailable) return false;

    _setLoading(true);
    try {
      // Verify PIN first
      bool isPINValid = await _authService.verifyPIN(pin);

      if (isPINValid) {
        // Generate a secret key and store it with biometric protection
        bool success = await _authService.enableBiometrics(pin);
        return success;
      } else {
        _setError('Invalid PIN');
        return false;
      }
    } catch (e) {
      _setError('Failed to enable biometrics: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Disable biometric authentication
  Future<bool> disableBiometrics() async {
    if (_isLoading || !_isBiometricsAvailable) return false;

    _setLoading(true);
    try {
      bool success = await _authService.disableBiometrics();
      if (!success) {
        _setError('Failed to disable biometrics');
      }
      return success;
    } catch (e) {
      _setError('Failed to disable biometrics: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Lock wallet (require authentication again)
  void lockWallet() async {
    _isAuthenticated = false;
    // Don't clear the wallet completely, just its sensitive data
    if (_wallet != null) {
      _wallet = WalletModel(
        address: _wallet!.address,
        privateKey: '', // Clear private key
        mnemonic: '', // Clear mnemonic
        credentials: EthPrivateKey.fromHex('0' * 64), // Placeholder credentials
      );
    }

    // Clear saved auth state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', false);

    notifyListeners();
  }

  Future<bool> checkBiometrics() async {
    return await _authService.checkBiometrics();
  }

  Future<bool> isBiometricsEnabled() async {
    return await _authService.isBiometricsEnabled();
  }

  // Change PIN
  Future<bool> changePIN(String currentPin, String newPin) async {
    if (_isLoading) return false;

    _setLoading(true);
    try {
      // Verify current PIN
      bool isPINValid = await _authService.verifyPIN(currentPin);

      if (isPINValid && _wallet != null) {
        // Set new PIN
        await _authService.setPIN(newPin);

        // Re-encrypt wallet data with new PIN
        await _walletService.encryptAndStoreWallet(_wallet!, newPin);

        // Update biometric secret if enabled
        if (_isBiometricsAvailable &&
            await _authService.isBiometricsEnabled()) {
          await _authService.updateBiometricSecret(newPin);
        }

        return true;
      } else {
        _setError('Invalid PIN');
        return false;
      }
    } catch (e) {
      _setError('Failed to change PIN: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Log out / clear wallet
  Future<void> logout() async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      // Clear sensitive data but keep metadata for potential recovery
      if (_wallet != null) {
        _wallet = WalletModel(
          address: _wallet!.address,
          privateKey: '', // Clear private key
          mnemonic: '', // Clear mnemonic
          credentials:
              EthPrivateKey.fromHex('0' * 64), // Placeholder credentials
        );
      }

      _walletConnectAddress = null;
      _isWalletConnected = false;
      _isAuthenticated = false;

      // Clear saved auth state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAuthenticated', false);

      // Notify listeners after all cleanup is done
      notifyListeners();
    } catch (e) {
      _setError('Failed to logout: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete wallet completely
  Future<void> deleteWallet(String pin) async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      // Verify PIN first
      bool isPINValid = await _authService.verifyPIN(pin);

      if (isPINValid) {
        // Delete wallet from secure storage
        await _walletService.deleteWallet();

        // Delete authentication data
        await _authService.deleteAuthData();

        // Clear memory
        _wallet = null;
        _walletConnectAddress = null;
        _isWalletConnected = false;
        _isAuthenticated = false;
      } else {
        _setError('Invalid PIN');
      }
    } catch (e) {
      _setError('Failed to delete wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMsg) {
    _error = errorMsg;
    print('AuthProvider error: $errorMsg');
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Add this method
  PinValidationResult validatePIN(String pin) {
    return _authService.validatePIN(pin);
  }
}
