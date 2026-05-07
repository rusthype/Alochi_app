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
import '../features/teacher/students/birthdays_screen.dart';
import '../features/teacher/lesson/lesson_workflow_screen.dart';
import '../features/teacher/attendance/attendance_mark_screen.dart';
import '../features/teacher/attendance/attendance_history_screen.dart';
import '../features/teacher/grades/grades_screen.dart';
import '../features/teacher/grades/grades_entry_screen.dart';
import '../features/teacher/homework/homework_list_screen.dart';
import '../features/teacher/homework/homework_create_screen.dart';
import '../features/teacher/homework/homework_detail_screen.dart';
import '../features/teacher/messages/messages_list_screen.dart';
import '../features/teacher/messages/chat_thread_screen.dart';
import '../features/teacher/messages/message_compose_screen.dart';
import '../features/teacher/ai/ai_welcome_screen.dart';
import '../features/teacher/ai/ai_chat_screen.dart';
import '../features/teacher/telegram/telegram_parents_screen.dart';
import '../features/teacher/telegram/telegram_broadcast_screen.dart';
import '../features/teacher/telegram/unlinked_parents_screen.dart';
import '../features/teacher/profile/profile_screen.dart' as teacher_profile;
import '../features/teacher/profile/profile_edit_screen.dart';
import '../features/teacher/profile/password_change_screen.dart';
import '../features/teacher/profile/about_screen.dart';
import '../features/teacher/onboarding/welcome_intro_screen.dart';
import '../features/teacher/onboarding/welcome_features_screen.dart';
import '../features/teacher/onboarding/welcome_ready_screen.dart';
import '../features/teacher/notifications/notifications_screen.dart';
import '../features/teacher/lesson/week_timetable_screen.dart';
import '../features/teacher/lesson/lesson_detail_screen.dart';
import '../core/models/test_model.dart';
import '../core/models/lesson_model.dart';
import '../core/utils/date_utils.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = authState.user != null;
      final role = authState.user?.role;
      final loc = state.uri.toString();

      final publicRoutes = [
        '/',
        '/teacher/auth/login',
        '/forgot-password',
        '/login'
      ];
      final isPublic =
          publicRoutes.any((r) => loc == r || loc.startsWith('$r?'));

      if (!isAuth && !isPublic) {
        return '/';
      }

      if (isAuth) {
        if (role == 'teacher' &&
            authState.needsOnboarding &&
            !loc.startsWith('/teacher/onboarding/')) {
          return '/teacher/onboarding/intro';
        }
        if (loc == '/teacher/auth/login' && role == 'teacher') {
          return '/teacher/dashboard';
        }
        if (isPublic && (loc == '/' || loc == '/login')) {
          if (role == 'parent') {
            return '/parent/dashboard';
          }
          if (role == 'teacher') {
            return '/teacher/dashboard';
          }
          return '/student/dashboard';
        }
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
      GoRoute(path: '/', builder: (_, __) => const LandingScreen()),
      GoRoute(
          path: '/teacher/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
          path: '/teacher/onboarding/intro',
          builder: (_, __) => const WelcomeIntroScreen()),
      GoRoute(
          path: '/teacher/onboarding/features',
          builder: (_, __) => const WelcomeFeaturesScreen()),
      GoRoute(
          path: '/teacher/onboarding/ready',
          builder: (_, __) => const WelcomeReadyScreen()),
      GoRoute(
        path: '/invite',
        redirect: (ctx, state) {
          final groupId = state.uri.queryParameters['group'];
          if (groupId != null) {
            return '/teacher/telegram/groups/$groupId/unlinked';
          }
          return '/teacher/dashboard';
        },
      ),
      ShellRoute(
        builder: (context, state, child) => TeacherShell(child: child),
        routes: [
          GoRoute(
              path: '/teacher/dashboard',
              builder: (_, __) => const TeacherDashboardScreen()),
          GoRoute(
              path: '/teacher/timetable',
              builder: (_, __) => const WeekTimetableScreen()),
          GoRoute(
            path: '/teacher/lessons/:lessonId',
            builder: (context, state) {
              final lessonId = state.pathParameters['lessonId']!;
              final lesson = state.extra as LessonModel?;
              return LessonDetailScreen(lessonId: lessonId, lesson: lesson);
            },
          ),
          GoRoute(
              path: '/teacher/groups',
              builder: (_, __) => const GroupsListScreen()),
          GoRoute(
            path: '/teacher/groups/:id',
            builder: (context, state) =>
                GroupDetailScreen(groupId: state.pathParameters['id'] ?? ''),
          ),
          GoRoute(
            path: '/teacher/groups/:id/attendance-history',
            builder: (context, state) => AttendanceHistoryScreen(
                groupId: state.pathParameters['id'] ?? ''),
          ),
          GoRoute(
            path: '/teacher/students/:id',
            builder: (context, state) => StudentProfileScreen(
                studentId: state.pathParameters['id'] ?? ''),
          ),
          GoRoute(
              path: '/teacher/birthdays',
              builder: (_, __) => const BirthdaysScreen()),
          GoRoute(
            path: '/teacher/lesson/:id',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return LessonWorkflowScreen(
                lessonId: state.pathParameters['id'] ?? '',
                extra: extra,
              );
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
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return GradesScreen(
                groupId: state.pathParameters['id'] ?? '',
                groupName: extra['groupName']?.toString() ?? '',
                subject: extra['subject']?.toString() ?? '',
              );
            },
          ),
          GoRoute(
            path: '/teacher/groups/:id/grades-entry',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return GradesEntryScreen(
                groupId: state.pathParameters['id'] ?? '',
                groupName: extra['groupName']?.toString() ?? '',
                subject: extra['subject']?.toString() ?? '',
              );
            },
          ),
          GoRoute(
              path: '/teacher/homework',
              builder: (_, __) => const HomeworkListScreen()),
          GoRoute(
              path: '/teacher/homework/create',
              builder: (_, __) => const HomeworkCreateScreen()),
          GoRoute(
            path: '/teacher/homework/:id',
            builder: (context, state) =>
                HomeworkDetailScreen(hwId: state.pathParameters['id'] ?? ''),
          ),
          GoRoute(
              path: '/teacher/messages',
              builder: (_, __) => const MessagesListScreen()),
          GoRoute(
              path: '/teacher/messages/compose',
              builder: (_, __) => const MessageComposeScreen()),
          GoRoute(
            path: '/teacher/messages/:id',
            builder: (context, state) => ChatThreadScreen(
                conversationId: state.pathParameters['id'] ?? ''),
          ),
          GoRoute(
              path: '/teacher/notifications',
              builder: (_, __) => const NotificationsScreen()),
          GoRoute(
              path: '/teacher/profile',
              builder: (_, __) => const teacher_profile.ProfileScreen()),
          GoRoute(
              path: '/teacher/profile/telegram',
              builder: (_, __) => const TelegramParentsScreen()),
          GoRoute(
              path: '/teacher/profile/edit',
              builder: (_, __) => const ProfileEditScreen()),
          GoRoute(
              path: '/teacher/profile/password',
              builder: (_, __) => const PasswordChangeScreen()),
          GoRoute(
              path: '/teacher/about', builder: (_, __) => const AboutScreen()),
          GoRoute(
              path: '/teacher/ai', builder: (_, __) => const AiWelcomeScreen()),
          GoRoute(
              path: '/teacher/ai/chat',
              builder: (_, __) => const AiChatScreen()),
          GoRoute(
            path: '/teacher/telegram/groups/:id/unlinked',
            builder: (context, state) => UnlinkedParentsScreen(
                groupId: state.pathParameters['id'] ?? ''),
          ),
          GoRoute(
              path: '/teacher/telegram/broadcast',
              builder: (_, __) => const TelegramBroadcastScreen()),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => StudentShell(child: child),
        routes: [
          GoRoute(
              path: '/student/dashboard',
              builder: (_, __) => const StudentDashboardScreen()),
          GoRoute(
              path: '/student/tests',
              builder: (_, __) => const TestListScreen()),
          GoRoute(
            path: '/student/tests/:id/play',
            builder: (context, state) =>
                TestPlayScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/student/tests/:id/result',
            builder: (context, state) => TestResultScreen(
              id: state.pathParameters['id']!,
              result: state.extra as TestResultModel?,
            ),
          ),
          GoRoute(
              path: '/student/leaderboard',
              builder: (_, __) => const LeaderboardScreen()),
          GoRoute(
              path: '/student/vocabulary',
              builder: (_, __) => const VocabularyScreen()),
          GoRoute(
            path: '/student/vocabulary/:topicId/flashcards',
            builder: (context, state) =>
                FlashcardScreen(topicId: state.pathParameters['topicId']!),
          ),
          GoRoute(
            path: '/student/vocabulary/:topicId/quiz',
            builder: (context, state) =>
                QuizScreen(topicId: state.pathParameters['topicId']!),
          ),
          GoRoute(
              path: '/student/shop', builder: (_, __) => const ShopScreen()),
          GoRoute(
              path: '/student/purchases',
              builder: (_, __) => const PurchasesScreen()),
          GoRoute(
              path: '/student/homework',
              builder: (_, __) => const HomeworkScreen()),
          GoRoute(
              path: '/student/profile',
              builder: (_, __) => const student_profile.ProfileScreen()),
          GoRoute(
              path: '/student/profile/edit',
              builder: (_, __) => const EditProfileScreen()),
          GoRoute(
              path: '/student/journey',
              builder: (_, __) => const JourneyScreen()),
          GoRoute(
              path: '/student/challenge',
              builder: (_, __) => const ChallengeScreen()),
          GoRoute(
            path: '/student/challenge/result',
            builder: (context, state) => ChallengeResultScreen(
                data: state.extra as Map<String, dynamic>? ?? {}),
          ),
        ],
      ),
      GoRoute(path: '/login', redirect: (_, __) => '/teacher/auth/login'),
      GoRoute(path: '/dashboard', redirect: (_, __) => '/teacher/dashboard'),
      GoRoute(
          path: '/leaderboard', redirect: (_, __) => '/student/leaderboard'),
      ShellRoute(
        builder: (context, state, child) => ParentShell(child: child),
        routes: [
          GoRoute(
              path: '/parent/dashboard',
              builder: (_, __) => const ParentDashboardScreen()),
          GoRoute(
              path: '/parent/children',
              builder: (_, __) => const ParentDashboardScreen()),
          GoRoute(
            path: '/parent/children/:id',
            builder: (context, state) =>
                ChildDetailScreen(childId: state.pathParameters['id']!),
          ),
          GoRoute(
              path: '/parent/notifications',
              builder: (_, __) => const ParentNotificationsScreen()),
        ],
      ),
    ],
  );
});
