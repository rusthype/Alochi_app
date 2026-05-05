import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/teacher_api.dart';
import '../dashboard/dashboard_provider.dart';

final teacherProfileProvider =
    FutureProvider<TeacherProfileModel>((ref) async {
  final api = ref.read(teacherApiProvider);
  try {
    return await api.getTeacherProfile();
  } catch (e, st) {
    debugPrint('teacherProfileProvider error: $e\n$st');
    rethrow;
  }
});
