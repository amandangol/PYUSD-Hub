import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/network_provider.dart';

class NetworkStatusCard extends StatefulWidget {
  final bool isDarkMode;
  final bool initialShowNetworkSelector;

  const NetworkStatusCard({
    super.key,
    required this.isDarkMode,
    this.initialShowNetworkSelector = false,
  });

  @override
  State<NetworkStatusCard> createState() => _NetworkStatusCardState();
}

class _NetworkStatusCardState extends State<NetworkStatusCard>
    with SingleTickerProviderStateMixin {
  late bool showNetworkSelector;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    showNetworkSelector = widget.initialShowNetworkSelector;

    // Setup animation controller for smooth transitions
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (showNetworkSelector) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleNetworkSelector() {
    setState(() {
      showNetworkSelector = !showNetworkSelector;
      if (showNetworkSelector) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final networkProvider = Provider.of<NetworkProvider>(context);
    final currentNetwork = networkProvider.currentNetwork;
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
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 2,
                          color: statusColor.withOpacity(0.7),
                        ),
                      ),
                    ],
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
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
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
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _toggleNetworkSelector,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 13,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        RotationTransition(
                          turns:
                              Tween(begin: 0.0, end: 0.5).animate(_animation),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: statusColor,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Animated Network Selector
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: showNetworkSelector ? null : 0,
          margin: EdgeInsets.only(top: showNetworkSelector ? 8.0 : 0),
          child: ClipRect(
            child: SizeTransition(
              sizeFactor: _animation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
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
                    Row(
                      children: [
                        Icon(
                          Icons.wifi_tethering,
                          size: 18,
                          color: widget.isDarkMode
                              ? Colors.white70
                              : Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Select Network',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: widget.isDarkMode
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildNetworkOption(
                      'Sepolia Testnet',
                      'Test network for development',
                      currentNetwork == NetworkType.sepoliaTestnet,
                      Colors.orange,
                      Icons.code,
                      () {
                        networkProvider
                            .switchNetwork(NetworkType.sepoliaTestnet);
                        _toggleNetworkSelector();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildNetworkOption(
                      'Ethereum Mainnet',
                      'Production network',
                      currentNetwork == NetworkType.ethereumMainnet,
                      Colors.green,
                      Icons.public,
                      () {
                        networkProvider
                            .switchNetwork(NetworkType.ethereumMainnet);
                        _toggleNetworkSelector();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkOption(
    String name,
    String description,
    bool isSelected,
    Color networkColor,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? networkColor.withOpacity(0.1)
              : widget.isDarkMode
                  ? Colors.black.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? networkColor.withOpacity(0.5)
                : widget.isDarkMode
                    ? Colors.grey.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: networkColor.withOpacity(isSelected ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? networkColor : Colors.grey,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? networkColor
                          : widget.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          widget.isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? networkColor.withOpacity(0.1)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: networkColor, width: 1.5)
                    : Border.all(color: Colors.grey.withOpacity(0.5), width: 1),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: networkColor,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
