import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../provider/network_congestion_provider.dart';

class DataSourceInfoCard extends StatelessWidget {
  const DataSourceInfoCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NetworkCongestionProvider>(context);
    final dataSourceInfo = provider.getDataSourceInfo();
    final lastUpdateTimes = provider.getLastUpdateTimes();
    final confidenceLevels = provider.getMetricConfidence();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text(
            'Data Sources & Accuracy',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Last updated ${timeago.format(lastUpdateTimes['lastRefreshed']!)}',
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height *
                  0.5, // 50% of screen height
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  _buildDataSourceSection(dataSourceInfo),
                  _buildUpdateTimesSection(lastUpdateTimes),
                  _buildConfidenceSection(confidenceLevels, context),
                  const SizedBox(height: 8), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSourceSection(Map<String, String> dataSourceInfo) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Sources',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...dataSourceInfo.entries
              .where((entry) =>
                  !entry.key.contains('Update Frequency') &&
                  !entry.key.contains('Data Accuracy'))
              .map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(entry.value),
                        ),
                      ],
                    ),
                  )),
          const Divider(),
          const Text(
            'Update Frequency',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(dataSourceInfo['Update Frequency'] ?? ''),
          const Divider(),
          const Text(
            'Data Accuracy',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(dataSourceInfo['Data Accuracy'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildUpdateTimesSection(Map<String, DateTime> lastUpdateTimes) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last Update Times',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...lastUpdateTimes.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(timeago.format(entry.value)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildConfidenceSection(
      Map<String, double> confidenceLevels, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Confidence Levels',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...confidenceLevels.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: entry.value,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getConfidenceColor(entry.value),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(entry.value * 100).toStringAsFixed(1)}% confidence',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
