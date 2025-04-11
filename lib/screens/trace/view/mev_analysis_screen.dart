import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/trace_provider.dart';
import '../../../widgets/pyusd_components.dart';
import '../widgets/trace_widgets.dart';

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
  void dispose() {
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
      final provider = Provider.of<TraceProvider>(context, listen: false);
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
          final blockNumber = int.parse(_blockHashController.text.trim());
          result = await provider.analyzeTransactionOrdering(blockNumber);
          break;
        case 'MEV Opportunities':
          result = await provider
              .identifyMEVOpportunities(_blockHashController.text.trim());
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

      case 'Transaction Ordering':
        if (_blockHashController.text.trim().isEmpty) {
          setState(() => _error = 'Block number is required');
          return false;
        }
        try {
          int.parse(_blockHashController.text.trim());
        } catch (e) {
          setState(() => _error = 'Invalid block number');
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

  Widget _buildAnalysisInputs() {
    switch (_selectedAnalysisType) {
      case 'Sandwich Attack Analysis':
      case 'MEV Opportunities':
        return TraceInputField(
          controller: _blockHashController,
          label: 'Block Hash',
          hintText: '0x...',
          prefixIcon: Icons.view_module,
        );

      case 'Frontrunning Analysis':
        return TraceInputField(
          controller: _txHashController,
          label: 'Transaction Hash',
          hintText: '0x...',
          prefixIcon: Icons.receipt,
        );

      case 'Transaction Ordering':
        return TraceInputField(
          controller: _blockHashController,
          label: 'Block Number',
          hintText: 'Enter block number',
          prefixIcon: Icons.numbers,
          isHexInput: false,
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
            ),
            const SizedBox(height: 16),
            TraceInputField(
              controller: _endBlockController,
              label: 'End Block',
              hintText: 'Enter end block number',
              prefixIcon: Icons.stop,
              isHexInput: false,
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildAnalysisResults() {
    if (_analysisResult == null) return const SizedBox();

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analysis Results',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildResultContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent() {
    if (_analysisResult == null) return const SizedBox();

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
      return const Text('No sandwich attacks detected in this block');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: attacks.map((attack) {
        final profit = attack['profit'] as double? ?? 0.0;
        return ListTile(
          title: Text('Sandwich Attack'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Frontrun: ${_truncateHash(attack['frontrun']['hash'])}'),
              Text('Victim: ${_truncateHash(attack['victim']['hash'])}'),
              Text('Backrun: ${_truncateHash(attack['backrun']['hash'])}'),
              Text('Profit: \$${profit.toStringAsFixed(2)}'),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFrontrunningResults() {
    final frontrunners = _analysisResult?['frontrunners'] as List? ?? [];
    if (frontrunners.isEmpty) {
      return const Text('No frontrunning detected for this transaction');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: frontrunners.map((frontrunner) {
        final profit = frontrunner['profit'] as double? ?? 0.0;
        return ListTile(
          title: const Text('Frontrunning Transaction'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Hash: ${_truncateHash(frontrunner['transaction']['hash'])}'),
              Text('Profit: \$${profit.toStringAsFixed(2)}'),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionOrderingResults() {
    final transactions = _analysisResult?['transactions'] as List? ?? [];
    if (transactions.isEmpty) {
      return const Text('No transactions found in this block');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: transactions.map((tx) {
        return ListTile(
          title: Text(_truncateHash(tx['hash'])),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gas Price: ${tx['gasPrice']} Gwei'),
              if (tx['isPYUSDInteraction'])
                const Text('PYUSD Interaction',
                    style: TextStyle(color: Colors.blue)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMEVOpportunitiesResults() {
    final opportunities = _analysisResult?['opportunities'] as List? ?? [];
    if (opportunities.isEmpty) {
      return const Text('No MEV opportunities detected in this block');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: opportunities.map((opp) {
        return ListTile(
          title: Text(opp['type']),
          subtitle: Text(
              'Estimated Profit: \$${(opp['estimatedProfit'] as double? ?? 0.0).toStringAsFixed(2)}'),
        );
      }).toList(),
    );
  }

  Widget _buildHistoricalMEVResults() {
    final events = _analysisResult?['events'] as List? ?? [];
    if (events.isEmpty) {
      return const Text('No MEV events found in the specified range');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: events.map((event) {
        return ListTile(
          title: Text('Block ${event['blockNumber']}'),
          subtitle: Text('Type: ${event['type']}'),
          onTap: () => _showEventDetails(event),
        );
      }).toList(),
    );
  }

  void _showEventDetails(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('MEV Event Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Block: ${event['blockNumber']}'),
              Text('Type: ${event['type']}'),
              const SizedBox(height: 8),
              Text('Data:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(event['data'].toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _truncateHash(String hash) {
    if (hash.length <= 10) return hash;
    return '${hash.substring(0, 6)}...${hash.substring(hash.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PyusdAppBar(
        title: 'MEV Analysis',
        showLogo: false,
        isDarkMode: Theme.of(context).brightness == Brightness.dark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoSection(context),
            const SizedBox(height: 24),
            Card(
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
                    TraceMethodSelector(
                      selectedMethod: _selectedAnalysisType,
                      onMethodChanged: (String newValue) {
                        setState(() {
                          _selectedAnalysisType = newValue;
                          _error = '';
                          _analysisResult = null;
                        });
                      },
                      availableMethods: const [
                        'Sandwich Attack Analysis',
                        'Frontrunning Analysis',
                        'Transaction Ordering',
                        'MEV Opportunities',
                        'Historical MEV Events',
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildAnalysisInputs(),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    TraceButton(
                      text: 'Analyze',
                      icon: Icons.analytics,
                      onPressed: _performAnalysis,
                      isLoading: _isLoading,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            if (_analysisResult != null) _buildAnalysisResults(),
          ],
        ),
      ),
    );
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
          const SizedBox(height: 16),
          _buildMEVStats(context),
        ],
      ),
    );
  }

  Widget _buildMEVStats(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Total MEV Events',
            '${_analysisResult?['events']?.length ?? 0}',
            Icons.timeline,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Total Profit',
            '\$${_calculateTotalProfit().toStringAsFixed(2)}',
            Icons.attach_money,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? theme.colorScheme.surface.withOpacity(0.1)
            : theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotalProfit() {
    if (_analysisResult == null) return 0.0;

    double total = 0.0;

    // Add profits from sandwich attacks
    final attacks = _analysisResult?['sandwichAttacks'] as List? ?? [];
    for (final attack in attacks) {
      total += attack['profit'] as double? ?? 0.0;
    }

    // Add profits from frontrunning
    final frontrunners = _analysisResult?['frontrunners'] as List? ?? [];
    for (final frontrunner in frontrunners) {
      total += frontrunner['profit'] as double? ?? 0.0;
    }

    // Add profits from MEV opportunities
    final opportunities = _analysisResult?['opportunities'] as List? ?? [];
    for (final opp in opportunities) {
      total += opp['estimatedProfit'] as double? ?? 0.0;
    }

    return total;
  }
}
