import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';

import '../../../utils/snackbar_utils.dart';
import '../../../widgets/pyusd_components.dart';
import '../provider/news_provider.dart';
import '../../settings/view/pyusd_info_screen.dart';

class NewsExploreScreen extends StatefulWidget {
  const NewsExploreScreen({super.key});

  @override
  State<NewsExploreScreen> createState() => _NewsExploreScreenState();
}

class _NewsExploreScreenState extends State<NewsExploreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().fetchNews();
    });
  }

  Future<void> _launchUrl(String url) async {
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
        message: "Failed to open article: $e",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PyusdAppBar(
        title: 'PYUSD Insights',
        isDarkMode: isDarkMode,
        showLogo: true,
        onRefreshPressed: context.read<NewsProvider>().refresh,
        hasWallet: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<NewsProvider>().refresh(),
        child: CustomScrollView(
          slivers: [
            // News Section Header
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Latest News',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // News List
            Consumer<NewsProvider>(
              builder: (context, newsProvider, child) {
                if (newsProvider.isLoading) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (newsProvider.error != null) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 80,
                            color: colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            newsProvider.error!,
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => newsProvider.refresh(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final filteredNews = newsProvider.filterNews();

                if (filteredNews.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text('No news available'),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final article = filteredNews[index];
                      final publishedAt =
                          DateTime.parse(article['publishedAt']);
                      final title = article['title'].toLowerCase();
                      final description =
                          article['description']?.toLowerCase() ?? '';
                      final content = article['content']?.toLowerCase() ?? '';

                      final isEthereumFocused = title.contains('ethereum') ||
                          description.contains('ethereum') ||
                          content.contains('ethereum');
                      final isPYUSDFocused = title.contains('pyusd') ||
                          description.contains('pyusd') ||
                          content.contains('pyusd') ||
                          title.contains('paypal usd') ||
                          description.contains('paypal usd') ||
                          content.contains('paypal usd');

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _launchUrl(article['url']),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (article['urlToImage'] != null)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                    child: CachedNetworkImage(
                                      imageUrl: article['urlToImage'],
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Center(
                                          child: CircularProgressIndicator(
                                              color: colorScheme.primary)),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                              height: 200,
                                              color: colorScheme
                                                  .surfaceContainerHighest,
                                              child: const Center(
                                                  child: Icon(Icons
                                                      .image_not_supported))),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (isEthereumFocused)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8),
                                              child: Chip(
                                                label: const Text('ETH'),
                                                backgroundColor: Colors.blue
                                                    .withOpacity(0.2),
                                                labelStyle: TextStyle(
                                                    color: Colors.blue.shade700,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          if (isPYUSDFocused)
                                            Chip(
                                              label: const Text('PYUSD'),
                                              backgroundColor:
                                                  Colors.green.withOpacity(0.2),
                                              labelStyle: TextStyle(
                                                  color: Colors.green.shade700,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        article['title'],
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      if (article['description'] != null)
                                        Text(
                                          article['description'],
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (article['source']['name'] != null)
                                            Chip(
                                              label: Text(
                                                  article['source']['name']),
                                              backgroundColor: colorScheme
                                                  .primaryContainer
                                                  .withOpacity(0.3),
                                            ),
                                          Text(
                                            timeago.format(publishedAt),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                    fontStyle:
                                                        FontStyle.italic),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: filteredNews.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// QA Item model
class QAItem {
  final String question;
  final String answer;
  final IconData icon;
  final Color iconColor;

  QAItem({
    required this.question,
    required this.answer,
    required this.icon,
    required this.iconColor,
  });
}
