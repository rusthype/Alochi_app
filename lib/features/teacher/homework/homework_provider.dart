import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/teacher_api.dart';
import '../dashboard/dashboard_provider.dart';

final homeworkListProvider = FutureProvider<HomeworkListData>((ref) async {
  final api = ref.read(teacherApiProvider);
  return api.getHomework();
});

final homeworkDetailProvider =
    FutureProvider.autoDispose.family<HomeworkModel, String>((ref, hwId) async {
  final api = ref.read(teacherApiProvider);
  return api.getHomeworkDetail(hwId);
});

final homeworkCreateProvider =
    StateNotifierProvider<HomeworkCreateNotifier, AsyncValue<HomeworkModel?>>(
        (ref) {
  final api = ref.read(teacherApiProvider);
  return HomeworkCreateNotifier(api, ref);
});

class HomeworkCreateNotifier extends StateNotifier<AsyncValue<HomeworkModel?>> {
  final TeacherApi _api;
  final Ref _ref;

  HomeworkCreateNotifier(this._api, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> create({
    required String groupId,
    required String title,
    required String description,
    required String dueDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      final hw = await _api.createHomework(
        groupId: groupId,
        title: title,
        description: description,
        dueDate: dueDate,
      );
      state = AsyncValue.data(hw);
      _ref.invalidate(homeworkListProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
