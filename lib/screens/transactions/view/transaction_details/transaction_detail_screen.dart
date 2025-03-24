import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../widgets/pyusd_components.dart';
import '../../../../providers/network_provider.dart';
import '../../model/transaction_model.dart';
import '../../provider/transactiondetail_provider.dart';
import '../../../../services/market_service.dart';
import 'widgets/gasdetails_widget.dart';
import 'widgets/interrnal_transaction_widget.dart';
import 'widgets/marketanalysis_widget.dart';
import 'widgets/statuscard_widget.dart';
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
  late final TransactionDetailProvider _transactionDetailProvider;
  final MarketService _marketService = MarketService();
  Map<String, double> _marketPrices = {};
  Map<String, dynamic>? _traceData;
  List<Map<String, dynamic>>? _internalTransactions;

  // TabController for the tabbed interface
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize TabController with 3 tabs
    _tabController = TabController(length: 3, vsync: this);

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
    // Dispose the TabController
    _tabController.dispose();

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
      _fetchTransactionDetails().then((_) {
        // After fetching transaction details, fetch market data if needed
        if (_detailedTransaction != null && mounted) {
          _fetchMarketData();
        }
      });
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

      // Fetch current market prices
      final prices = await _marketService.getCurrentPrices(tokensToFetch);

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
        _traceData = details?.traceData;
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
              PyusdButton(
                onPressed: _fetchTransactionDetails,
                text: 'Retry',
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
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
        Column(
          children: [
            // Scrollable section for the Status Card
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

            // TabBar section
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TabBar(
                controller: _tabController,
                labelColor: primaryColor,
                unselectedLabelColor: subtitleColor,
                indicatorColor: primaryColor,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "Details", icon: Icon(Icons.info_outline)),
                  Tab(text: "Gas", icon: Icon(Icons.local_gas_station)),
                  Tab(text: "Market", icon: Icon(Icons.show_chart)),
                ],
              ),
            ),

            // Tab content - takes remaining space
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Transaction Details Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
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

                        // Internal transactions card (if available)
                        if (_internalTransactions != null &&
                            _internalTransactions!.isNotEmpty)
                          InternalTransactionWidget(
                            internalTransactions: _internalTransactions!,
                            cardColor: cardColor,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            primaryColor: primaryColor,
                          ),

                        // Transaction trace card (if available)
                        if (_detailedTransaction?.traceData != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: TransactionTraceWidget(
                              transaction: _detailedTransaction!,
                              isDarkMode: widget.isDarkMode,
                              cardColor: cardColor,
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                              primaryColor: primaryColor,
                              onShowRawTraceData: (traceData) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Raw Trace Data'),
                                    content: SingleChildScrollView(
                                      child: SelectableText(
                                        JsonEncoder.withIndent('  ')
                                            .convert(traceData),
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(
                                              text: JsonEncoder.withIndent('  ')
                                                  .convert(traceData),
                                            ),
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text('Copied to clipboard'),
                                            ),
                                          );
                                        },
                                        child: const Text('Copy'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        else if (_detailedTransaction?.traceDataUnavailable ==
                            true)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Card(
                              color: cardColor,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: subtitleColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Transaction Trace',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                color: textColor,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Trace data is not available for this transaction. This is normal for older transactions.',
                                      style: TextStyle(
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
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
                ],
              ),
            ),
          ],
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
