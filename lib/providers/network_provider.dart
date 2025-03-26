import 'package:flutter/material.dart';

import '../config/rpc_endpoints.dart';

enum NetworkType {
  sepoliaTestnet,
  ethereumMainnet,
}

class NetworkProvider extends ChangeNotifier {
  // Default to Sepolia Testnet
  NetworkType _currentNetwork = NetworkType.sepoliaTestnet;

  // RPC endpoint configurations
  final Map<NetworkType, String> _rpcEndpoints = {
    NetworkType.sepoliaTestnet: RpcEndpoints.sepoliaTestnetHttpRpcUrl,
    NetworkType.ethereumMainnet: RpcEndpoints.mainnetHttpRpcUrl,
  };

  // Network explorers for viewing transactions
  final Map<NetworkType, String> _explorers = {
    NetworkType.sepoliaTestnet: 'https://sepolia.etherscan.io',
    NetworkType.ethereumMainnet: 'https://etherscan.io',
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

  // Getters
  NetworkType get currentNetwork => _currentNetwork;
  String get currentRpcEndpoint => _rpcEndpoints[_currentNetwork] ?? '';
  String get currentExplorer => _explorers[_currentNetwork] ?? '';
  String get currentNetworkName =>
      _networkNames[_currentNetwork] ?? 'Unknown Network';
  String get currentCurrencySymbol =>
      _currencySymbols[_currentNetwork] ?? 'ETH';

  // Get a list of available networks
  List<NetworkType> get availableNetworks => NetworkType.values;

  // Get network name by type
  String getNetworkName(NetworkType type) =>
      _networkNames[type] ?? 'Unknown Network';

  // Get current network name
  String get currentNetworkDisplayName =>
      _networkNames[_currentNetwork] ?? 'Unknown Network';

  // Switch network
  Future<void> switchNetwork(NetworkType network) async {
    if (_currentNetwork != network) {
      print(
          'Switching network from ${_currentNetwork.name} to ${network.name}');
      _currentNetwork = network;
      // Clear any cached data when switching networks
      notifyListeners();
    }
  }

  // Get transaction URL for explorer
  String getTransactionUrl(String txHash) {
    if (txHash.isEmpty) return '';
    return '${_explorers[_currentNetwork]}/tx/$txHash';
  }

  // Get address URL for explorer
  String getAddressUrl(String address) {
    if (address.isEmpty) return '';
    return '${_explorers[_currentNetwork]}/address/$address';
  }
}
