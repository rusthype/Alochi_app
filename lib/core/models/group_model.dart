class GroupModel {
  final String id;
  final String code;
  final String subjectName;
  final int studentsCount;
  final String? nextLessonAt;
  final double attendancePct;
  final double avgGrade;

  const GroupModel({
    required this.id,
    required this.code,
    required this.subjectName,
    required this.studentsCount,
    this.nextLessonAt,
    required this.attendancePct,
    required this.avgGrade,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id']?.toString() ?? '',
      // API returns 'name'; fall back to 'code' for older shapes
      code: json['name']?.toString() ?? json['code']?.toString() ?? '',
      // API returns 'subject'; fall back to 'subject_name' for older shapes
      subjectName:
          json['subject']?.toString() ?? json['subject_name']?.toString() ?? '',
      // API returns 'student_count'; fall back to 'students_count'
      studentsCount: (json['student_count'] as num?)?.toInt() ??
          (json['students_count'] as num?)?.toInt() ??
          0,
      nextLessonAt: json['next_lesson_at']?.toString(),
      attendancePct: (json['attendance_pct'] as num?)?.toDouble() ?? 0,
      avgGrade: (json['avg_grade'] as num?)?.toDouble() ?? 0,
    );
  }
}
