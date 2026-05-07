import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/lesson_model.dart';
import '../dashboard/dashboard_provider.dart';

final todayLessonsProvider =
    FutureProvider.autoDispose<List<LessonModel>>((ref) async {
  final api = ref.read(teacherApiProvider);
  return api.getTodayLessons();
});

final weekLessonsProvider =
    FutureProvider.autoDispose<Map<String, List<LessonModel>>>((ref) async {
  final api = ref.read(teacherApiProvider);
  return api.getWeekLessons();
});
