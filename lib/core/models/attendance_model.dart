enum AttendanceStatus { present, late, absent, unmarked }

class AttendanceRecordModel {
  final String studentId;
  final AttendanceStatus status;

  const AttendanceRecordModel({
    required this.studentId,
    required this.status,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    final raw = json['status']?.toString() ?? 'unmarked';
    AttendanceStatus status;
    switch (raw) {
      case 'present':
        status = AttendanceStatus.present;
        break;
      case 'late':
        status = AttendanceStatus.late;
        break;
      case 'absent':
        status = AttendanceStatus.absent;
        break;
      default:
        status = AttendanceStatus.unmarked;
    }
    return AttendanceRecordModel(
      studentId: json['student_id']?.toString() ?? '',
      status: status,
    );
  }

  static String statusToString(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.late:
        return 'late';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.unmarked:
        return 'unmarked';
    }
  }
}

class AttendanceHistoryModel {
  final double summaryPercent;
  final double deltaPct;
  final String trend;
  final List<DayAggregateModel> daily;
  final List<LowAttendanceStudentModel> lowAttendanceStudents;

  const AttendanceHistoryModel({
    required this.summaryPercent,
    required this.deltaPct,
    required this.trend,
    required this.daily,
    required this.lowAttendanceStudents,
  });

  factory AttendanceHistoryModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final dailyList = json['daily'] as List? ?? [];
    final lowList = json['low_attendance_students'] as List? ?? [];
    return AttendanceHistoryModel(
      summaryPercent: (summary['percent'] as num?)?.toDouble() ?? 0,
      deltaPct: (summary['delta_pct'] as num?)?.toDouble() ?? 0,
      trend: summary['trend']?.toString() ?? 'flat',
      daily: dailyList.isEmpty
          ? []
          : dailyList.map((e) => DayAggregateModel.fromJson(e as Map<String, dynamic>)).toList(),
      lowAttendanceStudents: lowList.isEmpty
          ? []
          : lowList.map((e) => LowAttendanceStudentModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class DayAggregateModel {
  final String date;
  final int present;
  final int late;
  final int absent;
  final bool isLessonDay;

  const DayAggregateModel({
    required this.date,
    required this.present,
    required this.late,
    required this.absent,
    required this.isLessonDay,
  });

  int get total => present + late + absent;

  factory DayAggregateModel.fromJson(Map<String, dynamic> json) {
    return DayAggregateModel(
      date: json['date']?.toString() ?? '',
      present: (json['present'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      isLessonDay: json['is_lesson_day'] == true,
    );
  }
}

class LowAttendanceStudentModel {
  final String id;
  final String name;
  final double attendancePct;

  const LowAttendanceStudentModel({
    required this.id,
    required this.name,
    required this.attendancePct,
  });

  factory LowAttendanceStudentModel.fromJson(Map<String, dynamic> json) {
    return LowAttendanceStudentModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      attendancePct: (json['attendance_pct'] as num?)?.toDouble() ?? 0,
    );
  }
}
