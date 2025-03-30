import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/gemini_provider.dart';
import '../provider/network_congestion_provider.dart';

class NetworkCongestionChatScreen extends StatefulWidget {
  const NetworkCongestionChatScreen({super.key});

  @override
  State<NetworkCongestionChatScreen> createState() =>
      _NetworkCongestionChatScreenState();
}

class _NetworkCongestionChatScreenState
    extends State<NetworkCongestionChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<NetworkCongestionProvider>(
        context,
        listen: false,
      );
      final gemini = Provider.of<GeminiProvider>(
        context,
        listen: false,
      );

      // Prepare network data for context
      final networkData = {
        'currentGasPrice': provider.congestionData.currentGasPrice,
        'averageGasPrice': provider.congestionData.averageGasPrice,
        'pendingTransactions': provider.congestionData.pendingTransactions,
        'gasUsagePercentage': provider.congestionData.gasUsagePercentage,
        'pyusdTransactionCount': provider.congestionData.pyusdTransactionCount,
        'networkLatency': provider.congestionData.networkLatency,
        'blockTime': provider.congestionData.blockTime,
        'confirmedPyusdTxCount': provider.congestionData.confirmedPyusdTxCount,
        'pendingPyusdTxCount': provider.congestionData.pendingPyusdTxCount,
        'lastBlockNumber': provider.congestionData.lastBlockNumber,
        'pendingQueueSize': provider.congestionData.pendingQueueSize,
        'averageBlockSize': provider.congestionData.averageBlockSize,
        'blocksPerHour': provider.congestionData.blocksPerHour,
        'averageTxPerBlock': provider.congestionData.averageTxPerBlock,
        'gasLimit': provider.congestionData.gasLimit,
        'networkVersion': provider.congestionData.networkVersion,
        'peerCount': provider.congestionData.peerCount,
        'isNetworkListening': provider.congestionData.isNetworkListening,
        'historicalGasPrices': provider.congestionData.historicalGasPrices,
        'pyusdHistoricalGasPrices':
            provider.congestionData.pyusdHistoricalGasPrices,
      };

      await gemini.sendChatMessage(
        message: message,
        networkData: networkData,
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Draggable handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PYUSD & Ethereum Chat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Chat messages
          Expanded(
            child: Consumer<GeminiProvider>(
              builder: (context, gemini, child) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: gemini.chatMessages.length,
                  itemBuilder: (context, index) {
                    final message = gemini.chatMessages[index];
                    final isUser = message['role'] == 'user';

                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Theme.of(context).primaryColor
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Text(
                          message['content']!,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Input field
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Ask about PYUSD, Ethereum, or network...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                  tooltip: 'Send message',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
