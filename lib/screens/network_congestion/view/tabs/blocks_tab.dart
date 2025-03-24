import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../widgets/pyusd_components.dart';
import '../../../../utils/formatter_utils.dart';
import '../../../../utils/snackbar_utils.dart';
import '../../../../widgets/common/info_dialog.dart';
import '../../provider/network_congestion_provider.dart';

class BlocksTab extends StatelessWidget {
  final NetworkCongestionProvider provider;

  const BlocksTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Block Information Overview
          _buildBlockInfoOverview(context),

          const SizedBox(height: 16),

          // Recent Blocks List (expanded with more details)
          _buildRecentBlocksSection(expandedView: true),
        ],
      ),
    );
  }

  // Block Information Overview Card
  Widget _buildBlockInfoOverview(BuildContext context) {
    // Get the latest block if available
    final latestBlock =
        provider.recentBlocks.isNotEmpty ? provider.recentBlocks[0] : null;

    // Parse block number
    int blockNumber = 0;
    if (latestBlock != null && latestBlock['number'] != null) {
      final numStr = latestBlock['number'].toString();
      blockNumber = numStr.startsWith('0x')
          ? int.parse(numStr.substring(2), radix: 16)
          : int.tryParse(numStr) ?? 0;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Block Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => InfoDialog.show(
                        context,
                        title: 'Block Information',
                        message:
                            'Overview of the latest block on the Ethereum network, including block number, time, size, and gas usage statistics.',
                      ),
                    ),
                  ],
                ),
                if (blockNumber > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Latest: #$blockNumber',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Block statistics
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildBlockStatCard(
                  context,
                  'Avg Block Time',
                  provider.congestionData.averageBlockTime > 0
                      ? '${provider.congestionData.averageBlockTime.toStringAsFixed(1)} sec'
                      : 'Loading...',
                  Icons.timer,
                  Colors.blue,
                  'Average time between new blocks being added to the blockchain. Target is around 12-15 seconds.',
                ),
                _buildBlockStatCard(
                  context,
                  'Blocks/Hour',
                  provider.congestionData.blocksPerHour > 0
                      ? '~${provider.congestionData.blocksPerHour}'
                      : 'Loading...',
                  Icons.av_timer,
                  Colors.green,
                  'Estimated number of blocks being mined per hour on the Ethereum network.',
                ),
                _buildBlockStatCard(
                  context,
                  'Avg Tx/Block',
                  provider.congestionData.averageTxPerBlock > 0
                      ? '${provider.congestionData.averageTxPerBlock}'
                      : 'Loading...',
                  Icons.sync_alt,
                  Colors.purple,
                  'Average number of transactions included in each block. Higher numbers indicate increased network activity.',
                ),
                _buildBlockStatCard(
                  context,
                  'Gas Limit',
                  provider.congestionData.gasLimit > 0
                      ? '${(provider.congestionData.gasLimit / 1000000).toStringAsFixed(1)}M'
                      : 'Loading...',
                  Icons.local_gas_station,
                  Colors.orange,
                  'Maximum amount of gas that can be used in a single block. This is a network parameter that can be adjusted.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Block Statistics Card
  Widget _buildBlockStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String infoMessage,
  ) {
    return GestureDetector(
      onTap: () => InfoDialog.show(
        context,
        title: title,
        message: infoMessage,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.info_outline,
                        size: 12,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Recent Blocks List
  Widget _buildRecentBlocksSection({bool expandedView = false}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Blocks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            provider.recentBlocks.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No recent blocks detected',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemCount: expandedView
                        ? provider.recentBlocks.length
                        : (provider.recentBlocks.length > 3
                            ? 3
                            : provider.recentBlocks.length),
                    itemBuilder: (context, index) {
                      final block = provider.recentBlocks[index];

                      // Parse block data
                      final blockNumberHex =
                          block['number'] as String? ?? '0x0';
                      final blockNumber =
                          int.parse(blockNumberHex.substring(2), radix: 16);

                      // Parse timestamp
                      final timestampHex =
                          block['timestamp'] as String? ?? '0x0';
                      final timestamp =
                          int.parse(timestampHex.substring(2), radix: 16);
                      final blockTime =
                          DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

                      // Parse transactions
                      final transactions =
                          block['transactions'] as List<dynamic>? ?? [];

                      // Parse gas used and gas limit
                      final gasUsedHex = block['gasUsed'] as String? ?? '0x0';
                      final gasLimitHex = block['gasLimit'] as String? ?? '0x0';
                      final gasUsed =
                          int.parse(gasUsedHex.substring(2), radix: 16);
                      final gasLimit =
                          int.parse(gasLimitHex.substring(2), radix: 16);

                      // Calculate utilization
                      final utilization = (gasUsed / gasLimit) * 100;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#$blockNumber',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('HH:mm:ss').format(blockTime),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${transactions.length} txs',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        subtitle: expandedView
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text(
                                        'Miner: ',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        FormatterUtils.formatAddress(
                                            '${(block['miner'] as String?)}'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Gas Usage',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            const SizedBox(height: 4),
                                            LinearProgressIndicator(
                                              value: utilization / 100,
                                              backgroundColor: Colors.grey[200],
                                              minHeight: 6,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                utilization > 90
                                                    ? Colors.red
                                                    : utilization > 70
                                                        ? Colors.orange
                                                        : Colors.green,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${utilization.toStringAsFixed(1)}% (${(gasUsed / 1000000).toStringAsFixed(2)}M/${(gasLimit / 1000000).toStringAsFixed(2)}M)',
                                              style:
                                                  const TextStyle(fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_new, size: 18),
                          onPressed: () async {
                            // Open block explorer to view block details
                            final url = Uri.parse(
                                'https://etherscan.io/block/$blockNumber');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            } else {
                              throw 'Could not launch $url';
                            }
                          },
                        ),
                        onTap: () {
                          // Show block details
                          _showBlockDetailsBottomSheet(context, block);
                        },
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  void _showBlockDetailsBottomSheet(
      BuildContext context, Map<String, dynamic> block) {
    // Parse block data
    final blockNumberHex = block['number'] as String? ?? '0x0';
    final blockNumber = int.parse(blockNumberHex.substring(2), radix: 16);

    // Parse timestamp
    final timestampHex = block['timestamp'] as String? ?? '0x0';
    final timestamp = int.parse(timestampHex.substring(2), radix: 16);
    final blockTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

    // Parse gas and size information
    final gasUsedHex = block['gasUsed'] as String? ?? '0x0';
    final gasLimitHex = block['gasLimit'] as String? ?? '0x0';
    final gasUsed = int.parse(gasUsedHex.substring(2), radix: 16);
    final gasLimit = int.parse(gasLimitHex.substring(2), radix: 16);
    final utilization = (gasUsed / gasLimit) * 100;

    // Get the miner (validator)
    final miner = block['miner'] as String? ?? '0x0';

    // Get transaction list
    final transactions = block['transactions'] as List<dynamic>? ?? [];

    // Theme colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final dividerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    const accentColor = Colors.blue;
    final utilColor = utilization > 90
        ? Colors.red
        : utilization > 70
            ? Colors.orange
            : Colors.green;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Draggable handle indicator
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: dividerColor,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),

                  // Header with block number and time
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.dashboard_rounded,
                                size: 16,
                                color: accentColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Block #$blockNumber',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            DateFormat('yyyy-MM-dd HH:mm:ss').format(blockTime),
                            style: TextStyle(
                              fontSize: 14,
                              color: subtitleColor,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Close',
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Divider(height: 1, thickness: 1, color: dividerColor),

                  // Content - Scrollable
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      children: [
                        // Quick stats cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildEnhancedStatCard(
                                context: context,
                                title: 'Transactions',
                                value: '${transactions.length}',
                                icon: Icons.sync_alt_rounded,
                                color: accentColor,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildEnhancedStatCard(
                                context: context,
                                title: 'Gas Used',
                                value: '${utilization.toStringAsFixed(1)}%',
                                icon: Icons.local_gas_station_rounded,
                                color: utilColor,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Block hash with copyable field
                        _buildEnhancedDetailRow(
                          context: context,
                          label: 'Block Hash',
                          value: FormatterUtils.formatHash(block['hash'] ?? ''),
                          icon: Icons.tag_rounded,
                          isMonospace: true,
                          canCopy: true,
                          valueToCopy: block['hash'] ?? '',
                          isDark: isDark,
                        ),
                        Divider(height: 24, color: dividerColor),

                        // Parent hash with copyable field
                        _buildEnhancedDetailRow(
                          context: context,
                          label: 'Parent Hash',
                          value: FormatterUtils.formatHash(
                              block['parentHash'] ?? ''),
                          icon: Icons.link_rounded,
                          isMonospace: true,
                          canCopy: true,
                          valueToCopy: block['parentHash'] ?? '',
                          isDark: isDark,
                        ),
                        Divider(height: 24, color: dividerColor),

                        // Miner address with copyable field
                        _buildEnhancedDetailRow(
                          context: context,
                          label: 'Miner (Validator)',
                          value: FormatterUtils.formatAddress(miner),
                          icon: Icons.account_balance_wallet_rounded,
                          isMonospace: true,
                          canCopy: true,
                          valueToCopy: miner,
                          isDark: isDark,
                          onTap: () async {
                            final url = Uri.parse(
                                'https://etherscan.io/address/$miner');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                        ),
                        Divider(height: 24, color: dividerColor),

                        // Gas information with progress bar
                        _buildEnhancedDetailRow(
                          context: context,
                          label: 'Gas Used / Gas Limit',
                          value:
                              '${(gasUsed / 1000000).toStringAsFixed(2)}M / ${(gasLimit / 1000000).toStringAsFixed(2)}M',
                          icon: Icons.local_gas_station_rounded,
                          isDark: isDark,
                          additionalWidget: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 12,
                                      width: double.infinity,
                                      color: isDark
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: utilization / 100,
                                      child: Container(
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: utilColor,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Utilization: ${utilization.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: utilColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                        Divider(height: 24, color: dividerColor),

                        // Additional block details - Expandable section
                        Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                            listTileTheme: ListTileThemeData(
                              dense: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[900]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                title: Text(
                                  'Additional Block Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                leading: const Icon(
                                  Icons.info_outline_rounded,
                                  color: accentColor,
                                ),
                                childrenPadding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                expandedCrossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _buildEnhancedDetailRow(
                                    context: context,
                                    label: 'Difficulty',
                                    value: block['difficulty'] != null
                                        ? _formatBigNumber(int.parse(
                                            block['difficulty']
                                                    .toString()
                                                    .startsWith('0x')
                                                ? block['difficulty']
                                                    .toString()
                                                    .substring(2)
                                                : block['difficulty']
                                                    .toString(),
                                            radix: 16))
                                        : 'N/A',
                                    icon: Icons.trending_up_rounded,
                                    isDark: isDark,
                                    iconSize: 16,
                                    noBackground: true,
                                  ),
                                  Divider(
                                      height: 16,
                                      color: dividerColor.withOpacity(0.5)),
                                  _buildEnhancedDetailRow(
                                    context: context,
                                    label: 'Size',
                                    value: block['size'] != null
                                        ? '${(int.parse(block['size'].toString().substring(2), radix: 16) / 1024).toStringAsFixed(2)} KB'
                                        : 'N/A',
                                    icon: Icons.data_usage_rounded,
                                    isDark: isDark,
                                    iconSize: 16,
                                    noBackground: true,
                                  ),
                                  Divider(
                                      height: 16,
                                      color: dividerColor.withOpacity(0.5)),
                                  _buildEnhancedDetailRow(
                                    context: context,
                                    label: 'Base Fee',
                                    value: block['baseFeePerGas'] != null
                                        ? '${(int.parse(block['baseFeePerGas'].toString().substring(2), radix: 16) / 1e9).toStringAsFixed(2)} Gwei'
                                        : 'N/A',
                                    icon: Icons.attach_money_rounded,
                                    isDark: isDark,
                                    iconSize: 16,
                                    noBackground: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Transactions section header
                        Row(
                          children: [
                            const Icon(
                              Icons.receipt_long_rounded,
                              color: accentColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Transactions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${transactions.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Show transactions or empty state
                        transactions.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey[900]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.grey[800]!
                                        : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.hourglass_empty_rounded,
                                      size: 48,
                                      color: isDark
                                          ? Colors.grey[700]
                                          : Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No transactions in this block',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey[500]
                                            : Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  // Show first 5 transactions
                                  ...transactions.take(3).map((tx) {
                                    final txHash = tx['hash'] as String? ?? '';
                                    final from = tx['from'] as String? ?? '';
                                    final to = tx['to'] as String? ?? '';

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.grey[800]!
                                              : Colors.grey[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          onTap: () async {
                                            // Close this sheet and show transaction details
                                            Navigator.pop(context);
                                            // Future implementation for showing transaction details
                                            _showAllTransactionsDialog(context,
                                                transactions, blockNumber);

                                            // For now, just launch etherscan
                                            final url = Uri.parse(
                                                'https://etherscan.io/tx/$txHash');
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(url);
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.paid_rounded,
                                                      size: 16,
                                                      color: accentColor,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        FormatterUtils
                                                            .formatHash(txHash),
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'monospace',
                                                          fontSize: 14,
                                                          color: textColor,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons
                                                            .open_in_new_rounded,
                                                        size: 16,
                                                        color: subtitleColor,
                                                      ),
                                                      onPressed: () async {
                                                        final url = Uri.parse(
                                                            'https://etherscan.io/tx/$txHash');
                                                        if (await canLaunchUrl(
                                                            url)) {
                                                          await launchUrl(url);
                                                        }
                                                      },
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(),
                                                      tooltip:
                                                          'View on Etherscan',
                                                    ),
                                                  ],
                                                ),
                                                if (from.isNotEmpty ||
                                                    to.isNotEmpty)
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                            top: 8),
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: isDark
                                                          ? Colors.grey[850]
                                                          : Colors.grey[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        if (from.isNotEmpty)
                                                          Row(
                                                            children: [
                                                              Text(
                                                                'From: ',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      subtitleColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  FormatterUtils
                                                                      .formatAddress(
                                                                          from),
                                                                  style:
                                                                      TextStyle(
                                                                    fontFamily:
                                                                        'monospace',
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        textColor,
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                              IconButton(
                                                                icon: Icon(
                                                                  Icons
                                                                      .copy_rounded,
                                                                  size: 14,
                                                                  color:
                                                                      subtitleColor,
                                                                ),
                                                                onPressed: () {
                                                                  Clipboard.setData(
                                                                      ClipboardData(
                                                                          text:
                                                                              from));
                                                                  SnackbarUtil.showSnackbar(
                                                                      context:
                                                                          context,
                                                                      message:
                                                                          "Address copied to clipboard");
                                                                },
                                                                visualDensity:
                                                                    VisualDensity
                                                                        .compact,
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                constraints:
                                                                    const BoxConstraints(),
                                                              ),
                                                            ],
                                                          ),
                                                        if (from.isNotEmpty &&
                                                            to.isNotEmpty)
                                                          Divider(
                                                            height: 10,
                                                            color: dividerColor
                                                                .withOpacity(
                                                                    0.5),
                                                          ),
                                                        if (to.isNotEmpty)
                                                          Row(
                                                            children: [
                                                              Text(
                                                                'To:   ',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      subtitleColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  FormatterUtils
                                                                      .formatAddress(
                                                                          to),
                                                                  style:
                                                                      TextStyle(
                                                                    fontFamily:
                                                                        'monospace',
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        textColor,
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                              IconButton(
                                                                icon: Icon(
                                                                  Icons
                                                                      .copy_rounded,
                                                                  size: 14,
                                                                  color:
                                                                      subtitleColor,
                                                                ),
                                                                onPressed: () {
                                                                  Clipboard.setData(
                                                                      ClipboardData(
                                                                          text:
                                                                              to));
                                                                  SnackbarUtil.showSnackbar(
                                                                      context:
                                                                          context,
                                                                      message:
                                                                          "Address copied to clipboard");
                                                                },
                                                                visualDensity:
                                                                    VisualDensity
                                                                        .compact,
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                constraints:
                                                                    const BoxConstraints(),
                                                                tooltip:
                                                                    'Copy address',
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
                                      ),
                                    );
                                  }),

                                  // "View all" button if more than 5 transactions
                                  if (transactions.length > 5)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12.0),
                                      child: PyusdButton(
                                        onPressed: () {
                                          // Close current sheet and show all transactions
                                          Navigator.pop(context);
                                          _showAllTransactionsDialog(context,
                                              transactions, blockNumber);
                                        },
                                        text:
                                            'View all ${transactions.length} transactions',
                                        icon:
                                            const Icon(Icons.list_alt_rounded),
                                        backgroundColor: accentColor,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                      ],
                    ),
                  ),

                  // Footer with action buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.grey[100],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, -2),
                        ),
                      ],
                      border: Border(
                        top: BorderSide(color: dividerColor),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Copy Block Hash'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: accentColor,
                              side: const BorderSide(color: accentColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              final hash = block['hash'] as String? ?? '';
                              Clipboard.setData(ClipboardData(text: hash));
                              SnackbarUtil.showSnackbar(
                                  context: context,
                                  message: 'Block hash copied to clipboard');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('View on Etherscan'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: accentColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              final url = Uri.parse(
                                  'https://etherscan.io/block/$blockNumber');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

// Enhanced stat card for quick overview
  Widget _buildEnhancedStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Enhanced detail row for block information
  Widget _buildEnhancedDetailRow({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
    bool isMonospace = false,
    bool canCopy = false,
    String valueToCopy = '',
    double iconSize = 20,
    bool noBackground = false,
    VoidCallback? onTap,
    Widget? additionalWidget,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    const accentColor = Colors.blue;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!noBackground)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accentColor, size: iconSize),
                  )
                else
                  Icon(icon, color: accentColor, size: iconSize),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          fontFamily: isMonospace ? 'monospace' : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (canCopy)
                  IconButton(
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: subtitleColor,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: valueToCopy));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: accentColor,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Copy to clipboard',
                  ),
              ],
            ),
            if (additionalWidget != null) additionalWidget,
          ],
        ),
      ),
    );
  }

// Format large numbers with commas
  String _formatBigNumber(int number) {
    final formatter = NumberFormat.decimalPattern();
    return formatter.format(number);
  }

// Show all transactions in a full-screen dialog
  void _showAllTransactionsDialog(
    BuildContext context,
    List<dynamic> transactions,
    int blockNumber,
  ) {
    // Theme colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final dividerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    const accentColor = Colors.blue;

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: Text('Block #$blockNumber Transactions'),
            backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () async {
                  final url =
                      Uri.parse('https://etherscan.io/block/$blockNumber');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                tooltip: 'View on Etherscan',
              ),
            ],
          ),
          body: Column(
            children: [
              // Transactions count header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Transactions (${transactions.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // Transactions list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final txHash = tx['hash'] as String? ?? '';
                    final from = tx['from'] as String? ?? '';
                    final to = tx['to'] as String? ?? '';

                    // Parse gas price and value if available
                    final gasPrice = tx['gasPrice'] != null
                        ? '${(int.parse(tx['gasPrice'].toString().substring(2), radix: 16) / 1e9).toStringAsFixed(2)} Gwei'
                        : 'N/A';

                    final value = tx['value'] != null
                        ? '${(int.parse(tx['value'].toString().substring(2), radix: 16) / 1e18).toStringAsFixed(6)} ETH'
                        : '0 ETH';

                    return Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final url =
                                Uri.parse('https://etherscan.io/tx/$txHash');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Transaction hash
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: accentColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.receipt_rounded,
                                          color: accentColor, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Transaction Hash',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: subtitleColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  FormatterUtils.formatHash(
                                                      txHash),
                                                  style: TextStyle(
                                                    fontFamily: 'monospace',
                                                    fontSize: 14,
                                                    color: textColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.copy,
                                                    size: 16),
                                                onPressed: () {
                                                  Clipboard.setData(
                                                      ClipboardData(
                                                          text: txHash));
                                                  SnackbarUtil.showSnackbar(
                                                    context: context,
                                                    message:
                                                        "Transaction hash copied to clipboard",
                                                  );
                                                },
                                                visualDensity:
                                                    VisualDensity.compact,
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                tooltip:
                                                    'Copy transaction hash',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),
                                Divider(height: 1, color: dividerColor),
                                const SizedBox(height: 12),

                                // From address
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        'From',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: subtitleColor,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        FormatterUtils.formatAddress(from),
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 14,
                                          color: textColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 16),
                                      onPressed: () {
                                        Clipboard.setData(
                                            ClipboardData(text: from));
                                        SnackbarUtil.showSnackbar(
                                          context: context,
                                          message:
                                              "Address copied to clipboard",
                                        );
                                      },
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Copy address',
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // To address
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        'To',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: subtitleColor,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        to.isEmpty
                                            ? '(Contract Creation)'
                                            : FormatterUtils.formatAddress(to),
                                        style: TextStyle(
                                          fontFamily:
                                              to.isEmpty ? null : 'monospace',
                                          fontSize: 14,
                                          fontStyle: to.isEmpty
                                              ? FontStyle.italic
                                              : FontStyle.normal,
                                          color: textColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (to.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 16),
                                        onPressed: () {
                                          Clipboard.setData(
                                              ClipboardData(text: to));
                                          SnackbarUtil.showSnackbar(
                                            context: context,
                                            message:
                                                "Address copied to clipboard",
                                          );
                                        },
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Copy address',
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 12),
                                Divider(height: 1, color: dividerColor),
                                const SizedBox(height: 12),

                                // Transaction details
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Value',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: subtitleColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            value,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Gas Price',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: subtitleColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            gasPrice,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // View on Etherscan button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.open_in_new,
                                          size: 16),
                                      label: const Text('View on Etherscan'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: accentColor,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () async {
                                        final url = Uri.parse(
                                            'https://etherscan.io/tx/$txHash');
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
