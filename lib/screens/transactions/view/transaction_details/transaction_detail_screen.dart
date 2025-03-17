import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_hub/utils/snackbar_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../providers/network_provider.dart';
import '../../model/transaction_model.dart';
import '../../provider/transactiondetail_provider.dart';
import '../../../../services/market_service.dart';
import 'widgets/gasdetails_widget.dart';
import 'widgets/interrnal_transaction_widget.dart';
import 'widgets/marketanalysis_widget.dart';
import 'widgets/statuscard_wudget.dart';
import 'widgets/transaction_details_widget.dart';
import 'widgets/transaction_trace_widget.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;
  final String currentAddress;
  final bool isDarkMode;
  final NetworkType networkType;
  final String rpcUrl;
  final bool needsRefresh;

  const TransactionDetailScreen({
    Key? key,
    required this.transaction,
    required this.currentAddress,
    required this.isDarkMode,
    required this.networkType,
    required this.rpcUrl,
    this.needsRefresh = false,
  }) : super(key: key);

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  TransactionDetailModel? _detailedTransaction;
  bool _isRefreshing = false;
  bool _isInitializing = true;
  bool _isLoadingMarketData = false;
  late final TransactionDetailProvider _transactionDetailProvider;
  final MarketService _marketService = MarketService();
  Map<String, double> _marketPrices = {};
  Map<String, dynamic>? _traceData;
  List<Map<String, dynamic>>? _internalTransactions;

  @override
  void initState() {
    super.initState();
    // Get provider reference once
    _transactionDetailProvider =
        Provider.of<TransactionDetailProvider>(context, listen: false);
    // Schedule the fetch for the next frame to avoid blocking UI render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    // Return the latest transaction details when navigating back
    if (widget.transaction is TransactionDetailModel &&
        widget.transaction != _detailedTransaction) {
      Navigator.pop(context, widget.transaction);
    }
    super.dispose();
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
        await _fetchTransactionDetails();
      } else {
        // If not cached, fetch it
        await _fetchTransactionDetails();
      }

      // After fetching transaction details, fetch trace data and internal transactions
      if (_detailedTransaction != null) {
        await _fetchTraceData();
        await _fetchInternalTransactions();
        await _fetchMarketData();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
      });
      _showErrorSnackBar('Error initializing data');
    }
  }

  Future<void> _fetchTraceData() async {
    if (!mounted || _detailedTransaction == null) return;

    try {
      final traceData = await _transactionDetailProvider.getTransactionTrace(
        txHash: widget.transaction.hash,
        rpcUrl: widget.rpcUrl,
      );

      if (mounted) {
        setState(() {
          _traceData = traceData;
        });
      }
    } catch (e) {
      print('Error fetching transaction trace: $e');
    }
  }

  Future<void> _fetchInternalTransactions() async {
    if (!mounted || _detailedTransaction == null) return;

    try {
      final internalTxs =
          await _transactionDetailProvider.getInternalTransactions(
        txHash: widget.transaction.hash,
        rpcUrl: widget.rpcUrl,
        networkType: widget.networkType,
        currentAddress: widget.currentAddress,
      );

      if (mounted) {
        setState(() {
          _internalTransactions = internalTxs;
        });
      }
    } catch (e) {
      print('Error fetching internal transactions: $e');
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

      // Fetch current market prices
      _marketPrices = await _marketService.getCurrentPrices(tokensToFetch);
    } catch (e) {
      print('Error fetching market data: $e');
    } finally {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction details updated')),
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

  Future<void> _refreshTransactionDetails() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    await _fetchTransactionDetails(forceRefresh: true);
    await _fetchTraceData();
    await _fetchInternalTransactions();
    await _fetchMarketData();
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

  @override
  Widget build(BuildContext context) {
    final isIncoming =
        widget.transaction.direction == TransactionDirection.incoming;
    final theme = Theme.of(context);

    // Get colors from theme
    final primaryColor =
        widget.isDarkMode ? theme.colorScheme.primary : const Color(0xFF3D56F0);
    final backgroundColor =
        widget.isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;
    final cardColor =
        widget.isDarkMode ? const Color(0xFF252547) : Colors.white;
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = widget.isDarkMode ? Colors.white70 : Colors.black54;

    // Determine transaction status color
    final statusColor = _getStatusColor(widget.transaction.status);

    // Show a placeholder view while data is loading
    if (_isInitializing && _detailedTransaction == null) {
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
            : _buildTransactionDetails(
                statusColor,
                isIncoming,
                cardColor,
                textColor,
                subtitleColor,
                primaryColor,
              ),
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
        // Debug trace button
        if (_detailedTransaction != null &&
            _detailedTransaction!.status != TransactionStatus.pending)
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _fetchTraceData().then((_) {
              if (_traceData != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction trace loaded')),
                );
              } else {
                SnackbarUtil.showSnackbar(
                    context: context,
                    isError: true,
                    message: 'Failed to load transaction trace');
              }
            }),
            tooltip: 'Debug Trace',
          ),
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _isRefreshing ? null : _refreshTransactionDetails,
          tooltip: 'Refresh transaction details',
        ),
        // Etherscan button
        IconButton(
          icon: const Icon(Icons.open_in_new),
          onPressed: _openBlockExplorer,
          tooltip: 'View on Etherscan',
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
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading transaction details...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(
      Color backgroundColor, Color textColor, Color primaryColor) {
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
                color: widget.isDarkMode ? Colors.white54 : Colors.black38,
              ),
              const SizedBox(height: 16),
              Text(
                'Transaction details not available',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchTransactionDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionDetails(
    Color statusColor,
    bool isIncoming,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Color primaryColor,
  ) {
    if (_detailedTransaction == null) return const SizedBox.shrink();

    return Stack(
      children: [
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction status and type card
              StatusCardWidget(
                transaction: _detailedTransaction!,
                isIncoming: isIncoming,
                statusColor: statusColor,
                cardColor: cardColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
              const SizedBox(height: 16),

              // Market Analysis Card
              MarketAnalysisWidget(
                transaction: _detailedTransaction!,
                marketPrices: _marketPrices,
                isLoadingMarketData: _isLoadingMarketData,
                cardColor: cardColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 16),

              // Transaction details card
              TransactionDetailsWidget(
                transaction: _detailedTransaction!,
                currentAddress: widget.currentAddress,
                cardColor: cardColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                primaryColor: primaryColor,
                onShowErrorDetails: _showErrorDetails,
              ),
              const SizedBox(height: 16),

              // Gas details card
              GasDetailsWidget(
                transaction: _detailedTransaction!,
                isDarkMode: widget.isDarkMode,
                cardColor: cardColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
              const SizedBox(height: 16),

              // Internal transactions card
              if (_internalTransactions != null &&
                  _internalTransactions!.isNotEmpty)
                InternalTransactionWidget(
                  internalTransactions: _internalTransactions!,
                  cardColor: cardColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  primaryColor: primaryColor,
                ),
              if (_internalTransactions != null &&
                  _internalTransactions!.isNotEmpty)
                const SizedBox(height: 16),

              // Transaction trace card
              // Transaction trace card
              if (_traceData != null)
                TransactionTraceWidget(
                  traceData: _traceData!,
                  cardColor: cardColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  primaryColor: primaryColor,
                  onShowRawTraceData: _showRawTraceData,
                ),
              if (_traceData != null) const SizedBox(height: 16),

              // Extra space at bottom for better scrolling experience
              const SizedBox(height: 40),
            ],
          ),
        ),

        // Loading indicator overlay when refreshing
        if (_isRefreshing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.2),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showRawTraceData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raw Trace Data'),
        content: SingleChildScrollView(
          child: SelectableText(
            _traceData.toString(),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _traceData.toString()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
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
    switch (status) {
      case TransactionStatus.confirmed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
    }
  }
}
