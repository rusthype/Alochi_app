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
  final String initials;
  final String color;
  final String status; // "pending" | "submitted" | "late"
  final String submittedAt;
  final String? fileUrl;

  const HomeworkSubmission({
    required this.studentId,
    required this.studentName,
    required this.initials,
    required this.color,
    required this.status,
    required this.submittedAt,
    this.fileUrl,
  });

  bool get hasSubmitted => status == 'submitted' || status == 'late';
  bool get isOnTime => status == 'submitted';
  bool get isPending => status == 'pending';

  factory HomeworkSubmission.fromJson(Map<String, dynamic> json) {
    final st = json['submitted_at']?.toString() ?? '';
    final status = json['status']?.toString() ?? 'pending';
    return HomeworkSubmission(
      studentId: json['student_id']?.toString() ?? '',
      // Backend returns 'name', older version might return 'student_name'
      studentName:
          json['name']?.toString() ?? json['student_name']?.toString() ?? '',
      initials: json['initials']?.toString() ?? '',
      color: json['color']?.toString() ?? '#1F6F65',
      status: status,
      submittedAt: st,
      fileUrl: json['file_url']?.toString(),
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
  final int totalCount;
  final int submittedCount;

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
    this.totalCount = 0,
    this.submittedCount = 0,
  });

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    // Backend returns 'due_date', older might return 'deadline'
    final dl =
        json['due_date']?.toString() ?? json['deadline']?.toString() ?? '';

    bool active = true;
    if (dl.isNotEmpty) {
      try {
        active = DateTime.parse(dl).isAfter(DateTime.now());
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
      responseCount: (json['response_count'] as num?)?.toInt() ??
          (json['submitted_count'] as num?)?.toInt() ??
          0,
      isActive: active,
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      submittedCount: (json['submitted_count'] as num?)?.toInt() ?? 0,
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
