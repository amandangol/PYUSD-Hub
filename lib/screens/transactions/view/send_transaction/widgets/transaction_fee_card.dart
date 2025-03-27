import 'package:flutter/material.dart';
import '../../../../../widgets/pyusd_components.dart';
import '../../../provider/transaction_provider.dart';

class TransactionFeeCard extends StatelessWidget {
  final String selectedAsset;
  final Function(String) onAssetSelected;
  final double estimatedGasFee;
  final GasOption? selectedGasOption;
  final bool isEstimatingGas;
  final double ethBalance;
  final double tokenBalance;
  final VoidCallback onGasOptionsPressed;
  final bool isLoadingGasPrice;
  final bool hasInsufficientETH;
  final String networkName;
  final double maxSendableEth;

  const TransactionFeeCard({
    super.key,
    required this.selectedAsset,
    required this.onAssetSelected,
    required this.estimatedGasFee,
    required this.selectedGasOption,
    required this.isEstimatingGas,
    required this.ethBalance,
    required this.tokenBalance,
    required this.onGasOptionsPressed,
    this.isLoadingGasPrice = false,
    this.hasInsufficientETH = false,
    required this.networkName,
    required this.maxSendableEth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return PyusdCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Asset Selection Header
            Row(
              children: [
                Icon(
                  Icons.swap_horiz,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Asset',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Asset Selection Buttons with Enhanced Balance Display
            Row(
              children: [
                _buildAssetButton(
                  context,
                  'PYUSD',
                  selectedAsset == 'PYUSD',
                  isDarkMode,
                ),
                const SizedBox(width: 12),
                _buildAssetButton(
                  context,
                  'ETH',
                  selectedAsset == 'ETH',
                  isDarkMode,
                ),
              ],
            ),

            // Show max sendable ETH if relevant
            if (selectedAsset == 'ETH' && estimatedGasFee > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Max sendable (after gas): ${maxSendableEth.toStringAsFixed(6)} ETH',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Gas Price Selection
            InkWell(
              onTap: onGasOptionsPressed,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDarkMode ? Colors.white24 : Colors.black12,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_gas_station,
                      size: 20,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Network Fee',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isLoadingGasPrice)
                            const Text(
                              'Fetching gas price...',
                              style: TextStyle(fontSize: 13),
                            )
                          else if (selectedGasOption != null)
                            Text(
                              '${selectedGasOption!.name} · ${selectedGasOption!.price.toStringAsFixed(3)} Gwei',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                                fontSize: 13,
                              ),
                            )
                          else
                            Text(
                              'Select gas price',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ],
                ),
              ),
            ),

            // Estimated Fee and Balance Warning
            if (!isEstimatingGas) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estimated Fee:',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  Text(
                    '${estimatedGasFee.toStringAsFixed(9)} ETH',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              if (hasInsufficientETH) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Insufficient ETH for gas fees. Current balance: ${ethBalance.toStringAsFixed(4)} ETH',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              // Loading state for gas estimation
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Estimating gas fee...',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssetButton(
      BuildContext context, String asset, bool isSelected, bool isDarkMode) {
    final balance = asset == 'PYUSD' ? tokenBalance : ethBalance;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => onAssetSelected(asset),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : isDarkMode
                      ? Colors.white24
                      : Colors.black12,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    asset == 'PYUSD'
                        ? Icons.attach_money
                        : Icons.currency_exchange,
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : isDarkMode
                            ? Colors.white70
                            : Colors.black87,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    asset,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isDarkMode
                              ? Colors.white
                              : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                balance.toStringAsFixed(asset == 'ETH' ? 4 : 2),
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
