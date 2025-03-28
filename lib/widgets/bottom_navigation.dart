import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({super.key});

  // Define screens for bottom navigation with metadata
  static final List<Map<String, dynamic>> _screens = [
    {
      'icon': Icons.speed,
      'label': 'Network',
      'color': Colors.green,
    },
    {
      'icon': Icons.newspaper,
      'label': 'Explore',
      'color': Colors.purple,
    },
    {
      'icon': Icons.account_balance_wallet,
      'label': 'Wallet',
      'color': Colors.blue,
    },
    {
      'icon': Icons.analytics,
      'label': 'Analytics',
      'color': Colors.orange,
    },
    {
      'icon': Icons.settings,
      'label': 'Settings',
      'color': Colors.grey,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final navigationProvider = context.watch<NavigationProvider>();

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
        items: _screens.map((screen) {
          return BottomNavigationBarItem(
            icon: Icon(
              screen['icon'] as IconData,
              color: navigationProvider.currentIndex == _screens.indexOf(screen)
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
