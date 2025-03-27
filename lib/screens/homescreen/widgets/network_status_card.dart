import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/network_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../widgets/pyusd_components.dart';
import '../../transactions/provider/transaction_provider.dart';

class NetworkStatusCard extends StatelessWidget {
  final bool isDarkMode;

  const NetworkStatusCard({
    super.key,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final networkProvider = context.watch<NetworkProvider>();
    final isTestnet =
        networkProvider.currentNetwork == NetworkType.sepoliaTestnet;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF252543) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTestnet
              ? Colors.orange.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showNetworkSelector(context, networkProvider),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isTestnet
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isTestnet ? Icons.wifi_tethering : Icons.public,
                    color: isTestnet ? Colors.orange : Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        networkProvider.currentNetworkDisplayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTestnet
                            ? 'Test network for development'
                            : 'Production network',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNetworkSelector(
      BuildContext context, NetworkProvider networkProvider) async {
    if (!context.mounted) return;

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PyusdBottomSheet(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Network',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildNetworkOption(
                context: context,
                networkProvider: networkProvider,
                networkType: NetworkType.sepoliaTestnet,
                icon: Icons.wifi_tethering,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildNetworkOption(
                context: context,
                networkProvider: networkProvider,
                networkType: NetworkType.ethereumMainnet,
                icon: Icons.public,
                color: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true && context.mounted) {
      try {
        ScaffoldMessenger.of(context).clearSnackBars();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.blueAccent,
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Switching network...'),
                ],
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }

        final transactionProvider =
            Provider.of<TransactionProvider>(context, listen: false);
        final walletProvider =
            Provider.of<WalletProvider>(context, listen: false);

        await Future.wait(
          [
            walletProvider.refreshBalances(forceRefresh: true),
            transactionProvider.refreshWalletData(forceRefresh: true),
          ],
          eagerError: false,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () => [null, null],
        );
      } catch (e) {
        print('Error during network switch refresh: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error refreshing data. Pull to refresh.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildNetworkOption({
    required BuildContext context,
    required NetworkProvider networkProvider,
    required NetworkType networkType,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = networkProvider.currentNetwork == networkType;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: networkProvider.isSwitching
            ? null // Disable during switching
            : () async {
                await networkProvider.switchNetwork(networkType);
                Navigator.pop(context, true);
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      networkProvider.getNetworkName(networkType),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      networkType == NetworkType.sepoliaTestnet
                          ? 'Test network for development'
                          : 'Production network',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: color,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
