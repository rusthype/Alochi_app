import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/teacher_api.dart';
import '../dashboard/dashboard_provider.dart';

// ─── AI chat message (local model) ──────────────────────────────────────────

class AiChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final DateTime timestamp;

  const AiChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.timestamp,
  });
}

// ─── AI chat state ───────────────────────────────────────────────────────────

class AiChatState {
  final List<AiChatMessage> messages;
  final bool isSending;
  final bool isLoadingHistory;
  final String? errorMessage;

  const AiChatState({
    this.messages = const [],
    this.isSending = false,
    this.isLoadingHistory = false,
    this.errorMessage,
  });

  AiChatState copyWith({
    List<AiChatMessage>? messages,
    bool? isSending,
    bool? isLoadingHistory,
    String? errorMessage,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      errorMessage: errorMessage,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class AiChatNotifier extends StateNotifier<AiChatState> {
  final TeacherApi _api;

  AiChatNotifier(this._api) : super(const AiChatState()) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    state = state.copyWith(isLoadingHistory: true);
    try {
      final history = await _api.getAiHistory();
      if (history.isEmpty) {
        state = state.copyWith(isLoadingHistory: false);
        return;
      }
      final msgs = history.map((h) {
        return AiChatMessage(
          id: '${h.role}_${h.timestamp}',
          isUser: !h.isAssistant,
          text: h.content,
          timestamp: _parseTs(h.timestamp),
        );
      }).toList();
      state = state.copyWith(messages: msgs, isLoadingHistory: false);
    } catch (e, st) {
      debugPrint('AiChat history error: $e\n$st');
      state = state.copyWith(isLoadingHistory: false);
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = AiChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      isUser: true,
      text: text.trim(),
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isSending: true,
      errorMessage: null,
    );

    try {
      final reply = await _api.sendAiMessage(text.trim());
      final aiMsg = AiChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        isUser: false,
        text: reply,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isSending: false,
      );
    } catch (e, st) {
      debugPrint('AI sendMessage error: $e\n$st');
      state = state.copyWith(
        isSending: false,
        errorMessage: 'AI hozir javob bera olmayapti, keyinroq urinib ko\'ring',
      );
    }
  }

  DateTime _parseTs(String raw) {
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }
}

final aiChatProvider =
    StateNotifierProvider.autoDispose<AiChatNotifier, AiChatState>((ref) {
  final api = ref.read(teacherApiProvider);
  return AiChatNotifier(api);
});
