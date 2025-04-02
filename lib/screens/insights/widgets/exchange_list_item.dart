import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ExchangeListItem extends StatelessWidget {
  final Map<String, dynamic> exchange;
  final bool isCompact;

  const ExchangeListItem({
    super.key,
    required this.exchange,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final String exchangeName = exchange['exchange'] ?? 'Unknown';
    final double volume = _parseDouble(exchange['volume']);
    final double price = _parseDouble(exchange['price']);
    final String pair = exchange['pair'] ?? 'PYUSD/USD';
    final String trustScore = exchange['trust_score'] ?? 'N/A';
    final String logoUrl = exchange['logo_url'] ?? '';
    final String url = exchange['url'] ?? '';

    // Get trust score color
    Color trustScoreColor;
    switch (trustScore.toLowerCase()) {
      case 'green':
        trustScoreColor =
            isDarkMode ? Colors.green.shade400 : Colors.green.shade700;
        break;
      case 'yellow':
        trustScoreColor =
            isDarkMode ? Colors.amber.shade400 : Colors.amber.shade700;
        break;
      case 'red':
        trustScoreColor =
            isDarkMode ? Colors.red.shade400 : Colors.red.shade700;
        break;
      default:
        trustScoreColor = theme.colorScheme.onSurfaceVariant;
    }

    return InkWell(
      onTap: () => _launchExchangeUrl(url, exchangeName),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: theme.colorScheme.surface,
        elevation: isCompact ? 0 : 1,
        margin: isCompact ? EdgeInsets.zero : const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isCompact
              ? BorderSide(color: theme.dividerColor.withOpacity(0.1))
              : BorderSide.none,
        ),
        child: Padding(
          padding: isCompact
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
              : const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildExchangeLogo(exchangeName, logoUrl, theme),
              SizedBox(width: isCompact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          exchangeName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isCompact ? 14 : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (trustScore != 'N/A')
                          Container(
                            width: isCompact ? 8 : 12,
                            height: isCompact ? 8 : 12,
                            decoration: BoxDecoration(
                              color: trustScoreColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: isCompact ? 2 : 4),
                    Text(
                      pair,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: isCompact ? 10 : null,
                      ),
                    ),
                    SizedBox(height: isCompact ? 4 : 8),
                    if (!isCompact)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Vol: \$${_formatNumber(volume)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${price.toStringAsFixed(4)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 14 : null,
                    ),
                  ),
                  SizedBox(height: isCompact ? 2 : 4),
                  if (!isCompact)
                    Text(
                      'Price',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
              if (!isCompact) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: theme.colorScheme.primary.withOpacity(0.7),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchExchangeUrl(String url, String exchangeName) async {
    if (url.isEmpty) {
      // Fallback to a Google search if no URL is available
      url =
          'https://www.google.com/search?q=${Uri.encodeComponent("$exchangeName PYUSD trading")}';
    }

    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Widget _buildExchangeLogo(
      String exchangeName, String logoUrl, ThemeData theme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: logoUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                logoUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildExchangeIcon(exchangeName, theme);
                },
              ),
            )
          : _buildExchangeIcon(exchangeName, theme),
    );
  }

  Widget _buildExchangeIcon(String exchangeName, ThemeData theme) {
    // Default icon if no logo is available
    IconData iconData;

    // Map common exchanges to specific icons
    switch (exchangeName.toLowerCase()) {
      case 'binance':
        iconData = Icons.currency_bitcoin;
        break;
      case 'coinbase':
        iconData = Icons.monetization_on;
        break;
      case 'kraken':
        iconData = Icons.water;
        break;
      case 'kucoin':
        iconData = Icons.currency_exchange;
        break;
      case 'bullish':
        iconData = Icons.trending_up;
        break;
      case 'htx':
        iconData = Icons.currency_yen;
        break;
      case 'curve (ethereum)':
        iconData = Icons.show_chart;
        break;
      case 'uniswap v3 (ethereum)':
        iconData = Icons.swap_horiz;
        break;
      case 'orca':
        iconData = Icons.water;
        break;
      default:
        iconData = Icons.account_balance;
    }

    return Center(
      child: Icon(
        iconData,
        color: theme.colorScheme.primary,
        size: 20,
      ),
    );
  }

  // Helper method to safely parse double values from various types
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  String _formatNumber(double number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(2)}B';
    }
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)}K';
    }
    return number.toStringAsFixed(2);
  }
}
