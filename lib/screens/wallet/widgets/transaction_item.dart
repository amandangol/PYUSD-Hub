import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/datetime_utils.dart';
import '../../transactions/model/transaction_model.dart';
import '../../../providers/network_provider.dart';
import '../../../utils/formatter_utils.dart';
import '../../transactions/provider/transactiondetail_provider.dart';
import '../../transactions/view/transaction_details/transaction_detail_screen.dart';

class TransactionItem extends StatefulWidget {
  final TransactionModel transaction;
  final String currentAddress;
  final bool isDarkMode;
  final Color cardColor;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.currentAddress,
    required this.isDarkMode,
    required this.cardColor,
  });

  @override
  State<TransactionItem> createState() => _TransactionItemState();
}

class _TransactionItemState extends State<TransactionItem> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: widget.cardColor,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap:
            _isLoading ? null : () => _handleTransactionTap(widget.transaction),
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildTransactionIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTransactionHeader(),
                        const SizedBox(height: 4),
                        _buildTransactionHash(),
                        const SizedBox(height: 4),
                        _buildTransactionTimestamp(),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildAmount(),
                      const SizedBox(height: 4),
                      _buildStatusPill(),
                    ],
                  ),
                ],
              ),
            ),
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionIcon() {
    final isIncoming =
        widget.transaction.direction == TransactionDirection.incoming;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: (isIncoming ? Colors.green : Colors.red).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
        color: isIncoming ? Colors.green : Colors.red,
        size: 20,
      ),
    );
  }

  Widget _buildTransactionHeader() {
    final isIncoming =
        widget.transaction.direction == TransactionDirection.incoming;
    return Row(
      children: [
        Text(
          isIncoming ? 'Received' : 'Sent',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: widget.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        if (widget.transaction.tokenSymbol != null)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.transaction.tokenSymbol!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionHash() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: widget.isDarkMode ? Colors.white10 : Colors.black12,
      ),
      child: Text(
        FormatterUtils.formatHash(widget.transaction.hash),
        style: TextStyle(
          fontSize: 12,
          fontFamily: "monospace",
          color: widget.isDarkMode ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildTransactionTimestamp() {
    return Text(
      DateTimeUtils.formatDateTime(widget.transaction.timestamp),
      style: TextStyle(
        fontSize: 12,
        color: widget.isDarkMode ? Colors.white70 : Colors.black54,
      ),
    );
  }

  Widget _buildAmount() {
    final isIncoming =
        widget.transaction.direction == TransactionDirection.incoming;
    final amount = widget.transaction.amount;
    final symbol = widget.transaction.tokenSymbol ?? 'ETH';
    final formattedAmount = symbol == 'PYUSD'
        ? '${amount.toStringAsFixed(2)} PYUSD'
        : '${amount.toStringAsFixed(6)} ETH';

    return Text(
      formattedAmount,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: isIncoming ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _buildStatusPill() {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData iconData;

    switch (widget.transaction.status) {
      case TransactionStatus.confirmed:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        text = 'Confirmed';
        iconData = Icons.check_circle;
        break;
      case TransactionStatus.failed:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        text = 'Failed';
        iconData = Icons.error;
        break;
      case TransactionStatus.pending:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        text = 'Pending';
        iconData = Icons.access_time;
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        text = 'Unknown';
        iconData = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTransactionTap(TransactionModel transaction) async {
    if (!mounted) return;

    if (transaction.status == TransactionStatus.pending) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Transaction details are not available for pending transactions'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final transactionDetailProvider =
        Provider.of<TransactionDetailProvider>(context, listen: false);
    final networkProvider =
        Provider.of<NetworkProvider>(context, listen: false);

    if (networkProvider.isSwitching) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait while network is switching...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final cachedDetails =
        transactionDetailProvider.getCachedTransactionDetails(transaction.hash);
    final bool isRecentlyFetched = cachedDetails != null;

    setState(() => _isLoading = true);

    try {
      if (context.mounted) {
        final detailsToShow = isRecentlyFetched ? cachedDetails : transaction;

        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;

        setState(() => _isLoading = false);

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(
              transaction: detailsToShow,
              currentAddress: widget.currentAddress,
              isDarkMode: widget.isDarkMode,
              networkType: networkProvider.currentNetwork,
              rpcUrl: networkProvider.currentRpcEndpoint,
              needsRefresh: !isRecentlyFetched,
            ),
          ),
        );

        if (!isRecentlyFetched) {
          transactionDetailProvider.getTransactionDetails(
            txHash: transaction.hash,
            rpcUrl: networkProvider.currentRpcEndpoint,
            networkType: networkProvider.currentNetwork,
            currentAddress: widget.currentAddress,
            forceRefresh: false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
