import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';
import 'package:pyusd_hub/utils/snackbar_utils.dart';
import 'package:intl/intl.dart';
import '../../../widgets/pyusd_components.dart';
import '../provider/trace_provider.dart';
import '../widgets/trace_widgets.dart';
import 'transaction_trace_screen.dart';
import '../../../providers/gemini_provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../widgets/loading_overlay.dart';

class BlockTraceScreen extends StatefulWidget {
  final int blockNumber;
  final String? heroTag;

  const BlockTraceScreen({
    super.key,
    required this.blockNumber,
    this.heroTag,
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
  bool _isAiAnalysisLoading = false;
  Map<String, dynamic> _aiAnalysis = {};
  bool _showAiAnalysis = false;
  final List<Map<String, dynamic>> _mevResults = [];
  bool _isAnalyzing = false;

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return LoadingOverlay(
      isLoading: _isLoading,
      loadingText: 'Loading block trace data...',
      body: Scaffold(
        appBar: CustomAppBar(
          title: 'Block Number: ${widget.blockNumber}',
          isDarkMode: isDarkMode,
          onBackPressed: () => Navigator.pop(context),
          onRefreshPressed: _loadBlockData,
          actions: [
            IconButton(
              icon: const Icon(Icons.psychology),
              tooltip: 'AI Analysis',
              onPressed: _isLoading ? null : _getAiAnalysis,
            ),
          ],
        ),
        body: _hasError
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
                      TraceButton(
                        text: 'Retry',
                        onPressed: _loadBlockData,
                        backgroundColor: Colors.blue,
                        icon: Icons.refresh,
                      ),
                    ],
                  ),
                ),
              )
            : _buildBlockContent(),
      ),
    );
  }

  Widget _buildBlockContent() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildBlockInfoCard(),
        ),
        if (_showAiAnalysis)
          SliverToBoxAdapter(
            child: _buildAiAnalysisCard(),
          ),
        SliverToBoxAdapter(
          child: _buildMEVAnalysisCard(),
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
            const Divider(height: 8),
            _buildCopyableRow('Parent Hash', parentHash),
            const Divider(height: 8),
            _buildCopyableRow('Miner', miner),
            const Divider(height: 8),
            TraceButton(
              text: 'Copy to Clipboard',
              onPressed: () {
                final blockJson = FormatterUtils.formatJson(_blockData);
                Clipboard.setData(ClipboardData(text: blockJson));
                SnackbarUtil.showSnackbar(
                  context: context,
                  message: 'Block data copied to clipboard',
                );
              },
              backgroundColor: Colors.blue,
              icon: Icons.copy,
              horizontalPadding: 12,
              verticalPadding: 8,
            ),
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      // Refresh the filtered list
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              TraceButton(
                text: 'PYUSD Only',
                onPressed: () {
                  setState(() {
                    _showOnlyPyusd = !_showOnlyPyusd;
                  });
                },
                backgroundColor: _showOnlyPyusd ? Colors.green : Colors.grey,
                icon: Icons.filter_list,
                horizontalPadding: 12,
                verticalPadding: 8,
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
                      heroTag: heroTag,
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

  Future<void> _getAiAnalysis() async {
    setState(() {
      _isAiAnalysisLoading = true;
      _showAiAnalysis = true;
    });

    try {
      final geminiProvider =
          Provider.of<GeminiProvider>(context, listen: false);

      // Prepare data for analysis
      final blockData = {
        'blockNumber': widget.blockNumber,
        'blockHash': _blockData['hash'],
        'timestamp': _blockData['timestamp'],
        'gasUsed': _blockData['gasUsed'],
        'gasLimit': _blockData['gasLimit'],
        'transactionCount': _transactions.length,
        'miner': _blockData['miner'],
      };

      // Get PYUSD transactions
      final pyusdTransactions = _transactions.where((tx) {
        final to = _safeToString(tx['to']).toLowerCase();
        return to == _pyusdContractAddress;
      }).toList();

      final analysis = await geminiProvider.analyzeBlockStructured(
        blockData,
        _transactions
            .take(10)
            .toList(), // Send first 10 transactions for analysis
        pyusdTransactions,
        _traces.take(10).toList(), // Send first 10 traces for analysis
      );

      if (!mounted) return;

      setState(() {
        _isAiAnalysisLoading = false;
        _aiAnalysis = analysis;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isAiAnalysisLoading = false;
        _aiAnalysis = {
          "summary": "Error generating AI analysis",
          "error": true,
          "errorMessage": e.toString()
        };
      });
    }
  }

  Widget _buildAiAnalysisCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    const accentColor = Colors.purple;

    return Card(
      elevation: 3,
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
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI Block Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_showAiAnalysis)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isAiAnalysisLoading ? null : _getAiAnalysis,
                    tooltip: 'Refresh Analysis',
                  ),
              ],
            ),
            const Divider(height: 24),
            if (!_showAiAnalysis)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Image.asset(
                      'assets/images/geminilogo.png',
                      height: 48,
                      width: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Get an AI-powered analysis of this block',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our AI will analyze the block data and provide insights',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TraceButton(
                      text: 'Analyze with AI',
                      onPressed: _getAiAnalysis,
                      icon: Icons.auto_awesome,
                      backgroundColor: Colors.blue.withOpacity(0.8),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              )
            else if (_isAiAnalysisLoading)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Analyzing block...',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'This may take a few moments',
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              )
            else if (_aiAnalysis.containsKey('error') &&
                _aiAnalysis['error'] == true)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error analyzing block',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _aiAnalysis['errorMessage'] ?? 'Unknown error occurred',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textColor.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 20),
                    TraceButton(
                      text: 'Try Again',
                      onPressed: _getAiAnalysis,
                      icon: Icons.refresh,
                      backgroundColor: Colors.blue,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              )
            else
              _buildStructuredAnalysisContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildStructuredAnalysisContent() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    // Extract data from analysis
    final summary = _aiAnalysis['summary'] ?? 'No summary available';
    final blockActivity = _aiAnalysis['blockActivity'] ?? 'Normal';
    final pyusdActivity = _aiAnalysis['pyusdActivity'] ?? 'None detected';
    final gasAnalysis =
        _aiAnalysis['gasAnalysis'] ?? 'No gas analysis available';
    final notableTransactions = _aiAnalysis['notableTransactions'] ?? [];
    final insights = _aiAnalysis['insights'] ?? 'No insights available';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.summarize, size: 18, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                summary,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Block Activity section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.analytics, size: 18, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Block Activity',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                blockActivity,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // PYUSD Activity section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.currency_exchange, size: 18, color: Colors.purple),
                  SizedBox(width: 8),
                  Text(
                    'PYUSD Activity',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                pyusdActivity,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Gas Analysis section
        ExpansionTile(
          title: const Text('Gas Analysis'),
          leading: const Icon(Icons.local_gas_station, color: Colors.orange),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: MarkdownBody(
                data: gasAnalysis,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(fontSize: 14, color: textColor),
                ),
              ),
            ),
          ],
        ),

        // Notable Transactions section
        if (notableTransactions.isNotEmpty)
          ExpansionTile(
            title: const Text('Notable Transactions'),
            leading: const Icon(Icons.star, color: Colors.amber),
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notableTransactions.length,
                itemBuilder: (context, index) {
                  final tx = notableTransactions[index];
                  return ListTile(
                    title: Text(tx['hash'] ?? 'Unknown hash'),
                    subtitle: Text(tx['description'] ?? 'No description'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      if (tx['hash'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransactionTraceScreen(
                              txHash: tx['hash'],
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),

        // Insights section
        ExpansionTile(
          title: const Text('Technical Insights'),
          leading: const Icon(Icons.lightbulb, color: Colors.yellow),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: MarkdownBody(
                data: insights,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(fontSize: 14, color: textColor),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Powered by Gemini
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/geminilogo.png',
                height: 16,
                width: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Powered by Google Gemini',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: textColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMEVAnalysisCard() {
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
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.analytics,
                      color: Colors.orange, size: 28),
                ),
                const SizedBox(width: 12),
                const Text(
                  'MEV Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_mevResults.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      setState(() => _mevResults.clear());
                    },
                    tooltip: 'Clear Results',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildMEVOpportunityButtons(),
            const SizedBox(height: 16),
            if (_isAnalyzing)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Analyzing MEV activities...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              )
            else
              _buildMEVResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildMEVOpportunityButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Analysis Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMEVButton(
              'Sandwich Attacks',
              Icons.fastfood,
              Colors.red,
              () => _analyzeSandwichAttacks(),
              'Detect sandwich attack patterns in this block',
            ),
            _buildMEVButton(
              'Transaction Ordering',
              Icons.reorder,
              Colors.blue,
              () => _analyzeTransactionOrdering(),
              'Analyze transaction ordering and gas prices',
            ),
            _buildMEVButton(
              'MEV Opportunities',
              Icons.trending_up,
              Colors.green,
              () => _identifyMEVOpportunities(),
              'Find potential MEV opportunities',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMEVButton(String label, IconData icon, Color color,
      VoidCallback onPressed, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: ElevatedButton.icon(
        onPressed: _isAnalyzing ? null : onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.withOpacity(0.5)),
          ),
          disabledBackgroundColor: Colors.grey.withOpacity(0.1),
          disabledForegroundColor: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMEVResults() {
    if (_mevResults.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.analytics_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No MEV Analysis Results',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Select an analysis type above to start',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analysis Results',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._mevResults.map((result) => _buildMEVResultCard(result)).toList(),
      ],
    );
  }

  Widget _buildMEVResultCard(Map<String, dynamic> result) {
    final type = result['type'] as String;
    final data = result['data'] as Map<String, dynamic>;
    final Color cardColor = _getMEVResultColor(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cardColor.withOpacity(0.5)),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(_getMEVResultIcon(type), size: 20, color: cardColor),
            const SizedBox(width: 8),
            Text(
              type,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cardColor,
              ),
            ),
          ],
        ),
        subtitle: Text(
          data['summary'] ?? 'No summary available',
          style: const TextStyle(fontSize: 13),
        ),
        trailing: data['profit'] != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  '\$${data['profit'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildDetailedResults(type, data),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedResults(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'Sandwich Attacks':
        return _buildSandwichAttackDetails(data);
      case 'Transaction Ordering':
        return _buildTransactionOrderingDetails(data);
      case 'MEV Opportunities':
        return _buildMEVOpportunitiesDetails(data);
      default:
        return const Text('No detailed information available');
    }
  }

  Widget _buildSandwichAttackDetails(Map<String, dynamic> data) {
    final attacks = data['attacks'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${attacks.length} Sandwich Attack Pattern${attacks.length == 1 ? '' : 's'} Detected',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...attacks
            .map((attack) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Frontrun: ${FormatterUtils.formatHash(attack['frontrun']['hash'])}'),
                      Text(
                          'Victim: ${FormatterUtils.formatHash(attack['victim']['hash'])}'),
                      Text(
                          'Backrun: ${FormatterUtils.formatHash(attack['backrun']['hash'])}'),
                      if (attack['profit'] != null)
                        Text(
                          'Estimated Profit: \$${attack['profit'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }

  Widget _buildTransactionOrderingDetails(Map<String, dynamic> data) {
    final transactions = data['transactions'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${transactions.length} Transactions Analyzed',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...transactions
            .take(5)
            .map((tx) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hash: ${FormatterUtils.formatHash(tx['hash'])}'),
                      Text(
                          'Gas Price: ${tx['gasPrice'].toStringAsFixed(2)} Gwei'),
                      if (tx['isPYUSDInteraction'])
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PYUSD',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ))
            .toList(),
        if (transactions.length > 5)
          Text(
            '... and ${transactions.length - 5} more transactions',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildMEVOpportunitiesDetails(Map<String, dynamic> data) {
    final opportunities = data['opportunities'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${opportunities.length} MEV Opportunit${opportunities.length == 1 ? 'y' : 'ies'} Found',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...opportunities
            .map((opp) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type: ${opp['type']}'),
                      if (opp['transaction'] != null)
                        Text(
                            'Transaction: ${FormatterUtils.formatHash(opp['transaction']['hash'])}'),
                      if (opp['estimatedProfit'] != null)
                        Text(
                          'Estimated Profit: \$${opp['estimatedProfit'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }

  Color _getMEVResultColor(String type) {
    switch (type) {
      case 'Sandwich Attacks':
        return Colors.red;
      case 'Transaction Ordering':
        return Colors.blue;
      case 'MEV Opportunities':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getMEVResultIcon(String type) {
    switch (type) {
      case 'Sandwich Attacks':
        return Icons.fastfood;
      case 'Transaction Ordering':
        return Icons.reorder;
      case 'MEV Opportunities':
        return Icons.trending_up;
      default:
        return Icons.analytics;
    }
  }

  Future<void> _analyzeSandwichAttacks() async {
    setState(() => _isAnalyzing = true);
    try {
      final provider = Provider.of<TraceProvider>(context, listen: false);
      final result = await provider.analyzeSandwichAttacks(_blockData['hash']);
      if (result['success']) {
        setState(() {
          _mevResults.add({
            'type': 'Sandwich Attacks',
            'data': {
              'summary':
                  '${result['sandwichAttacks'].length} potential sandwich attacks found',
              'attacks': result['sandwichAttacks'],
            },
          });
        });
      }
    } catch (e) {
      print('Error analyzing sandwich attacks: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _analyzeTransactionOrdering() async {
    setState(() => _isAnalyzing = true);
    try {
      final provider = Provider.of<TraceProvider>(context, listen: false);
      final result = await provider
          .analyzeTransactionOrdering(widget.blockNumber.toString());
      if (result['success']) {
        setState(() {
          _mevResults.add({
            'type': 'Transaction Ordering',
            'data': {
              'summary':
                  '${result['transactions'].length} transactions analyzed',
              'transactions': result['transactions'],
            },
          });
        });
      }
    } catch (e) {
      print('Error analyzing transaction ordering: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _identifyMEVOpportunities() async {
    setState(() => _isAnalyzing = true);
    try {
      final provider = Provider.of<TraceProvider>(context, listen: false);
      final result =
          await provider.identifyMEVOpportunities(_blockData['hash']);
      if (result['success']) {
        setState(() {
          _mevResults.add({
            'type': 'MEV Opportunities',
            'data': {
              'summary':
                  '${result['opportunities'].length} MEV opportunities found',
              'opportunities': result['opportunities'],
            },
          });
        });
      }
    } catch (e) {
      print('Error identifying MEV opportunities: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }
}
