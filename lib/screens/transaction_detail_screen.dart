import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/transaction.dart';
import '../services/transaction_analysis_service.dart';
import '../utils/snackbar_utils.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;
  final String currentAddress;

  const TransactionDetailScreen({
    Key? key,
    required this.transaction,
    required this.currentAddress,
  }) : super(key: key);

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late TransactionAnalysisService _analysisService;
  bool _isLoading = true;
  bool _isMounted = false;
  Map<String, dynamic> _gasAnalysis = {};
  Map<String, dynamic> _marketAnalysis = {};
  Map<String, dynamic> _fullTxDetails = {};

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _analysisService = TransactionAnalysisService();
    _loadTransactionDetails();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _loadTransactionDetails() async {
    if (!_isMounted) return;

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Use Future.wait to run all API calls simultaneously
      final results = await Future.wait([
        _analysisService.getFullTransactionDetails(widget.transaction.hash),
        _analysisService.analyzeGasCost(
          widget.transaction.hash,
          double.parse(widget.transaction.fee),
        ),
        _analysisService.getMarketConditionsAtTime(
          widget.transaction.timestamp,
        ),
      ]);

      // Check if widget is still mounted before updating state
      if (!_isMounted) return;

      setState(() {
        _fullTxDetails = results[0];
        _gasAnalysis = results[1];
        _marketAnalysis = results[2];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading transaction details: $e');
      // Check if widget is still mounted before updating state
      if (!_isMounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 10)}...${address.substring(address.length - 8)}';
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    SnackbarUtil.showSnackbar(
      context: context,
      message: "$label copied to clipboard",
    );
  }

  Future<void> _openInExplorer() async {
    final String explorerUrl =
        'https://holesky.etherscan.io/tx/${widget.transaction.hash}';
    final Uri url = Uri.parse(explorerUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      SnackbarUtil.showSnackbar(
          context: context, message: "Could not open explorer", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final bool isIncoming = widget.transaction.to.toLowerCase() ==
        widget.currentAddress.toLowerCase();
    final primaryColor = isIncoming ? Colors.green : Colors.red;
    final backgroundColor = isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;
    final cardColor = isDarkMode ? const Color(0xFF252543) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Transaction Details',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openInExplorer,
            tooltip: 'View in Explorer',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTransactionDetails,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction Status Card
                    _buildStatusCard(context, cardColor, isDarkMode,
                        primaryColor, isIncoming),

                    const SizedBox(height: 20),

                    // Transaction Details
                    _buildDetailsCard(context, cardColor, isDarkMode),

                    const SizedBox(height: 20),

                    // Gas Analysis
                    _buildGasAnalysisCard(context, cardColor, isDarkMode),

                    const SizedBox(height: 20),

                    // Market Context
                    _buildMarketContextCard(context, cardColor, isDarkMode),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard(BuildContext context, Color cardColor,
      bool isDarkMode, Color primaryColor, bool isIncoming) {
    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                    color: primaryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIncoming ? 'Received PYUSD' : 'Sent PYUSD',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMMM dd, yyyy • HH:mm:ss')
                            .format(widget.transaction.timestamp),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                Text(
                  '\$${widget.transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: widget.transaction.status == 'Confirmed'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.transaction.status == 'Confirmed'
                        ? Icons.check_circle
                        : Icons.pending,
                    color: widget.transaction.status == 'Confirmed'
                        ? Colors.green
                        : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.transaction.status,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.transaction.status == 'Confirmed'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openInExplorer,
              icon: const Icon(Icons.open_in_new),
              label: const Text('View on Etherscan'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(
      BuildContext context, Color cardColor, bool isDarkMode) {
    final blocks = _fullTxDetails['block'] ?? 0;
    final confirmations = _fullTxDetails['confirmations'] ?? 0;

    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'From:',
              widget.transaction.from,
              isDarkMode,
              onTap: () => _copyToClipboard(widget.transaction.from, 'Address'),
            ),
            const Divider(),
            _buildDetailRow(
              'To:',
              widget.transaction.to,
              isDarkMode,
              onTap: () => _copyToClipboard(widget.transaction.to, 'Address'),
            ),
            const Divider(),
            _buildDetailRow(
              'Transaction Hash:',
              widget.transaction.hash,
              isDarkMode,
              onTap: () =>
                  _copyToClipboard(widget.transaction.hash, 'Transaction hash'),
            ),
            const Divider(),
            _buildDetailRow(
              'Block:',
              blocks.toString(),
              isDarkMode,
            ),
            const Divider(),
            _buildDetailRow(
              'Confirmations:',
              confirmations.toString(),
              isDarkMode,
            ),
            const Divider(),
            _buildDetailRow(
              'Fee:',
              '\$${widget.transaction.fee}',
              isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGasAnalysisCard(
      BuildContext context, Color cardColor, bool isDarkMode) {
    final gasPrice = _gasAnalysis['gasPrice'] ?? '0';
    final gasUsed = _gasAnalysis['gasUsed'] ?? '0';
    final gasLimit = _gasAnalysis['gasLimit'] ?? '0';
    final gasEfficiency = _gasAnalysis['efficiency'] ?? '0';

    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gas Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Gas Price:',
              '$gasPrice Gwei',
              isDarkMode,
            ),
            const Divider(),
            _buildDetailRow(
              'Gas Used:',
              gasUsed,
              isDarkMode,
            ),
            const Divider(),
            _buildDetailRow(
              'Gas Limit:',
              gasLimit,
              isDarkMode,
            ),
            const Divider(),
            _buildDetailRow(
              'Efficiency:',
              '$gasEfficiency%',
              isDarkMode,
            ),
            const SizedBox(height: 16),
            if (_gasAnalysis['comparisonText'] != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Text(
                  _gasAnalysis['comparisonText'] ?? '',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketContextCard(
      BuildContext context, Color cardColor, bool isDarkMode) {
    final ethPrice = _marketAnalysis['ethPrice'] ?? 0.0;
    final pyusdPrice = _marketAnalysis['pyusdPrice'] ?? 1.0;
    final volatility = _marketAnalysis['volatility'] ?? 'Low';

    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Market Context',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'ETH Price at Time:',
              '\$${ethPrice.toStringAsFixed(2)}',
              isDarkMode,
            ),
            const Divider(),
            _buildDetailRow(
              'PYUSD Price:',
              '\$${pyusdPrice.toStringAsFixed(2)}',
              isDarkMode,
            ),
            const Divider(),
            _buildDetailRow(
              'Market Volatility:',
              volatility,
              isDarkMode,
            ),
            const SizedBox(height: 16),
            if (_marketAnalysis['insights'] != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.purple.withOpacity(0.1)
                      : Colors.purple.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Text(
                  _marketAnalysis['insights'] ?? '',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDarkMode,
      {VoidCallback? onTap}) {
    final displayValue = value.length > 20 ? _formatAddress(value) : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      displayValue,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.copy,
                      size: 14,
                      color: isDarkMode ? Colors.white54 : Colors.black45,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
