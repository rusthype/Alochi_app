import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/alochi_bottom_nav.dart';
import '../dashboard/dashboard_screen.dart';
import '../groups/groups_list_screen.dart';
import '../homework/homework_list_screen.dart';
import '../messages/messages_list_screen.dart';
import '../profile/profile_screen.dart';

class TeacherShell extends ConsumerStatefulWidget {
  final Widget child;

  const TeacherShell({super.key, required this.child});

  @override
  ConsumerState<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends ConsumerState<TeacherShell> {
  late final List<Widget> _tabs = const [
    TeacherDashboardScreen(),
    GroupsListScreen(),
    HomeworkListScreen(),
    MessagesListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    bool isRootTab = false;

    if (location == '/teacher/dashboard') {
      currentIndex = 0;
      isRootTab = true;
    } else if (location == '/teacher/groups') {
      currentIndex = 1;
      isRootTab = true;
    } else if (location == '/teacher/homework') {
      currentIndex = 2;
      isRootTab = true;
    } else if (location == '/teacher/messages') {
      currentIndex = 3;
      isRootTab = true;
    } else if (location == '/teacher/profile') {
      currentIndex = 4;
      isRootTab = true;
    } else {
      // Sub-route index for bottom nav active state
      if (location.startsWith('/teacher/dashboard') ||
          location.startsWith('/teacher/ai')) {
        currentIndex = 0;
      } else if (location.startsWith('/teacher/groups')) {
        currentIndex = 1;
      } else if (location.startsWith('/teacher/homework')) {
        currentIndex = 2;
      } else if (location.startsWith('/teacher/messages')) {
        currentIndex = 3;
      } else if (location.startsWith('/teacher/profile') ||
          location.startsWith('/teacher/telegram')) {
        currentIndex = 4;
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: currentIndex,
            children: _tabs,
          ),
          if (!isRootTab) widget.child,
        ],
      ),
      bottomNavigationBar: AlochiBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == currentIndex && isRootTab) return;

          switch (index) {
            case 0:
              context.go('/teacher/dashboard');
              break;
            case 1:
              context.go('/teacher/groups');
              break;
            case 2:
              context.go('/teacher/homework');
              break;
            case 3:
              context.go('/teacher/messages');
              break;
            case 4:
              context.go('/teacher/profile');
              break;
          }
        },
      ),
    );
  }
}
