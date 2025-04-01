import 'package:flutter/material.dart';
import 'package:pyusd_hub/utils/formatter_utils.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// A custom input field for blockchain-related data
class TraceInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool isMultiline;
  final bool isRequired;
  final IconData? prefixIcon;
  final VoidCallback? onPaste;
  final bool isHexInput;
  final String? helperText;

  const TraceInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.isMultiline = false,
    this.isRequired = true,
    this.prefixIcon,
    this.onPaste,
    this.isHexInput = true,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final inputFillColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
    final borderColor =
        isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    final labelColor = isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (prefixIcon != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(prefixIcon, size: 16, color: labelColor),
              ),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: labelColor,
                fontSize: 14,
              ),
            ),
            if (!isRequired)
              const Text(
                ' (Optional)',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
              fontSize: 13,
            ),
            filled: true,
            fillColor: inputFillColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                    },
                    tooltip: 'Clear text',
                  ),
                if (onPaste != null)
                  IconButton(
                    icon: const Icon(Icons.paste, size: 18),
                    onPressed: onPaste,
                    tooltip: 'Paste from clipboard',
                  ),
              ],
            ),
            helperText: helperText,
            helperStyle: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          maxLines: isMultiline ? 3 : 1,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade800,
          ),
          onChanged: (_) {
            (context as Element).markNeedsBuild();
          },
        ),
      ],
    );
  }
}

/// A card for displaying trace results
class TraceResultCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget content;
  final List<Widget>? actions;
  final bool isLoading;
  final bool isError;
  final String? errorMessage;

  const TraceResultCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.content,
    this.actions,
    this.isLoading = false,
    this.isError = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey.shade900 : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                if (actions != null) ...actions!,
              ],
            ),
            const Divider(height: 24),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (isError)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Error',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage ?? 'An unknown error occurred',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              )
            else
              content,
          ],
        ),
      ),
    );
  }
}

/// A button specifically designed for trace actions
class TraceButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color backgroundColor;
  final Color textColor;
  final double horizontalPadding;
  final double verticalPadding;
  final bool isOutlined;

  const TraceButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.horizontalPadding = 16.0,
    this.verticalPadding = 12.0,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            side: BorderSide(color: backgroundColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
          );

    final buttonContent = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOutlined ? backgroundColor : textColor,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(text),
            ],
          );

    return isOutlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: buttonContent,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: buttonContent,
          );
  }
}

/// A widget for displaying AI analysis results
class AiAnalysisCard extends StatelessWidget {
  final Map<String, dynamic> analysis;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const AiAnalysisCard({
    super.key,
    required this.analysis,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey.shade900 : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    // Extract data from analysis
    final hasError = analysis['error'] == true;
    final summary = analysis['summary'] as String? ?? 'No summary available';

    String riskLevel = analysis['riskLevel'] as String? ?? 'Unknown';
    Color riskColor;
    switch (riskLevel.toLowerCase()) {
      case 'low':
        riskColor = Colors.green;
        break;
      case 'medium':
        riskColor = Colors.orange;
        break;
      case 'high':
        riskColor = Colors.red;
        break;
      default:
        riskColor = Colors.grey;
    }

    final technicalInsights = analysis['technicalInsights'] as String? ?? '';
    final humanReadable = analysis['humanReadable'] as String? ?? '';

    List<dynamic> riskFactors = [];
    if (analysis['riskFactors'] is List) {
      riskFactors = analysis['riskFactors'] as List;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'AI Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: isLoading ? null : onRefresh,
                    tooltip: 'Refresh analysis',
                  ),
              ],
            ),
            const Divider(height: 24),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Generating AI analysis...'),
                    ],
                  ),
                ),
              )
            else if (hasError)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Error Generating Analysis',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      analysis['errorMessage'] as String? ??
                          'An unknown error occurred',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary section
                  ExpansionTile(
                    title: const Text(
                      'Summary',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    initiallyExpanded: true,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: MarkdownBody(
                          data: summary,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(fontSize: 14, color: textColor),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Risk Assessment section
                  if (riskLevel != 'Unknown')
                    ListTile(
                      leading: Icon(Icons.security, color: riskColor),
                      title: const Text('Risk Assessment'),
                      subtitle: Text(
                        riskLevel,
                        style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  // Risk Factors section
                  if (riskFactors.isNotEmpty)
                    ExpansionTile(
                      title: const Text('Risk Factors'),
                      leading: const Icon(Icons.warning, color: Colors.amber),
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: riskFactors.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: const Icon(Icons.arrow_right),
                              title: Text(riskFactors[index].toString()),
                            );
                          },
                        ),
                      ],
                    ),

                  // Technical Insights section
                  if (technicalInsights.isNotEmpty)
                    ExpansionTile(
                      title: const Text('Technical Insights'),
                      leading: const Icon(Icons.code, color: Colors.blue),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: MarkdownBody(
                            data: technicalInsights,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(fontSize: 14, color: textColor),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Human Readable section
                  if (humanReadable.isNotEmpty)
                    ExpansionTile(
                      title: const Text('Simplified Explanation'),
                      leading: const Icon(Icons.person, color: Colors.green),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: MarkdownBody(
                            data: humanReadable,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(fontSize: 14, color: textColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

            // Gemini attribution
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/gemini_logo.png',
                    height: 16,
                    width: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Powered by Google Gemini',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: textColor.withOpacity(0.6),
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
}

/// A widget for displaying trace visualization
class TraceVisualizationCard extends StatelessWidget {
  final List<Map<String, dynamic>> traces;
  final Function(Map<String, dynamic>) onTraceSelected;

  const TraceVisualizationCard({
    super.key,
    required this.traces,
    required this.onTraceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey.shade900 : Colors.white;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_tree, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Trace Visualization',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (traces.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No trace data available'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: traces.length,
                itemBuilder: (context, index) {
                  final trace = traces[index];
                  final callType = trace['type'] as String? ?? 'unknown';
                  final from = trace['from'] as String? ?? 'unknown';
                  final to = trace['to'] as String? ?? 'unknown';
                  final value = trace['value'] as String? ?? '0x0';

                  Color callTypeColor;
                  switch (callType.toLowerCase()) {
                    case 'call':
                      callTypeColor = Colors.blue;
                      break;
                    case 'staticcall':
                      callTypeColor = Colors.purple;
                      break;
                    case 'delegatecall':
                      callTypeColor = Colors.orange;
                      break;
                    case 'create':
                      callTypeColor = Colors.green;
                      break;
                    case 'create2':
                      callTypeColor = Colors.teal;
                      break;
                    case 'selfdestruct':
                      callTypeColor = Colors.red;
                      break;
                    default:
                      callTypeColor = Colors.grey;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: callTypeColor.withOpacity(0.2),
                        child: Text(
                          callType.substring(0, 1).toUpperCase(),
                          style: TextStyle(color: callTypeColor),
                        ),
                      ),
                      title: Text(
                        '${FormatterUtils.formatAddress(from)} → ${FormatterUtils.formatAddress(to)}',
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 14),
                      ),
                      subtitle: Text(
                        'Value: ${FormatterUtils.formatEthFromHex(value)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => onTraceSelected(trace),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// A widget for displaying method selector for advanced trace
class TraceMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final Function(String) onMethodChanged;
  final List<String> availableMethods;

  const TraceMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
    required this.availableMethods,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dropdownColor = isDarkMode ? Colors.grey.shade800 : Colors.white;

    // Ensure the selected method is in the available methods list
    // If not, default to the first available method
    final String effectiveSelectedMethod =
        availableMethods.contains(selectedMethod)
            ? selectedMethod
            : availableMethods.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Trace Method:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: dropdownColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: DropdownButton<String>(
            value: effectiveSelectedMethod,
            onChanged: (String? newValue) {
              if (newValue != null) {
                onMethodChanged(newValue);
              }
            },
            items:
                availableMethods.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down),
            dropdownColor: dropdownColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildMethodDescription(effectiveSelectedMethod),
      ],
    );
  }

  Widget _buildMethodDescription(String method) {
    String description;
    IconData icon;

    switch (method) {
      case 'Replay Block Transactions':
        description =
            'Replay all transactions in a block to get detailed traces.';
        icon = Icons.replay;
        break;
      case 'Replay Transaction':
        description =
            'Replay a specific transaction to get detailed trace information.';
        icon = Icons.history;
        break;
      case 'Storage Range':
        description =
            'Get storage values for a contract at a specific block and transaction.';
        icon = Icons.storage;
        break;
      case 'Trace Call':
        description =
            'Execute a call and trace its execution without modifying state.';
        icon = Icons.call;
        break;
      default:
        description = 'Select a trace method to see its description.';
        icon = Icons.help_outline;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
