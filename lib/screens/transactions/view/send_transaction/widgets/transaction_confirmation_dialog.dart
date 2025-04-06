import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../authentication/provider/auth_provider.dart';
import '../../../../authentication/widget/pin_input_widget.dart.dart';

class TransactionConfirmationDialog extends StatefulWidget {
  final String title;
  final String message;
  final double amount;
  final String asset;
  final String recipient;
  final double? gasFee;
  final bool isHighValue;

  const TransactionConfirmationDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.amount,
    required this.asset,
    required this.recipient,
    this.gasFee,
    this.isHighValue = false,
  }) : super(key: key);

  @override
  State<TransactionConfirmationDialog> createState() =>
      _TransactionConfirmationDialogState();
}

class _TransactionConfirmationDialogState
    extends State<TransactionConfirmationDialog> {
  final TextEditingController _pinController = TextEditingController();
  String? _error;
  bool _isLoading = false;
  int _failedAttempts = 0;
  static const int _maxAttempts = 3;
  static const Duration _lockoutDuration = Duration(minutes: 5);
  DateTime? _lockoutEndTime;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  bool get _isLockedOut {
    if (_lockoutEndTime == null) return false;
    return DateTime.now().isBefore(_lockoutEndTime!);
  }

  Duration get _remainingLockoutTime {
    if (_lockoutEndTime == null) return Duration.zero;
    return _lockoutEndTime!.difference(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.message,
              style: theme.textTheme.bodyMedium,
            ),
            if (widget.isHighValue) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is a high-value transaction. Please verify the details carefully.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? theme.colorScheme.surfaceVariant
                    : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTransactionDetail(
                    'Amount',
                    '${widget.amount.toStringAsFixed(6)} ${widget.asset}',
                    theme,
                  ),
                  if (widget.gasFee != null) ...[
                    const SizedBox(height: 8),
                    _buildTransactionDetail(
                      'Gas Fee',
                      '${widget.gasFee!.toStringAsFixed(6)} ETH',
                      theme,
                    ),
                    const SizedBox(height: 8),
                    _buildTransactionDetail(
                      'Total',
                      '${(widget.amount + (widget.gasFee ?? 0)).toStringAsFixed(6)} ${widget.asset}',
                      theme,
                      isBold: true,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildTransactionDetail(
                    'Recipient',
                    widget.recipient,
                    theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_isLockedOut) ...[
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.lock_clock,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Too many failed attempts',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please try again in ${_remainingLockoutTime.inMinutes} minutes',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ] else ...[
              PinInput(
                controller: _pinController,
                onCompleted: (pin) async {
                  if (pin.length == 6) {
                    await _verifyPin(pin);
                  }
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading || _isLockedOut
                      ? null
                      : () async {
                          if (_pinController.text.length == 6) {
                            await _verifyPin(_pinController.text);
                          } else {
                            setState(() {
                              _error = 'Please enter a 6-digit PIN';
                            });
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetail(String label, String value, ThemeData theme,
      {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _verifyPin(String pin) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = await authProvider.authenticateWithPIN(pin);

      if (isAuthenticated) {
        if (mounted) {
          Navigator.of(context).pop(pin);
        }
      } else {
        setState(() {
          _failedAttempts++;
          if (_failedAttempts >= _maxAttempts) {
            _lockoutEndTime = DateTime.now().add(_lockoutDuration);
            _error = 'Too many failed attempts. Please try again later.';
          } else {
            _error =
                'Invalid PIN. ${_maxAttempts - _failedAttempts} attempts remaining.';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Authentication failed';
        _isLoading = false;
      });
    }
  }
}
