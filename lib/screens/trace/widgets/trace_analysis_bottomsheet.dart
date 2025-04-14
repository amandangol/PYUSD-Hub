import 'package:flutter/material.dart';

class TraceAnalysisBottomSheet extends StatelessWidget {
  final Map<String, dynamic>? aiAnalysis;
  final bool isLoading;
  final String traceType;

  const TraceAnalysisBottomSheet({
    super.key,
    required this.aiAnalysis,
    required this.isLoading,
    required this.traceType,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Trace Analysis',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  if (isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            // Content
            if (isLoading)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Analyzing trace data...'),
                    ],
                  ),
                ),
              )
            else if (aiAnalysis == null)
              const Expanded(
                child: Center(
                  child: Text('No analysis available'),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildQuickInsightsCard(context),
                      const SizedBox(height: 16),
                      _buildDetailedAnalysis(context),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInsightsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Insights',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInsightRow(
              context: context,
              icon: Icons.category,
              title: 'Trace Type',
              content: traceType,
            ),
            const Divider(),
            _buildInsightRow(
              context: context,
              icon: Icons.description,
              title: 'Summary',
              content: aiAnalysis?['summary'] ?? 'No summary available',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedAnalysis(BuildContext context) {
    return Column(
      children: [
        _buildExpandableSection(
          title: 'Technical Details',
          icon: Icons.code,
          content: aiAnalysis?['technicalDetails']?.toString() ?? '',
        ),
        _buildExpandableSection(
          title: 'Insights',
          icon: Icons.lightbulb,
          content: aiAnalysis?['insights']?.toString() ?? '',
        ),
        _buildExpandableSection(
          title: 'Recommendations',
          icon: Icons.recommend,
          content: aiAnalysis?['recommendations']?.toString() ?? '',
        ),
      ],
    );
  }

  Widget _buildInsightRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: color ?? Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return ExpansionTile(
      leading: Icon(icon),
      title: Text(title),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(content),
        ),
      ],
    );
  }
}
