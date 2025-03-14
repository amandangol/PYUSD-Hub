import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/networkcongestion_model.dart';

class StatusCard extends StatelessWidget {
  final NetworkCongestionData congestionData;

  const StatusCard({super.key, required this.congestionData});

  @override
  Widget build(BuildContext context) {
    // Convert Unix timestamp to DateTime
    final lastBlockTime = congestionData.lastBlockTimestamp > 0
        ? DateTime.fromMillisecondsSinceEpoch(
            congestionData.lastBlockTimestamp * 1000)
        : null;

    final lastRefreshed = congestionData.lastRefreshed;

    // Calculate time difference for last block
    final now = DateTime.now();
    final lastBlockDiff =
        lastBlockTime != null ? now.difference(lastBlockTime) : null;
    final lastBlockAgo =
        lastBlockDiff != null ? _formatTimeDifference(lastBlockDiff) : 'N/A';

    // Calculate time difference for last refresh
    final lastRefreshDiff = now.difference(lastRefreshed);
    final lastRefreshAgo = _formatTimeDifference(lastRefreshDiff);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Last Block',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color:
                            lastBlockDiff != null && lastBlockDiff.inMinutes > 2
                                ? Colors.orange
                                : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lastBlockTime != null
                              ? DateFormat('HH:mm:ss').format(lastBlockTime)
                              : 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    lastBlockAgo,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          lastBlockDiff != null && lastBlockDiff.inMinutes > 2
                              ? Colors.orange
                              : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 30,
              width: 1,
              color: Colors.grey.withOpacity(0.3),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Last Refreshed',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.refresh,
                        size: 14,
                        color: lastRefreshDiff.inMinutes > 5
                            ? Colors.orange
                            : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('HH:mm:ss').format(lastRefreshed),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    lastRefreshAgo,
                    style: TextStyle(
                      fontSize: 11,
                      color: lastRefreshDiff.inMinutes > 5
                          ? Colors.orange
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to format time difference
  String _formatTimeDifference(Duration difference) {
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
