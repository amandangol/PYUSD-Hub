import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/credentials.dart';
import '../model/wallet.dart';
import '../service/authentication_service.dart';
import '../service/wallet_service.dart';

class AuthProvider extends ChangeNotifier {
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

        // If we have a saved auth state, attempt to auto-authenticate
        if (savedAuthState) {
          _isAuthenticated = true;

          // Attempt to load the full wallet data (including private key and mnemonic)
          // if user has biometrics enabled
          if (_isBiometricsAvailable &&
              await _authService.isBiometricsEnabled()) {
            try {
              // Get secret key stored with biometric protection
              String? secretKey = await _authService.getBiometricSecret();

              if (secretKey != null) {
                // Load wallet with the secret key
                _wallet =
                    await _walletService.decryptAndLoadWalletWithKey(secretKey);
              }
            } catch (e) {
              // If biometric loading fails, we'll just keep the metadata-only wallet
              print('Failed to auto-load wallet with biometrics: $e');
            }
          }
        }
      } else {
        // No authentication set up yet
        _wallet = null;
        _isAuthenticated = false;
      }
    } catch (e) {
      _setError('Failed to initialize wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new wallet with PIN protection
  Future<void> createWallet(String pin) async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      // Create the wallet first
      _wallet = await _walletService.createWallet();

      // Set PIN for authentication
      await _authService.setPIN(pin);

      // Encrypt wallet data with PIN
      await _walletService.encryptAndStoreWallet(_wallet!, pin);

      // Set authenticated state
      _isAuthenticated = true;
    } catch (e) {
      _setError('Failed to create wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Import wallet from mnemonic with PIN protection

  Future<void> importWalletFromMnemonic(String mnemonic, String pin) async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      // Delete any existing PIN data first to avoid conflicts
      await _authService.deleteAuthData();

      // Import the wallet
      _wallet = await _walletService.importWalletFromMnemonic(mnemonic);

      // Set PIN for authentication
      await _authService.setPIN(pin);

      // Encrypt and store wallet data with PIN
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

  // Import wallet from private key with PIN protection
  Future<void> importWalletFromPrivateKey(String privateKey, String pin) async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      // Import the wallet
      _wallet = await _walletService.importWalletFromPrivateKey(privateKey);

      // Delete any existing PIN data first to avoid conflicts
      await _authService.deleteAuthData();

      // Set PIN for authentication
      await _authService.setPIN(pin);

      // Encrypt wallet data with PIN
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
        await saveAuthState(); // Save authentication state
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

  // Add this to your AuthProvider class
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
}
