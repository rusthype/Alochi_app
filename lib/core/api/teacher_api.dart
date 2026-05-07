import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/teacher_dashboard.dart';
import '../models/group_model.dart';
import '../models/student_model.dart';
import '../models/lesson_detail_model.dart';
import '../models/lesson_model.dart';
import '../models/message_model.dart';
import '../models/grades_model.dart';
import '../models/homework_model.dart';
import '../models/ai_message_model.dart';
import '../models/teacher_profile_model.dart';
import '../models/telegram_model.dart';
import '../models/notification.dart';
import '../models/group_analytics.dart';

export '../models/grades_model.dart';
export '../models/homework_model.dart';
export '../models/ai_message_model.dart';
export '../models/teacher_profile_model.dart';
export '../models/telegram_model.dart';
export '../models/notification.dart';

class TeacherApi {
  final _client = ApiClient.instance;

  // ───── Dashboard ─────────────────────────────────────────────────────────

  /// Composes dashboard summary from real endpoints:
  ///   GET /teacher/panel/dashboard/  → attendance_today, top_students, etc.
  ///   GET /teacher/timetable/        → week.lessons filtered by today's weekday
  Future<TeacherDashboardSummary> getDashboardSummary() async {
    try {
      final results = await Future.wait([
        _client.get('/teacher/panel/dashboard/').catchError((e) {
          debugPrint('Dashboard data error: $e');
          return <String, dynamic>{};
        }),
        _client.get('/teacher/timetable/').catchError((e) {
          debugPrint('Timetable data error: $e');
          return <String, dynamic>{};
        }),
        _client.get('/teacher/panel/groups/').catchError((e) {
          debugPrint('Groups data error: $e');
          return <String, dynamic>{'results': []};
        }),
      ]);
      final dashData = (results[0] as Map?)?.cast<String, dynamic>() ?? {};
      final ttData = (results[1] as Map?)?.cast<String, dynamic>() ?? {};

      List<dynamic> groupsList = [];
      final groupsResponse = results[2];
      if (groupsResponse is Map<String, dynamic>) {
        groupsList = groupsResponse['results'] as List? ?? [];
      } else if (groupsResponse is List) {
        groupsList = groupsResponse;
      }

      return TeacherDashboardSummary.fromComposed(dashData, ttData, groupsList);
    } catch (e, st) {
      debugPrint('getDashboardSummary error: $e\n$st');
      return TeacherDashboardSummary.empty();
    }
  }

  // ───── Groups / Classes ──────────────────────────────────────────────────

  Future<List<GroupModel>> getGroups() async {
    try {
      final data = await _client.get('/teacher/panel/groups/');
      List<dynamic> list;
      if (data is Map<String, dynamic>) {
        list = data['results'] as List? ?? [];
      } else if (data is List) {
        list = data;
      } else {
        list = [];
      }
      if (list.isEmpty) return [];
      return list
          .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      debugPrint('getGroups error: $e\n$st');
      rethrow;
    }
  }

  Future<GroupModel> getGroupDetail(String groupId) async {
    try {
      // /teacher/panel/groups/:id/ returns 404 — fall back to listing and filtering
      final data = await _client.get('/teacher/panel/groups/');
      List<dynamic> list;
      if (data is Map<String, dynamic>) {
        list = data['results'] as List? ?? [];
      } else if (data is List) {
        list = data;
      } else {
        list = [];
      }
      final match = list.firstWhere(
        (e) => (e as Map<String, dynamic>)['id']?.toString() == groupId,
        orElse: () => <String, dynamic>{'id': groupId},
      );
      return GroupModel.fromJson(match as Map<String, dynamic>);
    } catch (e, st) {
      debugPrint('getGroupDetail error: $e\n$st');
      rethrow;
    }
  }

  // ───── Students ──────────────────────────────────────────────────────────

  /// Returns students for a group using the panel attendance endpoint
  /// which reliably returns the student list.
  Future<List<StudentModel>> getGroupStudents(String groupId) async {
    try {
      final data =
          await _client.get('/teacher/panel/groups/$groupId/attendance/');
      if (data is Map<String, dynamic>) {
        final rawStudents = data['students'] as List? ?? [];
        if (rawStudents.isEmpty) return [];
        return rawStudents.map((e) {
          final m = e as Map<String, dynamic>;
          // attendance endpoint returns {id, name, status}
          final nameParts = (m['name']?.toString() ?? '').split(' ');
          return StudentModel(
            id: m['id']?.toString() ?? '',
            firstName: nameParts.isNotEmpty ? nameParts[0] : '',
            lastName:
                nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
            classId: groupId,
          );
        }).toList();
      }
      return [];
    } catch (e, st) {
      debugPrint('getGroupStudents error: $e\n$st');
      rethrow;
    }
  }

  /// Raw attendance data for a group — verified working endpoint.
  /// Returns {lesson_id, date, group: {id, name, subject}, students: [...], stats: {...}}
  Future<Map<String, dynamic>> getGroupAttendanceRaw(String groupId) async {
    try {
      final data =
          await _client.get('/teacher/panel/groups/$groupId/attendance/');
      if (data is Map<String, dynamic>) return data;
      return {};
    } catch (e, st) {
      debugPrint('getGroupAttendanceRaw error: $e\n$st');
      rethrow;
    }
  }

  Future<StudentModel> getStudentProfile(String studentId) async {
    try {
      // Verified: /students/:id/ returns 404; /students/:id/portfolio/ returns 200
      final data = await _client.get('/teacher/students/$studentId/portfolio/')
          as Map<String, dynamic>;
      // Portfolio shape: {id, name, class_name, level, xp, avg_score, attendance_rate, ...}
      final fullName = data['name']?.toString() ?? '';
      final parts = fullName.split(' ');
      return StudentModel(
        id: data['id']?.toString() ?? studentId,
        firstName: parts.isNotEmpty ? parts[0] : '',
        lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
        classId: data['class_id']?.toString() ?? '',
        avgGrade: (data['avg_score'] as num?)?.toDouble(),
        attendancePct: (data['attendance_rate'] as num?)?.toDouble(),
        xp: (data['xp'] as num?)?.toInt() ?? 0,
        level: (data['level'] as num?)?.toInt() ?? 1,
        schoolName: data['subjects']?.toString(),
      );
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
      // Verified: backend requires group_id, not class_id
      final data = await _client.get(
        '/teacher/attendance/history/',
        params: {'group_id': classId, 'period': period},
      ) as Map<String, dynamic>;
      return AttendanceHistoryModel.fromJson(data);
    } catch (e, st) {
      debugPrint('getAttendanceHistory error: $e\n$st');
      rethrow;
    }
  }

  // ───── Grades ────────────────────────────────────────────────────────────

  /// GET /teacher/grades/journal/?group_id=X
  /// Returns {group: {}, students: [{id, name, grades_by_date: {}, average}]}
  Future<GradesJournalData> getGrades({required String groupId}) async {
    try {
      final data = await _client.get(
        '/teacher/grades/journal/',
        params: {'group_id': groupId},
      ) as Map<String, dynamic>;
      return GradesJournalData.fromJson(data, groupId);
    } catch (e, st) {
      debugPrint('getGrades error: $e\n$st');
      rethrow;
    }
  }

  /// Analytics composed from working endpoints:
  ///   GET /attendance/history/?group_id=X → attendance trend + low attendance
  ///   GET /grades/journal/?group_id=X → grade averages → grade trend
  Future<GroupAnalyticsModel> getGroupAnalytics(String groupId) async {
    try {
      final results = await Future.wait([
        _client.get('/teacher/attendance/history/', params: {
          'group_id': groupId,
          'period': 'month',
        }).catchError((e) => <String, dynamic>{}),
        _client.get('/teacher/grades/journal/', params: {
          'group_id': groupId,
        }).catchError((e) => <String, dynamic>{}),
      ]);

      final attData = (results[0] as Map?)?.cast<String, dynamic>() ?? {};
      final gradeData = (results[1] as Map?)?.cast<String, dynamic>() ?? {};

      // Attendance trend from by_day
      final byDay = attData['by_day'] as List? ?? [];
      final attTrend = byDay.map((d) {
        final m = d as Map<String, dynamic>;
        final total = (m['total'] as num?)?.toInt() ?? 0;
        final present = (m['present'] as num?)?.toInt() ?? 0;
        final rate = total > 0 ? (present / total * 100) : 0.0;
        return ChartPointModel(
          label: m['date']?.toString() ?? '',
          value: rate.toDouble(),
        );
      }).toList();

      // Grade trend from journal averages
      final students = gradeData['students'] as List? ?? [];
      final avgGrade = students.isEmpty
          ? 0.0
          : students.fold<double>(
                0,
                (sum, s) =>
                    sum +
                    ((s as Map<String, dynamic>)['average'] as num? ?? 0)
                        .toDouble(),
              ) /
              students.length;

      final gradeTrend = attTrend.isNotEmpty
          ? attTrend
              .map((pt) => ChartPointModel(label: pt.label, value: avgGrade))
              .toList()
          : <ChartPointModel>[];

      // Low attendance from history
      final lowList = attData['low_attendance_students'] as List? ?? [];
      final lowAttendance = lowList
          .map((e) =>
              LowAttendanceStudentModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Top students from grades journal
      final topStudents = students
          .where((s) => ((s as Map)['average'] as num? ?? 0) >= 4.0)
          .take(3)
          .map((s) {
        final m = s as Map<String, dynamic>;
        return TopStudentModel(
          id: m['id']?.toString() ?? '',
          name: m['name']?.toString() ?? '',
          xp: 0,
          level: 1,
        );
      }).toList();

      return GroupAnalyticsModel(
        attendanceTrend: attTrend,
        gradeTrend: gradeTrend,
        topStudents: topStudents,
        lowAttendanceStudents: lowAttendance,
      );
    } catch (e, st) {
      debugPrint('getGroupAnalytics error: $e\n$st');
      return const GroupAnalyticsModel(
        attendanceTrend: [],
        gradeTrend: [],
        topStudents: [],
        lowAttendanceStudents: [],
      );
    }
  }

  /// POST /teacher/grades/set/
  /// Payload: {student_id, grade (2-5), date, group_id}
  Future<void> setGrade({
    required String studentId,
    required int grade,
    required String date,
    required String groupId,
    String subject = 'Matematika',
  }) async {
    try {
      await _client.post('/teacher/grades/set/', data: {
        'student_id': studentId,
        'grade': grade,
        'date': date,
        'group_id': groupId,
        'subject': subject,
      });
    } catch (e, st) {
      debugPrint('setGrade error: $e\n$st');
      rethrow;
    }
  }

  // ───── Homework ──────────────────────────────────────────────────────────

  /// GET /teacher/homework/
  /// Returns {stats: {}, assignments: []}
  Future<HomeworkListData> getHomework() async {
    try {
      final data =
          await _client.get('/teacher/homework/') as Map<String, dynamic>;
      return HomeworkListData.fromJson(data);
    } catch (e, st) {
      debugPrint('getHomework error: $e\n$st');
      rethrow;
    }
  }

  /// GET /teacher/homework/:id/ — returns detail of one homework
  Future<HomeworkModel> getHomeworkDetail(String hwId) async {
    try {
      final data =
          await _client.get('/teacher/homework/$hwId/') as Map<String, dynamic>;
      return HomeworkModel.fromJson(data);
    } catch (e, st) {
      debugPrint('getHomeworkDetail error: $e\n$st');
      rethrow;
    }
  }

  /// POST /teacher/homework/
  Future<HomeworkModel> createHomework({
    required String groupId,
    required String title,
    required String description,
    required String dueDate,
  }) async {
    try {
      final data = await _client.post('/teacher/homework/', data: {
        'group_id': groupId,
        'title': title,
        'description': description,
        'due_date': dueDate,
      }) as Map<String, dynamic>;
      return HomeworkModel.fromJson(data);
    } catch (e, st) {
      debugPrint('createHomework error: $e\n$st');
      rethrow;
    }
  }

  /// POST /teacher/homework/:id/remind/
  Future<void> sendHomeworkReminder(String hwId) async {
    try {
      await _client.post('/teacher/homework/$hwId/remind/', data: {});
    } catch (e, st) {
      debugPrint('sendHomeworkReminder error: $e\n$st');
      rethrow;
    }
  }

  // ───── Lessons ───────────────────────────────────────────────────────────

  Future<LessonDetailModel> getLessonDetail(String lessonId) async {
    try {
      final data = await _client.get('/teacher/lessons/$lessonId/')
          as Map<String, dynamic>;
      return LessonDetailModel.fromJson(data);
    } catch (e, st) {
      debugPrint('getLessonDetail error: $e\n$st');
      rethrow;
    }
  }

  Future<List<LessonModel>> getTodayLessons() async {
    try {
      final data = await _client.get('/teacher/lessons/today/');
      if (data is List) {
        return data
            .map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e, st) {
      debugPrint('getTodayLessons error: $e\n$st');
      rethrow;
    }
  }

  Future<Map<String, List<LessonModel>>> getWeekLessons() async {
    try {
      final data =
          await _client.get('/teacher/lessons/week/') as Map<String, dynamic>;
      return data.map((key, value) {
        final list = value as List? ?? [];
        return MapEntry(
          key,
          list
              .map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      });
    } catch (e, st) {
      debugPrint('getWeekLessons error: $e\n$st');
      rethrow;
    }
  }

  // ───── Messages ──────────────────────────────────────────────────────────

  /// GET /teacher/messages/ → {conversations: []}
  Future<List<ConversationModel>> getConversations() async {
    try {
      final data = await _client.get('/teacher/messages/');
      List<dynamic> list;
      if (data is Map<String, dynamic>) {
        list = data['conversations'] as List? ?? [];
      } else if (data is List) {
        list = data;
      } else {
        list = [];
      }
      if (list.isEmpty) return [];
      return list
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      debugPrint('getConversations error: $e\n$st');
      rethrow;
    }
  }

  /// GET /teacher/messages/:id/  → conversation detail + messages
  Future<ConversationDetailModel> getConversationDetail(String id) async {
    try {
      final data =
          await _client.get('/teacher/messages/$id/') as Map<String, dynamic>;
      final conv = ConversationModel.fromJson(data);
      final rawMsgs = data['messages'] as List? ?? [];
      final msgs = rawMsgs.isEmpty
          ? <MessageModel>[]
          : rawMsgs
              .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
              .toList();
      return ConversationDetailModel(conversation: conv, messages: msgs);
    } catch (e, st) {
      debugPrint('getConversationDetail error: $e\n$st');
      rethrow;
    }
  }

  /// POST /teacher/messages/
  Future<void> sendNewMessage({
    required String recipientId,
    required String body,
  }) async {
    try {
      await _client.post('/teacher/messages/', data: {
        'recipient_id': recipientId,
        'body': body,
      });
    } catch (e, st) {
      debugPrint('sendNewMessage error: $e\n$st');
      rethrow;
    }
  }

  /// POST /teacher/messages/:id/send/
  Future<MessageModel> sendMessage(String conversationId, String text) async {
    try {
      final data = await _client.post(
        '/teacher/messages/$conversationId/send/',
        data: {'text': text},
      ) as Map<String, dynamic>;
      return MessageModel.fromJson(data);
    } catch (e, st) {
      debugPrint('sendMessage error: $e\n$st');
      rethrow;
    }
  }

  // ───── AI ────────────────────────────────────────────────────────────────

  /// POST /teacher/ai/chat/ → {reply: "..."}
  Future<String> sendAiMessage(String message) async {
    try {
      final data = await _client.post(
        '/teacher/ai/chat/',
        data: {'message': message},
      ) as Map<String, dynamic>;
      return data['reply']?.toString() ?? '';
    } catch (e, st) {
      debugPrint('sendAiMessage error: $e\n$st');
      rethrow;
    }
  }

  /// GET /teacher/ai/history/ → list of {role, content, timestamp}
  Future<List<AiMessageModel>> getAiHistory() async {
    try {
      final data = await _client.get('/teacher/ai/history/');
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic>) {
        list = data['results'] as List? ?? data['messages'] as List? ?? [];
      } else {
        list = [];
      }
      if (list.isEmpty) return [];
      return list
          .map((e) => AiMessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      debugPrint('getAiHistory error: $e\n$st');
      return [];
    }
  }

  // ───── Telegram ──────────────────────────────────────────────────────────

  /// GET /teacher/telegram/groups-status/ — may 404 (backend pending)
  Future<List<TelegramGroupStatusData>> getTelegramGroupsStatus() async {
    try {
      final data = await _client.get('/teacher/telegram/groups-status/');
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic>) {
        list = data['results'] as List? ?? data['groups'] as List? ?? [];
      } else {
        list = [];
      }
      if (list.isEmpty) return [];
      return list
          .map((e) =>
              TelegramGroupStatusData.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      debugPrint('getTelegramGroupsStatus error: $e\n$st');
      rethrow;
    }
  }

  /// GET /teacher/telegram/groups/{id}/unlinked-parents/ — may 404
  Future<List<UnlinkedParentData>> getUnlinkedParents(String groupId) async {
    try {
      final data = await _client
          .get('/teacher/telegram/groups/$groupId/unlinked-parents/');
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic>) {
        list = data['results'] as List? ?? data['parents'] as List? ?? [];
      } else {
        list = [];
      }
      if (list.isEmpty) return [];
      return list
          .map((e) => UnlinkedParentData.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      debugPrint('getUnlinkedParents error: $e\n$st');
      rethrow;
    }
  }

  /// POST /teacher/telegram/groups/{id}/remind/{parentId}/ — send one reminder
  Future<void> sendTelegramReminder(String groupId, String parentId) async {
    try {
      await _client.post(
        '/teacher/telegram/groups/$groupId/remind/$parentId/',
        data: {},
      );
    } catch (e, st) {
      debugPrint('sendTelegramReminder error: $e\n$st');
      rethrow;
    }
  }

  /// POST /teacher/telegram/groups/{id}/remind-all/ — bulk reminder
  Future<void> sendTelegramReminderAll(String groupId) async {
    try {
      await _client.post(
        '/teacher/telegram/groups/$groupId/remind-all/',
        data: {},
      );
    } catch (e, st) {
      debugPrint('sendTelegramReminderAll error: $e\n$st');
      rethrow;
    }
  }

  /// POST /teacher/telegram/broadcast/
  /// Payload: {group_id: "all"|groupId, message: text, type: "text"|"attendance"|"grades"}
  Future<void> broadcastTelegramMessage({
    required String groupId,
    required String message,
    required String type,
  }) async {
    try {
      await _client.post('/teacher/telegram/broadcast/', data: {
        'group_id': groupId,
        'message': message,
        'type': type,
      });
    } catch (e, st) {
      debugPrint('broadcastTelegramMessage error: $e\n$st');
      rethrow;
    }
  }

  // ───── Teacher profile ───────────────────────────────────────────────────

  /// GET /teacher/profile/ → {id, name, username, phone}
  Future<TeacherProfileModel> getTeacherProfile() async {
    try {
      final data =
          await _client.get('/teacher/profile/') as Map<String, dynamic>;
      return TeacherProfileModel.fromJson(data);
    } catch (e, st) {
      debugPrint('getTeacherProfile error: $e\n$st');
      rethrow;
    }
  }

  /// PATCH /teacher/profile/ → {id, name, username, phone}
  /// Verified 200 with real backend.
  Future<TeacherProfileModel> patchTeacherProfile({
    required String name,
    String? phone,
  }) async {
    try {
      final payload = <String, dynamic>{'name': name};
      if (phone != null && phone.isNotEmpty) payload['phone'] = phone;
      final data = await _client.patch('/teacher/profile/', data: payload)
          as Map<String, dynamic>;
      return TeacherProfileModel.fromJson(data);
    } catch (e, st) {
      debugPrint('patchTeacherProfile error: $e\n$st');
      rethrow;
    }
  }

  /// POST /teacher/auth/change-password/
  /// Returns 404 currently — caller handles graceful fallback.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _client.post('/teacher/auth/change-password/', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
    } catch (e, st) {
      debugPrint('changePassword error: $e\n$st');
      rethrow;
    }
  }

  // ───── Notifications ─────────────────────────────────────────────────────

  /// GET /teacher/notifications/ → {results: [], unread: 0}
  Future<List<AppNotification>> getNotifications() async {
    try {
      final data = await _client.get('/teacher/notifications/');
      List<dynamic> list;
      if (data is Map<String, dynamic>) {
        list = data['results'] as List? ?? [];
      } else if (data is List) {
        list = data;
      } else {
        list = [];
      }
      return list
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      debugPrint('getNotifications error: $e\n$st');
      rethrow;
    }
  }

  /// POST /teacher/notifications/:id/mark-read/
  Future<void> markNotificationAsRead(String id) async {
    try {
      await _client.post('/teacher/notifications/$id/mark-read/', data: {});
    } catch (e, st) {
      debugPrint('markNotificationAsRead error: $e\n$st');
      rethrow;
    }
  }

  /// POST /teacher/notifications/mark-all-read/
  Future<void> markAllNotificationsAsRead() async {
    try {
      await _client.post('/teacher/notifications/mark-all-read/', data: {});
    } catch (e, st) {
      debugPrint('markAllNotificationsAsRead error: $e\n$st');
      rethrow;
    }
  }

  // ───── FCM ───────────────────────────────────────────────────────────────

  Future<void> registerFCMToken(String token) async {
    try {
      await _client.post('/notifications/fcm/register/', data: {
        'token': token,
        'platform': 'android',
        'device_id': token.length > 16 ? token.substring(0, 16) : token,
      });
    } catch (e, st) {
      debugPrint('registerFCMToken error: $e\n$st');
      // We don't rethrow as FCM is non-critical
    }
  }

  Future<void> unregisterFCMToken(String token) async {
    try {
      await _client.post('/notifications/fcm/unregister/', data: {
        'token': token,
      });
    } catch (e, st) {
      debugPrint('unregisterFCMToken error: $e\n$st');
    }
  }
}
