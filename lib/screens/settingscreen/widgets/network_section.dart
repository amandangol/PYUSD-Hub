// lib/widgets/settings/network_section.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/network_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../utils/snackbar_utils.dart';

class NetworkSection extends StatelessWidget {
  final WalletProvider walletProvider;

  const NetworkSection({
    Key? key,
    required this.walletProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;

    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            title: const Text('Network Settings'),
            subtitle: Text(
              walletProvider.currentNetworkName,
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showNetworkDialog(context, walletProvider);
            },
          ),
          const Divider(height: 1),
          // Faucet section
          ExpansionTile(
            title: Row(
              children: [
                Icon(Icons.water_drop, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text('Faucets'),
              ],
            ),
            subtitle: Text(
              'Get testnet tokens',
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
            children: [
              _buildFaucetTile(
                context,
                'Sepolia ETH Faucet',
                'Get test ETH for development',
                Icons.water_drop,
                Colors.blue,
                'https://cloud.google.com/application/web3/faucet/ethereum/sepolia',
              ),
              _buildFaucetTile(
                context,
                'PYUSD Faucet',
                'Get test PYUSD tokens',
                Icons.attach_money,
                Colors.green,
                'https://faucet.paxos.com/',
              ),
              _buildFaucetTile(
                context,
                'Other Testnet Tokens',
                'Access various test tokens',
                Icons.currency_exchange,
                Colors.purple,
                'https://cloud.google.com/application/web3/faucet/ethereum',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaucetTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String url,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        _launchUrl(context, url);
      },
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      SnackbarUtil.showSnackbar(
        context: context,
        message: "Failed to open link: $e",
      );
    }
  }

  void _showNetworkDialog(BuildContext context, WalletProvider walletProvider) {
    final networks = [
      {
        'name': 'Ethereum Mainnet',
        'chainId': 1,
        'icon': Icons.public,
        'color': Colors.blue
      },
      {
        'name': 'Sepolia Testnet',
        'chainId': 11155111,
        'icon': Icons.science,
        'color': Colors.green
      },
      {
        'name': 'Base',
        'chainId': 8453,
        'icon': Icons.layers,
        'color': Colors.blue
      },
      {
        'name': 'Base Sepolia',
        'chainId': 84532,
        'icon': Icons.layers,
        'color': Colors.green
      },
      {
        'name': 'Optimism',
        'chainId': 10,
        'icon': Icons.flash_on,
        'color': Colors.red
      },
      {
        'name': 'Arbitrum',
        'chainId': 42161,
        'icon': Icons.speed,
        'color': Colors.blue
      },
      {
        'name': 'Avalanche',
        'chainId': 43114,
        'icon': Icons.ac_unit,
        'color': Colors.red
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.swap_horiz,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Select Network'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 350, // Fixed height for scrollable content
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Active networks:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: networks.length,
                  itemBuilder: (context, index) {
                    final network = networks[index];
                    final currentNetworkName =
                        walletProvider.currentNetworkName;
                    final isSelected = network['name'] == currentNetworkName;

                    return Card(
                      elevation: isSelected ? 2 : 0,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              (network['color'] as Color).withOpacity(0.2),
                          child: Icon(
                            network['icon'] as IconData,
                            color: network['color'] as Color,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          network['name'] as String,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text('Chain ID: ${network['chainId']}'),
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary)
                            : null,
                        onTap: () {
                          // Call wallet provider to switch network
                          walletProvider
                              .switchNetwork(NetworkType.sepoliaTestnet);
                          Navigator.pop(context);

                          // Show confirmation
                          SnackbarUtil.showSnackbar(
                            context: context,
                            message: 'Switched to ${network['name']}',
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: Switching networks may require reloading your wallet data',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
