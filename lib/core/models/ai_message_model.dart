class AiMessageModel {
  final String role; // "user" | "assistant"
  final String content;
  final String timestamp;

  const AiMessageModel({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory AiMessageModel.fromJson(Map<String, dynamic> json) {
    return AiMessageModel(
      role: json['role']?.toString() ?? 'user',
      content: json['content']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  bool get isAssistant => role == 'assistant';
}
