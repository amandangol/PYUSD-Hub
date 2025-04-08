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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: widget.cardColor,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap:
            _isLoading ? null : () => _handleTransactionTap(widget.transaction),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildTransactionIcon(colorScheme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTransactionHeader(colorScheme),
                        const SizedBox(height: 4),
                        _buildTransactionHash(colorScheme),
                        const SizedBox(height: 4),
                        _buildTransactionTimestamp(colorScheme),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildAmount(colorScheme),
                      const SizedBox(height: 4),
                      _buildStatusPill(colorScheme),
                    ],
                  ),
                ],
              ),
            ),
            if (_isLoading) _buildLoadingOverlay(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionIcon(ColorScheme colorScheme) {
    final isIncoming =
        widget.transaction.direction == TransactionDirection.incoming;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isIncoming ? Colors.green : Colors.red).withOpacity(0.1),
            (isIncoming ? Colors.green : Colors.red).withOpacity(0.05),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
        color: isIncoming ? Colors.green : Colors.red,
        size: 20,
      ),
    );
  }

  Widget _buildTransactionHeader(ColorScheme colorScheme) {
    final isIncoming =
        widget.transaction.direction == TransactionDirection.incoming;
    return Row(
      children: [
        Text(
          isIncoming ? 'Received' : 'Sent',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: colorScheme.onSurface,
          ),
        ),
        if (widget.transaction.tokenSymbol != null)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.1),
                  colorScheme.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.transaction.tokenSymbol!,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionHash(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            colorScheme.surfaceVariant,
            colorScheme.surfaceVariant.withOpacity(0.8),
          ],
        ),
      ),
      child: Text(
        FormatterUtils.formatHash(widget.transaction.hash),
        style: TextStyle(
          fontSize: 12,
          fontFamily: "monospace",
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildTransactionTimestamp(ColorScheme colorScheme) {
    return Text(
      DateTimeUtils.formatDateTime(widget.transaction.timestamp),
      style: TextStyle(
        fontSize: 12,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildAmount(ColorScheme colorScheme) {
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

  Widget _buildStatusPill(ColorScheme colorScheme) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData iconData;

    switch (widget.transaction.status) {
      case TransactionStatus.confirmed:
        backgroundColor = Colors.green;
        textColor = Colors.white;
        text = 'Confirmed';
        iconData = Icons.check_circle;
        break;
      case TransactionStatus.failed:
        backgroundColor = Colors.red;
        textColor = Colors.white;
        text = 'Failed';
        iconData = Icons.error;
        break;
      case TransactionStatus.pending:
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        text = 'Pending';
        iconData = Icons.access_time;
        break;
      default:
        backgroundColor = Colors.grey;
        textColor = Colors.white;
        text = 'Unknown';
        iconData = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(0.8),
          ],
        ),
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

  Widget _buildLoadingOverlay(ColorScheme colorScheme) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
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
          SnackBar(
            content: const Text(
              'Transaction details are not available for pending transactions',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
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
          SnackBar(
            content: const Text('Please wait while network is switching...'),
            backgroundColor: Theme.of(context).colorScheme.error,
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
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
