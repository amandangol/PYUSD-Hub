import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../providers/network_provider.dart';
import '../../../../utils/formatter_utils.dart';
import '../../model/transaction_model.dart';
import '../../provider/transactiondetail_provider.dart';
import '../../../../utils/datetime_utils.dart';
import '../../../../services/market_service.dart';

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

      // After fetching transaction details, fetch market data
      if (_detailedTransaction != null) {
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

    // Get colors from theme to match HomeScreen
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
      appBar: AppBar(
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
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: _refreshTransactionDetails,
        child: _detailedTransaction == null
            ? _buildErrorView(backgroundColor, textColor, primaryColor)
            : _buildTransactionDetails(statusColor, isIncoming, cardColor,
                textColor, subtitleColor, primaryColor),
      ),
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
      Color primaryColor) {
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
              _buildStatusCard(
                  statusColor, isIncoming, cardColor, textColor, subtitleColor),
              const SizedBox(height: 16),

              // Market Analysis Card - New Addition
              _buildMarketAnalysisCard(
                  cardColor, textColor, subtitleColor, primaryColor),
              const SizedBox(height: 16),

              // Transaction details card
              _buildDetailsCard(
                  cardColor, textColor, subtitleColor, primaryColor),
              const SizedBox(height: 16),

              // Gas details card
              _buildGasDetailsCard(cardColor, textColor, subtitleColor),

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

  Widget _buildMarketAnalysisCard(Color cardColor, Color textColor,
      Color subtitleColor, Color primaryColor) {
    final tx = _detailedTransaction!;
    final tokenSymbol = tx.tokenSymbol ?? 'ETH';
    final currentPrice = _marketPrices[tokenSymbol] ?? 0.0;

    return Card(
      color: cardColor,
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Market Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current market value1
            _buildDetailRow(
              title: 'Current Price',
              value: _isLoadingMarketData
                  ? 'Loading...'
                  : '\$${currentPrice.toStringAsFixed(6)} USD',
              textColor: textColor,
              subtitleColor: subtitleColor,
              valueColor: primaryColor,
            ),

            // Transaction value at current price
            _buildDetailRow(
              title: 'Value Now',
              value: currentPrice <= 0 || _isLoadingMarketData
                  ? 'Loading...'
                  : '\$${(tx.amount * currentPrice).toStringAsFixed(6)} USD',
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),

            // Gas fee in USD
            _buildDetailRow(
              title: 'Gas Fee (USD)',
              value: _marketPrices['ETH'] == null || _isLoadingMarketData
                  ? 'Loading...'
                  : '\$${(tx.fee * _marketPrices['ETH']!).toStringAsFixed(6)} USD',
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),

            // Transaction efficiency (value to fee ratio)
            if (!_isLoadingMarketData &&
                _marketPrices['ETH'] != null &&
                _marketPrices['ETH']! > 0)
              _buildDetailRow(
                title: 'Value/Fee Ratio',
                value: _calculateValueToFeeRatio(),
                textColor: textColor,
                subtitleColor: subtitleColor,
                valueColor: _getValueToFeeRatioColor(),
              ),
          ],
        ),
      ),
    );
  }

  String _calculateValueToFeeRatio() {
    final tx = _detailedTransaction!;
    final ethPrice = _marketPrices['ETH'] ?? 0.0;

    if (ethPrice <= 0 || tx.fee <= 0) return 'N/A';

    // For token transactions
    if (tx.tokenSymbol != null) {
      final tokenPrice = _marketPrices[tx.tokenSymbol!] ?? 0.0;
      if (tokenPrice <= 0) return 'N/A';

      final txValueUsd = tx.amount * tokenPrice;
      final feeValueUsd = tx.fee * ethPrice;

      if (feeValueUsd <= 0) return 'N/A';

      final ratio = txValueUsd / feeValueUsd;
      return ratio.toStringAsFixed(1) + 'x';
    }
    // For ETH transactions
    else {
      final txValueUsd = tx.amount * ethPrice;
      final feeValueUsd = tx.fee * ethPrice;

      if (feeValueUsd <= 0) return 'N/A';

      final ratio = txValueUsd / feeValueUsd;
      return ratio.toStringAsFixed(1) + 'x';
    }
  }

  Color _getValueToFeeRatioColor() {
    try {
      final ratioText = _calculateValueToFeeRatio();
      if (ratioText == 'N/A') return Colors.grey;

      final ratio = double.parse(ratioText.replaceAll('x', ''));

      if (ratio < 1) return Colors.red;
      if (ratio < 10) return Colors.orange;
      if (ratio < 50) return Colors.green;
      return Colors.blue;
    } catch (_) {
      return Colors.grey;
    }
  }

  Widget _buildStatusCard(Color statusColor, bool isIncoming, Color cardColor,
      Color textColor, Color subtitleColor) {
    final tx = _detailedTransaction!;

    return Card(
      color: cardColor,
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(widget.transaction.status),
                color: statusColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            // Transaction type and status
            Text(
              isIncoming ? 'Received' : 'Sent',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),

            // Status with confirmations
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      fontSize: 14,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount
            Text(
              _formatAmount(tx),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isIncoming ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 12),

            // Fee and date
            Text(
              'Fee: ${tx.fee.toStringAsFixed(10)} ETH',
              style: TextStyle(
                fontSize: 14,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateTimeUtils.formatDateTime(tx.timestamp),
              style: TextStyle(
                fontSize: 14,
                color: subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(Color cardColor, Color textColor,
      Color subtitleColor, Color primaryColor) {
    final tx = _detailedTransaction!;

    return Card(
      color: cardColor,
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment_outlined, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Transaction Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              title: 'Transaction Hash',
              value: FormatterUtils.formatHash(tx.hash),
              canCopy: true,
              data: tx.hash,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildDetailRow(
              title: 'Status',
              value: _getStatusTextWithConfirmations(),
              valueColor: _getStatusColor(tx.status),
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildDetailRow(
              title: 'Block',
              value: tx.blockNumber != 'Pending' ? tx.blockNumber : 'Pending',
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildDetailRow(
              title: 'Block Hash',
              value: tx.blockHash != 'Pending'
                  ? FormatterUtils.formatHash(tx.blockHash)
                  : 'Pending',
              canCopy: tx.blockHash != 'Pending',
              data: tx.blockHash != 'Pending' ? tx.blockHash : null,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildDetailRow(
              title: 'From',
              value: FormatterUtils.formatHash(tx.from),
              canCopy: true,
              data: tx.from,
              valueColor:
                  tx.from.toLowerCase() == widget.currentAddress.toLowerCase()
                      ? primaryColor
                      : null,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildDetailRow(
              title: 'To',
              value: FormatterUtils.formatHash(tx.to),
              canCopy: true,
              data: tx.to,
              valueColor:
                  tx.to.toLowerCase() == widget.currentAddress.toLowerCase()
                      ? primaryColor
                      : null,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            if (tx.tokenContractAddress != null) ...[
              _buildDetailRow(
                title: 'Token',
                value: tx.tokenSymbol ?? 'Unknown Token',
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
              if (tx.tokenName != null)
                _buildDetailRow(
                  title: 'Token Name',
                  value: tx.tokenName!,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                ),
              if (tx.tokenDecimals != null)
                _buildDetailRow(
                  title: 'Token Decimals',
                  value: tx.tokenDecimals.toString(),
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                ),
              _buildDetailRow(
                title: 'Token Contract',
                value: FormatterUtils.formatHash(tx.tokenContractAddress!),
                canCopy: true,
                data: tx.tokenContractAddress!,
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
            ],
            _buildDetailRow(
              title: 'Nonce',
              value: tx.nonce.toString(),
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            if (tx.isError && tx.errorMessage != null)
              _buildDetailRow(
                title: 'Error',
                value: tx.errorMessage!,
                valueColor: Colors.red,
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
            if (tx.data != null && tx.data!.length > 2)
              _buildDetailRow(
                title: 'Transaction Data',
                value: FormatterUtils.formatHash(tx.data!),
                canCopy: true,
                data: tx.data,
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGasDetailsCard(
      Color cardColor, Color textColor, Color subtitleColor) {
    final tx = _detailedTransaction!;

    return Card(
      color: cardColor,
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_gas_station_outlined,
                  size: 18,
                  color: widget.isDarkMode ? Colors.orange : Colors.deepOrange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Gas Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              title: 'Gas Limit',
              value: '${tx.gasUsed.toStringAsFixed(0)} units',
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildDetailRow(
              title: 'Gas Used',
              value: '${tx.gasUsed.toStringAsFixed(0)} units',
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildDetailRow(
              title: 'Gas Price',
              value: '${tx.gasPrice.toStringAsFixed(9)} Gwei',
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildDetailRow(
              title: 'Gas Efficiency',
              value: _calculateGasEfficiency(),
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildDetailRow(
              title: 'Transaction Fee',
              value: '${tx.fee.toStringAsFixed(8)} ETH',
              valueColor: widget.isDarkMode ? Colors.orange : Colors.deepOrange,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String title,
    required String value,
    bool canCopy = false,
    String? data,
    Color? valueColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? textColor,
              ),
            ),
          ),
          if (canCopy && data != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: data));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.copy_outlined,
                    size: 16,
                    color: subtitleColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatAmount(TransactionDetailModel tx) {
    if (tx.tokenSymbol != null) {
      return '${tx.amount.toStringAsFixed(2)} ${tx.tokenSymbol}';
    } else {
      return '${tx.amount.toStringAsFixed(6)} ETH';
    }
  }

  String _getStatusText() {
    switch (widget.transaction.status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.confirmed:
        return 'Confirmed';
      case TransactionStatus.failed:
        return 'Failed';
    }
  }

  String _getStatusTextWithConfirmations() {
    if (_detailedTransaction == null) return 'Unknown';

    switch (_detailedTransaction!.status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.confirmed:
        return 'Confirmed (${_detailedTransaction!.confirmations} confirmations)';
      case TransactionStatus.failed:
        return 'Failed';
    }
  }

  IconData _getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.confirmed:
        return Icons.check_circle;
      case TransactionStatus.pending:
        return Icons.pending;
      case TransactionStatus.failed:
        return Icons.error;
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

  String _calculateGasEfficiency() {
    final tx = _detailedTransaction!;

    // Check if gasPrice is not zero to avoid division by zero
    if (tx.gasPrice <= 0) {
      return 'N/A';
    }

    // Calculate what percentage of the gas limit was actually used
    final double gasLimit =
        tx.gasUsed; // Assuming gasUsed here is actually gas limit
    final double gasUsed = tx.gasUsed;

    // If we have both values, calculate efficiency
    if (gasLimit > 0 && gasUsed > 0) {
      final double efficiency = (gasUsed / gasLimit) * 100;
      return '${efficiency.toStringAsFixed(1)}%';
    }

    return 'N/A';
  }
}
