import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../provider/transaction_provider.dart';

class GasSelectionSheet extends StatefulWidget {
  final Map<String, GasOption> gasOptions;
  final GasOption selectedOption;
  final Function(GasOption) onOptionSelected;

  const GasSelectionSheet({
    super.key,
    required this.gasOptions,
    required this.selectedOption,
    required this.onOptionSelected,
  });

  @override
  State<GasSelectionSheet> createState() => _GasSelectionSheetState();
}

class _GasSelectionSheetState extends State<GasSelectionSheet> {
  final _customGasPriceController = TextEditingController();
  final _customGasPriceFocusNode = FocusNode();
  final _scrollController = ScrollController();
  bool _isCustom = false;

  @override
  void initState() {
    super.initState();
    _customGasPriceController.text =
        widget.selectedOption.price.toStringAsFixed(0);

    _customGasPriceFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_customGasPriceFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Scroll to the bottom of the sheet
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _customGasPriceController.dispose();
    _customGasPriceFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: mediaQuery.size.height * 0.7, // Increased height
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Network Fee',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      ...widget.gasOptions.values
                          .map((option) => _buildGasOption(
                                context,
                                option,
                                option == widget.selectedOption && !_isCustom,
                                isDarkMode,
                              )),
                      _buildCustomGasOption(context, isDarkMode),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Higher gas price = Faster transaction confirmation',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGasOption(BuildContext context, GasOption option,
      bool isSelected, bool isDarkMode) {
    return InkWell(
      onTap: () {
        setState(() => _isCustom = false);
        widget.onOptionSelected(option);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : isDarkMode
                    ? Colors.white24
                    : Colors.black12,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        option.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (option.recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Recommended',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.timeEstimate,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${option.price.toStringAsFixed(3)} Gwei',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomGasOption(BuildContext context, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: _isCustom
              ? Theme.of(context).primaryColor
              : isDarkMode
                  ? Colors.white24
                  : Colors.black12,
          width: _isCustom ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Custom',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _customGasPriceController,
            focusNode: _customGasPriceFocusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
            ],
            decoration: InputDecoration(
              hintText: 'Enter gas price',
              suffixText: 'Gwei',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onTap: () {
              setState(() => _isCustom = true);
              // Scroll to the bottom when tapped
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            onChanged: (value) {
              if (value.isNotEmpty) {
                final price = double.tryParse(value) ?? 0;
                if (price > 0) {
                  widget.onOptionSelected(GasOption(
                    name: 'Custom',
                    price: price,
                    timeEstimate: 'Variable',
                  ));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
