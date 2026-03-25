import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/colors.dart';
import '../../../core/api/student_api.dart';

final _unreadCountProvider =
    FutureProvider<int>((ref) async {
  try {
    final data = await StudentApi().getUnreadCount();
    return data['count'] as int? ?? 0;
  } catch (_) {
    return 0;
  }
});

class StudentShell extends ConsumerWidget {
  final Widget child;
  const StudentShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/student/dashboard')) return 0;
    if (loc.startsWith('/student/tests')) return 1;
    if (loc.startsWith('/student/leaderboard') ||
        loc.startsWith('/leaderboard')) return 2;
    if (loc.startsWith('/student/profile')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/student/dashboard');
        break;
      case 1:
        context.go('/student/tests');
        break;
      case 2:
        context.go('/student/leaderboard');
        break;
      case 3:
        context.go('/student/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(_unreadCountProvider).valueOrNull ?? 0;
    final selectedIndex = _selectedIndex(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 600;
        final isTablet = width >= 600 && width < 1200;

        final destinations = _buildDestinations(unread);

        if (isMobile) {
          return Scaffold(
            backgroundColor: kBgMain,
            body: child,
            bottomNavigationBar: _BottomNav(
              selectedIndex: selectedIndex,
              onTap: (i) => _onTap(context, i),
              unreadCount: unread,
            ),
          );
        }

        if (isTablet) {
          return Scaffold(
            backgroundColor: kBgMain,
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: kBgCard,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (i) => _onTap(context, i),
                  labelType: NavigationRailLabelType.selected,
                  selectedIconTheme:
                      const IconThemeData(color: kOrange),
                  selectedLabelTextStyle:
                      const TextStyle(color: kOrange),
                  unselectedIconTheme:
                      const IconThemeData(color: kTextMuted),
                  unselectedLabelTextStyle:
                      const TextStyle(color: kTextMuted),
                  destinations: destinations
                      .map((d) => NavigationRailDestination(
                            icon: d.icon,
                            selectedIcon: d.selectedIcon,
                            label: Text(d.label),
                          ))
                      .toList(),
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Icon(Icons.school_rounded,
                        color: kOrange, size: 28),
                  ),
                ),
                const VerticalDivider(
                    thickness: 1, width: 1, color: kBgBorder),
                Expanded(child: child),
              ],
            ),
          );
        }

        // Desktop: full sidebar
        return Scaffold(
          backgroundColor: kBgMain,
          body: Row(
            children: [
              _DesktopSidebar(
                selectedIndex: selectedIndex,
                onTap: (i) => _onTap(context, i),
                unreadCount: unread,
                destinations: destinations,
              ),
              const VerticalDivider(
                  thickness: 1, width: 1, color: kBgBorder),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }

  List<_Destination> _buildDestinations(int unread) {
    return [
      _Destination(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard_rounded),
          label: 'Bosh sahifa'),
      _Destination(
          icon: const Icon(Icons.quiz_outlined),
          selectedIcon: const Icon(Icons.quiz_rounded),
          label: 'Testlar'),
      _Destination(
          icon: const Icon(Icons.leaderboard_outlined),
          selectedIcon: const Icon(Icons.leaderboard_rounded),
          label: 'Reyting'),
      _Destination(
          icon: const Icon(Icons.person_outline_rounded),
          selectedIcon: const Icon(Icons.person_rounded),
          label: 'Profil'),
    ];
  }
}

class _Destination {
  final Widget icon;
  final Widget selectedIcon;
  final String label;
  const _Destination(
      {required this.icon,
      required this.selectedIcon,
      required this.label});
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final int unreadCount;
  const _BottomNav(
      {required this.selectedIndex,
      required this.onTap,
      required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: kBgBorder)),
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        backgroundColor: kBgCard,
        selectedItemColor: kOrange,
        unselectedItemColor: kTextMuted,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Bosh sahifa',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.quiz_outlined),
            activeIcon: Icon(Icons.quiz_rounded),
            label: 'Testlar',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard_outlined),
            activeIcon: Icon(Icons.leaderboard_rounded),
            label: 'Reyting',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.person_outline_rounded),
            ),
            activeIcon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.person_rounded),
            ),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final int unreadCount;
  final List<_Destination> destinations;
  const _DesktopSidebar(
      {required this.selectedIndex,
      required this.onTap,
      required this.unreadCount,
      required this.destinations});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Container(
        color: kBgCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SafeArea(
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Row(
                  children: [
                    Icon(Icons.school_rounded,
                        color: kOrange, size: 28),
                    SizedBox(width: 10),
                    Text("A'lochi",
                        style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
            const Divider(color: kBgBorder, height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                children: destinations.asMap().entries.map((e) {
                  final i = e.key;
                  final d = e.value;
                  final isSelected = selectedIndex == i;
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      selected: isSelected,
                      selectedTileColor:
                          kOrange.withOpacity(0.1),
                      selectedColor: kOrange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      leading: isSelected
                          ? d.selectedIcon
                          : d.icon,
                      title: Text(d.label,
                          style: TextStyle(
                              color: isSelected
                                  ? kOrange
                                  : kTextMuted,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 14)),
                      onTap: () => onTap(i),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
