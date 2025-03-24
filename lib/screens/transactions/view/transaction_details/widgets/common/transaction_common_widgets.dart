import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../utils/snackbar_utils.dart';
import '../../../../../../widgets/common/info_dialog.dart';
import '../../../../model/transaction_model.dart';

/// A reusable card widget with consistent styling for transaction details
class TransactionCard extends StatelessWidget {
  final Widget child;
  final Color cardColor;
  final EdgeInsetsGeometry? padding;
  final double elevation;
  final Color? shadowColor;

  const TransactionCard({
    super.key,
    required this.child,
    required this.cardColor,
    this.padding = const EdgeInsets.all(20),
    this.elevation = 3,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardColor,
      elevation: elevation,
      shadowColor: shadowColor ?? Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: padding!,
        child: child,
      ),
    );
  }
}

/// A reusable detail row widget with icon, title, value, and optional info popup
class TransactionDetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String infoMessage;
  final Color textColor;
  final Color subtitleColor;
  final Color? valueColor;
  final bool isHighlighted;
  final bool canCopy;
  final String? dataToCopy;

  const TransactionDetailRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.infoMessage,
    required this.textColor,
    required this.subtitleColor,
    this.valueColor,
    this.isHighlighted = false,
    this.canCopy = false,
    this.dataToCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: subtitleColor,
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showInfoPopup(context),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.info_outline,
                  size: 12,
                  color: subtitleColor.withOpacity(0.5),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: isHighlighted
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                : EdgeInsets.zero,
            decoration: isHighlighted
                ? BoxDecoration(
                    color: (valueColor ?? textColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isHighlighted ? 15 : 14,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? textColor,
              ),
            ),
          ),
          if (canCopy && dataToCopy != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: dataToCopy!));
                  SnackbarUtil.showSnackbar(
                    context: context,
                    message: '$title copied to clipboard',
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

  void _showInfoPopup(BuildContext context) {
    InfoDialog.show(
      context,
      title: title,
      message: infoMessage,
      textColor: textColor,
      subtitleColor: subtitleColor,
      icon: icon,
      iconColor: subtitleColor,
    );
  }
}

/// A reusable status badge widget
class TransactionStatusBadge extends StatelessWidget {
  final TransactionStatus status;
  final Color textColor;
  final Color subtitleColor;

  const TransactionStatusBadge({
    super.key,
    required this.status,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: 14,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            _getStatusText(status),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Icons.pending;
      case TransactionStatus.failed:
        return Icons.error;
      case TransactionStatus.confirmed:
        return Icons.check_circle;
      default:
        return Icons.info_outline;
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.confirmed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.confirmed:
        return 'Confirmed';
      default:
        return 'Unknown';
    }
  }
}

/// A reusable section header widget
class TransactionSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final Color textColor;
  final String? infoMessage;

  const TransactionSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.textColor,
    this.infoMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 22,
          color: iconColor,
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        if (infoMessage != null) ...[
          // const Spacer(),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _showInfoPopup(context),
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: textColor.withOpacity(0.5),
            ),
          ),
        ],
      ],
    );
  }

  void _showInfoPopup(BuildContext context) {
    if (infoMessage == null) return;

    InfoDialog.show(
      context,
      title: title,
      message: infoMessage!,
      textColor: textColor,
      subtitleColor: textColor.withOpacity(0.7),
      icon: icon,
      iconColor: iconColor,
    );
  }
}
