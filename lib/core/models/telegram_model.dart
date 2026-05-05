class TelegramGroupStatusData {
  final String groupId;
  final String groupName;
  final String subject;
  final int linkedCount;
  final int totalParents;

  const TelegramGroupStatusData({
    required this.groupId,
    required this.groupName,
    required this.subject,
    required this.linkedCount,
    required this.totalParents,
  });

  double get linkedPercent =>
      totalParents == 0 ? 0 : linkedCount / totalParents;

  factory TelegramGroupStatusData.fromJson(Map<String, dynamic> json) {
    return TelegramGroupStatusData(
      groupId: json['group_id']?.toString() ?? json['id']?.toString() ?? '',
      groupName:
          json['group_name']?.toString() ?? json['name']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      linkedCount: (json['linked_count'] as num?)?.toInt() ?? 0,
      totalParents: (json['total_parents'] as num?)?.toInt() ?? 0,
    );
  }
}

class UnlinkedParentData {
  final String parentId;
  final String parentName;
  final String studentName;
  final String phone;

  const UnlinkedParentData({
    required this.parentId,
    required this.parentName,
    required this.studentName,
    required this.phone,
  });

  factory UnlinkedParentData.fromJson(Map<String, dynamic> json) {
    return UnlinkedParentData(
      parentId:
          json['parent_id']?.toString() ?? json['id']?.toString() ?? '',
      parentName:
          json['parent_name']?.toString() ?? json['name']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}
