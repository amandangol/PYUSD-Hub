import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pyusd_forensics/utils/formatter_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../model/transaction_model.dart';
import '../../../../providers/network_provider.dart';
import '../../provider/transactiondetail_provider.dart';
import '../../../../utils/datetime_utils.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;
  final String currentAddress;
  final bool isDarkMode;
  final NetworkType networkType;
  final String rpcUrl;

  const TransactionDetailScreen({
    Key? key,
    required this.transaction,
    required this.currentAddress,
    required this.isDarkMode,
    required this.networkType,
    required this.rpcUrl,
  }) : super(key: key);

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  TransactionDetailModel? _detailedTransaction;
  bool _isRefreshing = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
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
    final transactionDetailProvider =
        Provider.of<TransactionDetailProvider>(context, listen: false);

    setState(() {
      _isInitializing = true;
    });

    try {
      // First check if the data is already in the cache
      if (transactionDetailProvider
          .isTransactionCached(widget.transaction.hash)) {
        final details = await transactionDetailProvider.getTransactionDetails(
          txHash: widget.transaction.hash,
          rpcUrl: widget.rpcUrl,
          networkType: widget.networkType,
          currentAddress: widget.currentAddress,
        );

        if (mounted) {
          setState(() {
            _detailedTransaction = details;
            _isInitializing = false;
          });
        }
      } else {
        // If not cached, fetch it
        _fetchTransactionDetails();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        _showErrorSnackBar('Error initializing data');
      }
    }
  }

  Future<void> _fetchTransactionDetails() async {
    final transactionDetailProvider =
        Provider.of<TransactionDetailProvider>(context, listen: false);

    try {
      final details = await transactionDetailProvider.getTransactionDetails(
        txHash: widget.transaction.hash,
        rpcUrl: widget.rpcUrl,
        networkType: widget.networkType,
        currentAddress: widget.currentAddress,
      );

      if (mounted) {
        setState(() {
          _detailedTransaction = details;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        _showErrorSnackBar('Error loading transaction details');
      }
    }
  }

  Future<void> _refreshTransactionDetails() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    final transactionDetailProvider =
        Provider.of<TransactionDetailProvider>(context, listen: false);

    try {
      final details = await transactionDetailProvider.getTransactionDetails(
        txHash: widget.transaction.hash,
        rpcUrl: widget.rpcUrl,
        networkType: widget.networkType,
        currentAddress: widget.currentAddress,
        forceRefresh: true,
      );

      if (mounted) {
        setState(() {
          _detailedTransaction = details;
          _isRefreshing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction details updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        _showErrorSnackBar('Failed to refresh transaction details');
      }
    }
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

  Widget _buildStatusCard(Color statusColor, bool isIncoming, Color cardColor,
      Color textColor, Color subtitleColor) {
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
              _formatAmount(_detailedTransaction!),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isIncoming ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 12),

            // Fee and date
            Text(
              'Fee: ${_detailedTransaction!.fee.toStringAsFixed(10)} ETH',
              style: TextStyle(
                fontSize: 14,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateTimeUtils.formatDateTime(_detailedTransaction!.timestamp),
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
              value: FormatterUtils.formatHash(_detailedTransaction!.hash),
              canCopy: true,
              data: _detailedTransaction!.hash,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildDetailRow(
              title: 'Status',
              value: _getStatusTextWithConfirmations(),
              valueColor: _getStatusColor(_detailedTransaction!.status),
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildDetailRow(
              title: 'Block',
              value: _detailedTransaction!.blockNumber != 'Pending'
                  ? _detailedTransaction!.blockNumber
                  : 'Pending',
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildDetailRow(
              title: 'Block Hash',
              value: _detailedTransaction!.blockHash != 'Pending'
                  ? FormatterUtils.formatHash(_detailedTransaction!.blockHash)
                  : 'Pending',
              canCopy: _detailedTransaction!.blockHash != 'Pending',
              data: _detailedTransaction!.blockHash != 'Pending'
                  ? _detailedTransaction!.blockHash
                  : null,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildDetailRow(
              title: 'From',
              value: FormatterUtils.formatHash(_detailedTransaction!.from),
              canCopy: true,
              data: _detailedTransaction!.from,
              valueColor: _detailedTransaction!.from.toLowerCase() ==
                      widget.currentAddress.toLowerCase()
                  ? primaryColor
                  : null,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildDetailRow(
              title: 'To',
              value: FormatterUtils.formatHash(_detailedTransaction!.to),
              canCopy: true,
              data: _detailedTransaction!.to,
              valueColor: _detailedTransaction!.to.toLowerCase() ==
                      widget.currentAddress.toLowerCase()
                  ? primaryColor
                  : null,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            if (_detailedTransaction!.tokenContractAddress != null) ...[
              _buildDetailRow(
                title: 'Token',
                value: _detailedTransaction!.tokenSymbol ?? 'Unknown Token',
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
              if (_detailedTransaction!.tokenName != null)
                _buildDetailRow(
                  title: 'Token Name',
                  value: _detailedTransaction!.tokenName!,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                ),
              if (_detailedTransaction!.tokenDecimals != null)
                _buildDetailRow(
                  title: 'Token Decimals',
                  value: _detailedTransaction!.tokenDecimals.toString(),
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                ),
              _buildDetailRow(
                title: 'Token Contract',
                value: FormatterUtils.formatHash(
                    _detailedTransaction!.tokenContractAddress!),
                canCopy: true,
                data: _detailedTransaction!.tokenContractAddress!,
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
            ],
            _buildDetailRow(
              title: 'Nonce',
              value: _detailedTransaction!.nonce.toString(),
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            if (_detailedTransaction!.isError &&
                _detailedTransaction!.errorMessage != null)
              _buildDetailRow(
                title: 'Error',
                value: _detailedTransaction!.errorMessage!,
                valueColor: Colors.red,
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
            if (_detailedTransaction!.data != null &&
                _detailedTransaction!.data!.length > 2)
              _buildDetailRow(
                title: 'Transaction Data',
                value: FormatterUtils.formatHash(_detailedTransaction!.data!),
                canCopy: true,
                data: _detailedTransaction!.data,
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
              value:
                  '${_detailedTransaction!.gasUsed.toStringAsFixed(0)} units',
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildDetailRow(
              title: 'Gas Used',
              value:
                  '${_detailedTransaction!.gasUsed.toStringAsFixed(0)} units',
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildDetailRow(
              title: 'Gas Price',
              value:
                  '${_detailedTransaction!.gasPrice.toStringAsFixed(9)} Gwei',
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
              value: '${_detailedTransaction!.fee.toStringAsFixed(8)} ETH',
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

    switch (widget.transaction.status) {
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
    // Check if gasPrice is not zero to avoid division by zero
    if (_detailedTransaction!.gasPrice <= 0) {
      return 'N/A';
    }

    // Calculate what percentage of the gas limit was actually used
    final double gasLimit = _detailedTransaction!
        .gasUsed; // Assuming gasUsed here is actually gas limit
    final double gasUsed = _detailedTransaction!.gasUsed;

    // If we have both values, calculate efficiency
    if (gasLimit > 0 && gasUsed > 0) {
      final double efficiency = (gasUsed / gasLimit) * 100;
      return '${efficiency.toStringAsFixed(1)}%';
    }

    return 'N/A';
  }
}
