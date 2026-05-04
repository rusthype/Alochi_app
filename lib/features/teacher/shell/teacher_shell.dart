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
    if (location.startsWith('/dashboard')) {
      currentIndex = 0;
    } else if (location.startsWith('/groups')) {
      currentIndex = 1;
    } else if (location.startsWith('/homework')) {
      currentIndex = 2;
    } else if (location.startsWith('/messages')) {
      currentIndex = 3;
    } else if (location.startsWith('/profile')) {
      currentIndex = 4;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: AlochiBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/groups');
              break;
            case 2:
              context.go('/homework');
              break;
            case 3:
              context.go('/messages');
              break;
            case 4:
              context.go('/profile');
              break;
          }
        },
      ),
    );
  }
}
