import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/pyusd_components.dart';
import '../provider/trace_provider.dart';
import 'trace_screen.dart';

class TraceHomeScreen extends StatelessWidget {
  const TraceHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final traceProvider = Provider.of<TraceProvider>(context);
    final recentTraces = traceProvider.recentTraces;

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
              _buildHeaderSection(context),
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

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_tree_outlined,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'PYUSD Blockchain Tracer',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Analyze transactions, trace blocks, and inspect PYUSD transfers on the Ethereum blockchain with powerful tracing tools.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 16),
          TraceButton(
            text: 'Explore Tracing Tools',
            onPressed: () => _navigateToTraceScreen(context, 0),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            icon: Icons.explore,
            borderRadius: 12,
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
                      style: const TextStyle(
                        fontSize: 18,
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
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 14,
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
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          title: Text(title),
          subtitle: Text(
            '$subtitle • ${_formatTimeAgo(timestamp)}',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.black54,
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
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documentation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black87,
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
