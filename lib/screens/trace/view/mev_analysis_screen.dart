import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../provider/trace_provider.dart';
import '../provider/mev_analysis_provider.dart';
import '../../../widgets/pyusd_components.dart';
import '../../../widgets/loading_overlay.dart';
import '../widgets/trace_widgets.dart';
import '../../../utils/formatter_utils.dart';

class MevAnalysisScreen extends StatefulWidget {
  const MevAnalysisScreen({super.key});

  @override
  State<MevAnalysisScreen> createState() => _MevAnalysisScreenState();
}

class _MevAnalysisScreenState extends State<MevAnalysisScreen> {
  final TextEditingController _blockHashController = TextEditingController();
  final TextEditingController _startBlockController = TextEditingController();
  final TextEditingController _endBlockController = TextEditingController();
  final TextEditingController _txHashController = TextEditingController();

  String _selectedAnalysisType = 'Sandwich Attack Analysis';
  bool _isLoading = false;
  Map<String, dynamic>? _analysisResult;
  String _error = '';

  @override
  void initState() {
    super.initState();
    // Initialize controllers with stored values from provider
    final provider = Provider.of<MevAnalysisProvider>(context, listen: false);
    _blockHashController.text = provider.lastMevBlockHash ?? '';
    _startBlockController.text = provider.lastMevStartBlock ?? '';
    _endBlockController.text = provider.lastMevEndBlock ?? '';
    _txHashController.text = provider.lastMevTxHash ?? '';
    _selectedAnalysisType =
        provider.lastMevAnalysisType ?? 'Sandwich Attack Analysis';

    // Add listeners to update provider when text changes
    _blockHashController.addListener(() {
      provider.updateLastMevBlockHash(_blockHashController.text);
    });
    _startBlockController.addListener(() {
      provider.updateLastMevStartBlock(_startBlockController.text);
    });
    _endBlockController.addListener(() {
      provider.updateLastMevEndBlock(_endBlockController.text);
    });
    _txHashController.addListener(() {
      provider.updateLastMevTxHash(_txHashController.text);
    });
  }

  @override
  void dispose() {
    // Remove listeners before disposing
    final provider = Provider.of<MevAnalysisProvider>(context, listen: false);
    provider.updateLastMevAnalysisType(_selectedAnalysisType);

    _blockHashController.removeListener(() {
      provider.updateLastMevBlockHash(_blockHashController.text);
    });
    _startBlockController.removeListener(() {
      provider.updateLastMevStartBlock(_startBlockController.text);
    });
    _endBlockController.removeListener(() {
      provider.updateLastMevEndBlock(_endBlockController.text);
    });
    _txHashController.removeListener(() {
      provider.updateLastMevTxHash(_txHashController.text);
    });

    _blockHashController.dispose();
    _startBlockController.dispose();
    _endBlockController.dispose();
    _txHashController.dispose();
    super.dispose();
  }

  Future<void> _performAnalysis() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
      _error = '';
      _analysisResult = null;
    });

    try {
      final provider = Provider.of<MevAnalysisProvider>(context, listen: false);
      Map<String, dynamic> result;

      switch (_selectedAnalysisType) {
        case 'Sandwich Attack Analysis':
          result = await provider
              .analyzeSandwichAttacks(_blockHashController.text.trim());
          break;
        case 'Frontrunning Analysis':
          result =
              await provider.analyzeFrontrunning(_txHashController.text.trim());
          break;
        case 'Transaction Ordering':
          result = await provider
              .analyzeTransactionOrdering(_blockHashController.text.trim());
          break;
        case 'MEV Opportunities':
          result = await provider
              .analyzeMevOpportunities(_blockHashController.text.trim());
          break;
        case 'Historical MEV Events':
          final startBlock = int.parse(_startBlockController.text.trim());
          final endBlock = int.parse(_endBlockController.text.trim());
          result =
              await provider.trackHistoricalMEVEvents(startBlock, endBlock);
          break;
        default:
          result = {'error': 'Invalid analysis type'};
      }

      setState(() {
        _analysisResult = result;
        _error = result['error'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  bool _validateInputs() {
    setState(() => _error = '');

    switch (_selectedAnalysisType) {
      case 'Sandwich Attack Analysis':
      case 'MEV Opportunities':
      case 'Transaction Ordering':
        if (_blockHashController.text.trim().isEmpty) {
          setState(() => _error = 'Block hash is required');
          return false;
        }
        if (!_blockHashController.text.trim().startsWith('0x')) {
          setState(() => _error = 'Block hash must start with 0x');
          return false;
        }
        break;

      case 'Frontrunning Analysis':
        if (_txHashController.text.trim().isEmpty) {
          setState(() => _error = 'Transaction hash is required');
          return false;
        }
        if (!_txHashController.text.trim().startsWith('0x')) {
          setState(() => _error = 'Transaction hash must start with 0x');
          return false;
        }
        break;

      case 'Historical MEV Events':
        if (_startBlockController.text.trim().isEmpty ||
            _endBlockController.text.trim().isEmpty) {
          setState(
              () => _error = 'Both start and end block numbers are required');
          return false;
        }
        try {
          final start = int.parse(_startBlockController.text.trim());
          final end = int.parse(_endBlockController.text.trim());
          if (end <= start) {
            setState(
                () => _error = 'End block must be greater than start block');
            return false;
          }
        } catch (e) {
          setState(() => _error = 'Invalid block numbers');
          return false;
        }
        break;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PyusdAppBar(
        title: 'MEV Analysis',
        showLogo: false,
        isDarkMode: Theme.of(context).brightness == Brightness.dark,
        onRefreshPressed: _analysisResult != null ? _performAnalysis : null,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        loadingText: 'Analyzing MEV activities...',
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoSection(context),
              _buildAnalysisTools(),
              if (_error.isNotEmpty) _buildErrorMessage(),
              if (_analysisResult != null) _buildAnalysisResults(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisTools() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MEV Analysis Tools',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildMethodSelector(),
            const SizedBox(height: 24),
            _buildInputFields(),
            const SizedBox(height: 24),
            _buildAnalyzeButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodSelector() {
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Sandwich Attack Analysis',
            'Frontrunning Analysis',
            'Transaction Ordering',
            'MEV Opportunities',
            'Historical MEV Events',
          ]
              .map((type) => ChoiceChip(
                    label: Text(type),
                    selected: _selectedAnalysisType == type,
                    onSelected: (selected) {
                      if (selected) {
                        final provider = Provider.of<MevAnalysisProvider>(
                            context,
                            listen: false);
                        setState(() {
                          _selectedAnalysisType = type;
                          provider.updateLastMevAnalysisType(type);
                          _error = '';
                          _analysisResult = null;
                        });
                      }
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildInputFields() {
    switch (_selectedAnalysisType) {
      case 'Sandwich Attack Analysis':
      case 'MEV Opportunities':
      case 'Transaction Ordering':
        return TraceInputField(
          controller: _blockHashController,
          label: 'Block Hash',
          hintText: '0x...',
          prefixIcon: Icons.view_module,
          onPaste: () async {
            final data = await Clipboard.getData('text/plain');
            if (data != null && data.text != null) {
              setState(() {
                _blockHashController.text = data.text!.trim();
              });
            }
          },
        );

      case 'Frontrunning Analysis':
        return TraceInputField(
          controller: _txHashController,
          label: 'Transaction Hash',
          hintText: '0x...',
          prefixIcon: Icons.receipt,
          onPaste: () async {
            final data = await Clipboard.getData('text/plain');
            if (data != null && data.text != null) {
              setState(() {
                _txHashController.text = data.text!.trim();
              });
            }
          },
        );

      case 'Historical MEV Events':
        return Column(
          children: [
            TraceInputField(
              controller: _startBlockController,
              label: 'Start Block',
              hintText: 'Enter start block number',
              prefixIcon: Icons.start,
              isHexInput: false,
              onPaste: () async {
                final data = await Clipboard.getData('text/plain');
                if (data != null && data.text != null) {
                  setState(() {
                    _startBlockController.text = data.text!.trim();
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TraceInputField(
              controller: _endBlockController,
              label: 'End Block',
              hintText: 'Enter end block number',
              prefixIcon: Icons.stop,
              isHexInput: false,
              onPaste: () async {
                final data = await Clipboard.getData('text/plain');
                if (data != null && data.text != null) {
                  setState(() {
                    _endBlockController.text = data.text!.trim();
                  });
                }
              },
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      child: TraceButton(
        text: 'Analyze',
        icon: Icons.analytics,
        onPressed: _performAnalysis,
        isLoading: _isLoading,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults() {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getAnalysisIcon(),
                  color: _getAnalysisColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Analysis Results',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy Results',
                  onPressed: () => _copyResults(),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildResultContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent() {
    switch (_selectedAnalysisType) {
      case 'Sandwich Attack Analysis':
        return _buildSandwichAttackResults();
      case 'Frontrunning Analysis':
        return _buildFrontrunningResults();
      case 'Transaction Ordering':
        return _buildTransactionOrderingResults();
      case 'MEV Opportunities':
        return _buildMEVOpportunitiesResults();
      case 'Historical MEV Events':
        return _buildHistoricalMEVResults();
      default:
        return const Text('No results available');
    }
  }

  Widget _buildSandwichAttackResults() {
    final attacks = _analysisResult?['sandwichAttacks'] as List? ?? [];
    if (attacks.isEmpty) {
      return _buildEmptyResults('No sandwich attacks detected in this block');
    }

    return Column(
      children:
          attacks.map((attack) => _buildSandwichAttackCard(attack)).toList(),
    );
  }

  Widget _buildSandwichAttackCard(Map<String, dynamic> attack) {
    final profit = attack['profit'] as double? ?? 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'Sandwich Attack Detected',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '\$${profit.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildTransactionRow('Frontrun', attack['frontrun']['hash']),
          _buildTransactionRow('Victim', attack['victim']['hash']),
          _buildTransactionRow('Backrun', attack['backrun']['hash']),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(String label, String hash) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(FormatterUtils.formatHash(hash)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: hash));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hash copied to clipboard')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFrontrunningResults() {
    final frontrunning = _analysisResult?['frontrunning'];
    if (frontrunning == null) {
      return _buildEmptyResults(
          'No frontrunning detected for this transaction');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed, color: Colors.purple),
              const SizedBox(width: 8),
              const Text(
                'Frontrunning Detected',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '\$${(frontrunning['frontrun']['profit'] as double? ?? 0.0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildTransactionRow('Frontrunner', frontrunning['frontrun']['hash']),
          _buildTransactionRow('Victim', frontrunning['victim']['hash']),
          const SizedBox(height: 16),
          Text(
            'Block: ${frontrunning['blockNumber']}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionOrderingResults() {
    final transactions = _analysisResult?['transactions'] as List? ?? [];
    if (transactions.isEmpty) {
      return _buildEmptyResults('No transactions found in this block');
    }

    return Column(
      children:
          transactions.map((tx) => _buildTransactionOrderCard(tx)).toList(),
    );
  }

  Widget _buildTransactionOrderCard(Map<String, dynamic> tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTransactionRow('Transaction', tx['hash']),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  'Gas Price: ${(tx['gasPrice'] / 1e9).toStringAsFixed(2)} Gwei'),
              Text('Gas Used: ${tx['gasUsed']}'),
            ],
          ),
          if (tx['status'] != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tx['status'] == '0x1'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tx['status'] == '0x1' ? 'Success' : 'Failed',
                style: TextStyle(
                  color: tx['status'] == '0x1' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMEVOpportunitiesResults() {
    final opportunities = _analysisResult?['opportunities'] as List? ?? [];
    if (opportunities.isEmpty) {
      return _buildEmptyResults('No MEV opportunities detected in this block');
    }

    return Column(
      children: opportunities.map((opp) => _buildOpportunityCard(opp)).toList(),
    );
  }

  Widget _buildOpportunityCard(Map<String, dynamic> opportunity) {
    final profit = opportunity['profit'] as double? ?? 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                opportunity['type'] == 'arbitrage'
                    ? Icons.swap_horiz
                    : Icons.warning,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                opportunity['type'].toString().toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '\$${profit.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildTransactionRow('Transaction', opportunity['hash']),
          const SizedBox(height: 8),
          Text(
            'Gas Price: ${(opportunity['gasPrice'] / 1e9).toStringAsFixed(2)} Gwei',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalMEVResults() {
    final events = _analysisResult?['events'] as List? ?? [];
    if (events.isEmpty) {
      return _buildEmptyResults('No MEV events found in the specified range');
    }

    return Column(
      children: [
        _buildHistoricalStats(events),
        const SizedBox(height: 16),
        ...events.map((event) => _buildHistoricalEventCard(event)).toList(),
      ],
    );
  }

  Widget _buildHistoricalStats(List<dynamic> events) {
    double totalProfit = 0;
    int sandwichAttacks = 0;
    int mevOpportunities = 0;

    for (final event in events) {
      if (event['type'] == 'sandwich_attack') {
        sandwichAttacks++;
        totalProfit += event['data']['profit'] as double? ?? 0.0;
      } else if (event['type'] == 'mev_opportunity') {
        mevOpportunities++;
        totalProfit += event['data']['profit'] as double? ?? 0.0;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historical Analysis Summary',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Divider(height: 24),
          _buildStatRow('Total Events', events.length.toString()),
          _buildStatRow('Sandwich Attacks', sandwichAttacks.toString()),
          _buildStatRow('MEV Opportunities', mevOpportunities.toString()),
          _buildStatRow('Total Profit', '\$${totalProfit.toStringAsFixed(2)}'),
          _buildStatRow(
            'Block Range',
            '${_analysisResult!['startBlock']} - ${_analysisResult!['endBlock']}',
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalEventCard(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getEventColor(event['type']).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: _getEventColor(event['type']).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getEventIcon(event['type']),
                  color: _getEventColor(event['type'])),
              const SizedBox(width: 8),
              Text(
                _formatEventType(event['type']),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text('Block: ${event['blockNumber']}'),
          const SizedBox(height: 8),
          if (event['data'] != null) ...[
            if (event['data']['profit'] != null)
              Text(
                'Profit: \$${(event['data']['profit'] as double).toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyResults(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              _getAnalysisIcon(),
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAnalysisIcon() {
    switch (_selectedAnalysisType) {
      case 'Sandwich Attack Analysis':
        return Icons.warning_amber;
      case 'Frontrunning Analysis':
        return Icons.speed;
      case 'Transaction Ordering':
        return Icons.sort;
      case 'MEV Opportunities':
        return Icons.analytics;
      case 'Historical MEV Events':
        return Icons.history;
      default:
        return Icons.analytics;
    }
  }

  Color _getAnalysisColor() {
    switch (_selectedAnalysisType) {
      case 'Sandwich Attack Analysis':
        return Colors.orange;
      case 'Frontrunning Analysis':
        return Colors.purple;
      case 'Transaction Ordering':
        return Colors.blue;
      case 'MEV Opportunities':
        return Colors.green;
      case 'Historical MEV Events':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'sandwich_attack':
        return Colors.orange;
      case 'mev_opportunity':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'sandwich_attack':
        return Icons.warning_amber;
      case 'mev_opportunity':
        return Icons.analytics;
      default:
        return Icons.info;
    }
  }

  String _formatEventType(String type) {
    return type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _copyResults() {
    final jsonString = FormatterUtils.formatJson(_analysisResult);
    Clipboard.setData(ClipboardData(text: jsonString));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analysis results copied to clipboard')),
    );
  }
}

Widget _buildInfoSection(BuildContext context) {
  final theme = Theme.of(context);
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
                Icons.analytics,
                color: theme.colorScheme.secondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'MEV Analysis Tools',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Analyze Maximal Extractable Value (MEV) activities on the Ethereum network. Monitor sandwich attacks, frontrunning, and other MEV opportunities involving PYUSD.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    ),
  );
}
