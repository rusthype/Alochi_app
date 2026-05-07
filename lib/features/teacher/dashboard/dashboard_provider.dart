import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/teacher_api.dart';
import '../../../core/models/teacher_dashboard.dart';

final teacherApiProvider = Provider((ref) => TeacherApi());

/// Composes dashboard summary from:
///   GET /teacher/panel/dashboard/  — attendance, top students, weekly activity
///   GET /teacher/timetable/        — week schedule, today lessons
final dashboardSummaryProvider =
    FutureProvider<TeacherDashboardSummary>((ref) async {
  final api = ref.read(teacherApiProvider);
  return api.getDashboardSummary();
});
