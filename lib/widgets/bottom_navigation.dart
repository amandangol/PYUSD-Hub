import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final navigationProvider = context.watch<NavigationProvider>();

    // Define screens for bottom navigation with metadata - matching the ones in MainApp
    final List<Map<String, dynamic>> screens = [
      {
        'icon': Icons.network_check,
        'label': 'Network',
        'color': Colors.blue,
      },
      {
        'icon': Icons.explore,
        'label': 'Explore',
        'color': Colors.green,
      },
      {
        'icon': Icons.account_balance_wallet,
        'label': 'Wallet',
        'color': Colors.orange,
      },
      {
        'icon': Icons.account_tree_outlined,
        'label': 'Tracer',
        'color': Colors.purple,
      },
      {
        'icon': Icons.settings,
        'label': 'Settings',
        'color': Colors.grey,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: navigationProvider.currentIndex,
        onTap: (index) {
          navigationProvider.setIndex(index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        items: screens.map((screen) {
          return BottomNavigationBarItem(
            icon: Icon(
              screen['icon'] as IconData,
              color: navigationProvider.currentIndex == screens.indexOf(screen)
                  ? screen['color'] as Color
                  : null,
            ),
            label: screen['label'] as String,
          );
        }).toList(),
      ),
    );
  }
}
