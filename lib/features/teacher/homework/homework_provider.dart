import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/teacher_api.dart';
import '../dashboard/dashboard_provider.dart';

final homeworkListProvider = FutureProvider.autoDispose<HomeworkListData>((ref) async {
  final api = ref.read(teacherApiProvider);
  return api.getHomework();
});

final homeworkDetailProvider =
    FutureProvider.autoDispose.family<HomeworkModel, String>((ref, hwId) async {
  final api = ref.read(teacherApiProvider);
  return api.getHomeworkDetail(hwId);
});
