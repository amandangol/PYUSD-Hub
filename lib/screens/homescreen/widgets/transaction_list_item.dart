import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pyusd_forensics/utils/datetime_utils.dart';

import '../../../models/transaction.dart';
import '../../../providers/network_provider.dart';
import '../../../providers/transactiondetail_provider.dart';
import '../../transaction_detail_screen.dart';

class TransactionItem extends StatefulWidget {
  final TransactionModel transaction;
  final String currentAddress;
  final bool isDarkMode;
  final Color cardColor;

  const TransactionItem({
    Key? key,
    required this.transaction,
    required this.currentAddress,
    required this.isDarkMode,
    required this.cardColor,
  }) : super(key: key);

  @override
  State<TransactionItem> createState() => _TransactionItemState();
}

class _TransactionItemState extends State<TransactionItem> {
  bool _isLoading = false;
  TransactionDetailModel? _cachedDetails;

  @override
  void initState() {
    super.initState();
    // Move prefetch to after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetchTransactionDetails();
    });
  }

  Future<void> _prefetchTransactionDetails() async {
    if (!mounted) return;

    final networkProvider =
        Provider.of<NetworkProvider>(context, listen: false);
    final transactionDetailProvider =
        Provider.of<TransactionDetailProvider>(context, listen: false);

    try {
      // Check if transaction is already in cache
      final details = await transactionDetailProvider.getTransactionDetails(
        txHash: widget.transaction.hash,
        rpcUrl: networkProvider.currentRpcEndpoint,
        networkType: networkProvider.currentNetwork,
        currentAddress: widget.currentAddress,
        forceRefresh: false,
      );

      // Store the cached details for display
      if (mounted && details != null) {
        setState(() {
          _cachedDetails = details;
        });
      }
    } catch (e) {
      // Silently handle error, will try again when user taps
      print('Background prefetch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final networkProvider =
        Provider.of<NetworkProvider>(context, listen: false);

    // Use detailed transaction if available, otherwise use the base transaction
    final displayTransaction = _cachedDetails ?? widget.transaction;

    // Determine if the transaction is incoming or outgoing
    final bool isIncoming =
        displayTransaction.direction == TransactionDirection.incoming;

    // Format the value with the appropriate sign and token symbol
    final String formattedValue = (isIncoming ? '+ ' : '- ') +
        displayTransaction.value
            .toStringAsFixed(displayTransaction.tokenSymbol != null ? 4 : 6) +
        ' ${displayTransaction.tokenSymbol ?? 'ETH'}';

    return Card(
      color: widget.cardColor,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () async {
          // Set loading state
          setState(() {
            _isLoading = true;
          });

          try {
            // Get the provider outside of the build phase
            final transactionDetailProvider =
                Provider.of<TransactionDetailProvider>(context, listen: false);
            final networkProvider =
                Provider.of<NetworkProvider>(context, listen: false);

            // First, try to get transaction details synchronously from cache
            final cachedDetails = transactionDetailProvider
                    .isTransactionCached(widget.transaction.hash)
                ? await transactionDetailProvider.getTransactionDetails(
                    txHash: widget.transaction.hash,
                    rpcUrl: networkProvider.currentRpcEndpoint,
                    networkType: networkProvider.currentNetwork,
                    currentAddress: widget.currentAddress,
                    forceRefresh: false,
                  )
                : null;

            // Use the latest available data for navigation
            final transactionToShow = cachedDetails ?? displayTransaction;

            // Navigate using the current data
            if (context.mounted) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionDetailScreen(
                    transaction: transactionToShow,
                    currentAddress: widget.currentAddress,
                    isDarkMode: widget.isDarkMode,
                    networkType: networkProvider.currentNetwork,
                    rpcUrl: networkProvider.currentRpcEndpoint,
                  ),
                ),
              );

              // If we got updated transaction details back from the detail screen
              if (result != null && result is TransactionDetailModel) {
                // Update our local cached details
                setState(() {
                  _cachedDetails = result;
                });
              }
            }

            // Start a separate detached fetch in the background for future use
            if (context.mounted) {
              transactionDetailProvider.getTransactionDetails(
                txHash: widget.transaction.hash,
                rpcUrl: networkProvider.currentRpcEndpoint,
                networkType: networkProvider.currentNetwork,
                currentAddress: widget.currentAddress,
              );
            }
          } catch (e) {
            // Show error if navigation fails
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          } finally {
            // Reset loading state if still mounted
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Transaction icon with animation for pending status
                  _buildTransactionIcon(isIncoming),
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
                        formattedValue,
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

  Widget _buildTransactionIcon(bool isIncoming) {
    // For pending transactions, use a pulsating animation
    final status = _cachedDetails?.status ?? widget.transaction.status;

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
