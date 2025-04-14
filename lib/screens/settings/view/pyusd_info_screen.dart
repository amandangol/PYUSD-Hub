import 'package:flutter/material.dart';
import '../../../widgets/pyusd_components.dart';

class PyusdInfoScreen extends StatefulWidget {
  const PyusdInfoScreen({super.key});

  // Static list of Q&A items with improved accuracy
  static final List<QAItem> qaItems = [
    QAItem(
      question: "What is PayPal USD?",
      answer:
          "PayPal USD (PYUSD) is a regulated USD-backed stablecoin issued by Paxos Trust Company. It maintains a 1:1 value with the US Dollar and is fully backed by USD cash, cash equivalents, and US Treasury bills held in Paxos' segregated accounts.",
      icon: Icons.currency_exchange,
      iconColor: Colors.green,
    ),
    QAItem(
      question: "When was PayPal USD launched?",
      answer:
          "PayPal USD was launched in August 2023 as a collaborative effort between Paxos Trust Company and PayPal. The stablecoin was introduced as part of PayPal's strategy to expand its cryptocurrency offerings and provide users with a regulated stablecoin option.",
      icon: Icons.calendar_today,
      iconColor: Colors.blue,
    ),
    QAItem(
      question: "How does PayPal USD operate on blockchain?",
      answer:
          "PayPal USD is an ERC-20 token that operates on the Ethereum blockchain. This allows PYUSD to be integrated with various decentralized finance (DeFi) applications, exchanges, and wallets that support Ethereum-based tokens, while benefiting from Ethereum's security and smart contract functionality.",
      icon: Icons.trending_up,
      iconColor: Colors.purple,
    ),
    QAItem(
      question: "What makes PayPal USD different from other stablecoins?",
      answer:
          "PayPal USD is regulated by the New York Department of Financial Services (NYDFS), undergoes monthly reserve attestations by a third-party accounting firm, and is backed by highly liquid assets. Its key differentiator is its direct integration with PayPal's ecosystem of over 430 million users and merchants, potentially providing broader mainstream adoption than other stablecoins.",
      icon: Icons.verified,
      iconColor: Colors.teal,
    ),
    QAItem(
      question: "Where can PayPal USD be used?",
      answer:
          "PayPal USD can be used within PayPal's platform for various transactions and transfers. Outside of PayPal, it can be transferred to compatible external wallets and used across the Ethereum ecosystem, including decentralized exchanges (DEXs), lending protocols, and other DeFi applications that support ERC-20 tokens.",
      icon: Icons.store,
      iconColor: Colors.indigo,
    ),
    QAItem(
      question: "How is PayPal USD's adoption progressing?",
      answer:
          "Since its launch, PayPal USD has been gaining steady adoption. As of April 2025, PYUSD has established itself as one of the regulated stablecoins in the market, with growing support in various DeFi protocols, centralized exchanges, and payment services. Its market cap has been increasing as more users and businesses adopt it for transactions and financial activities.",
      icon: Icons.group_add,
      iconColor: Colors.amber,
    ),
    QAItem(
      question: "How is PayPal USD secured?",
      answer:
          "PayPal USD is secured through multiple mechanisms: 1) The reserves backing PYUSD are held in segregated accounts with eligible U.S. institutions; 2) Monthly attestations by independent accountants verify the 1:1 backing; 3) As an ERC-20 token, it inherits Ethereum's blockchain security; 4) Paxos, as the regulated issuer, implements additional security protocols and compliance measures.",
      icon: Icons.security,
      iconColor: Colors.red,
    ),
    QAItem(
      question: "What are the transaction fees for PayPal USD?",
      answer:
          "Transaction fees for PayPal USD vary depending on where and how it's used. Within PayPal's ecosystem, fees align with PayPal's standard fee structure. For on-chain Ethereum transactions, users pay standard Ethereum gas fees which fluctuate based on network congestion. Some DeFi protocols and exchanges may charge additional fees for PYUSD transactions, swaps, or liquidity provision.",
      icon: Icons.paid,
      iconColor: Colors.orange,
    ),
    QAItem(
      question: "Can I earn yield on my PayPal USD?",
      answer:
          "Yes, PYUSD holders can potentially earn yield by utilizing various DeFi protocols. Options include supplying PYUSD to lending platforms, providing liquidity in decentralized exchanges, or depositing in yield aggregators. The specific yields vary based on market conditions, protocol risks, and incentive programs. Note that these activities typically involve smart contract risks and may not be directly supported by PayPal.",
      icon: Icons.savings,
      iconColor: Colors.green,
    ),
    QAItem(
      question: "Is PayPal USD available globally?",
      answer:
          "PayPal USD availability varies by region due to regulatory considerations. Initially, it was primarily available to eligible U.S. PayPal customers. PayPal has been gradually expanding access based on regional regulations and compliance requirements. Users should check the PayPal app or website for current availability in their region.",
      icon: Icons.public,
      iconColor: Colors.blue,
    ),
    QAItem(
      question: "Who issues PayPal USD, and how is it regulated?",
      answer:
          "PayPal USD is issued by Paxos Trust Company, a regulated financial institution. Paxos is regulated by the New York Department of Financial Services (NYDFS) as a limited purpose trust company. PYUSD undergoes monthly reserve attestations by third-party accountants to verify that all tokens are fully backed by USD reserves. PayPal facilitates access to PYUSD but Paxos remains the official issuer and regulatory compliance entity.",
      icon: Icons.policy,
      iconColor: Colors.deepPurple,
    ),
    QAItem(
      question: "Is PayPal USD available on multiple blockchains?",
      answer:
          "As of April 2025, PayPal USD primarily exists as an ERC-20 token on the Ethereum blockchain. While Paxos and PayPal may consider multichain expansion in the future to improve scalability and reduce transaction costs, any such expansion would need to maintain the security and regulatory compliance standards established for PYUSD.",
      icon: Icons.code,
      iconColor: Colors.brown,
    ),
    QAItem(
      question: "Can PYUSD be used for everyday payments?",
      answer:
          "Yes, PYUSD can be used for everyday payments through the PayPal ecosystem, allowing users to send money to friends, family, and eligible merchants who accept PayPal. Outside of PayPal, PYUSD can be used with merchants and services that accept ERC-20 tokens, though this adoption continues to develop. Transaction speeds and costs on Ethereum may affect its practicality for small everyday payments.",
      icon: Icons.payment,
      iconColor: Colors.cyan,
    ),
    QAItem(
      question: "What risks are associated with using PYUSD?",
      answer:
          "While PYUSD is designed to be stable and secure, risks include: 1) Smart contract vulnerabilities, 2) Regulatory changes affecting stablecoins, 3) Ethereum network congestion impacting transaction speeds and costs, 4) Counterparty risks with Paxos as the issuer, 5) Potential technical issues during blockchain transfers. However, PYUSD's regulatory oversight and full reserve backing mitigate some of these risks compared to unregulated alternatives.",
      icon: Icons.warning,
      iconColor: Colors.redAccent,
    ),
    QAItem(
      question: "How do I convert between PYUSD and USD?",
      answer:
          "Within PayPal, eligible users can convert between USD and PYUSD directly in the app with minimal friction. For external conversions, users can transfer PYUSD to compatible external wallets and use various centralized or decentralized exchanges that support PYUSD trading pairs. Conversion rates are typically 1:1, though small spreads or fees may apply depending on the platform used.",
      icon: Icons.swap_horiz,
      iconColor: Colors.lightBlue,
    ),
    QAItem(
      question: "What technological innovations does PYUSD incorporate?",
      answer:
          "PYUSD combines traditional financial infrastructure with blockchain technology. As an ERC-20 token, it utilizes Ethereum's smart contract functionality for programmable money applications. It incorporates standard security features like upgradeable contracts for potential improvements and optional transaction pause functionality for emergency situations - common in regulated stablecoins. Its innovation lies in bridging PayPal's mainstream financial services with decentralized blockchain capabilities.",
      icon: Icons.lightbulb,
      iconColor: Colors.amber,
    ),
  ];

  @override
  State<PyusdInfoScreen> createState() => _PyusdQAScreenState();
}

class _PyusdQAScreenState extends State<PyusdInfoScreen> {
  final Set<int> _expandedItems = {0, 1, 2};
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
                          "Learn about PayPal USD stablecoin features and ecosystem",
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
                        onExpansionChanged: (expanded) {
                          setState(() {
                            if (expanded) {
                              _expandedItems.add(index);
                            } else {
                              _expandedItems.remove(index);
                            }
                          });
                        },
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
