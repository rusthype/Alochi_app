import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/colors.dart';

class ParentShell extends ConsumerWidget {
  final Widget child;
  const ParentShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/parent/dashboard')) return 0;
    if (loc.startsWith('/parent/children')) return 1;
    if (loc.startsWith('/parent/notifications')) return 2;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/parent/dashboard');
        break;
      case 1:
        context.go('/parent/children');
        break;
      case 2:
        context.go('/parent/notifications');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _selectedIndex(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return Scaffold(
            backgroundColor: kBgMain,
            body: child,
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: kBgBorder)),
              ),
              child: BottomNavigationBar(
                currentIndex: selectedIndex,
                onTap: (i) => _onTap(context, i),
                backgroundColor: kBgCard,
                selectedItemColor: kOrange,
                unselectedItemColor: kTextMuted,
                type: BottomNavigationBarType.fixed,
                selectedFontSize: 11,
                unselectedFontSize: 11,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home_rounded),
                    label: 'Bosh sahifa',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.child_care_outlined),
                    activeIcon: Icon(Icons.child_care_rounded),
                    label: 'Farzandlar',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.notifications_none_rounded),
                    activeIcon: Icon(Icons.notifications_rounded),
                    label: 'Bildirishnoma',
                  ),
                ],
              ),
            ),
          );
        }

        // Tablet / Desktop
        return Scaffold(
          backgroundColor: kBgMain,
          body: Row(
            children: [
              NavigationRail(
                backgroundColor: kBgCard,
                selectedIndex: selectedIndex,
                onDestinationSelected: (i) => _onTap(context, i),
                labelType: NavigationRailLabelType.selected,
                selectedIconTheme: const IconThemeData(color: kOrange),
                selectedLabelTextStyle: const TextStyle(color: kOrange),
                unselectedIconTheme: const IconThemeData(color: kTextMuted),
                unselectedLabelTextStyle: const TextStyle(color: kTextMuted),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: Text('Bosh sahifa'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.child_care_outlined),
                    selectedIcon: Icon(Icons.child_care_rounded),
                    label: Text('Farzandlar'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.notifications_none_rounded),
                    selectedIcon: Icon(Icons.notifications_rounded),
                    label: Text('Bildirishnoma'),
                  ),
                ],
                leading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Icon(Icons.family_restroom_rounded,
                      color: kOrange, size: 28),
                ),
              ),
              const VerticalDivider(thickness: 1, width: 1, color: kBgBorder),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}
