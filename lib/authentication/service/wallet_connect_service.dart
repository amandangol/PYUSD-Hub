import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class WalletService {
  // Singleton pattern
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  // Key constants
  static const String sessionStorageKey = 'walletconnect_session';

  // Connection state
  bool get isConnected => _connector != null && _connector!.connected;
  String? get walletAddress => _connector?.session.accounts.first;

  // WalletConnect connector
  WalletConnect? _connector;

  // Infura provider (replace with your own Infura project ID)
  final String _infuraProjectId =
      'YTUIjmVsAIaZnRFKdGI5lNg9i59E6yXPCxKa5LJHuXzzqSlD+WMI9A';
  late final Web3Client _web3client;

  // Initialize the service
  Future<void> init() async {
    _web3client = Web3Client(
      'https://mainnet.infura.io/v3/$_infuraProjectId',
      http.Client(),
    );

    // Try to restore session
    await _restoreSession();
  }

  Future<bool> connectWallet() async {
    if (isConnected) return true;

    final Completer<bool> completer = Completer<bool>();

    // Initialize WalletConnect
    _connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      clientMeta: PeerMeta(
        name: 'Your App Name',
        description: 'Your app description',
        url: 'https://yourapp.com',
        icons: ['https://yourapp.com/icon.png'],
      ),
    );

    // Subscribe to connection events
    _connector!.on('connect', (session) async {
      // Ensure session is of type SessionStatus and save it
      await _saveSession(session);
      completer.complete(true);
    });

    _connector!.on('session_update', (payload) async {
      await _saveSession(payload);
    });

    _connector!.on('disconnect', (payload) async {
      await _clearSession();
      completer.complete(false);
    });

    // Create session
    try {
      Uri? uri = (await _connector!.createSession(
        chainId: 1,
        onDisplayUri: (uri) async {
          await _launchURL(uri); // Launch the URI
        },
      )) as Uri?;

      return await completer.future;
    } catch (e) {
      print('Error connecting wallet: $e');
      return false;
    }
  }

  // Disconnect wallet
  Future<void> disconnectWallet() async {
    if (_connector != null && _connector!.connected) {
      try {
        await _connector!.killSession();
      } catch (e) {
        print('Error disconnecting wallet: $e');
      }
    }
    await _clearSession();
  }

  // Get wallet balance
  Future<EtherAmount?> getBalance() async {
    if (!isConnected) return null;

    try {
      final address = EthereumAddress.fromHex(walletAddress!);
      return await _web3client.getBalance(address);
    } catch (e) {
      print('Error getting balance: $e');
      return null;
    }
  }

  // Send a transaction
  Future<String?> sendTransaction({
    required String to,
    required BigInt amount,
    required String privateKey,
  }) async {
    if (!isConnected) return null;

    try {
      final credentials = EthPrivateKey.fromHex(privateKey);
      final transaction = Transaction(
        to: EthereumAddress.fromHex(to),
        value: EtherAmount.fromBigInt(EtherUnit.wei, amount),
      );

      final txHash = await _web3client.sendTransaction(
        credentials,
        transaction,
        chainId: 1,
      );
      return txHash;
    } catch (e) {
      print('Error sending transaction: $e');
      return null;
    }
  }

  // Sign message
  Future<String?> signMessage(String message) async {
    if (!isConnected) return null;

    try {
      final result = await _connector!.sendCustomRequest(
        method: 'personal_sign',
        params: [
          message,
          walletAddress!.toLowerCase(),
        ],
      );
      return result;
    } catch (e) {
      print('Error signing message: $e');
      return null;
    }
  }

  // Helper methods
  Future<void> _saveSession(dynamic session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(sessionStorageKey, jsonEncode(session));
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(sessionStorageKey);
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(sessionStorageKey);

    if (sessionJson != null) {
      try {
        final session = jsonDecode(sessionJson);
        _connector = WalletConnect(
          bridge: 'https://bridge.walletconnect.org',
          session: WalletConnectSession.fromJson(session),
          clientMeta: PeerMeta(
            name: 'Your App Name',
            description: 'Your app description',
            url: 'https://yourapp.com',
            icons: ['https://yourapp.com/icon.png'],
          ),
        );

        // Restore event listeners
        _connector!.on('disconnect', (payload) async {
          await _clearSession();
        });
      } catch (e) {
        print('Error restoring session: $e');
        await _clearSession();
      }
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

// 3. Create a wallet provider
class WalletProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();

  bool _isConnecting = false;
  bool _isConnected = false;
  String? _walletAddress;
  String? _walletBalance;
  String? _errorMessage;

  // Getters
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  String? get walletAddress => _walletAddress;
  String? get walletBalance => _walletBalance;
  String? get errorMessage => _errorMessage;

  // Initialize
  Future<void> init() async {
    await _walletService.init();
    _isConnected = _walletService.isConnected;
    _walletAddress = _walletService.walletAddress;
    if (_isConnected) {
      await _updateBalance();
    }
    notifyListeners();
  }

  // Connect wallet
  Future<bool> connectWallet() async {
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _walletService.connectWallet();
      _isConnected = success;
      _walletAddress = _walletService.walletAddress;

      if (success) {
        await _updateBalance();
      }

      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  // Disconnect wallet
  Future<void> disconnectWallet() async {
    try {
      await _walletService.disconnectWallet();
      _isConnected = false;
      _walletAddress = null;
      _walletBalance = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Sign message
  Future<String?> signMessage(String message) async {
    try {
      return await _walletService.signMessage(message);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Update balance
  Future<void> _updateBalance() async {
    try {
      final balance = await _walletService.getBalance();
      if (balance != null) {
        _walletBalance = balance.getValueInUnit(EtherUnit.ether).toString();
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
