class LessonModel {
  final String id;
  final String? groupId;
  final String groupName;
  final String subject;
  final String startTime;
  final String endTime;
  final String room;
  final bool isNow;
  final int studentsCount;

  const LessonModel({
    required this.id,
    this.groupId,
    required this.groupName,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.isNow,
    required this.studentsCount,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) => LessonModel(
        id: json['id']?.toString() ?? '',
        groupId: json['group_id']?.toString() ?? json['class_id']?.toString(),
        groupName: json['group_name']?.toString() ?? '',
        subject: json['subject']?.toString() ?? '',
        startTime: json['start_time']?.toString() ?? '',
        endTime: json['end_time']?.toString() ?? '',
        room: json['room']?.toString() ?? '',
        isNow: json['is_now'] == true,
        studentsCount: (json['students_count'] as num?)?.toInt() ?? 0,
      );

  bool get isFinished {
    if (endTime.isEmpty) return false;
    try {
      final parts = endTime.split(':');
      if (parts.length < 2) return false;
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final now = DateTime.now();
      final end = DateTime(now.year, now.month, now.day, h, m);
      return now.isAfter(end);
    } catch (_) {
      return false;
    }
  }
}
