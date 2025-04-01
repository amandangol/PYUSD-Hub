import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';
import 'package:pyusd_hub/utils/snackbar_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../provider/trace_provider.dart';
import 'transaction_trace_screen.dart';

class BlockTraceScreen extends StatefulWidget {
  final int blockNumber;

  const BlockTraceScreen({
    super.key,
    required this.blockNumber,
  });

  @override
  State<BlockTraceScreen> createState() => _BlockTraceScreenState();
}

class _BlockTraceScreenState extends State<BlockTraceScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic> _blockData = {};
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _traces = [];
  bool _showOnlyPyusd = false;
  final TextEditingController _searchController = TextEditingController();
  final String _pyusdContractAddress =
      '0x6c3ea9036406852006290770BEdFcAbA0e23A0e8'.toLowerCase();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadBlockData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBlockData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      // Get the TraceProvider
      final traceProvider = Provider.of<TraceProvider>(context, listen: false);

      // Fetch block data with transactions
      final blockResult =
          await traceProvider.getBlockWithTransactions(widget.blockNumber);

      if (!blockResult['success']) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = blockResult['error'] ?? 'Failed to load block data';
        });
        return;
      }

      // Fetch block trace data
      final traceResult = await traceProvider.getBlockTrace(widget.blockNumber);

      if (!mounted) return;

      if (traceResult['success']) {
        // Process block data
        final block = blockResult['block'];

        // Extract transactions
        List<Map<String, dynamic>> txs = [];
        if (block['transactions'] is List) {
          for (var tx in block['transactions']) {
            if (tx is Map<String, dynamic>) {
              txs.add(Map<String, dynamic>.from(tx));
            }
          }
        }

        // Process traces
        List<Map<String, dynamic>> processedTraces = [];
        if (traceResult['fullTrace'] is List) {
          for (var trace in traceResult['fullTrace']) {
            if (trace is Map<String, dynamic>) {
              // Find the transaction hash for this trace
              final txHash = trace['transactionHash'];
              if (txHash != null) {
                processedTraces.add({
                  'txHash': txHash,
                  'trace': trace,
                });
              }
            }
          }
        }

        setState(() {
          _blockData = Map<String, dynamic>.from(block);
          _transactions = txs;
          _traces = processedTraces;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = traceResult['error'] ?? 'Failed to load trace data';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  String _safeToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Block #${widget.blockNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBlockData,
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () async {
              final url = 'https://etherscan.io/block/${widget.blockNumber}';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              } else {
                if (context.mounted) {
                  SnackbarUtil.showSnackbar(
                    context: context,
                    message: 'Could not open Etherscan',
                    isError: true,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading block data...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : _hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_errorMessage, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadBlockData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildBlockInfoCard(),
                    ),
                    SliverToBoxAdapter(
                      child: _buildSearchAndFilter(),
                    ),
                    SliverToBoxAdapter(
                      child: _buildTransactionStats(),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: _buildTransactionsList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildBlockInfoCard() {
    final blockNumber = _blockData['number'] != null
        ? FormatterUtils.parseHexSafely(_safeToString(_blockData['number'])) ??
            widget.blockNumber
        : widget.blockNumber;
    final blockHash = _safeToString(_blockData['hash']);
    final parentHash = _safeToString(_blockData['parentHash']);
    final timestamp = _formatBlockTimestamp(_blockData['timestamp']);
    final miner = _safeToString(_blockData['miner']);
    final gasUsed = _blockData['gasUsed'] != null
        ? FormatterUtils.parseHexSafely(_safeToString(_blockData['gasUsed'])) ??
            0
        : 0;
    final gasLimit = _blockData['gasLimit'] != null
        ? FormatterUtils.parseHexSafely(
                _safeToString(_blockData['gasLimit'])) ??
            0
        : 0;
    final gasPercentage = _calculateGasPercentage();
    final txCount = _transactions.length;

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.storage, color: Colors.blue, size: 28),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Block #$blockNumber',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      timestamp,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    Icons.receipt_long,
                    '$txCount',
                    'Transactions',
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildInfoChip(
                    Icons.local_gas_station,
                    gasPercentage,
                    'Gas Used',
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildInfoChip(
                    Icons.memory,
                    '${gasUsed.toString()} / ${gasLimit.toString()}',
                    'Gas',
                    Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildCopyableRow('Block Hash', blockHash),
            const SizedBox(height: 8),
            _buildCopyableRow('Parent Hash', parentHash),
            const SizedBox(height: 8),
            _buildCopyableRow('Miner', miner),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            FormatterUtils.formatHash(value),
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            SnackbarUtil.showSnackbar(
              context: context,
              message: '$label copied to clipboard',
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by hash, from, or to address',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Show only PYUSD transactions',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Switch(
                value: _showOnlyPyusd,
                onChanged: (value) {
                  setState(() {
                    _showOnlyPyusd = value;
                  });
                },
                activeColor: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionStats() {
    final searchQuery = _searchController.text.toLowerCase();

    // Filter transactions based on search and PYUSD filter
    final filteredTransactions = _transactions.where((tx) {
      final hash = _safeToString(tx['hash']).toLowerCase();
      final from = _safeToString(tx['from']).toLowerCase();
      final to = _safeToString(tx['to']).toLowerCase();
      final isPyusdTx = to == _pyusdContractAddress;

      // Apply PYUSD filter if enabled
      if (_showOnlyPyusd && !isPyusdTx) {
        return false;
      }

      // Apply search filter if there's a query
      if (searchQuery.isNotEmpty) {
        return hash.contains(searchQuery) ||
            from.contains(searchQuery) ||
            to.contains(searchQuery);
      }

      return true;
    }).toList();

    int pyusdCount = _transactions.where((tx) {
      final to = _safeToString(tx['to']).toLowerCase();
      return to == _pyusdContractAddress;
    }).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Showing ${filteredTransactions.length} of ${_transactions.length} transactions',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              if (pyusdCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '$pyusdCount PYUSD transactions',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          if (searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  const Text(
                    'Search: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          searchQuery,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    final searchQuery = _searchController.text.toLowerCase();

    // Filter transactions based on search and PYUSD filter
    final filteredTransactions = _transactions.where((tx) {
      final hash = _safeToString(tx['hash']).toLowerCase();
      final from = _safeToString(tx['from']).toLowerCase();
      final to = _safeToString(tx['to']).toLowerCase();
      final isPyusdTx = to == _pyusdContractAddress;

      // Apply PYUSD filter if enabled
      if (_showOnlyPyusd && !isPyusdTx) {
        return false;
      }

      // Apply search filter if there's a query
      if (searchQuery.isNotEmpty) {
        return hash.contains(searchQuery) ||
            from.contains(searchQuery) ||
            to.contains(searchQuery);
      }

      return true;
    }).toList();

    if (filteredTransactions.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'No transactions found',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search criteria',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              if (_showOnlyPyusd || searchQuery.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showOnlyPyusd = false;
                      _searchController.clear();
                    });
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear filters'),
                ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final tx = filteredTransactions[index];
          final hash = _safeToString(tx['hash']);
          final from = _safeToString(tx['from']);
          final to = _safeToString(tx['to']);
          final value = _safeToString(tx['value']);
          final gasPrice = _safeToString(tx['gasPrice']);
          final isPyusdTx = to.toLowerCase() == _pyusdContractAddress;

          // Find trace for this transaction
          final traceData = _traces.firstWhere(
            (t) => t['txHash'] == hash,
            orElse: () => <String, dynamic>{},
          );

          // Create a unique hero tag for each transaction
          final heroTag = 'block_${widget.blockNumber}_tx_$hash';

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: isPyusdTx
                  ? BorderSide(
                      color: Colors.green.withOpacity(0.5),
                      width: 1.5,
                    )
                  : BorderSide(
                      color: Colors.grey[300]!,
                      width: 0.5,
                    ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransactionTraceScreen(
                      txHash: hash,
                      // heroTag: heroTag,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            FormatterUtils.formatHash(hash),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isPyusdTx)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PYUSD',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'From:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                FormatterUtils.formatAddress(from),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward,
                            size: 16, color: Colors.grey),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'To:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                FormatterUtils.formatAddress(to),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Value: ${FormatterUtils.formatEthFromHex(value)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const Spacer(),
                        Text(
                          'Gas: ${FormatterUtils.formatEthFromHex(gasPrice)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: filteredTransactions.length,
      ),
    );
  }

  String _formatBlockTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      // Parse the timestamp (in seconds)
      int timestampInt;
      if (timestamp is String) {
        timestampInt = FormatterUtils.parseHexSafely(timestamp) ?? 0;
      } else if (timestamp is int) {
        timestampInt = timestamp;
      } else {
        return 'Unknown';
      }

      if (timestampInt == 0) return 'Unknown';

      // Convert seconds to milliseconds
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestampInt * 1000);
      return DateFormat('MMM dd, yyyy HH:mm:ss').format(dateTime);
    } catch (e) {
      print('Error formatting timestamp: $e');
      return 'Unknown';
    }
  }

  // Calculate gas usage percentage
  String _calculateGasPercentage() {
    try {
      final gasUsed = _blockData['gasUsed'];
      final gasLimit = _blockData['gasLimit'];

      if (gasUsed == null || gasLimit == null) return '0%';

      int gasUsedInt;
      int gasLimitInt;

      // Handle different types
      if (gasUsed is String) {
        gasUsedInt = FormatterUtils.parseHexSafely(gasUsed) ?? 0;
      } else if (gasUsed is int) {
        gasUsedInt = gasUsed;
      } else {
        return '0%';
      }

      if (gasLimit is String) {
        gasLimitInt = FormatterUtils.parseHexSafely(gasLimit) ?? 1;
      } else if (gasLimit is int) {
        gasLimitInt = gasLimit;
      } else {
        return '0%';
      }

      if (gasLimitInt == 0) return '0%';

      final percentage = (gasUsedInt / gasLimitInt) * 100;
      return '${percentage.toStringAsFixed(1)}%';
    } catch (e) {
      print('Error calculating gas percentage: $e');
      return '0%';
    }
  }
}
