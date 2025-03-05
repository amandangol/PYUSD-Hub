import 'package:flutter/material.dart';
import '../services/blockchain_service.dart';

// Enum for supported networks
enum NetworkType {
  sepoliaTestnet,
  ethereumMainnet,
}

class NetworkConfig {
  final String name;
  final String rpcUrl;
  final int chainId;
  final String pyusdContractAddress;
  final String explorerUrl;

  NetworkConfig({
    required this.name,
    required this.rpcUrl,
    required this.chainId,
    required this.pyusdContractAddress,
    required this.explorerUrl,
  });
}

class NetworkProvider extends ChangeNotifier {
  // Network configurations
  static final Map<NetworkType, NetworkConfig> networks = {
    NetworkType.sepoliaTestnet: NetworkConfig(
      name: 'Sepolia Testnet',
      rpcUrl:
          'https://blockchain.googleapis.com/v1/projects/tidy-computing-433704-d6/locations/asia-east1/endpoints/ethereum-sepolia/rpc?key=AIzaSyCBonfhoxR_wlTKPhAhStdQ5djdv_Pah6o',
      chainId: 11155111,
      pyusdContractAddress: '0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9',
      explorerUrl: 'https://sepolia.etherscan.io',
    ),
    NetworkType.ethereumMainnet: NetworkConfig(
      name: 'Ethereum Mainnet',
      rpcUrl:
          'https://blockchain.googleapis.com/v1/projects/tidy-computing-433704-d6/locations/us-central1/endpoints/ethereum-mainnet/rpc?key=AIzaSyCBonfhoxR_wlTKPhAhStdQ5djdv_Pah6o',
      chainId: 1,
      pyusdContractAddress:
          '0x466a756E9A7401B5e2444a3fCB3c2C12FBEa0a54', // Official PYUSD contract address on mainnet
      explorerUrl: 'https://etherscan.io',
    ),
  };

  // Current network
  NetworkType _currentNetwork = NetworkType.sepoliaTestnet;
  bool _isChangingNetwork = false;
  String? _error;

  // Getters
  NetworkType get currentNetwork => _currentNetwork;
  NetworkConfig get currentNetworkConfig => networks[_currentNetwork]!;
  bool get isChangingNetwork => _isChangingNetwork;
  String? get error => _error;

  Future<bool> switchNetwork(
      NetworkType network, BlockchainService blockchainService) async {
    if (_currentNetwork == network) return true;
    if (_isChangingNetwork) return false;

    _isChangingNetwork = true;
    _error = null;
    notifyListeners();

    try {
      // Reinitialize blockchain service with new network
      await blockchainService.updateNetwork(
        networks[network]!.chainId, // Pass chainId here
      );

      _currentNetwork = network;
      print('Network switched to ${networks[network]!.name}');

      _isChangingNetwork = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to switch network: $e';
      print(_error);

      _isChangingNetwork = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// Network selector widget
class NetworkSelector extends StatelessWidget {
  final NetworkProvider networkProvider;
  final BlockchainService blockchainService;
  final VoidCallback onNetworkChanged;
  final bool isDarkMode;

  const NetworkSelector({
    Key? key,
    required this.networkProvider,
    required this.blockchainService,
    required this.onNetworkChanged,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? const Color(0xFF252543) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Network',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: NetworkProvider.networks.length,
              itemBuilder: (context, index) {
                final network = NetworkProvider.networks.keys.elementAt(index);
                final config = NetworkProvider.networks[network]!;
                final isSelected = network == networkProvider.currentNetwork;

                return InkWell(
                  onTap: networkProvider.isChangingNetwork
                      ? null
                      : () async {
                          if (!isSelected) {
                            final success = await networkProvider.switchNetwork(
                              network,
                              blockchainService,
                            );
                            if (success) {
                              onNetworkChanged();
                            }
                          }
                        },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDarkMode
                              ? const Color(0xFF303064)
                              : const Color(0xFFE6F2FF))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? (isDarkMode
                                ? const Color(0xFF5E5EC9)
                                : const Color(0xFF3B82F6))
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? (isDarkMode
                                    ? const Color(0xFF5E5EC9)
                                    : const Color(0xFF3B82F6))
                                : (isDarkMode
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                config.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Chain ID: ${config.chainId}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: isDarkMode
                                ? const Color(0xFF5E5EC9)
                                : const Color(0xFF3B82F6),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (networkProvider.isChangingNetwork)
              const Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            if (networkProvider.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  networkProvider.error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
