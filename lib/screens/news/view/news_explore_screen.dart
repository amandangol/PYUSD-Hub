import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';

import '../../../utils/snackbar_utils.dart';
import '../../../widgets/pyusd_components.dart';
import '../provider/news_provider.dart';

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

  Widget _buildFilterChips() {
    return Consumer<NewsProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: NewsCategory.values.map((category) {
                final isSelected =
                    provider.selectedCategories.contains(category);
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category.icon,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : category.color.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(category.displayName),
                      ],
                    ),
                    selectedColor: category.color,
                    checkmarkColor: Colors.white,
                    onSelected: (_) => provider.toggleCategory(category),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
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
        title: 'Explore News',
        isDarkMode: isDarkMode,
        showLogo: false,
        onRefreshPressed: context.read<NewsProvider>().refresh,
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () => context.read<NewsProvider>().refresh(),
        child: CustomScrollView(
          slivers: [
            // News Section Header
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Latest News',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Filter Chips
            SliverToBoxAdapter(
              child: _buildFilterChips(),
            ),

            const SliverPadding(
              padding: EdgeInsets.symmetric(vertical: 8),
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
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 64,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No news available for selected categories',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final article = filteredNews[index];
                      final publishedAt =
                          DateTime.parse(article['publishedAt']);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Card(
                          color: theme.colorScheme.surface,
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
