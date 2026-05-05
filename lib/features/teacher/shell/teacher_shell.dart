import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/alochi_bottom_nav.dart';

class TeacherShell extends StatelessWidget {
  final Widget child;

  const TeacherShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location.startsWith('/teacher/dashboard')) {
      currentIndex = 0;
    } else if (location.startsWith('/teacher/groups')) {
      currentIndex = 1;
    } else if (location.startsWith('/teacher/homework')) {
      currentIndex = 2;
    } else if (location.startsWith('/teacher/messages')) {
      currentIndex = 3;
    } else if (location.startsWith('/teacher/profile')) {
      currentIndex = 4;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: AlochiBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
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
