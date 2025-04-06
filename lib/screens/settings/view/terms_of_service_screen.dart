import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../widgets/pyusd_components.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PyusdAppBar(
        showLogo: kFlutterMemoryAllocationsEnabled,
        isDarkMode: isDarkMode,
        title: "Terms of Service",
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
                '1. Acceptance of Terms',
                [
                  'By using PYUSD Hub, you agree to these Terms of Service.',
                  'If you do not agree, please do not use our services.',
                ],
              ),
              _buildSection(
                context,
                '2. Description of Service',
                [
                  'PYUSD Hub provides a digital wallet for managing PYUSD tokens.',
                  'We offer features for sending, receiving, and managing your crypto assets.',
                  'The service is provided "as is" without warranties of any kind.',
                ],
              ),
              _buildSection(
                context,
                '3. User Responsibilities',
                [
                  'You are responsible for maintaining the security of your wallet.',
                  'Keep your private keys and recovery phrases secure.',
                  'Do not share your private keys with anyone.',
                  'Report any unauthorized access immediately.',
                ],
              ),
              _buildSection(
                context,
                '4. Prohibited Activities',
                [
                  'Illegal or fraudulent activities',
                  'Money laundering or terrorist financing',
                  'Unauthorized access to the service',
                  'Interference with service operations',
                ],
              ),
              _buildSection(
                context,
                '5. Limitation of Liability',
                [
                  'We are not responsible for lost funds due to user error.',
                  'We do not guarantee uninterrupted service.',
                  'We are not liable for third-party services.',
                ],
              ),
              _buildSection(
                context,
                '6. Changes to Terms',
                [
                  'We may update these terms at any time.',
                  'Continued use after changes constitutes acceptance.',
                  'We will notify users of significant changes.',
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
                'If you have any questions about our Terms of Service, please contact us at:',
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
