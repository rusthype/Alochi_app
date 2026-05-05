import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/teacher_api.dart';
import '../../../core/models/student_model.dart';
import '../dashboard/dashboard_provider.dart';

enum ComposeMode { single, group, multiple }

class RecipientRef {
  final String id;
  final String name;
  final String? avatar;
  final String? subtext;

  const RecipientRef({
    required this.id,
    required this.name,
    this.avatar,
    this.subtext,
  });
}

class MessageComposeState {
  final ComposeMode mode;
  final List<RecipientRef> recipients;
  final String subject;
  final String body;
  final bool isSending;
  final String? error;
  final bool sentSuccessfully;

  const MessageComposeState({
    this.mode = ComposeMode.single,
    this.recipients = const [],
    this.subject = '',
    this.body = '',
    this.isSending = false,
    this.error,
    this.sentSuccessfully = false,
  });

  MessageComposeState copyWith({
    ComposeMode? mode,
    List<RecipientRef>? recipients,
    String? subject,
    String? body,
    bool? isSending,
    String? error,
    bool? sentSuccessfully,
  }) {
    return MessageComposeState(
      mode: mode ?? this.mode,
      recipients: recipients ?? this.recipients,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      isSending: isSending ?? this.isSending,
      error: error,
      sentSuccessfully: sentSuccessfully ?? this.sentSuccessfully,
    );
  }
}

class MessageComposeNotifier extends StateNotifier<MessageComposeState> {
  final TeacherApi _api;

  MessageComposeNotifier(this._api) : super(const MessageComposeState());

  void setMode(ComposeMode mode) => state = state.copyWith(mode: mode);

  void addRecipient(RecipientRef ref) {
    if (state.recipients.any((r) => r.id == ref.id)) return;
    state = state.copyWith(recipients: [...state.recipients, ref]);
  }

  void removeRecipient(String id) {
    state = state.copyWith(
      recipients: state.recipients.where((r) => r.id != id).toList(),
    );
  }

  void setSubject(String val) => state = state.copyWith(subject: val);
  void setBody(String val) => state = state.copyWith(body: val);

  Future<void> send() async {
    if (state.recipients.isEmpty || state.body.trim().isEmpty) return;
    state = state.copyWith(isSending: true, error: null);

    try {
      final recipient = state.recipients.first;
      await _api.sendNewMessage(recipientId: recipient.id, body: state.body);
      state = state.copyWith(isSending: false, sentSuccessfully: true);
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }
}

final messageComposeProvider =
    StateNotifierProvider.autoDispose<MessageComposeNotifier, MessageComposeState>(
  (ref) => MessageComposeNotifier(ref.read(teacherApiProvider)),
);
