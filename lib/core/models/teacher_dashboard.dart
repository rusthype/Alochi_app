import '../utils/date_utils.dart';

class TeacherDashboardSummary {
  final String greeting;
  final List<LessonModel> todayLessons;
  final List<ConcernModel> concerns;

  const TeacherDashboardSummary({
    required this.greeting,
    required this.todayLessons,
    required this.concerns,
  });

  factory TeacherDashboardSummary.fromJson(Map<String, dynamic> json) {
    return TeacherDashboardSummary(
      greeting: json['greeting'] ?? '',
      todayLessons: (json['today_lessons'] as List? ?? [])
          .map((e) => LessonModel.fromJson(e))
          .toList(),
      concerns: (json['concerns'] as List? ?? [])
          .map((e) => ConcernModel.fromJson(e))
          .toList(),
    );
  }

  /// Compose from:
  ///   GET /teacher/panel/dashboard/ → dashData
  ///   GET /teacher/timetable/       → ttData
  factory TeacherDashboardSummary.fromComposed(
    Map<String, dynamic> dashData,
    Map<String, dynamic> ttData,
  ) {
    final today = todayUzbekDayName();
    final week = (ttData['week'] as List?) ?? [];
    final todayEntry = week.firstWhere(
      (d) => d['day'] == today,
      orElse: () => <String, dynamic>{'lessons': []},
    );
    final rawLessons = (todayEntry['lessons'] as List?) ?? [];
    final todayLessons = rawLessons.map((l) {
      final m = l as Map<String, dynamic>;
      return LessonModel(
        id: m['id']?.toString() ?? '',
        time: m['time']?.toString() ?? '',
        className: m['group_name']?.toString() ??
            m['class_name']?.toString() ??
            '',
        subject: m['subject']?.toString() ?? '',
        studentCount: (m['student_count'] as num?)?.toInt() ?? 0,
        isActive: isLessonNow(m['time']?.toString() ?? ''),
      );
    }).toList();

    final concerns = <ConcernModel>[];
    final homeworkPending =
        (dashData['homework_pending_count'] as num?)?.toInt() ?? 0;
    if (homeworkPending > 0) {
      concerns.add(ConcernModel(
        type: 'homework',
        title: 'Tekshirilmagan vazifalar',
        count: '$homeworkPending',
        route: '/teacher/homework',
      ));
    }
    final unreadMessages =
        (dashData['unread_messages_count'] as num?)?.toInt() ?? 0;
    if (unreadMessages > 0) {
      concerns.add(ConcernModel(
        type: 'messages',
        title: "O'qilmagan xabarlar",
        count: '$unreadMessages',
        route: '/teacher/messages',
      ));
    }

    return TeacherDashboardSummary(
      greeting: 'Salom, Ustoz',
      todayLessons: todayLessons,
      concerns: concerns,
    );
  }
}

class LessonModel {
  final String id;
  final String time;
  final String className;
  final String subject;
  final int studentCount;
  final bool isActive;

  const LessonModel({
    required this.id,
    required this.time,
    required this.className,
    required this.subject,
    required this.studentCount,
    this.isActive = false,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id']?.toString() ?? '',
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
