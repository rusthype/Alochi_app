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
