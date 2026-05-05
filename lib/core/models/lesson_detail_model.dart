class LessonDetailModel {
  final String id;
  final String groupId;
  final String groupCode;
  final String subjectName;
  final String startTime;
  final String endTime;
  final String date;
  final bool isActive;
  final int studentCount;

  const LessonDetailModel({
    required this.id,
    required this.groupId,
    required this.groupCode,
    required this.subjectName,
    required this.startTime,
    required this.endTime,
    required this.date,
    required this.isActive,
    required this.studentCount,
  });

  factory LessonDetailModel.fromJson(Map<String, dynamic> json) {
    return LessonDetailModel(
      id: json['id']?.toString() ?? '',
      groupId:
          json['group_id']?.toString() ?? json['class_id']?.toString() ?? '',
      groupCode: json['group_code']?.toString() ??
          json['class_code']?.toString() ??
          '',
      subjectName: json['subject_name']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      isActive: json['is_active'] == true,
      studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
    );
  }
}
