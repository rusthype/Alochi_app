import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/landing/landing_screen.dart';
import '../features/student/shell/student_shell.dart';
import '../features/student/dashboard/student_dashboard_screen.dart';
import '../features/student/tests/test_list_screen.dart';
import '../features/student/tests/test_play_screen.dart';
import '../features/student/tests/test_result_screen.dart';
import '../features/student/leaderboard/leaderboard_screen.dart';
import '../features/student/vocabulary/vocabulary_screen.dart';
import '../features/student/vocabulary/flashcard_screen.dart';
import '../features/student/vocabulary/quiz_screen.dart';
import '../features/student/shop/shop_screen.dart';
import '../features/student/shop/purchases_screen.dart';
import '../features/student/homework/homework_screen.dart';
import '../features/student/profile/profile_screen.dart';
import '../features/student/profile/edit_profile_screen.dart';
import '../features/student/journey/journey_screen.dart';
import '../features/student/challenge/challenge_screen.dart';
import '../features/student/challenge/challenge_result_screen.dart';
import '../features/parent/shell/parent_shell.dart';
import '../features/parent/dashboard/parent_dashboard_screen.dart';
import '../features/parent/children/child_detail_screen.dart';
import '../features/parent/notifications/parent_notifications_screen.dart';
import '../features/teacher/shell/teacher_shell.dart';
import '../features/teacher/dashboard/dashboard_screen.dart';
import '../core/models/test_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = authState.user != null;
      final role = authState.user?.role;
      final loc = state.uri.toString();

      // Allow public routes
      final publicRoutes = ['/', '/login', '/forgot-password'];
      final isPublic = publicRoutes.contains(loc);

      if (!isAuth && !isPublic) return '/login';

      if (isAuth) {
        // Redirect away from public routes if already logged in
        if (isPublic) {
          if (role == 'parent') return '/parent/dashboard';
          if (role == 'teacher') return '/dashboard';
          return '/student/dashboard';
        }
        // Role-based restrictions
        if (role == 'student' && (loc.startsWith('/parent') || loc.startsWith('/teacher') || loc == '/dashboard')) {
          return '/student/dashboard';
        }
        if (role == 'parent' && (loc.startsWith('/student') || loc.startsWith('/teacher') || loc == '/dashboard')) {
          return '/parent/dashboard';
        }
        if (role == 'teacher' && (loc.startsWith('/student') || loc.startsWith('/parent'))) {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      // Public routes
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) =>
            const ForgotPasswordScreen(),
      ),

      // Teacher shell
      ShellRoute(
        builder: (context, state, child) => TeacherShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const TeacherDashboardScreen(),
          ),
          GoRoute(
            path: '/groups',
            builder: (context, state) => const Scaffold(body: Center(child: Text('Guruhlar'))),
          ),
          GoRoute(
            path: '/homework',
            builder: (context, state) => const Scaffold(body: Center(child: Text('Vazifalar'))),
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const Scaffold(body: Center(child: Text('Xabarlar'))),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const Scaffold(body: Center(child: Text('Profil'))),
          ),
        ],
      ),

      // Student shell with nested routes
      ShellRoute(
        builder: (context, state, child) =>
            StudentShell(child: child),
        routes: [
          GoRoute(
            path: '/student/dashboard',
            builder: (context, state) =>
                const StudentDashboardScreen(),
          ),
          GoRoute(
            path: '/student/tests',
            builder: (context, state) => const TestListScreen(),
          ),
          GoRoute(
            path: '/student/tests/:id/play',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TestPlayScreen(id: id);
            },
          ),
          GoRoute(
            path: '/student/tests/:id/result',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final result = state.extra as TestResultModel?;
              return TestResultScreen(id: id, result: result);
            },
          ),
          GoRoute(
            path: '/student/leaderboard',
            builder: (context, state) =>
                const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/student/vocabulary',
            builder: (context, state) =>
                const VocabularyScreen(),
          ),
          GoRoute(
            path: '/student/vocabulary/:topicId/flashcards',
            builder: (context, state) {
              final topicId =
                  state.pathParameters['topicId']!;
              return FlashcardScreen(topicId: topicId);
            },
          ),
          GoRoute(
            path: '/student/vocabulary/:topicId/quiz',
            builder: (context, state) {
              final topicId =
                  state.pathParameters['topicId']!;
              return QuizScreen(topicId: topicId);
            },
          ),
          GoRoute(
            path: '/student/shop',
            builder: (context, state) => const ShopScreen(),
          ),
          GoRoute(
            path: '/student/purchases',
            builder: (context, state) =>
                const PurchasesScreen(),
          ),
          GoRoute(
            path: '/student/homework',
            builder: (context, state) =>
                const HomeworkScreen(),
          ),
          GoRoute(
            path: '/student/profile',
            builder: (context, state) =>
                const ProfileScreen(),
          ),
          GoRoute(
            path: '/student/profile/edit',
            builder: (context, state) =>
                const EditProfileScreen(),
          ),
          GoRoute(
            path: '/student/journey',
            builder: (context, state) =>
                const JourneyScreen(),
          ),
          GoRoute(
            path: '/student/challenge',
            builder: (context, state) =>
                const ChallengeScreen(),
          ),
          GoRoute(
            path: '/student/challenge/result',
            builder: (context, state) {
              final data =
                  state.extra as Map<String, dynamic>? ??
                      {};
              return ChallengeResultScreen(data: data);
            },
          ),
        ],
      ),

      // Legacy leaderboard route
      GoRoute(
        path: '/leaderboard',
        redirect: (ctx, st) =>
            '/student/leaderboard',
      ),

      // Parent shell with nested routes
      ShellRoute(
        builder: (context, state, child) =>
            ParentShell(child: child),
        routes: [
          GoRoute(
            path: '/parent/dashboard',
            builder: (context, state) =>
                const ParentDashboardScreen(),
          ),
          GoRoute(
            path: '/parent/children',
            builder: (context, state) =>
                const ParentDashboardScreen(),
          ),
          GoRoute(
            path: '/parent/children/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ChildDetailScreen(childId: id);
            },
          ),
          GoRoute(
            path: '/parent/notifications',
            builder: (context, state) =>
                const ParentNotificationsScreen(),
          ),
        ],
      ),
    ],
  );
});
