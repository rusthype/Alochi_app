import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/message_model.dart';
import '../../../core/ws/ws_client.dart';
import '../dashboard/dashboard_provider.dart';

// ─── Conversations list ───────────────────────────────────────────────────────

final conversationsProvider =
    FutureProvider<List<ConversationModel>>((ref) async {
  final api = ref.read(teacherApiProvider);
  return api.getConversations();
});

// ─── Chat thread ──────────────────────────────────────────────────────────────

class ChatThreadState {
  final ConversationDetailModel? detail;
  final List<MessageModel> messages;
  final bool isSending;
  final String? errorMessage;

  const ChatThreadState({
    this.detail,
    this.messages = const [],
    this.isSending = false,
    this.errorMessage,
  });

  ChatThreadState copyWith({
    ConversationDetailModel? detail,
    List<MessageModel>? messages,
    bool? isSending,
    String? errorMessage,
  }) {
    return ChatThreadState(
      detail: detail ?? this.detail,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
    );
  }
}

class ChatThreadNotifier extends StateNotifier<AsyncValue<ChatThreadState>> {
  final String conversationId;
  final Ref _ref;
  StreamSubscription? _wsSub;

  ChatThreadNotifier(this.conversationId, this._ref)
      : super(const AsyncValue.loading()) {
    _load();
    _initWs();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      state = const AsyncValue.loading();
      final api = _ref.read(teacherApiProvider);
      final detail = await api.getConversationDetail(conversationId);
      state = AsyncValue.data(ChatThreadState(
        detail: detail,
        messages: List.from(detail.messages),
      ));
    } catch (e, st) {
      debugPrint('ChatThread load error: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }

  void _initWs() {
    final ws = WsClient.instance;
    // Base URL is https://api.alochi.org, so WS is wss://api.alochi.org/ws/chat/
    ws.connect('wss://api.alochi.org/ws/chat/$conversationId/');
    _wsSub = ws.stream.listen((data) {
      if (data['type'] == 'chat_message') {
        final rawMsg = data['message'];
        if (rawMsg != null) {
          final msg = MessageModel.fromJson(rawMsg as Map<String, dynamic>);
          _onNewWsMessage(msg);
        }
      }
    });
  }

  void _onNewWsMessage(MessageModel msg) {
    final current = state.valueOrNull;
    if (current == null) return;
    
    // Avoid duplicates if we already added it optimistically
    if (current.messages.any((m) => m.id == msg.id)) return;

    state = AsyncValue.data(current.copyWith(
      messages: [...current.messages, msg],
    ));
    _ref.invalidate(conversationsProvider);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistic local bubble
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = MessageModel(
      id: tempId,
      text: text.trim(),
      isFromTeacher: true,
      timestamp: DateTime.now().toIso8601String(),
      isRead: false,
    );
    state = AsyncValue.data(current.copyWith(
      messages: [...current.messages, tempMsg],
      isSending: true,
    ));

    try {
      final api = _ref.read(teacherApiProvider);
      final sent = await api.sendMessage(conversationId, text.trim());
      final updated = state.valueOrNull;
      if (updated == null) return;
      final newMessages = updated.messages.map((m) {
        if (m.id == tempId) return sent;
        return m;
      }).toList();
      state = AsyncValue.data(updated.copyWith(
        messages: newMessages,
        isSending: false,
      ));
      // Invalidate conversations list so unread count refreshes
      _ref.invalidate(conversationsProvider);
    } catch (e, st) {
      debugPrint('sendMessage error: $e\n$st');
      final failed = state.valueOrNull;
      if (failed == null) return;
      // Remove the optimistic message on failure
      final reverted = failed.messages.where((m) => m.id != tempId).toList();
      state = AsyncValue.data(failed.copyWith(
        messages: reverted,
        isSending: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> refresh() => _load();
}

final chatThreadProvider = StateNotifierProvider.autoDispose
    .family<ChatThreadNotifier, AsyncValue<ChatThreadState>, String>(
  (ref, conversationId) => ChatThreadNotifier(conversationId, ref),
);
