import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/transaction.dart';
import '../services/blockchain_service.dart';
import '../services/market_service.dart'; // We'll create this service

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;
  final String currentAddress;
  final bool isDarkMode;

  const TransactionDetailScreen({
    Key? key,
    required this.transaction,
    required this.currentAddress,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _TransactionDetailScreenState createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late BlockchainService _blockchainService;
  late MarketService _marketService;

  // Transaction context details
  double? _ethPrice;
  double? _pyusdPrice;
  double _usdTransactionValue = 0.0;
  Map<String, dynamic>? _gasAnalysis;

  @override
  void initState() {
    super.initState();
    _blockchainService = BlockchainService();
    _marketService = MarketService();
    _fetchTransactionContext();
  }

  Future<void> _fetchTransactionContext() async {
    try {
      // Fetch market prices
      final marketPrices =
          await _marketService.getCurrentPrices(['ETH', 'PYUSD']);
      setState(() {
        _ethPrice = marketPrices['ETH'];
        _pyusdPrice = marketPrices['PYUSD'];

        // Calculate USD value of transaction
        _usdTransactionValue = widget.transaction.amount * (_pyusdPrice ?? 0);
      });

      // Fetch gas analysis for this transaction
      final gasAnalysis = await _blockchainService.analyzeTransactionGas(
          widget.transaction.hash,
          widget.transaction.networkName ?? 'Sepolia Testnet');

      setState(() {
        _gasAnalysis = gasAnalysis;
      });
    } catch (e) {
      print('Transaction context fetch error: $e');
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _launchExplorerLink() async {
    if (widget.transaction.hashLink != null) {
      final Uri url = Uri.parse(widget.transaction.hashLink!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = widget.isDarkMode ? Colors.white70 : Colors.black54;
    final cardColor =
        widget.isDarkMode ? const Color(0xFF252543) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction Details', style: TextStyle(color: textColor)),
        backgroundColor: cardColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Summary Card
            _buildTransactionSummaryCard(textColor, subtextColor, cardColor),

            // Transaction Details Section
            _buildTransactionDetailsSection(textColor, subtextColor),

            // Gas Analysis Section
            if (_gasAnalysis != null)
              _buildGasAnalysisSection(textColor, subtextColor),

            // Market Context Section
            if (_ethPrice != null && _pyusdPrice != null)
              _buildMarketContextSection(textColor, subtextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSummaryCard(
      Color textColor, Color subtextColor, Color cardColor) {
    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: widget.transaction.isSend(widget.currentAddress)
                    ? Colors.red.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                widget.transaction.isSend(widget.currentAddress)
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                color: widget.transaction.isSend(widget.currentAddress)
                    ? Colors.red
                    : Colors.green,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.transaction.isSend(widget.currentAddress)
                        ? 'Sent PYUSD'
                        : 'Received PYUSD',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.transaction.amount.toStringAsFixed(2)} PYUSD',
                    style: TextStyle(
                      fontSize: 16,
                      color: subtextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _usdTransactionValue > 0
                        ? '\$${_usdTransactionValue.toStringAsFixed(2)} USD'
                        : 'Calculating...',
                    style: TextStyle(
                      fontSize: 14,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetailsSection(Color textColor, Color subtextColor) {
    return Card(
      color: widget.isDarkMode ? const Color(0xFF252543) : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              'Transaction Hash',
              widget.transaction.hash,
              textColor,
              subtextColor,
              onCopy: () {},
              onTap: _launchExplorerLink,
            ),
            _buildDetailRow(
              'From',
              widget.transaction.from,
              textColor,
              subtextColor,
              onCopy: () {},
            ),
            _buildDetailRow(
              'To',
              widget.transaction.to,
              textColor,
              subtextColor,
              onCopy: () {},
            ),
            _buildDetailRow(
              'Date',
              widget.transaction.timestamp.toString(),
              textColor,
              subtextColor,
            ),
            _buildDetailRow(
              'Network',
              widget.transaction.networkName ?? 'Unknown',
              textColor,
              subtextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    Color textColor,
    Color subtextColor, {
    VoidCallback? onCopy,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                value,
                style: TextStyle(
                  color: onTap != null ? Colors.blue : subtextColor,
                  decoration: onTap != null
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: Icon(Icons.copy, size: 20, color: subtextColor),
              onPressed: () => onCopy(),
            ),
        ],
      ),
    );
  }

  Widget _buildGasAnalysisSection(Color textColor, Color subtextColor) {
    return Card(
      color: widget.isDarkMode ? const Color(0xFF252543) : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gas Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            ..._gasAnalysis!.entries
                .map((entry) => _buildDetailRow(
                      entry.key,
                      entry.value.toString(),
                      textColor,
                      subtextColor,
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketContextSection(Color textColor, Color subtextColor) {
    return Card(
      color: widget.isDarkMode ? const Color(0xFF252543) : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Market Context',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'ETH Price',
              '\$${_ethPrice?.toStringAsFixed(2) ?? 'N/A'}',
              textColor,
              subtextColor,
            ),
            _buildDetailRow(
              'PYUSD Price',
              '\$${_pyusdPrice?.toStringAsFixed(2) ?? 'N/A'}',
              textColor,
              subtextColor,
            ),
          ],
        ),
      ),
    );
  }
}
