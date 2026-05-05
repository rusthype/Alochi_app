class ConversationModel {
  final String id;
  final String participantName;
  final String? participantRole; // 'father' | 'mother' | 'group'
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final bool isFromMe;
  final String? classCode;
  final String? studentId;

  const ConversationModel({
    required this.id,
    required this.participantName,
    this.participantRole,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isFromMe,
    this.classCode,
    this.studentId,
  });

  bool get isGroup => participantRole == 'group';

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id']?.toString() ?? '',
      participantName: json['participant_name']?.toString() ??
          json['name']?.toString() ??
          '',
      participantRole:
          json['participant_role']?.toString() ?? json['role']?.toString(),
      lastMessage: json['last_message']?.toString() ?? '',
      lastMessageTime: json['last_message_time']?.toString() ??
          json['time']?.toString() ??
          '',
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      isFromMe: json['is_from_me'] == true,
      classCode: json['class_code']?.toString(),
      studentId: json['student_id']?.toString(),
    );
  }
}

class MessageModel {
  final String id;
  final String text;
  final bool isFromTeacher;
  final String timestamp;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.text,
    required this.isFromTeacher,
    required this.timestamp,
    required this.isRead,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? json['body']?.toString() ?? '',
      isFromTeacher: json['is_from_teacher'] == true ||
          json['sender_role']?.toString() == 'teacher',
      timestamp:
          json['timestamp']?.toString() ?? json['created_at']?.toString() ?? '',
      isRead: json['is_read'] == true,
    );
  }
}

class ConversationDetailModel {
  final ConversationModel conversation;
  final List<MessageModel> messages;

  const ConversationDetailModel({
    required this.conversation,
    required this.messages,
  });
}
