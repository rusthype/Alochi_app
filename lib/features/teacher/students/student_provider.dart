import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/student_model.dart';
import '../dashboard/dashboard_provider.dart';

final studentProfileProvider =
    FutureProvider.family<StudentModel, String>((ref, studentId) async {
  final api = ref.read(teacherApiProvider);
  return api.getStudentProfile(studentId);
});
