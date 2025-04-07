import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/rpc_endpoints.dart';
import '../screens/transactions/provider/transaction_provider.dart';

enum NetworkType {
  sepoliaTestnet,
  ethereumMainnet,
}

extension NetworkTypeExtension on NetworkType {
  String get storageKey {
    return toString().split('.').last.toLowerCase();
  }
}

class NetworkProvider extends ChangeNotifier {
  NetworkType _currentNetwork = NetworkType.ethereumMainnet;
  SharedPreferences? _prefs;
  static const String _networkKey = 'selected_network';

  final Map<NetworkType, String> _rpcEndpoints = {
    NetworkType.ethereumMainnet: RpcEndpoints.mainnetHttpRpcUrl,
    NetworkType.sepoliaTestnet: RpcEndpoints.sepoliaTestnetHttpRpcUrl,
  };

  // WebSocket RPC endpoints
  final Map<NetworkType, String> _wssEndpoints = {
    NetworkType.sepoliaTestnet: RpcEndpoints.sepoliaTestnetWssRpcUrl,
    NetworkType.ethereumMainnet: RpcEndpoints.mainnetWssRpcUrl,
  };

  // Chain IDs
  final Map<NetworkType, int> _chainIds = {
    NetworkType.sepoliaTestnet: 11155111, // Sepolia chain ID
    NetworkType.ethereumMainnet: 1, // Ethereum Mainnet chain ID
  };

  // Network names for display
  final Map<NetworkType, String> _networkNames = {
    NetworkType.sepoliaTestnet: 'Sepolia Testnet',
    NetworkType.ethereumMainnet: 'Ethereum Mainnet',
  };

  // Native currency symbols
  final Map<NetworkType, String> _currencySymbols = {
    NetworkType.sepoliaTestnet: 'ETH',
    NetworkType.ethereumMainnet: 'ETH',
  };

  // Add new field to track switching state
  bool _isSwitching = false;
  bool get isSwitching => _isSwitching;

  // Enhanced getters
  NetworkType get currentNetwork => _currentNetwork;
  String get currentRpcEndpoint => _rpcEndpoints[_currentNetwork] ?? '';
  String get currentWssEndpoint => _wssEndpoints[_currentNetwork] ?? '';
  int get currentChainId => _chainIds[_currentNetwork] ?? 1;
  String get currentNetworkName =>
      _networkNames[_currentNetwork] ?? 'Unknown Network';
  String get currentCurrencySymbol =>
      _currencySymbols[_currentNetwork] ?? 'ETH';

  // Get network details
  Map<String, dynamic> getCurrentNetworkDetails() {
    return {
      'network': _currentNetwork,
      'rpcUrl': currentRpcEndpoint,
      'wssUrl': currentWssEndpoint,
      'chainId': currentChainId,
      'name': currentNetworkName,
      'currency': currentCurrencySymbol,
    };
  }

  // Get a list of available networks
  List<NetworkType> get availableNetworks => NetworkType.values;

  // Get network name by type
  String getNetworkName(NetworkType type) =>
      _networkNames[type] ?? 'Unknown Network';

  // Get current network name for display
  String get currentNetworkDisplayName =>
      _networkNames[_currentNetwork] ?? 'Unknown Network';

  NetworkProvider() {
    _loadSavedNetwork();
  }

  Future<void> _loadSavedNetwork() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedNetwork = _prefs?.getString(_networkKey);
      if (savedNetwork != null) {
        final networkType = NetworkType.values.firstWhere(
          (e) => e.toString() == savedNetwork,
          orElse: () => NetworkType.ethereumMainnet,
        );
        _currentNetwork = networkType;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading saved network: $e');
      // Default to Ethereum Mainnet if there's an error
      _currentNetwork = NetworkType.ethereumMainnet;
      notifyListeners();
    }
  }

  Future<void> switchNetwork(NetworkType network) async {
    if (_currentNetwork != network) {
      try {
        _isSwitching = true;
        notifyListeners();

        print('Switching network:');
        print('From: ${_currentNetwork.name} (${_chainIds[_currentNetwork]})');
        print('To: ${network.name} (${_chainIds[network]})');
        print('New RPC URL: ${_rpcEndpoints[network]}');

        // Set the new network first
        _currentNetwork = network;
        await _prefs?.setString(_networkKey, network.toString());

        // Notify listeners about the network change
        notifyListeners();

        // Add a small delay to ensure UI updates before clearing data
        await Future.delayed(const Duration(milliseconds: 100));

        // Clear transactions for the previous network
        final transactionProvider = TransactionProvider.instance;
        if (transactionProvider != null) {
          transactionProvider.clearNetworkData(network);
        }

        // Add another small delay before completing the switch
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('Error during network switch: $e');
        // Revert to previous network if there's an error
        _currentNetwork = _currentNetwork;
        notifyListeners();
      } finally {
        _isSwitching = false;
        notifyListeners();
        print('Network switch completed');
      }
    }
  }

  // Helper method to validate RPC endpoint
  Future<bool> validateRpcConnection() async {
    try {
      // Implement RPC connection test
      // You can use web3dart to make a simple call like getting the latest block
      return true;
    } catch (e) {
      print('RPC connection error: $e');
      return false;
    }
  }

  String getEtherscanApiKey() {
    return dotenv.env['ETHERSCAN_API_KEY'] ?? '';
  }

  String getEtherscanBaseUrl() {
    return _currentNetwork == NetworkType.sepoliaTestnet
        ? 'https://api-sepolia.etherscan.io/api'
        : 'https://api.etherscan.io/api';
  }

  String getGeminiApiKey() {
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  String getPyusdContractAddress() {
    return dotenv.env['PYUSD_CONTRACT_ADDRESS'] ?? '';
  }
}
