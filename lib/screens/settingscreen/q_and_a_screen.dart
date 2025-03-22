import 'package:flutter/material.dart';
import '../../common/pyusd_appbar.dart';

class PyusdQAScreen extends StatefulWidget {
  const PyusdQAScreen({super.key});

  @override
  State<PyusdQAScreen> createState() => _PyusdQAScreenState();
}

class _PyusdQAScreenState extends State<PyusdQAScreen> {
  // List of all Q&A items
  final List<QAItem> _qaItems = [
    QAItem(
      question: "What is PYUSD?",
      answer:
          "PYUSD is a regulated USD-backed stablecoin issued by Paxos. It maintains a 1:1 value with the US Dollar and is fully backed by cash, cash equivalents, and US Treasury bills.",
      icon: Icons.currency_exchange,
      iconColor: Colors.green,
    ),
    QAItem(
      question: "When was PYUSD launched?",
      answer:
          "PYUSD was launched in August 2023 as a collaborative effort between Paxos and PayPal, providing a regulated stablecoin option in the cryptocurrency ecosystem.",
      icon: Icons.calendar_today,
      iconColor: Colors.blue,
    ),
    QAItem(
      question: "How does PYUSD impact the Ethereum network?",
      answer:
          "PYUSD has contributed to increased transaction volume on Ethereum, particularly in DeFi applications. It has helped bring traditional finance users into the blockchain ecosystem through PayPal's established user base.",
      icon: Icons.trending_up,
      iconColor: Colors.purple,
    ),
    QAItem(
      question: "What makes PYUSD different from other stablecoins?",
      answer:
          "PYUSD is regulated by the New York State Department of Financial Services (NYDFS), undergoes regular attestations, and is backed by liquid assets. Its connection to PayPal provides a bridge between traditional payment systems and crypto.",
      icon: Icons.verified,
      iconColor: Colors.teal,
    ),
    QAItem(
      question: "Where can PYUSD be used?",
      answer:
          "PYUSD can be used across the Ethereum ecosystem including DeFi protocols, exchanges, and payment services. It's also integrated with PayPal, allowing millions of users and merchants to access stablecoin functionality.",
      icon: Icons.store,
      iconColor: Colors.indigo,
    ),
    QAItem(
      question: "How is PYUSD's adoption growing?",
      answer:
          "Since its launch, PYUSD has seen steady growth in market capitalization and usage. Multiple DeFi protocols have added support for PYUSD liquidity pools and lending markets, while exchanges have added trading pairs.",
      icon: Icons.group_add,
      iconColor: Colors.amber,
    ),
    QAItem(
      question: "How is PYUSD secured?",
      answer:
          "PYUSD is secured through regular third-party attestations that verify its dollar reserves. The stablecoin uses standard ERC-20 token security on Ethereum, with additional security measures implemented by Paxos as the issuer.",
      icon: Icons.security,
      iconColor: Colors.red,
    ),
    QAItem(
      question: "What is the transaction fee for PYUSD?",
      answer:
          "PYUSD transaction fees are determined by the Ethereum network gas fees. Since it's an ERC-20 token, the cost to send PYUSD varies based on network congestion. PayPal may charge additional fees for purchasing or converting PYUSD through their platform.",
      icon: Icons.paid,
      iconColor: Colors.orange,
    ),
    QAItem(
      question: "Can I earn interest on my PYUSD?",
      answer:
          "Yes, you can earn interest on PYUSD through various DeFi platforms that support it. Lending protocols, liquidity pools, and yield farming opportunities are available that allow you to earn returns on your PYUSD holdings.",
      icon: Icons.savings,
      iconColor: Colors.green,
    ),
    QAItem(
      question: "Is PYUSD available globally?",
      answer:
          "PYUSD availability varies by region due to regulatory considerations. Through PayPal, it's initially available to US customers, with plans for international expansion. When using decentralized platforms, access depends on local regulations regarding cryptocurrency usage.",
      icon: Icons.public,
      iconColor: Colors.blue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PyusdAppBar(
        showLogo: true,
        isDarkMode: isDarkMode,
        title: "PYUSD Information",
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.primary.withOpacity(0.1),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "PYUSD Information Center",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Learn about PYUSD's performance, adoption, and impact",
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 10,
            ),
            // Q&A list
            Expanded(
              child: ListView.builder(
                itemCount: _qaItems.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final item = _qaItems[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: item.iconColor.withOpacity(0.2),
                              child: Icon(item.icon,
                                  size: 18, color: item.iconColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.question,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        childrenPadding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 44),
                            child: Text(
                              item.answer,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.8),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// QA Item model
class QAItem {
  final String question;
  final String answer;
  final IconData icon;
  final Color iconColor;

  QAItem({
    required this.question,
    required this.answer,
    required this.icon,
    required this.iconColor,
  });
}
