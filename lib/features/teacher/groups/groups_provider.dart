import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/group_model.dart';
import '../../../core/models/student_model.dart';
import '../dashboard/dashboard_provider.dart';

final groupsListProvider = FutureProvider<List<GroupModel>>((ref) async {
  final api = ref.read(teacherApiProvider);
  return api.getGroups();
});

final groupDetailProvider =
    FutureProvider.autoDispose.family<GroupModel, String>((ref, groupId) async {
  final api = ref.read(teacherApiProvider);
  return api.getGroupDetail(groupId);
});

final groupStudentsProvider =
    FutureProvider.autoDispose.family<List<StudentModel>, String>((ref, groupId) async {
  final api = ref.read(teacherApiProvider);
  return api.getGroupStudents(groupId);
});
