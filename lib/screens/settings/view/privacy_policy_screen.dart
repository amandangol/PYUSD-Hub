import 'package:flutter/material.dart';
import '../../../widgets/pyusd_components.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PyusdAppBar(
        showLogo: false,
        isDarkMode: isDarkMode,
        title: "Privacy Policy",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Updated: April 2025',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                '1. Information We Collect',
                [
                  '• Wallet addresses and transaction data',
                  '• Device information and usage statistics',
                  '• App preferences and settings',
                  '• Support and feedback communications',
                ],
              ),
              _buildSection(
                context,
                '2. How We Use Your Information',
                [
                  '• To provide and maintain our services',
                  '• To improve user experience and app functionality',
                  '• To communicate with you about updates and support',
                  '• To ensure security and prevent fraud',
                ],
              ),
              _buildSection(
                context,
                '3. Data Security',
                [
                  '• We implement industry-standard security measures',
                  '• Your private keys and recovery phrases are stored locally',
                  '• We never store your private keys on our servers',
                  '• Regular security audits and updates',
                ],
              ),
              _buildSection(
                context,
                '4. Third-Party Services',
                [
                  '• We may use third-party services for analytics',
                  '• These services have their own privacy policies',
                  '• We carefully select partners who respect privacy',
                ],
              ),
              _buildSection(
                context,
                '5. Your Rights',
                [
                  '• Access your personal data',
                  '• Request data deletion',
                  '• Opt-out of data collection',
                  '• Export your data',
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Contact Us',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'If you have any questions about our Privacy Policy, please contact us at:',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'support@pyusd.com',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<String> points) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...points.map((point) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                point,
                style: theme.textTheme.bodyMedium,
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}
