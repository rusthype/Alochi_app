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
          groupId: m['group_id']?.toString() ?? m['class_id']?.toString() ?? '',
          time: m['time']?.toString() ?? '',
          className:
              m['group_name']?.toString() ?? m['class_name']?.toString() ?? '',
          subject: m['subject']?.toString() ?? '',
          topic: m['topic']?.toString() ?? '',
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
          groupId: m['group_id']?.toString() ?? m['class_id']?.toString() ?? '',
          time: m['time']?.toString() ?? '',
          className:
              m['group_name']?.toString() ?? m['class_name']?.toString() ?? '',
          subject: m['subject']?.toString() ?? '',
          topic: m['topic']?.toString() ?? '',
          studentCount: (m['student_count'] as num?)?.toInt() ?? 0,
          isActive: isLessonNow(m['time']?.toString() ?? ''),
        );
      }).toList();
    }

    final concerns = <ConcernModel>[];

    // 2. Concerns from available backend fields
    // avg_score low → alert
    final avgScore = (dashData['avg_score'] as num?)?.toDouble() ?? 0;
    if (avgScore > 0 && avgScore < 60) {
      concerns.add(const ConcernModel(
        type: 'avg_score',
        title: "O'rtacha ball past",
        count: '',
        route: '/teacher/groups',
      ));
    }

    // attendance_today rate low → alert
    final attToday = dashData['attendance_today'] as Map<String, dynamic>?;
    if (attToday != null) {
      final absent = (attToday['absent'] as num?)?.toInt() ?? 0;
      if (absent > 0) {
        concerns.add(ConcernModel(
          type: 'attendance',
          title: "Bugun $absent o'quvchi yo'q",
          count: '$absent',
          route: '/teacher/groups',
        ));
      }
    }

    // pending_homework from backend (if exists)
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

    // unread messages
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
  final String topic;
  final int studentCount;
  final bool isActive;

  const DashboardLessonModel({
    required this.id,
    this.groupId,
    required this.time,
    required this.className,
    required this.subject,
    this.topic = '',
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
      topic: json['topic'] ?? '',
      studentCount: json['student_count'] ?? 0,
      isActive: json['is_active'] ?? false,
    );
  }

  String get timeStatus {
    if (isActive) return 'Hozir davom etmoqda';
    try {
      final startTimeStr = time.split('-').first.trim();
      final parts = startTimeStr.split(':');
      if (parts.length < 2) return '';
      final h = int.parse(parts[0].trim());
      final m = int.parse(parts[1].trim());

      final now = DateTime.now();
      final lessonStart = DateTime(now.year, now.month, now.day, h, m);

      if (now.isAfter(lessonStart)) return 'Tugagan';

      final diff = lessonStart.difference(now);
      if (diff.inHours > 0) {
        return '${diff.inHours} soat keyin';
      } else {
        return '${diff.inMinutes} daqiqa keyin';
      }
    } catch (_) {
      return '';
    }
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
