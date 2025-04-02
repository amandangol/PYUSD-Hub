import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/pyusd_components.dart';
import '../provider/trace_provider.dart';
import '../widgets/trace_widgets.dart';
import 'trace_screen.dart';

class TraceHomeScreen extends StatelessWidget {
  const TraceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final traceProvider = Provider.of<TraceProvider>(context);
    final recentTraces = traceProvider.recentTraces;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PyusdAppBar(
        title: 'PYUSD Tracer',
        isDarkMode: isDarkMode,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              _buildHeaderSection(context, theme),
              const SizedBox(height: 24),

              // Main features section
              Text(
                'Tracing Features',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Transaction Tracing Card
              _buildFeatureCard(
                context: context,
                title: 'Transaction Tracing',
                description:
                    'Analyze the execution of any transaction on the Ethereum network. See internal calls, state changes, and PYUSD transfers.',
                icon: Icons.receipt_long,
                color: Colors.blue,
                onTap: () => _navigateToTraceScreen(context, 0),
              ),

              // Block Tracing Card
              _buildFeatureCard(
                context: context,
                title: 'Block Tracing',
                description:
                    'Examine all transactions in a specific block. Useful for analyzing network activity during specific time periods.',
                icon: Icons.storage,
                color: Colors.green,
                onTap: () => _navigateToTraceScreen(context, 1),
              ),

              // Advanced Tracing Card
              _buildFeatureCard(
                context: context,
                title: 'Advanced Tracing',
                description:
                    'Use specialized GCP tracing methods like raw transaction tracing, replay transactions, and storage inspection.',
                icon: Icons.science,
                color: Colors.purple,
                onTap: () => _navigateToTraceScreen(context, 2),
              ),

              // Recent Activity Section
              if (recentTraces.isNotEmpty) ...[
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Traces',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton(
                      onPressed: () => _navigateToTraceScreen(context, 3),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildRecentTracesPreview(context, recentTraces, isDarkMode),
              ],

              // Documentation Section
              const SizedBox(height: 16),
              _buildDocumentationSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  theme.colorScheme.primary.withOpacity(0.2),
                  theme.colorScheme.primary.withOpacity(0.05),
                ]
              : [
                  theme.colorScheme.primary.withOpacity(0.1),
                  theme.colorScheme.primary.withOpacity(0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_tree_outlined,
                  color: theme.colorScheme.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'PYUSD Blockchain Tracer',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Analyze transactions, trace blocks, and inspect PYUSD transfers on the Ethereum blockchain with powerful tracing tools.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TraceButton(
            text: 'Explore Tracing Tools',
            onPressed: () => _navigateToTraceScreen(context, 0),
            backgroundColor: theme.colorScheme.primary.withOpacity(0.5),
            icon: Icons.explore,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTracesPreview(
    BuildContext context,
    List<Map<String, dynamic>> recentTraces,
    bool isDarkMode,
  ) {
    // Show only the 3 most recent traces
    final traces = recentTraces.take(3).toList();
    final theme = Theme.of(context);

    return Column(
      children: traces.map((trace) {
        final String type = trace['type'] ?? 'unknown';
        final DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(
          trace['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
        );

        IconData icon;
        String title;
        String subtitle;

        if (type == 'transaction') {
          icon = Icons.receipt_long;
          title = 'Transaction Trace';
          subtitle = 'Hash: ${_truncateHash(trace['hash'] ?? 'Unknown')}';
        } else if (type == 'block') {
          icon = Icons.storage;
          title = 'Block Trace';
          subtitle = 'Block: ${trace['blockNumber'] ?? 'Unknown'}';
        } else if (type == 'txReplay') {
          icon = Icons.replay;
          title = 'Transaction Replay';
          subtitle = 'Hash: ${_truncateHash(trace['hash'] ?? 'Unknown')}';
        } else if (type == 'blockReplay') {
          icon = Icons.replay_circle_filled;
          title = 'Block Replay';
          subtitle = 'Block: ${trace['blockNumber'] ?? 'Unknown'}';
        } else {
          icon = Icons.code;
          title = 'Advanced Trace';
          subtitle = 'Custom trace operation';
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '$subtitle • ${_formatTimeAgo(timestamp)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
          onTap: () => _navigateToTraceScreen(context, 3),
        );
      }).toList(),
    );
  }

  Widget _buildDocumentationSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FYI',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 3),
            ),
            const SizedBox(height: 12),
            _buildDocItem(
              context: context,
              title: 'What is transaction tracing?',
              description:
                  'Transaction tracing allows you to see the step-by-step execution of a transaction, including all internal calls and state changes.',
            ),
            const Divider(),
            _buildDocItem(
              context: context,
              title: 'When to use block tracing?',
              description:
                  'Block tracing is useful when you want to analyze all transactions in a specific block, especially during high network activity periods.',
            ),
            const Divider(),
            _buildDocItem(
              context: context,
              title: 'Advanced tracing capabilities',
              description:
                  'Advanced tracing provides specialized methods for detailed blockchain analysis, including raw transaction tracing and storage inspection.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocItem({
    required BuildContext context,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTraceScreen(BuildContext context, int tabIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TraceScreen(initialTabIndex: tabIndex),
      ),
    );
  }

  String _truncateHash(String hash) {
    if (hash.length <= 10) return hash;
    return '${hash.substring(0, 6)}...${hash.substring(hash.length - 4)}';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
