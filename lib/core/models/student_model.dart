class StudentModel {
  final String id;
  final String firstName;
  final String lastName;
  final String classId;
  final double? attendancePct;
  final int? totalLessons;
  final int? missedLessons;
  final double? avgGrade;
  final int? lastGrade;
  final String? avatarUrl;
  final List<ParentModel> parents;
  final List<AttendanceDayModel> recentAttendance;
  final List<RecentGradeModel> recentGrades;

  const StudentModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.classId,
    this.attendancePct,
    this.totalLessons,
    this.missedLessons,
    this.avgGrade,
    this.lastGrade,
    this.avatarUrl,
    this.parents = const [],
    this.recentAttendance = const [],
    this.recentGrades = const [],
  });

  String get fullName => '$firstName $lastName';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  bool get needsAttention =>
      (attendancePct ?? 100) < 75 || (avgGrade ?? 5) < 3.5;

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    final parentsList = json['parents'] as List? ?? [];
    final attList = json['recent_attendance'] as List? ?? [];
    final gradesList = json['recent_grades'] as List? ?? [];
    return StudentModel(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      classId: json['class_id']?.toString() ?? '',
      attendancePct: (json['attendance_pct'] as num?)?.toDouble(),
      totalLessons: (json['total_lessons'] as num?)?.toInt(),
      missedLessons: (json['missed_lessons'] as num?)?.toInt(),
      avgGrade: (json['avg_grade'] as num?)?.toDouble(),
      lastGrade: (json['last_grade'] as num?)?.toInt(),
      avatarUrl: json['avatar_url']?.toString(),
      parents: parentsList.isEmpty
          ? []
          : parentsList
              .map((e) => ParentModel.fromJson(e as Map<String, dynamic>))
              .toList(),
      recentAttendance: attList.isEmpty
          ? []
          : attList
              .map(
                  (e) => AttendanceDayModel.fromJson(e as Map<String, dynamic>))
              .toList(),
      recentGrades: gradesList.isEmpty
          ? []
          : gradesList
              .map((e) => RecentGradeModel.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

class ParentModel {
  final String id;
  final String name;
  final String relation;
  final String? phone;
  final bool telegramLinked;

  const ParentModel({
    required this.id,
    required this.name,
    required this.relation,
    this.phone,
    required this.telegramLinked,
  });

  factory ParentModel.fromJson(Map<String, dynamic> json) {
    return ParentModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      relation: json['relation']?.toString() ?? '',
      phone: json['phone']?.toString(),
      telegramLinked: json['telegram_linked'] == true,
    );
  }
}

class AttendanceDayModel {
  final String date;
  final String status; // present | late | absent | no_lesson

  const AttendanceDayModel({required this.date, required this.status});

  factory AttendanceDayModel.fromJson(Map<String, dynamic> json) {
    return AttendanceDayModel(
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'no_lesson',
    );
  }
}

class RecentGradeModel {
  final String id;
  final int value;
  final String topicTitle;
  final String date;

  const RecentGradeModel({
    required this.id,
    required this.value,
    required this.topicTitle,
    required this.date,
  });

  factory RecentGradeModel.fromJson(Map<String, dynamic> json) {
    return RecentGradeModel(
      id: json['id']?.toString() ?? '',
      value: (json['value'] as num?)?.toInt() ?? 0,
      topicTitle: json['topic_title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
    );
  }
}
