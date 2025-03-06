import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../providers/network_provider.dart';
import '../providers/transactiondetail_provider.dart';
import '../utils/datetime_utils.dart';

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

    // Determine transaction status color
    final statusColor = _getStatusColor(widget.transaction.status);

    // Show a placeholder view while data is loading
    if (_isInitializing && _detailedTransaction == null) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
        foregroundColor: widget.isDarkMode ? Colors.white : Colors.black,
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
        onRefresh: _refreshTransactionDetails,
        child: _detailedTransaction == null
            ? _buildErrorView()
            : _buildTransactionDetails(statusColor, isIncoming),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
        foregroundColor: widget.isDarkMode ? Colors.white : Colors.black,
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

  Widget _buildErrorView() {
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
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionDetails(Color statusColor, bool isIncoming) {
    return Stack(
      children: [
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction status and type card
              _buildStatusCard(statusColor, isIncoming),
              const SizedBox(height: 16),

              // Transaction details card
              _buildDetailsCard(),
              const SizedBox(height: 16),

              // Gas details card
              _buildGasDetailsCard(),

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
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusCard(Color statusColor, bool isIncoming) {
    return Card(
      color: widget.isDarkMode ? Colors.grey[900] : Colors.white,
      elevation: 1,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
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
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Status with confirmations
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      fontSize: 14,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount
            Text(
              _formatAmount(_detailedTransaction!),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isIncoming ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),

            // Fee and date
            Text(
              'Fee: ${_detailedTransaction!.fee.toStringAsFixed(6)} ETH',
              style: TextStyle(
                fontSize: 14,
                color: widget.isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateTimeUtils.formatDateTime(_detailedTransaction!.timestamp),
              style: TextStyle(
                fontSize: 14,
                color: widget.isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      color: widget.isDarkMode ? Colors.grey[900] : Colors.white,
      elevation: 1,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              title: 'Transaction Hash',
              value: _formatHash(_detailedTransaction!.hash),
              canCopy: true,
              data: _detailedTransaction!.hash,
            ),
            _buildDetailRow(
              title: 'Status',
              value: _getStatusTextWithConfirmations(),
              valueColor: _getStatusColor(widget.transaction.status),
            ),
            _buildDetailRow(
              title: 'Block',
              value: _detailedTransaction!.blockNumber > 0
                  ? _detailedTransaction!.blockNumber.toString()
                  : 'Pending',
            ),
            _buildDetailRow(
              title: 'From',
              value: _formatHash(_detailedTransaction!.from),
              canCopy: true,
              data: _detailedTransaction!.from,
              valueColor: _detailedTransaction!.from.toLowerCase() ==
                      widget.currentAddress.toLowerCase()
                  ? Colors.orange
                  : null,
            ),
            _buildDetailRow(
              title: 'To',
              value: _formatHash(_detailedTransaction!.to),
              canCopy: true,
              data: _detailedTransaction!.to,
              valueColor: _detailedTransaction!.to.toLowerCase() ==
                      widget.currentAddress.toLowerCase()
                  ? Colors.orange
                  : null,
            ),
            if (_detailedTransaction!.tokenContractAddress != null) ...[
              _buildDetailRow(
                title: 'Token',
                value: _detailedTransaction!.tokenSymbol ?? 'Unknown Token',
              ),
              _buildDetailRow(
                title: 'Token Contract',
                value: _formatHash(_detailedTransaction!.tokenContractAddress!),
                canCopy: true,
                data: _detailedTransaction!.tokenContractAddress!,
              ),
            ],
            _buildDetailRow(
              title: 'Nonce',
              value: _detailedTransaction!.nonce.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGasDetailsCard() {
    return Card(
      color: widget.isDarkMode ? Colors.grey[900] : Colors.white,
      elevation: 1,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_gas_station_outlined, size: 20),
                SizedBox(width: 8),
                Text(
                  'Gas Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              title: 'Gas Limit',
              value:
                  '${_detailedTransaction!.gasLimit.toStringAsFixed(0)} units',
            ),
            _buildDetailRow(
              title: 'Gas Used',
              value:
                  '${_detailedTransaction!.gasUsed.toStringAsFixed(0)} units',
            ),
            _buildDetailRow(
              title: 'Gas Price',
              value:
                  '${_detailedTransaction!.gasPrice.toStringAsFixed(2)} Gwei',
            ),
            _buildDetailRow(
              title: 'Gas Efficiency',
              value: _calculateGasEfficiency(),
            ),
            _buildDetailRow(
              title: 'Transaction Fee',
              value: '${_detailedTransaction!.fee.toStringAsFixed(6)} ETH',
              valueColor: Colors.orange,
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
                color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ??
                    (widget.isDarkMode ? Colors.white : Colors.black87),
              ),
            ),
          ),
          if (canCopy && data != null)
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: data));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatAmount(TransactionDetailModel tx) {
    if (tx.tokenSymbol != null) {
      return '${tx.value.toStringAsFixed(tx.tokenDecimals != null && tx.tokenDecimals! <= 6 ? tx.tokenDecimals! : 6)} ${tx.tokenSymbol}';
    } else {
      return '${tx.value.toStringAsFixed(6)} ETH';
    }
  }

  String _formatHash(String hash) {
    if (hash.length <= 16) return hash;
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 8)}';
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
    final double efficiency =
        (_detailedTransaction!.gasUsed / _detailedTransaction!.gasLimit) * 100;
    return '${efficiency.toStringAsFixed(1)}%';
  }
}
