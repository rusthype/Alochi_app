class GradeStudentRow {
  final String id;
  final String name;
  final Map<String, int> gradesByDate;
  final double average;

  const GradeStudentRow({
    required this.id,
    required this.name,
    required this.gradesByDate,
    required this.average,
  });

  factory GradeStudentRow.fromJson(Map<String, dynamic> json) {
    final rawGrades = json['grades_by_date'] as Map<String, dynamic>? ?? {};
    final gradesByDate = <String, int>{};
    rawGrades.forEach((date, grade) {
      gradesByDate[date.toString()] = (grade as num?)?.toInt() ?? 0;
    });

    return GradeStudentRow(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      gradesByDate: gradesByDate,
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GradesJournalData {
  final List<GradeStudentRow> students;
  final String groupId;
  final String? groupName;
  final String? subject;

  const GradesJournalData({
    required this.students,
    required this.groupId,
    this.groupName,
    this.subject,
  });

  factory GradesJournalData.fromJson(
      Map<String, dynamic> json, String groupId) {
    final rawStudents = json['students'] as List? ?? [];
    final students = rawStudents
        .map((e) => GradeStudentRow.fromJson(e as Map<String, dynamic>))
        .toList();

    final group = json['group'] as Map<String, dynamic>?;

    return GradesJournalData(
      students: students,
      groupId: groupId,
      groupName: group?['name']?.toString(),
      subject: group?['subject']?.toString(),
    );
  }

  static GradesJournalData empty(String groupId) => GradesJournalData(
        students: [],
        groupId: groupId,
      );
}
