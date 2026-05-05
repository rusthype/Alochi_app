import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/teacher_dashboard.dart';
import '../models/group_model.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/lesson_detail_model.dart';
import '../models/message_model.dart';

class TeacherApi {
  final _client = ApiClient.instance;

  // ───── Dashboard ─────────────────────────────────────────────────────────

  /// Composes dashboard summary from real endpoints:
  ///   GET /teacher/panel/dashboard/  → attendance_today, top_students, etc.
  ///   GET /teacher/timetable/        → week.lessons filtered by today's weekday
  Future<TeacherDashboardSummary> getDashboardSummary() async {
    try {
      final results = await Future.wait([
        _client.get('/teacher/panel/dashboard/'),
        _client.get('/teacher/timetable/'),
      ]);
      final dashData = results[0] as Map<String, dynamic>;
      final ttData = results[1] as Map<String, dynamic>;
      return TeacherDashboardSummary.fromComposed(dashData, ttData);
    } catch (e, st) {
      debugPrint('getDashboardSummary error: $e\n$st');
      rethrow;
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

  Future<StudentModel> getStudentProfile(String studentId) async {
    try {
      final data = await _client.get('/teacher/students/$studentId/')
          as Map<String, dynamic>;
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

  // ───── Grades ────────────────────────────────────────────────────────────

  /// GET /teacher/grades/?group_id=X
  /// Returns {students: [], dates: [], journal: {studentId: {date: grade}}}
  Future<GradesJournalData> getGrades({required String groupId}) async {
    try {
      final data = await _client.get(
        '/teacher/grades/',
        params: {'group_id': groupId},
      ) as Map<String, dynamic>;
      return GradesJournalData.fromJson(data, groupId);
    } catch (e, st) {
      debugPrint('getGrades error: $e\n$st');
      rethrow;
    }
  }

  /// POST /teacher/grades/set/
  /// Payload: {student_id, subject, grade (2-5), date}
  Future<void> setGrade({
    required String studentId,
    required String subject,
    required int grade,
    required String date,
  }) async {
    try {
      await _client.post('/teacher/grades/set/', data: {
        'student_id': studentId,
        'subject': subject,
        'grade': grade,
        'date': date,
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
}

// ────────────────────────────────────────────────────────────────────────────
// Grades models
// ────────────────────────────────────────────────────────────────────────────

class GradesJournalData {
  final List<GradeStudentRow> students;
  final List<String> dates;
  final Map<String, Map<String, int>> journal; // studentId → {date → grade}
  final String groupId;

  const GradesJournalData({
    required this.students,
    required this.dates,
    required this.journal,
    required this.groupId,
  });

  factory GradesJournalData.fromJson(
      Map<String, dynamic> json, String groupId) {
    final rawStudents = json['students'] as List? ?? [];
    final rawDates = json['dates'] as List? ?? [];
    final rawJournal = json['journal'] as Map<String, dynamic>? ?? {};

    final students = rawStudents.isEmpty
        ? <GradeStudentRow>[]
        : rawStudents
            .map((e) => GradeStudentRow.fromJson(e as Map<String, dynamic>))
            .toList();
    final dates = rawDates.map((d) => d.toString()).toList();

    final journal = <String, Map<String, int>>{};
    rawJournal.forEach((studentId, dateMap) {
      if (dateMap is Map) {
        final inner = <String, int>{};
        dateMap.forEach((date, grade) {
          inner[date.toString()] = (grade as num?)?.toInt() ?? 0;
        });
        journal[studentId] = inner;
      }
    });

    return GradesJournalData(
      students: students,
      dates: dates,
      journal: journal,
      groupId: groupId,
    );
  }

  GradesJournalData empty() => GradesJournalData(
        students: [],
        dates: [],
        journal: {},
        groupId: groupId,
      );
}

class GradeStudentRow {
  final String id;
  final String name;

  const GradeStudentRow({required this.id, required this.name});

  factory GradeStudentRow.fromJson(Map<String, dynamic> json) {
    return GradeStudentRow(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Homework models
// ────────────────────────────────────────────────────────────────────────────

class HomeworkListData {
  final HomeworkStats stats;
  final List<HomeworkModel> assignments;

  const HomeworkListData({required this.stats, required this.assignments});

  factory HomeworkListData.fromJson(Map<String, dynamic> json) {
    final rawStats = json['stats'] as Map<String, dynamic>? ?? {};
    final rawList = json['assignments'] as List? ?? [];
    return HomeworkListData(
      stats: HomeworkStats.fromJson(rawStats),
      assignments: rawList.isEmpty
          ? []
          : rawList
              .map((e) => HomeworkModel.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

class HomeworkStats {
  final int submitted;
  final int onTime;
  final int pending;

  const HomeworkStats(
      {required this.submitted, required this.onTime, required this.pending});

  factory HomeworkStats.fromJson(Map<String, dynamic> json) {
    return HomeworkStats(
      submitted: (json['submitted'] as num?)?.toInt() ?? 0,
      onTime: (json['on_time'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
    );
  }
}

class HomeworkModel {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String groupName;
  final String deadline;
  final int responseCount;
  final bool isActive;

  const HomeworkModel({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.groupName,
    required this.deadline,
    required this.responseCount,
    required this.isActive,
  });

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    // Determine active from deadline
    bool active = true;
    final dl = json['deadline']?.toString() ?? '';
    if (dl.isNotEmpty) {
      try {
        final deadlineDate = DateTime.parse(dl);
        active = deadlineDate.isAfter(DateTime.now());
      } catch (_) {}
    }
    final isActiveParsed = json['is_active'];
    if (isActiveParsed != null) active = isActiveParsed == true;

    return HomeworkModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      groupName: json['group_name']?.toString() ??
          json['class_name']?.toString() ??
          '',
      deadline: dl,
      responseCount: (json['response_count'] as num?)?.toInt() ?? 0,
      isActive: active,
    );
  }
}
