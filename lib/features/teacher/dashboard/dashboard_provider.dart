import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/teacher_api.dart';
import '../../../core/models/teacher_dashboard.dart';

final teacherApiProvider = Provider((ref) => TeacherApi());

// TODO(Day 2): Replace with real compose pattern per TZ §5.3.3 — Future.wait([
//   teacherApi.getPanelDashboard(),
//   teacherApi.getPanelGroups(),
//   teacherApi.getTimetable(),
// ])
// Backend endpoint /teacher/dashboard/summary/ does NOT exist yet.
// Real endpoints: /teacher/panel/dashboard/ + /teacher/panel/groups/ + /teacher/timetable/
final dashboardSummaryProvider = FutureProvider<TeacherDashboardSummary>((ref) async {
  // DAY 1: mock data only. Real backend integration is Day 2 (TZ §5.3.3 compose pattern).
  await Future.delayed(const Duration(milliseconds: 300));
  return const TeacherDashboardSummary(
    greeting: 'Salom, Ustoz',
    todayLessons: [
      LessonModel(
        id: '1',
        time: '08:00',
        className: '2-guruh',
        subject: 'Matematika',
        studentCount: 11,
        isActive: true,
      ),
      LessonModel(
        id: '2',
        time: '09:30',
        className: '5-guruh',
        subject: 'Matematika',
        studentCount: 14,
        isActive: false,
      ),
      LessonModel(
        id: '3',
        time: '11:00',
        className: '8-guruh',
        subject: 'Matematika',
        studentCount: 12,
        isActive: false,
      ),
    ],
    concerns: [
      ConcernModel(
        type: 'homework',
        title: 'Tekshirilmagan vazifalar',
        count: '3',
        route: '/teacher/homework',
      ),
      ConcernModel(
        type: 'messages',
        title: "O'qilmagan xabarlar",
        count: '5',
        route: '/teacher/messages',
      ),
      ConcernModel(
        type: 'telegram',
        title: "Telegram'da kutilayotgan ota-onalar",
        count: '8',
        route: '/teacher/profile',
      ),
    ],
  );
});
