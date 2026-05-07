import 'attendance_model.dart';
export 'attendance_model.dart';

class GroupAnalyticsModel {
  final List<ChartPointModel> attendanceTrend;
  final List<ChartPointModel> gradeTrend;
  final List<TopStudentModel> topStudents;
  final List<LowAttendanceStudentModel> lowAttendanceStudents;

  const GroupAnalyticsModel({
    required this.attendanceTrend,
    required this.gradeTrend,
    required this.topStudents,
    required this.lowAttendanceStudents,
  });

  factory GroupAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final attTrend = json['attendance_trend'] as List? ?? [];
    final grdTrend = json['grade_trend'] as List? ?? [];
    final topStud = json['top_students'] as List? ?? [];
    final lowAtt = json['low_attendance_students'] as List? ?? [];

    return GroupAnalyticsModel(
      attendanceTrend: attTrend.map((e) => ChartPointModel.fromJson(e as Map<String, dynamic>)).toList(),
      gradeTrend: grdTrend.map((e) => ChartPointModel.fromJson(e as Map<String, dynamic>)).toList(),
      topStudents: topStud.map((e) => TopStudentModel.fromJson(e as Map<String, dynamic>)).toList(),
      lowAttendanceStudents: lowAtt.map((e) => LowAttendanceStudentModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class ChartPointModel {
  final String label;
  final double value;

  const ChartPointModel({required this.label, required this.value});

  factory ChartPointModel.fromJson(Map<String, dynamic> json) {
    return ChartPointModel(
      label: json['label']?.toString() ?? json['date']?.toString() ?? '',
      value: (json['value'] ?? 0).toDouble(),
    );
  }
}

class TopStudentModel {
  final String id;
  final String name;
  final int xp;
  final int level;

  const TopStudentModel({
    required this.id,
    required this.name,
    required this.xp,
    required this.level,
  });

  factory TopStudentModel.fromJson(Map<String, dynamic> json) {
    return TopStudentModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
    );
  }
}
