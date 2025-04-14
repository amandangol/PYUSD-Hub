import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../utils/snackbar_utils.dart';
import '../../../../widgets/pyusd_components.dart';
import '../../../../providers/network_provider.dart';
import '../../model/transaction_model.dart';
import '../../provider/transactiondetail_provider.dart';
import '../../../../services/market_service.dart';
import 'widgets/gasdetails_widget.dart';
import 'widgets/marketanalysis_widget.dart';
import 'widgets/statuscard_widget.dart';
import 'widgets/transaction_details_widget.dart';
import 'widgets/trace_details_widget.dart';
import '../../../geminiai/provider/gemini_provider.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;
  final String currentAddress;
  final bool isDarkMode;
  final NetworkType networkType;
  final String rpcUrl;
  final bool needsRefresh;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    required this.currentAddress,
    required this.isDarkMode,
    required this.networkType,
    required this.rpcUrl,
    this.needsRefresh = false,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen>
    with SingleTickerProviderStateMixin {
  TransactionDetailModel? _detailedTransaction;
  bool _isRefreshing = false;
  bool _isInitializing = true;
  bool _isLoadingMarketData = false;
  Map<String, double> _marketPrices = {};
  Map<String, dynamic>? _traceData;
  bool _isLoadingTrace = false;
  Map<String, dynamic>? _aiAnalysis;
  bool _isLoadingAiAnalysis = false;
  late final TransactionDetailProvider _transactionDetailProvider;
  late MarketService _marketService = MarketService();

  // TabController for the tabbed interface
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _transactionDetailProvider =
        Provider.of<TransactionDetailProvider>(context, listen: false);
    _marketService = Provider.of<MarketService>(context, listen: false);

    // Initialize tab controller with 4 tabs
    _tabController = TabController(length: 4, vsync: this);

    // Load cached data first
    _loadCachedData();

    // Then initialize fresh data
    _initializeData();

    // Schedule AI analysis for after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAiAnalysis();
    });
  }

  @override
  void dispose() {
    // Dispose the TabController
    _tabController.dispose();

    // Return the latest transaction details when navigating back
    if (widget.transaction is TransactionDetailModel &&
        widget.transaction != _detailedTransaction) {
      Navigator.pop(context, widget.transaction);
    }
    super.dispose();
  }

  Future<void> _loadCachedData() async {
    if (!mounted) return;

    try {
      // Check for cached transaction details
      if (_transactionDetailProvider
          .isTransactionCached(widget.transaction.hash)) {
        final cachedData = _transactionDetailProvider
            .getCachedTransactionDetails(widget.transaction.hash);
        if (cachedData != null) {
          setState(() {
            _detailedTransaction = cachedData;
            _isInitializing = false;
          });
        }
      }

      // Check for cached trace data
      final cachedTrace = await _transactionDetailProvider.getTransactionTrace(
        txHash: widget.transaction.hash,
        rpcUrl: widget.rpcUrl,
      );
      if (cachedTrace != null && mounted) {
        setState(() {
          _traceData = cachedTrace;
          _isLoadingTrace = false;
        });
      }

      // Check for cached market data
      if (_detailedTransaction != null && mounted) {
        final tokensToFetch = ['ETH'];
        if (_detailedTransaction?.tokenSymbol != null &&
            _detailedTransaction!.tokenSymbol!.isNotEmpty) {
          tokensToFetch.add(_detailedTransaction!.tokenSymbol!);
        }

        final cachedMarketData = await _transactionDetailProvider.getMarketData(
          txHash: widget.transaction.hash,
          tokens: tokensToFetch,
        );

        if (cachedMarketData.isNotEmpty && mounted) {
          setState(() {
            _marketPrices = cachedMarketData;
            _isLoadingMarketData = false;
          });
        }
      }
    } catch (e) {
      print('Error loading cached data: $e');
    }
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    setState(() {
      _isInitializing = true;
    });

    try {
      // First check if the data is already in the cache
      if (_transactionDetailProvider
          .isTransactionCached(widget.transaction.hash)) {
        final cachedData = _transactionDetailProvider
            .getCachedTransactionDetails(widget.transaction.hash);
        if (cachedData != null) {
          setState(() {
            _detailedTransaction = cachedData;
            _isInitializing = false;
          });
        }
      }

      // Start fetching fresh data in the background
      await _fetchTransactionDetails();

      // After fetching transaction details, fetch market data and trace data in parallel
      if (_detailedTransaction != null && mounted) {
        await Future.wait([
          _fetchMarketData(),
          _fetchTransactionTrace(),
        ]);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
      });
      _showErrorSnackBar('Error initializing data');
    }
  }

  Future<void> _fetchMarketData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingMarketData = true;
    });

    try {
      // Determine which tokens to fetch prices for
      final tokensToFetch = ['ETH'];

      // If this is a token transaction, add the token symbol
      if (_detailedTransaction?.tokenSymbol != null &&
          _detailedTransaction!.tokenSymbol!.isNotEmpty) {
        tokensToFetch.add(_detailedTransaction!.tokenSymbol!);
      }

      // Fetch current market prices using the provider's caching
      final prices = await _transactionDetailProvider.getMarketData(
        txHash: widget.transaction.hash,
        tokens: tokensToFetch,
      );

      if (mounted) {
        setState(() {
          _marketPrices = prices;
          _isLoadingMarketData = false;
        });
      }
    } catch (e) {
      print('Error fetching market data: $e');
      if (mounted) {
        setState(() {
          _isLoadingMarketData = false;
        });
      }
    }
  }

  Future<void> _fetchTransactionDetails({bool forceRefresh = false}) async {
    try {
      final details = await _transactionDetailProvider.getTransactionDetails(
        txHash: widget.transaction.hash,
        rpcUrl: widget.rpcUrl,
        networkType: widget.networkType,
        currentAddress: widget.currentAddress,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      setState(() {
        _detailedTransaction = details;
        _isInitializing = false;
        _isRefreshing = false;
      });

      if (forceRefresh) {
        SnackbarUtil.showSnackbar(
          context: context,
          message: 'Transaction details updated',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _isRefreshing = false;
      });
      _showErrorSnackBar(forceRefresh
          ? 'Failed to refresh transaction details'
          : 'Error loading transaction details');
    }
  }

  Future<void> _fetchTransactionTrace({bool forceRefresh = false}) async {
    if (!mounted) return;

    setState(() {
      _isLoadingTrace = true;
    });

    try {
      final traceData = await _transactionDetailProvider.getTransactionTrace(
        txHash: widget.transaction.hash,
        rpcUrl: widget.rpcUrl,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _traceData = traceData;
          _isLoadingTrace = false;
        });
      }
    } catch (e) {
      print('Error fetching transaction trace: $e');
      if (mounted) {
        setState(() {
          _isLoadingTrace = false;
        });
      }
    }
  }

  Future<void> _refreshTransactionDetails() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    await _fetchTransactionDetails(forceRefresh: true);

    await Future.wait([
      _fetchMarketData(),
      _fetchTransactionTrace(forceRefresh: true),
    ]);
  }

  Future<void> _openBlockExplorer() async {
    final String baseUrl = widget.networkType == NetworkType.sepoliaTestnet
        ? 'https://sepolia.etherscan.io/tx/'
        : 'https://etherscan.io/tx/';
    final url = Uri.parse('$baseUrl${widget.transaction.hash}');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Could not open block explorer');
      }
    } catch (e) {
      _showErrorSnackBar('Error opening block explorer');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _fetchAiAnalysis() async {
    if (!mounted) return;

    setState(() {
      _isLoadingAiAnalysis = true;
    });

    try {
      // First check cache
      final cachedAnalysis = _transactionDetailProvider
          .getCachedAiAnalysis(widget.transaction.hash);

      if (cachedAnalysis != null) {
        setState(() {
          _aiAnalysis = cachedAnalysis;
          _isLoadingAiAnalysis = false;
        });
        return;
      }

      final geminiProvider =
          Provider.of<GeminiProvider>(context, listen: false);
      final transactionData =
          _detailedTransaction?.toJson() ?? widget.transaction.toJson();
      final tokenDetails = {
        'symbol': _detailedTransaction?.tokenSymbol ??
            widget.transaction.tokenSymbol ??
            'ETH',
        'decimals': _detailedTransaction?.tokenDecimals ?? 18,
        'contractAddress': _detailedTransaction?.tokenContractAddress ?? '',
      };

      final analysis = await geminiProvider.analyzeTransactionTraceStructured(
        _traceData ?? {},
        transactionData,
        tokenDetails,
      );

      if (!mounted) return;

      // Cache the analysis
      _transactionDetailProvider.cacheAiAnalysis(
          widget.transaction.hash, analysis);

      setState(() {
        _aiAnalysis = analysis;
        _isLoadingAiAnalysis = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingAiAnalysis = false;
        _aiAnalysis = {
          'error': true,
          'summary': 'Failed to generate AI analysis',
          'errorMessage': e.toString(),
          'riskLevel': 'Unknown',
          'type': 'Unknown',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if network is currently switching
    final isNetworkSwitching = context.select<NetworkProvider, bool>(
      (provider) => provider.isSwitching,
    );

    // Add check for pending transactions
    if (widget.transaction.status == TransactionStatus.pending) {
      return _buildPendingTransactionView();
    }

    final isIncoming =
        widget.transaction.direction == TransactionDirection.incoming;
    final theme = Theme.of(context);

    // Get colors from theme
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final textColor =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final subtitleColor = theme.textTheme.bodySmall?.color ??
        theme.colorScheme.onSurface.withOpacity(0.7);

    // Determine transaction status color
    final statusColor = _getStatusColor(widget.transaction.status);

    // Show a placeholder view while data is loading or network is switching
    if ((_isInitializing && _detailedTransaction == null) ||
        isNetworkSwitching) {
      return _buildLoadingScreen(backgroundColor, textColor);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(textColor, primaryColor),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: _refreshTransactionDetails,
        child: _detailedTransaction == null
            ? _buildErrorView(backgroundColor, textColor, primaryColor)
            : Column(
                children: [
                  // Status Card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: StatusCardWidget(
                      transaction: _detailedTransaction!,
                      isIncoming: isIncoming,
                      statusColor: statusColor,
                      cardColor: cardColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                    ),
                  ),

                  // Tab Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: primaryColor,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: primaryColor,
                        unselectedLabelColor: subtitleColor,
                        tabs: const [
                          Tab(text: 'Details'),
                          Tab(text: 'Gas'),
                          Tab(text: 'Market'),
                          Tab(text: 'Trace'),
                        ],
                      ),
                    ),
                  ),

                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Transaction Details Tab
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: TransactionDetailsWidget(
                            transaction: _detailedTransaction!,
                            currentAddress: widget.currentAddress,
                            cardColor: cardColor,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            primaryColor: primaryColor,
                            onShowErrorDetails: _showErrorDetails,
                          ),
                        ),
                        // Gas Details Tab
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: GasDetailsWidget(
                            transaction: _detailedTransaction!,
                            isDarkMode: widget.isDarkMode,
                            cardColor: cardColor,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                        ),
                        // Market Analysis Tab
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: MarketAnalysisWidget(
                            transaction: _detailedTransaction!,
                            marketPrices: _marketPrices,
                            isLoadingMarketData: _isLoadingMarketData,
                            cardColor: cardColor,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            primaryColor: primaryColor,
                          ),
                        ),
                        // Trace Analysis Tab
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: TraceDetailsWidget(
                            traceData: _traceData,
                            isLoading: _isLoadingTrace,
                            cardColor: cardColor,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            primaryColor: primaryColor,
                            isDarkMode: widget.isDarkMode,
                            onRefresh: _refreshTransactionDetails,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAiAnalysisSheet,
        label: const Text('AI Insights'),
        icon: const Icon(Icons.psychology),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  AppBar _buildAppBar(Color textColor, Color primaryColor) {
    return AppBar(
      title: const Text('Transaction Details'),
      backgroundColor: Colors.transparent,
      foregroundColor: textColor,
      elevation: 0,
      actions: [
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _isRefreshing ? null : _refreshTransactionDetails,
        ),
        // Etherscan button
        IconButton(
          icon: const Icon(Icons.open_in_new),
          onPressed: _openBlockExplorer,
        ),
      ],
    );
  }

  Widget _buildLoadingScreen(Color backgroundColor, Color textColor) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading transaction details...',
              style: TextStyle(color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(
      Color backgroundColor, Color textColor, Color primaryColor) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Transaction details not available',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              PyusdButton(
                onPressed: _fetchTransactionDetails,
                text: 'Retry',
                backgroundColor: primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showErrorDetails() async {
    if (_detailedTransaction == null || !_detailedTransaction!.isError) return;

    try {
      final errorDetails =
          await _transactionDetailProvider.getTransactionErrorDetails(
        txHash: widget.transaction.hash,
        rpcUrl: widget.rpcUrl,
        networkType: widget.networkType,
        currentAddress: widget.currentAddress,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Transaction Error Details'),
          content: SingleChildScrollView(
            child:
                Text(errorDetails ?? 'No detailed error information available'),
          ),
          actions: [
            if (errorDetails != null)
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: errorDetails));
                  SnackbarUtil.showSnackbar(
                    context: context,
                    message: 'Copied to clipboard',
                  );
                },
                child: const Text('Copy'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error fetching transaction error details');
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    final theme = Theme.of(context);

    switch (status) {
      case TransactionStatus.confirmed:
        return theme.colorScheme.tertiary;
      case TransactionStatus.pending:
        return theme.colorScheme.secondary;
      case TransactionStatus.failed:
        return theme.colorScheme.error;
    }
  }

  Widget _buildPendingTransactionView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Transaction'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Transaction is pending confirmation...'),
            const SizedBox(height: 8),
            Text('Transaction Hash: ${widget.transaction.hash}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openBlockExplorer,
              child: const Text('View on Block Explorer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAiAnalysisSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
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
                      'AI Transaction Analysis',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    if (_isLoadingAiAnalysis)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildQuickInsightsCard(),
                      const SizedBox(height: 16),
                      _buildDetailedAnalysis(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInsightsCard() {
    // Ensure we have default values for required fields
    final analysis = _aiAnalysis ??
        {
          'riskLevel': 'Unknown',
          'type': 'Unknown',
          'summary': 'Analysis not available',
        };

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
              icon: Icons.security,
              title: 'Risk Level',
              content: analysis['riskLevel'] as String? ?? 'Unknown',
              color:
                  _getRiskColor(analysis['riskLevel'] as String? ?? 'Unknown'),
            ),
            const Divider(),
            _buildInsightRow(
              icon: Icons.category,
              title: 'Transaction Type',
              content: analysis['type'] as String? ?? 'Unknown',
            ),
            const Divider(),
            _buildInsightRow(
              icon: Icons.description,
              title: 'Summary',
              content: analysis['summary'] as String? ?? 'No summary available',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedAnalysis() {
    return Column(
      children: [
        _buildExpandableSection(
          title: 'Technical Analysis',
          icon: Icons.code,
          content: _aiAnalysis?['technicalInsights']?.toString() ?? '',
        ),
        _buildExpandableSection(
          title: 'Gas Analysis',
          icon: Icons.local_gas_station,
          content: _aiAnalysis?['gasAnalysis']?.toString() ?? '',
        ),
        _buildExpandableSection(
          title: 'Contract Interactions',
          icon: Icons.account_tree,
          content:
              _formatContractInteractions(_aiAnalysis?['contractInteractions']),
        ),
        _buildExpandableSection(
          title: 'Simple Explanation',
          icon: Icons.person_outline,
          content: _aiAnalysis?['humanReadable']?.toString() ?? '',
        ),
      ],
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

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInsightRow({
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

  String _formatContractInteractions(dynamic interactions) {
    if (interactions == null) {
      return 'No contract interactions detected';
    }

    try {
      if (interactions is List) {
        return interactions.map((e) => e.toString()).toList().join('\n\n');
      } else if (interactions is String) {
        return interactions;
      }
      return 'Invalid contract interactions format';
    } catch (e) {
      print('Error formatting contract interactions: $e');
      return 'Error displaying contract interactions';
    }
  }
}
