import 'package:flutter/material.dart';

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
  // Default to Sepolia Testnet
  NetworkType _currentNetwork = NetworkType.sepoliaTestnet;

  // RPC endpoint configurations
  final Map<NetworkType, String> _rpcEndpoints = {
    NetworkType.sepoliaTestnet: RpcEndpoints.sepoliaTestnetHttpRpcUrl,
    NetworkType.ethereumMainnet: RpcEndpoints.mainnetHttpRpcUrl,
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

  // Enhanced switch network method
  Future<void> switchNetwork(NetworkType network) async {
    if (_currentNetwork != network) {
      try {
        _isSwitching = true;
        notifyListeners();

        print('Switching network:');
        print('From: ${_currentNetwork.name} (${_chainIds[_currentNetwork]})');
        print('To: ${network.name} (${_chainIds[network]})');
        print('New RPC URL: ${_rpcEndpoints[network]}');

        _currentNetwork = network;

        // Clear transactions for the previous network
        final transactionProvider = TransactionProvider.instance;
        transactionProvider.clearNetworkData(_currentNetwork);

        notifyListeners();
      } finally {
        _isSwitching = false;
        notifyListeners();
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
}
