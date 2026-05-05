import '../utils/date_utils.dart';

class TeacherDashboardSummary {
  final String greeting;
  final List<DashboardLessonModel> todayLessons;
  final List<ConcernModel> concerns;
  final int groupsCount;
  final int studentsCount;
  final int activeHomeworkCount;

  const TeacherDashboardSummary({
    required this.greeting,
    required this.todayLessons,
    required this.concerns,
    this.groupsCount = 0,
    this.studentsCount = 0,
    this.activeHomeworkCount = 0,
  });

  factory TeacherDashboardSummary.fromJson(Map<String, dynamic> json) {
    return TeacherDashboardSummary(
      greeting: json['greeting'] ?? '',
      todayLessons: (json['today_lessons'] as List? ?? [])
          .map((e) => DashboardLessonModel.fromJson(e))
          .toList(),
      concerns: (json['concerns'] as List? ?? [])
          .map((e) => ConcernModel.fromJson(e))
          .toList(),
      groupsCount: json['groups_count'] ?? 0,
      studentsCount: json['students_count'] ?? 0,
      activeHomeworkCount: json['active_homework_count'] ?? 0,
    );
  }

  /// Compose from:
  ///   GET /teacher/panel/dashboard/ → dashData
  ///   GET /teacher/timetable/       → ttData
  ///   GET /teacher/panel/groups/    → groupsData
  factory TeacherDashboardSummary.fromComposed(
    Map<String, dynamic> dashData,
    Map<String, dynamic> ttData,
    List<dynamic> groupsData,
  ) {
    // 1. Prioritize today_lessons from dashData, fallback to ttData (timetable)
    List<DashboardLessonModel> todayLessons = [];
    final dashLessons = dashData['today_lessons'] as List?;

    if (dashLessons != null && dashLessons.isNotEmpty) {
      todayLessons = dashLessons.map((l) {
        final m = l as Map<String, dynamic>;
        return DashboardLessonModel(
          id: m['id']?.toString() ?? '',
          groupId:
              m['group_id']?.toString() ?? m['class_id']?.toString() ?? '',
          time: m['time']?.toString() ?? '',
          className:
              m['group_name']?.toString() ?? m['class_name']?.toString() ?? '',
          subject: m['subject']?.toString() ?? '',
          studentCount: (m['student_count'] as num?)?.toInt() ?? 0,
          isActive: isLessonNow(m['time']?.toString() ?? ''),
        );
      }).toList();
    } else {
      final today = todayUzbekDayName();
      final week = (ttData['week'] as List?) ?? [];
      final todayEntry = week.firstWhere(
        (d) => d['day'] == today,
        orElse: () => <String, dynamic>{'lessons': []},
      );
      final rawLessons = (todayEntry['lessons'] as List?) ?? [];
      todayLessons = rawLessons.map((l) {
        final m = l as Map<String, dynamic>;
        return DashboardLessonModel(
          id: m['id']?.toString() ?? '',
          groupId:
              m['group_id']?.toString() ?? m['class_id']?.toString() ?? '',
          time: m['time']?.toString() ?? '',
          className:
              m['group_name']?.toString() ?? m['class_name']?.toString() ?? '',
          subject: m['subject']?.toString() ?? '',
          studentCount: (m['student_count'] as num?)?.toInt() ?? 0,
          isActive: isLessonNow(m['time']?.toString() ?? ''),
        );
      }).toList();
    }

    final concerns = <ConcernModel>[];

    // 2. Handle pending homework (can be count or list)
    int homeworkCount = 0;
    if (dashData['homework_pending_count'] != null) {
      homeworkCount = (dashData['homework_pending_count'] as num).toInt();
    } else if (dashData['pending_homework'] is List) {
      homeworkCount = (dashData['pending_homework'] as List).length;
    }

    if (homeworkCount > 0) {
      concerns.add(ConcernModel(
        type: 'homework',
        title: 'Tekshirilmagan vazifalar',
        count: '$homeworkCount',
        route: '/teacher/homework',
      ));
    }

    // 3. Handle unread messages
    int messagesCount = 0;
    if (dashData['unread_messages_count'] != null) {
      messagesCount = (dashData['unread_messages_count'] as num).toInt();
    } else if (dashData['unread_messages'] is List) {
      messagesCount = (dashData['unread_messages'] as List).length;
    }

    if (messagesCount > 0) {
      concerns.add(ConcernModel(
        type: 'messages',
        title: "O'qilmagan xabarlar",
        count: '$messagesCount',
        route: '/teacher/messages',
      ));
    }

    // 4. Calculate stats from groupsData
    final groupsCount = groupsData.length;
    int studentsCount = 0;
    for (final g in groupsData) {
      final m = g as Map<String, dynamic>;
      studentsCount += (m['student_count'] as num?)?.toInt() ??
          (m['students_count'] as num?)?.toInt() ??
          0;
    }

    return TeacherDashboardSummary(
      greeting: 'Salom, Ustoz',
      todayLessons: todayLessons,
      concerns: concerns,
      groupsCount: groupsCount,
      studentsCount: studentsCount,
      activeHomeworkCount: homeworkCount,
    );
  }

  factory TeacherDashboardSummary.empty() {
    return const TeacherDashboardSummary(
      greeting: 'Salom, Ustoz',
      todayLessons: [],
      concerns: [],
      groupsCount: 0,
      studentsCount: 0,
      activeHomeworkCount: 0,
    );
  }
}

class DashboardLessonModel {
  final String id;
  final String? groupId;
  final String time;
  final String className;
  final String subject;
  final int studentCount;
  final bool isActive;

  const DashboardLessonModel({
    required this.id,
    this.groupId,
    required this.time,
    required this.className,
    required this.subject,
    required this.studentCount,
    this.isActive = false,
  });

  factory DashboardLessonModel.fromJson(Map<String, dynamic> json) {
    return DashboardLessonModel(
      id: json['id']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? json['class_id']?.toString(),
      time: json['time'] ?? '',
      className: json['class_name'] ?? '',
      subject: json['subject'] ?? '',
      studentCount: json['student_count'] ?? 0,
      isActive: json['is_active'] ?? false,
    );
  }
}

class ConcernModel {
  final String type;
  final String title;
  final String count;
  final String route;

  const ConcernModel({
    required this.type,
    required this.title,
    required this.count,
    required this.route,
  });

  factory ConcernModel.fromJson(Map<String, dynamic> json) {
    return ConcernModel(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      count: json['count']?.toString() ?? '0',
      route: json['route'] ?? '',
    );
  }
}
