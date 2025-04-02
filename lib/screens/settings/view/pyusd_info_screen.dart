import 'package:flutter/material.dart';
import '../../../widgets/pyusd_components.dart';

class PyusdInfoScreen extends StatefulWidget {
  const PyusdInfoScreen({super.key});

  // Static list of Q&A items
  static final List<QAItem> qaItems = [
    QAItem(
      question: "What is PayPal USD?",
      answer:
          "PayPal USD is a regulated USD-backed stablecoin issued by Paxos. It maintains a 1:1 value with the US Dollar and is fully backed by cash, cash equivalents, and US Treasury bills.",
      icon: Icons.currency_exchange,
      iconColor: Colors.green,
    ),
    QAItem(
      question: "When was PayPal USD launched?",
      answer:
          "PayPal USD was launched in August 2023 as a collaborative effort between Paxos and PayPal, providing a regulated stablecoin option in the cryptocurrency ecosystem.",
      icon: Icons.calendar_today,
      iconColor: Colors.blue,
    ),
    QAItem(
      question: "How does PayPal USD impact the Ethereum network?",
      answer:
          "PayPal USD facilitates increased activity on Ethereum by integrating with DeFi applications and payment services, enabling seamless transactions for users and businesses.",
      icon: Icons.trending_up,
      iconColor: Colors.purple,
    ),
    QAItem(
      question: "What makes PayPal USD different from other stablecoins?",
      answer:
          "PayPal USD is regulated by the NYDFS, undergoes monthly attestations, and is backed by highly liquid assets. Its integration with PayPal enhances accessibility and adoption in traditional finance.",
      icon: Icons.verified,
      iconColor: Colors.teal,
    ),
    QAItem(
      question: "Where can PayPal USD be used?",
      answer:
          "PayPal USD can be used across the Ethereum ecosystem, including DeFi protocols, exchanges, and payment services. It is also integrated with PayPal for user-friendly transactions.",
      icon: Icons.store,
      iconColor: Colors.indigo,
    ),
    QAItem(
      question: "How is PayPal USD's adoption growing?",
      answer:
          "Since its launch, PayPal USD has seen steady growth in market capitalization and usage, with multiple DeFi protocols and exchanges supporting it for trading, liquidity pools, and lending markets.",
      icon: Icons.group_add,
      iconColor: Colors.amber,
    ),
    QAItem(
      question: "How is PayPal USD secured?",
      answer:
          "PayPal USD is secured through regular third-party attestations verifying its reserves. Additionally, it follows ERC-20 security standards, with Paxos implementing further protections as the issuer.",
      icon: Icons.security,
      iconColor: Colors.red,
    ),
    QAItem(
      question: "What is the transaction fee for PayPal USD?",
      answer:
          "PayPal USD transaction fees depend on Ethereum gas fees. Since it's an ERC-20 token, costs vary with network congestion. PayPal may also impose additional fees for conversions and transactions.",
      icon: Icons.paid,
      iconColor: Colors.orange,
    ),
    QAItem(
      question: "Can I earn interest on my PayPal USD?",
      answer:
          "Yes, PayPal USD holders can earn interest through DeFi platforms offering lending, staking, and liquidity pools. However, returns depend on market conditions and platform-specific terms.",
      icon: Icons.savings,
      iconColor: Colors.green,
    ),
    QAItem(
      question: "Is PayPal USD available globally?",
      answer:
          "PayPal USD availability depends on regional regulations. Initially available to US customers through PayPal, it may expand internationally based on compliance approvals.",
      icon: Icons.public,
      iconColor: Colors.blue,
    ),
    QAItem(
      question: "Who issues PayPal USD, and is it regulated?",
      answer:
          "PayPal USD is issued by Paxos Trust Company and regulated by the NYDFS. It undergoes monthly attestations to ensure full USD backing.",
      icon: Icons.policy,
      iconColor: Colors.deepPurple,
    ),
    QAItem(
      question: "Is PayPal USD available on multiple blockchains?",
      answer:
          "Currently, PayPal USD is an ERC-20 token on Ethereum. Future expansion to other networks depends on adoption and regulatory considerations.",
      icon: Icons.code,
      iconColor: Colors.brown,
    ),
    QAItem(
      question: "Can PYUSD be used for everyday payments?",
      answer:
          "Yes, PayPal supports PYUSD for payments, enabling transactions with merchants and individuals. However, acceptance depends on merchant adoption.",
      icon: Icons.payment,
      iconColor: Colors.cyan,
    ),
    QAItem(
      question: "What risks are associated with using PYUSD?",
      answer:
          "Risks include regulatory changes, Ethereum network congestion affecting transaction costs, and smart contract vulnerabilities. However, PYUSD is fully backed and regulated.",
      icon: Icons.warning,
      iconColor: Colors.redAccent,
    ),
  ];

  @override
  State<PyusdInfoScreen> createState() => _PyusdQAScreenState();
}

class _PyusdQAScreenState extends State<PyusdInfoScreen> {
  // Track which items are expanded
  final Set<int> _expandedItems = {
    0,
    1,
    2
  }; // First three items expanded by default

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

            const SizedBox(height: 10),
            // Q&A list
            Expanded(
              child: ListView.builder(
                itemCount: PyusdInfoScreen.qaItems.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final item = PyusdInfoScreen.qaItems[index];
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
                        initiallyExpanded: _expandedItems.contains(index),
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
