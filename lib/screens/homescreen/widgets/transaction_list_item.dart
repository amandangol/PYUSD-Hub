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

  // Helper method to format amount - updated to match the detail screen formatting
  String _formatAmount(TransactionModel tx) {
    if (tx.tokenSymbol != null) {
      return '${tx.amount.toStringAsFixed(2)} ${tx.tokenSymbol}';
    } else {
      return '${tx.amount.toStringAsFixed(6)} ETH';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the transaction directly from props
    final displayTransaction = widget.transaction;

    // Determine if the transaction is incoming or outgoing
    final bool isIncoming =
        displayTransaction.direction == TransactionDirection.incoming;

    // Format the amount string
    final formattedAmount = _formatAmount(displayTransaction);

    return Card(
      color: widget.cardColor,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _handleTransactionTap(displayTransaction),
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Transaction icon with animation for pending status
                  _buildTransactionIcon(isIncoming, displayTransaction.status),
                  const SizedBox(width: 12),

                  // Transaction details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isIncoming ? 'Received' : 'Sent',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: widget.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            if (displayTransaction.tokenSymbol != null)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  displayTransaction.tokenSymbol!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: Text(
                            FormatterUtils.formatHash(displayTransaction.hash),
                            style: TextStyle(
                              fontSize: 8,
                              fontFamily: "monospace",
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateTimeUtils.formatDateTime(
                              displayTransaction.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDarkMode
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Transaction amount and status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formattedAmount,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isIncoming ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Transaction status
                      _buildStatusPill(displayTransaction.status),
                    ],
                  ),
                ],
              ),
            ),

            // Loading indicator overlay
            if (_isLoading)
              Positioned.fill(
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
              ),
          ],
        ),
      ),
    );
  }

  // Optimized transaction tap handler
  void _handleTransactionTap(TransactionModel transaction) async {
    if (!mounted) return;

    final transactionDetailProvider =
        Provider.of<TransactionDetailProvider>(context, listen: false);
    final networkProvider =
        Provider.of<NetworkProvider>(context, listen: false);

    // Check if we already have this transaction in cache
    final cachedDetails =
        transactionDetailProvider.getCachedTransactionDetails(transaction.hash);
    final bool isRecentlyFetched = cachedDetails != null;

    // Show loading indicator briefly
    setState(() {
      _isLoading = true;
    });

    try {
      // First navigate to the detail screen with either cached or basic data
      // This provides immediate feedback to the user without waiting for network
      if (context.mounted) {
        final detailsToShow = isRecentlyFetched ? cachedDetails : transaction;

        // Only show loading indicator for a short time to indicate response
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(
              transaction: detailsToShow,
              currentAddress: widget.currentAddress,
              isDarkMode: widget.isDarkMode,
              networkType: networkProvider.currentNetwork,
              rpcUrl: networkProvider.currentRpcEndpoint,
              // Pass a flag if we want the detail screen to refresh the data
              needsRefresh: !isRecentlyFetched,
            ),
          ),
        );

        // If the data isn't recently fetched, trigger a refresh in the background for next time
        if (!isRecentlyFetched) {
          // No need to await this since we've already navigated
          transactionDetailProvider.getTransactionDetails(
            txHash: transaction.hash,
            rpcUrl: networkProvider.currentRpcEndpoint,
            networkType: networkProvider.currentNetwork,
            currentAddress: widget.currentAddress,
            forceRefresh: false, // Don't force refresh if we already have data
          );
        }
      }
    } catch (e) {
      // Reset loading state if still mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Show error if navigation fails
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildTransactionIcon(bool isIncoming, TransactionStatus status) {
    // For pending transactions, use a pulsating animation
    if (status == TransactionStatus.pending) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        duration: const Duration(seconds: 1),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pending,
                color: Colors.orange,
                size: 20,
              ),
            ),
          );
        },
        onEnd: () {
          // Re-trigger the animation
          if (status == TransactionStatus.pending) {
            Future.delayed(const Duration(milliseconds: 100), () {});
          }
        },
      );
    }

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

  Widget _buildStatusPill(TransactionStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData iconData;

    switch (status) {
      case TransactionStatus.pending:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        text = 'Pending';
        iconData = Icons.pending;
        break;
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
}
