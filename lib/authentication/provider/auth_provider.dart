import 'package:flutter/material.dart';
import '../model/wallet.dart';
import '../service/wallet_service.dart';

class AuthProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();

  WalletModel? _wallet;
  bool _isLoading = false;
  String? _error;
  bool _isWalletConnected = false;
  String? _walletConnectAddress;

  // Getters
  WalletModel? get wallet => _wallet;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasWallet => _wallet != null || _isWalletConnected;
  bool get isWalletConnected => _isWalletConnected;
  String? get walletConnectAddress => _walletConnectAddress;

  // Get current address (wallet or walletconnect)
  String? getCurrentAddress() {
    if (_isWalletConnected && _walletConnectAddress != null) {
      return _walletConnectAddress;
    }
    return _wallet?.address;
  }

  // Initialize wallet on startup
  Future<void> initWallet() async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      _wallet = await _walletService.loadWallet();
    } catch (e) {
      _setError('Failed to initialize wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new wallet
  Future<void> createWallet() async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      _wallet = await _walletService.createWallet();
    } catch (e) {
      _setError('Failed to create wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Import wallet from mnemonic
  Future<void> importWalletFromMnemonic(String mnemonic) async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      _wallet = await _walletService.importWalletFromMnemonic(mnemonic);
    } catch (e) {
      _setError('Failed to import wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Import wallet from private key
  Future<void> importWalletFromPrivateKey(String privateKey) async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      _wallet = await _walletService.importWalletFromPrivateKey(privateKey);
    } catch (e) {
      _setError('Failed to import wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Connect external wallet (WalletConnect)
  Future<void> connectWallet(String address) async {
    _walletConnectAddress = address;
    _isWalletConnected = true;
    notifyListeners();
  }

  // Disconnect external wallet
  void disconnectWallet() {
    _walletConnectAddress = null;
    _isWalletConnected = false;
    notifyListeners();
  }

  // Log out / clear wallet
  Future<void> logout() async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      // await _walletService.clearWallet();
      _wallet = null;
      _walletConnectAddress = null;
      _isWalletConnected = false;
    } catch (e) {
      _setError('Failed to logout: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Validate Ethereum address
  bool isValidAddress(String address) {
    final regex = RegExp(r'^0x[a-fA-F0-9]{40}$');
    return regex.hasMatch(address);
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
