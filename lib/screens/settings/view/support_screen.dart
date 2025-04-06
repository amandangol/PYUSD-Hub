import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../widgets/pyusd_components.dart';
import '../../../utils/snackbar_utils.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PyusdAppBar(
        showLogo: false,
        isDarkMode: isDarkMode,
        title: "Support",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How can we help you?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildSupportCard(
                context,
                'FAQ',
                'Find answers to common questions',
                Icons.help_outline,
                () {
                  // Navigate to FAQ screen
                  SnackbarUtil.showSnackbar(
                    context: context,
                    message: "FAQ section coming soon",
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSupportCard(
                context,
                'Contact Support',
                'Get in touch with our support team',
                Icons.support_agent,
                () {
                  _launchUrl(context, 'mailto:icrextha@gmail.com');
                },
              ),
              const SizedBox(height: 16),
              _buildSupportCard(
                context,
                'Documentation',
                'Read our detailed guides and documentation',
                Icons.menu_book,
                () {
                  _launchUrl(
                      context, 'https://github.com/amandangol/PYUSD-Hub');
                },
              ),
              const SizedBox(height: 16),
              _buildSupportCard(
                context,
                'Report a Bug',
                'Help us improve by reporting issues',
                Icons.bug_report,
                () {
                  _launchUrl(context,
                      'https://github.com/amandangol/PYUSD-Hub/issues');
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Community Support',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildCommunityCard(
                context,
                'Discord',
                'Join our community on Discord',
                'https://discord.gg/4m.4n',
                'assets/icon/discord_icon.svg',
                Colors.indigo,
              ),
              const SizedBox(height: 16),
              _buildCommunityCard(
                context,
                'Twitter',
                'Follow us for updates and announcements',
                'https://twitter.com/amand4ngol',
                'assets/icon/x_icon.svg',
                Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildCommunityCard(
                context,
                'GitHub',
                'Contribute to our open-source project',
                'https://github.com/amandangol/PYUSD-Hub',
                'assets/icon/github_icon.svg',
                Colors.black,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 28,
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildCommunityCard(
    BuildContext context,
    String title,
    String subtitle,
    String url,
    String svgImage,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: SvgPicture.asset(
          svgImage,
          width: 28,
          height: 28,
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        onTap: () => _launchUrl(context, url),
      ),
    );
  }
}
