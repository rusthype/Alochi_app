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
