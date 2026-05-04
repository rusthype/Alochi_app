import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/teacher_api.dart';
import '../../../core/models/teacher_dashboard.dart';

final teacherApiProvider = Provider((ref) => TeacherApi());

final dashboardSummaryProvider = FutureProvider<TeacherDashboardSummary>((ref) async {
  final api = ref.read(teacherApiProvider);
  return api.getDashboardSummary();
});
