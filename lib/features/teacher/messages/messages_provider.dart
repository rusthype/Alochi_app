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
  final bool wsConnected;

  const ChatThreadState({
    this.detail,
    this.messages = const [],
    this.isSending = false,
    this.errorMessage,
    this.wsConnected = false,
  });

  ChatThreadState copyWith({
    ConversationDetailModel? detail,
    List<MessageModel>? messages,
    bool? isSending,
    String? errorMessage,
    bool? wsConnected,
  }) {
    return ChatThreadState(
      detail: detail ?? this.detail,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
      wsConnected: wsConnected ?? this.wsConnected,
    );
  }
}

class ChatThreadNotifier extends StateNotifier<AsyncValue<ChatThreadState>> {
  final String conversationId;
  final Ref _ref;
  StreamSubscription? _wsSub;
  StreamSubscription? _wsStatusSub;
  Timer? _pollTimer;

  ChatThreadNotifier(this.conversationId, this._ref)
      : super(const AsyncValue.loading()) {
    _load();
    _initWs();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _wsStatusSub?.cancel();
    _pollTimer?.cancel();
    WsClient.instance.disconnect();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      if (state is! AsyncData) state = const AsyncValue.loading();
      final api = _ref.read(teacherApiProvider);
      final detail = await api.getConversationDetail(conversationId);
      state = AsyncValue.data(ChatThreadState(
        detail: detail,
        messages: List.from(detail.messages),
        wsConnected: WsClient.instance.isConnected,
      ));
    } catch (e, st) {
      debugPrint('ChatThread load error: $e\n$st');
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  void _initWs() {
    final ws = WsClient.instance;

    // Try WebSocket
    ws.connect('wss://api.alochi.org/ws/chat/$conversationId/');

    // Monitor WS status
    _wsStatusSub = ws.statusStream.listen((status) {
      final cur = state.valueOrNull;
      if (cur != null) {
        state = AsyncValue.data(cur.copyWith(
          wsConnected: status == WsStatus.connected,
        ));
      }
      // If WS unavailable, fall back to HTTP polling every 15s
      if (status == WsStatus.unavailable) {
        debugPrint('WS unavailable — starting HTTP polling fallback');
        _startPolling();
      }
    });

    // Handle incoming WS messages
    _wsSub = ws.stream.listen((data) {
      if (data['type'] == 'chat_message') {
        final rawMsg = data['message'];
        if (rawMsg != null) {
          final msg = MessageModel.fromJson(rawMsg as Map<String, dynamic>);
          _onNewMessage(msg);
        }
      }
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!mounted) return;
      try {
        final api = _ref.read(teacherApiProvider);
        final detail = await api.getConversationDetail(conversationId);
        final cur = state.valueOrNull;
        if (cur == null || !mounted) return;

        // Only add new messages
        final existingIds = cur.messages.map((m) => m.id).toSet();
        final newMsgs =
            detail.messages.where((m) => !existingIds.contains(m.id)).toList();

        if (newMsgs.isNotEmpty) {
          state = AsyncValue.data(cur.copyWith(
            messages: [...cur.messages, ...newMsgs],
          ));
          _ref.invalidate(conversationsProvider);
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }
    });
  }

  void _onNewMessage(MessageModel msg) {
    final current = state.valueOrNull;
    if (current == null) return;
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
      final newMessages =
          updated.messages.map((m) => m.id == tempId ? sent : m).toList();
      state = AsyncValue.data(updated.copyWith(
        messages: newMessages,
        isSending: false,
      ));
      _ref.invalidate(conversationsProvider);
    } catch (e, st) {
      debugPrint('sendMessage error: $e\n$st');
      final failed = state.valueOrNull;
      if (failed == null) return;
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
