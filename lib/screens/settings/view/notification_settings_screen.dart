import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../networkcongestion/provider/network_congestion_provider.dart';
import '../../../widgets/pyusd_components.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PyusdAppBar(
        showLogo: true,
        isDarkMode: isDarkMode,
        title: "Notification Settings",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gas Price Alerts section
              Text(
                'GAS PRICE ALERTS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: theme.colorScheme.surface,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Consumer<NetworkCongestionProvider>(
                  builder: (context, provider, child) {
                    return Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Enable Gas Price Alerts'),
                          subtitle: Text(
                            'Get notified when gas prices are low',
                            style: TextStyle(color: textColor.withOpacity(0.7)),
                          ),
                          secondary: Icon(
                            Icons.notifications_active,
                            color: primaryColor,
                          ),
                          value: provider.gasPriceNotificationsEnabled,
                          onChanged: (bool value) {
                            provider.toggleGasPriceNotifications(value);
                          },
                          activeColor: primaryColor,
                          inactiveTrackColor: Colors.grey.withOpacity(0.3),
                        ),
                        if (provider.gasPriceNotificationsEnabled) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Alert Threshold',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Slider(
                                        value: provider.gasPriceThreshold,
                                        min: 10,
                                        max: 200,
                                        divisions: 38,
                                        label:
                                            '${provider.gasPriceThreshold.round()} Gwei',
                                        onChanged: (value) {
                                          provider.setGasPriceThreshold(value);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      '${provider.gasPriceThreshold.round()} Gwei',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You will be notified when gas price drops below ${provider.gasPriceThreshold.round()} Gwei',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),

              // Transaction Notifications section
              Text(
                'TRANSACTION NOTIFICATIONS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: theme.colorScheme.surface,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Transaction Status'),
                      subtitle: Text(
                        'Get notified about transaction confirmations and failures',
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                      ),
                      secondary: Icon(
                        Icons.receipt_long,
                        color: primaryColor,
                      ),
                      value: true, // TODO: Implement transaction notifications
                      onChanged: (bool value) {
                        // TODO: Implement transaction notifications
                      },
                      activeColor: primaryColor,
                      inactiveTrackColor: Colors.grey.withOpacity(0.3),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Network Congestion'),
                      subtitle: Text(
                        'Get notified about high network congestion',
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                      ),
                      secondary: Icon(
                        Icons.traffic,
                        color: primaryColor,
                      ),
                      value:
                          true, // TODO: Implement network congestion notifications
                      onChanged: (bool value) {
                        // TODO: Implement network congestion notifications
                      },
                      activeColor: primaryColor,
                      inactiveTrackColor: Colors.grey.withOpacity(0.3),
                    ),
                  ],
                ),
              ),

              // Notification Preferences section
              Text(
                'NOTIFICATION PREFERENCES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: theme.colorScheme.surface,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Sound'),
                      subtitle: Text(
                        'Play sound for notifications',
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                      ),
                      secondary: Icon(
                        Icons.volume_up,
                        color: primaryColor,
                      ),
                      value: true, // TODO: Implement sound preferences
                      onChanged: (bool value) {
                        // TODO: Implement sound preferences
                      },
                      activeColor: primaryColor,
                      inactiveTrackColor: Colors.grey.withOpacity(0.3),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Vibration'),
                      subtitle: Text(
                        'Vibrate for notifications',
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                      ),
                      secondary: Icon(
                        Icons.vibration,
                        color: primaryColor,
                      ),
                      value: true, // TODO: Implement vibration preferences
                      onChanged: (bool value) {
                        // TODO: Implement vibration preferences
                      },
                      activeColor: primaryColor,
                      inactiveTrackColor: Colors.grey.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
