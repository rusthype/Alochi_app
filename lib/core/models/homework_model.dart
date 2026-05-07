class HomeworkStats {
  final int submitted;
  final int onTime;
  final int pending;
  final int total;

  const HomeworkStats({
    required this.submitted,
    required this.onTime,
    required this.pending,
    this.total = 0,
  });

  factory HomeworkStats.fromJson(Map<String, dynamic> json) {
    return HomeworkStats(
      submitted: (json['submitted'] as num?)?.toInt() ?? 0,
      onTime: (json['on_time'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class HomeworkSubmission {
  final String studentId;
  final String studentName;
  final String submittedAt;
  final bool isOnTime;
  final String? comment;

  const HomeworkSubmission({
    required this.studentId,
    required this.studentName,
    required this.submittedAt,
    required this.isOnTime,
    this.comment,
  });

  factory HomeworkSubmission.fromJson(Map<String, dynamic> json) {
    return HomeworkSubmission(
      studentId: json['student_id']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? '',
      submittedAt: json['submitted_at']?.toString() ?? '',
      isOnTime: json['is_on_time'] == true,
      comment: json['comment']?.toString(),
    );
  }
}

class HomeworkModel {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String groupName;
  final String deadline;
  final int responseCount;
  final bool isActive;
  final HomeworkStats? stats;
  final List<HomeworkSubmission> submissions;

  const HomeworkModel({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.groupName,
    required this.deadline,
    required this.responseCount,
    required this.isActive,
    this.stats,
    this.submissions = const [],
  });

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    // Determine active from deadline
    bool active = true;
    final dl = json['deadline']?.toString() ?? '';
    if (dl.isNotEmpty) {
      try {
        final deadlineDate = DateTime.parse(dl);
        active = deadlineDate.isAfter(DateTime.now());
      } catch (_) {}
    }
    final isActiveParsed = json['is_active'];
    if (isActiveParsed != null) active = isActiveParsed == true;

    final rawStats = json['stats'] as Map<String, dynamic>?;
    final rawSubmissions = json['submissions'] as List? ?? [];

    return HomeworkModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      groupName: json['group_name']?.toString() ??
          json['class_name']?.toString() ??
          '',
      deadline: dl,
      responseCount: (json['response_count'] as num?)?.toInt() ?? 0,
      isActive: active,
      stats: rawStats != null ? HomeworkStats.fromJson(rawStats) : null,
      submissions: rawSubmissions
          .map((e) => HomeworkSubmission.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HomeworkListData {
  final HomeworkStats stats;
  final List<HomeworkModel> assignments;

  const HomeworkListData({required this.stats, required this.assignments});

  factory HomeworkListData.fromJson(Map<String, dynamic> json) {
    final rawStats = json['stats'] as Map<String, dynamic>? ?? {};
    final rawList = json['assignments'] as List? ?? [];
    return HomeworkListData(
      stats: HomeworkStats.fromJson(rawStats),
      assignments: rawList.isEmpty
          ? []
          : rawList
              .map((e) => HomeworkModel.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}
