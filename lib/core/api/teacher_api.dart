import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/teacher_dashboard.dart';
import '../models/group_model.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/lesson_detail_model.dart';

class TeacherApi {
  final _client = ApiClient.instance;

  // ───── Dashboard ─────────────────────────────────────────────────────────

  Future<TeacherDashboardSummary> getDashboardSummary() async {
    try {
      final data = await _client.get('/teacher/dashboard/summary/') as Map<String, dynamic>;
      return TeacherDashboardSummary.fromJson(data);
    } catch (e, st) {
      debugPrint('getDashboardSummary error: $e\n$st');
      rethrow;
    }
  }

  // ───── Groups / Classes ──────────────────────────────────────────────────

  Future<List<GroupModel>> getGroups() async {
    try {
      final data = await _client.get('/teacher/classes/');
      List<dynamic> list;
      if (data is Map<String, dynamic>) {
        list = data['results'] as List? ?? [];
      } else if (data is List) {
        list = data;
      } else {
        list = [];
      }
      if (list.isEmpty) return [];
      return list.map((e) => GroupModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, st) {
      debugPrint('getGroups error: $e\n$st');
      rethrow;
    }
  }

  Future<GroupModel> getGroupDetail(String groupId) async {
    try {
      final data = await _client.get('/teacher/classes/$groupId/') as Map<String, dynamic>;
      return GroupModel.fromJson(data);
    } catch (e, st) {
      debugPrint('getGroupDetail error: $e\n$st');
      rethrow;
    }
  }

  // ───── Students ──────────────────────────────────────────────────────────

  Future<List<StudentModel>> getGroupStudents(String groupId) async {
    try {
      final data = await _client.get('/teacher/classes/$groupId/students/');
      List<dynamic> list;
      if (data is Map<String, dynamic>) {
        list = data['results'] as List? ?? [];
      } else if (data is List) {
        list = data;
      } else {
        list = [];
      }
      if (list.isEmpty) return [];
      return list.map((e) => StudentModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, st) {
      debugPrint('getGroupStudents error: $e\n$st');
      rethrow;
    }
  }

  Future<StudentModel> getStudentProfile(String studentId) async {
    try {
      final data = await _client.get('/teacher/students/$studentId/') as Map<String, dynamic>;
      return StudentModel.fromJson(data);
    } catch (e, st) {
      debugPrint('getStudentProfile error: $e\n$st');
      rethrow;
    }
  }

  // ───── Attendance ────────────────────────────────────────────────────────

  Future<Map<String, AttendanceStatus>> getAttendance({
    required String classId,
    required String date,
  }) async {
    try {
      final data = await _client.get(
        '/teacher/attendance/',
        params: {'class_id': classId, 'date': date},
      );
      Map<String, dynamic> statusMap;
      if (data is Map<String, dynamic>) {
        statusMap = (data['statuses'] ?? data) as Map<String, dynamic>;
      } else {
        statusMap = {};
      }
      return statusMap.map((key, value) {
        AttendanceStatus s;
        switch (value?.toString()) {
          case 'present':
            s = AttendanceStatus.present;
            break;
          case 'late':
            s = AttendanceStatus.late;
            break;
          case 'absent':
            s = AttendanceStatus.absent;
            break;
          default:
            s = AttendanceStatus.unmarked;
        }
        return MapEntry(key, s);
      });
    } catch (e, st) {
      debugPrint('getAttendance error: $e\n$st');
      return {};
    }
  }

  Future<void> markAttendance({
    required String classId,
    required String date,
    required Map<String, AttendanceStatus> statuses,
  }) async {
    try {
      final statusStrings = statuses.map(
        (k, v) => MapEntry(k, AttendanceRecordModel.statusToString(v)),
      );
      await _client.post('/teacher/attendance/mark/', data: {
        'class_id': classId,
        'date': date,
        'statuses': statusStrings,
      });
    } catch (e, st) {
      debugPrint('markAttendance error: $e\n$st');
      rethrow;
    }
  }

  Future<AttendanceHistoryModel> getAttendanceHistory({
    required String classId,
    String period = 'month',
  }) async {
    try {
      final data = await _client.get(
        '/teacher/attendance/history/',
        params: {'class_id': classId, 'period': period},
      ) as Map<String, dynamic>;
      return AttendanceHistoryModel.fromJson(data);
    } catch (e, st) {
      debugPrint('getAttendanceHistory error: $e\n$st');
      rethrow;
    }
  }

  // ───── Lessons ───────────────────────────────────────────────────────────

  Future<LessonDetailModel> getLessonDetail(String lessonId) async {
    try {
      final data = await _client.get('/teacher/lessons/$lessonId/') as Map<String, dynamic>;
      return LessonDetailModel.fromJson(data);
    } catch (e, st) {
      debugPrint('getLessonDetail error: $e\n$st');
      rethrow;
    }
  }
}
