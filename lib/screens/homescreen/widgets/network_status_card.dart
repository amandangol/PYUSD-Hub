import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/network_provider.dart';
import '../../../providers/wallet_provider.dart';

class EnhancedNetworkStatusCard extends StatefulWidget {
  final bool isDarkMode;
  final bool initialShowNetworkSelector;

  const EnhancedNetworkStatusCard({
    Key? key,
    required this.isDarkMode,
    this.initialShowNetworkSelector = false,
  }) : super(key: key);

  @override
  State<EnhancedNetworkStatusCard> createState() =>
      _EnhancedNetworkStatusCardState();
}

class _EnhancedNetworkStatusCardState extends State<EnhancedNetworkStatusCard> {
  late bool showNetworkSelector;

  @override
  void initState() {
    super.initState();
    showNetworkSelector = widget.initialShowNetworkSelector;
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final currentNetwork = walletProvider.currentNetwork;
    final currentNetworkName = walletProvider.currentNetworkName;
    final cardColor =
        widget.isDarkMode ? const Color(0xFF252543) : Colors.white;

    // Define network status color based on the current network
    final isTestnet = currentNetwork == NetworkType.sepoliaTestnet;
    final statusColor = isTestnet ? Colors.orange : Colors.green;
    final statusMessage = isTestnet
        ? 'Connected to Sepolia Testnet'
        : 'Connected to Ethereum Mainnet';

    return Column(
      children: [
        // Network Status Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_done_rounded,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Network Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.isDarkMode
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showNetworkSelector = !showNetworkSelector;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          showNetworkSelector
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: statusColor,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Network Selector
        if (showNetworkSelector)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.isDarkMode
                        ? Colors.black.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Network',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  NetworkOption(
                    name: 'Sepolia Testnet',
                    isSelected: currentNetwork == NetworkType.sepoliaTestnet,
                    isDarkMode: widget.isDarkMode,
                    onTap: () {
                      walletProvider.switchNetwork(NetworkType.sepoliaTestnet);
                      setState(() {
                        showNetworkSelector = false;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  NetworkOption(
                    name: 'Ethereum Mainnet',
                    isSelected: currentNetwork == NetworkType.ethereumMainnet,
                    isDarkMode: widget.isDarkMode,
                    onTap: () {
                      walletProvider.switchNetwork(NetworkType.ethereumMainnet);
                      setState(() {
                        showNetworkSelector = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// Helper widget for network selection
class NetworkOption extends StatelessWidget {
  final String name;
  final bool isSelected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const NetworkOption({
    Key? key,
    required this.name,
    required this.isSelected,
    required this.isDarkMode,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color selectionColor = isSelected ? Colors.green : Colors.grey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? selectionColor.withOpacity(0.1)
              : isDarkMode
                  ? Colors.transparent
                  : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? selectionColor.withOpacity(0.5)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: selectionColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? selectionColor
                    : isDarkMode
                        ? Colors.white70
                        : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
