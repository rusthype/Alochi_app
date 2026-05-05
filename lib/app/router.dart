import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/forgot_password_screen.dart';
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
import '../features/student/profile/profile_screen.dart' as student_profile;
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
import '../features/teacher/groups/groups_list_screen.dart';
import '../features/teacher/groups/group_detail_screen.dart';
import '../features/teacher/students/student_profile_screen.dart';
import '../features/teacher/lesson/lesson_workflow_screen.dart';
import '../features/teacher/attendance/attendance_mark_screen.dart';
import '../features/teacher/attendance/attendance_history_screen.dart';
import '../features/teacher/grades/grades_screen.dart';
import '../features/teacher/homework/homework_list_screen.dart';
import '../features/teacher/homework/homework_create_screen.dart';
import '../features/teacher/homework/homework_detail_screen.dart';
import '../features/teacher/messages/messages_list_screen.dart';
import '../features/teacher/messages/chat_thread_screen.dart';
import '../features/teacher/ai/ai_welcome_screen.dart';
import '../features/teacher/ai/ai_chat_screen.dart';
import '../features/teacher/telegram/telegram_parents_screen.dart';
import '../features/teacher/telegram/unlinked_parents_screen.dart';
import '../features/teacher/profile/profile_screen.dart' as teacher_profile;
import '../features/teacher/profile/profile_edit_screen.dart';
import '../features/teacher/profile/password_change_screen.dart';
import '../features/teacher/onboarding/welcome_intro_screen.dart';
import '../core/models/test_model.dart';
import '../core/utils/date_utils.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/teacher/auth/login',
    redirect: (context, state) {
      final isAuth = authState.user != null;
      final role = authState.user?.role;
      final loc = state.uri.toString();

      // Teacher app public routes
      final publicRoutes = [
        '/teacher/auth/login',
        '/forgot-password',
        // Legacy public routes kept for backward compat
        '/',
        '/login',
      ];
      final isPublic = publicRoutes.contains(loc);

      // Any non-/teacher/* route goes to teacher login
      if (!loc.startsWith('/teacher') &&
          !loc.startsWith('/student') &&
          !loc.startsWith('/parent') &&
          loc != '/forgot-password' &&
          loc != '/login' &&
          loc != '/') {
        return '/teacher/auth/login';
      }

      if (!isAuth && !isPublic) return '/teacher/auth/login';

      if (isAuth) {
        // Show onboarding for first-time teacher logins
        if (role == 'teacher' &&
            authState.needsOnboarding &&
            loc != '/teacher/onboarding/intro') {
          return '/teacher/onboarding/intro';
        }
        // If on teacher login while authenticated as teacher, go to dashboard
        if (loc == '/teacher/auth/login' && role == 'teacher') {
          return '/teacher/dashboard';
        }
        // Redirect away from legacy public routes
        if (isPublic && (loc == '/' || loc == '/login')) {
          if (role == 'parent') return '/parent/dashboard';
          if (role == 'teacher') return '/teacher/dashboard';
          return '/student/dashboard';
        }
        // Role-based restrictions for student/parent routes
        if (role == 'student' &&
            (loc.startsWith('/parent') || loc.startsWith('/teacher'))) {
          return '/student/dashboard';
        }
        if (role == 'parent' &&
            (loc.startsWith('/student') || loc.startsWith('/teacher'))) {
          return '/parent/dashboard';
        }
        if (role == 'teacher' &&
            (loc.startsWith('/student') || loc.startsWith('/parent'))) {
          return '/teacher/dashboard';
        }
      }

      return null;
    },
    routes: [
      // Teacher auth routes
      GoRoute(
        path: '/teacher/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Teacher shell
      ShellRoute(
        builder: (context, state, child) => TeacherShell(child: child),
        routes: [
          GoRoute(
            path: '/teacher/dashboard',
            builder: (context, state) => const TeacherDashboardScreen(),
          ),
          GoRoute(
            path: '/teacher/groups',
            builder: (context, state) => const GroupsListScreen(),
          ),
          GoRoute(
            path: '/teacher/groups/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return GroupDetailScreen(groupId: id);
            },
          ),
          GoRoute(
            path: '/teacher/groups/:id/attendance-history',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return AttendanceHistoryScreen(groupId: id);
            },
          ),
          GoRoute(
            path: '/teacher/students/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return StudentProfileScreen(studentId: id);
            },
          ),
          GoRoute(
            path: '/teacher/lesson/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return LessonWorkflowScreen(lessonId: id);
            },
          ),
          GoRoute(
            path: '/teacher/lesson/:id/attendance',
            builder: (context, state) {
              final lessonId = state.pathParameters['id'] ?? '';
              final extra = state.extra as Map<String, dynamic>? ?? {};
              final classId = extra['classId']?.toString() ?? lessonId;
              final date = extra['date']?.toString() ?? todayIsoString();
              return AttendanceMarkScreen(classId: classId, date: date);
            },
          ),
          GoRoute(
            path: '/teacher/groups/:id/grades',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              final extra = state.extra as Map<String, dynamic>? ?? {};
              final subject = extra['subject']?.toString() ?? '';
              final groupName = extra['groupName']?.toString() ?? '';
              return GradesScreen(
                groupId: id,
                groupName: groupName,
                subject: subject,
              );
            },
          ),
          GoRoute(
            path: '/teacher/homework',
            builder: (context, state) => const HomeworkListScreen(),
          ),
          GoRoute(
            path: '/teacher/homework/create',
            builder: (context, state) => const HomeworkCreateScreen(),
          ),
          GoRoute(
            path: '/teacher/homework/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return HomeworkDetailScreen(hwId: id);
            },
          ),
          GoRoute(
            path: '/teacher/messages',
            builder: (context, state) => const MessagesListScreen(),
          ),
          GoRoute(
            path: '/teacher/messages/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return ChatThreadScreen(conversationId: id);
            },
          ),
          GoRoute(
            path: '/teacher/profile',
            builder: (context, state) => const teacher_profile.ProfileScreen(),
          ),
          GoRoute(
            path: '/teacher/profile/telegram',
            builder: (context, state) => const TelegramParentsScreen(),
          ),
          GoRoute(
            path: '/teacher/profile/edit',
            builder: (context, state) => const ProfileEditScreen(),
          ),
          GoRoute(
            path: '/teacher/profile/password',
            builder: (context, state) => const PasswordChangeScreen(),
          ),
          GoRoute(
            path: '/teacher/onboarding/intro',
            builder: (context, state) => const WelcomeIntroScreen(),
          ),
          GoRoute(
            path: '/teacher/ai',
            builder: (context, state) => const AiWelcomeScreen(),
          ),
          GoRoute(
            path: '/teacher/ai/chat',
            builder: (context, state) => const AiChatScreen(),
          ),
          GoRoute(
            path: '/teacher/telegram/groups/:id/unlinked',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return UnlinkedParentsScreen(groupId: id);
            },
          ),
        ],
      ),

      // Student shell with nested routes
      ShellRoute(
        builder: (context, state, child) => StudentShell(child: child),
        routes: [
          GoRoute(
            path: '/student/dashboard',
            builder: (context, state) => const StudentDashboardScreen(),
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
            builder: (context, state) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/student/vocabulary',
            builder: (context, state) => const VocabularyScreen(),
          ),
          GoRoute(
            path: '/student/vocabulary/:topicId/flashcards',
            builder: (context, state) {
              final topicId = state.pathParameters['topicId']!;
              return FlashcardScreen(topicId: topicId);
            },
          ),
          GoRoute(
            path: '/student/vocabulary/:topicId/quiz',
            builder: (context, state) {
              final topicId = state.pathParameters['topicId']!;
              return QuizScreen(topicId: topicId);
            },
          ),
          GoRoute(
            path: '/student/shop',
            builder: (context, state) => const ShopScreen(),
          ),
          GoRoute(
            path: '/student/purchases',
            builder: (context, state) => const PurchasesScreen(),
          ),
          GoRoute(
            path: '/student/homework',
            builder: (context, state) => const HomeworkScreen(),
          ),
          GoRoute(
            path: '/student/profile',
            builder: (context, state) => const student_profile.ProfileScreen(),
          ),
          GoRoute(
            path: '/student/profile/edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: '/student/journey',
            builder: (context, state) => const JourneyScreen(),
          ),
          GoRoute(
            path: '/student/challenge',
            builder: (context, state) => const ChallengeScreen(),
          ),
          GoRoute(
            path: '/student/challenge/result',
            builder: (context, state) {
              final data = state.extra as Map<String, dynamic>? ?? {};
              return ChallengeResultScreen(data: data);
            },
          ),
        ],
      ),

      // Legacy routes — kept registered, redirect to appropriate destinations
      GoRoute(
        path: '/',
        redirect: (ctx, st) => '/teacher/auth/login',
      ),
      GoRoute(
        path: '/login',
        redirect: (ctx, st) => '/teacher/auth/login',
      ),
      GoRoute(
        path: '/dashboard',
        redirect: (ctx, st) => '/teacher/dashboard',
      ),
      GoRoute(
        path: '/leaderboard',
        redirect: (ctx, st) => '/student/leaderboard',
      ),

      // Parent shell with nested routes
      ShellRoute(
        builder: (context, state, child) => ParentShell(child: child),
        routes: [
          GoRoute(
            path: '/parent/dashboard',
            builder: (context, state) => const ParentDashboardScreen(),
          ),
          GoRoute(
            path: '/parent/children',
            builder: (context, state) => const ParentDashboardScreen(),
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
            builder: (context, state) => const ParentNotificationsScreen(),
          ),
        ],
      ),
    ],
  );
});
