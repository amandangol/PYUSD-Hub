import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/network_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../services/blockchain_service.dart';

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
    final networkProvider = walletProvider.networkProvider;
    final blockchainService = context.read<BlockchainService>();

    final cardColor =
        widget.isDarkMode ? const Color(0xFF252543) : Colors.white;
    final currentNetwork = networkProvider.currentNetworkConfig;

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
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_done_rounded,
                    color: Colors.green,
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
                        'Connected to ${currentNetwork.name}',
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
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          showNetworkSelector
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.green,
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

        // Network Selector (conditionally shown)
        if (showNetworkSelector)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: NetworkSelector(
              networkProvider: networkProvider,
              blockchainService: blockchainService,
              onNetworkChanged: () {
                walletProvider.handleNetworkChange();
              },
              isDarkMode: widget.isDarkMode,
            ),
          ),
      ],
    );
  }
}
