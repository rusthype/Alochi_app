import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/teacher_api.dart';
import '../dashboard/dashboard_provider.dart';

class AiChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final bool isStreaming;
  final DateTime timestamp;

  const AiChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.isStreaming = false,
    required this.timestamp,
  });

  AiChatMessage copyWith({String? text, bool? isStreaming}) {
    return AiChatMessage(
      id: id,
      isUser: isUser,
      text: text ?? this.text,
      isStreaming: isStreaming ?? this.isStreaming,
      timestamp: timestamp,
    );
  }
}

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

class AiChatNotifier extends StateNotifier<AiChatState> {
  final TeacherApi _api;
  Timer? _streamTimer;

  AiChatNotifier(this._api) : super(const AiChatState()) {
    _loadHistory();
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    super.dispose();
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

    _streamTimer?.cancel();

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
      _streamReply(reply);
    } catch (e, st) {
      debugPrint('AI sendMessage error: $e\n$st');
      state = state.copyWith(
        isSending: false,
        errorMessage: "AI hozir javob bera olmayapti, keyinroq urinib ko'ring",
      );
    }
  }

  /// Typewriter streaming — displays reply word by word.
  /// Backend doesn't support SSE, so we simulate streaming client-side.
  void _streamReply(String fullText) {
    final msgId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    final aiMsg = AiChatMessage(
      id: msgId,
      isUser: false,
      text: '',
      isStreaming: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, aiMsg],
      isSending: false,
    );

    // Stream by words (~40ms per word = natural reading speed)
    final words = fullText.split(' ');
    int wordIndex = 0;
    String displayed = '';

    _streamTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (wordIndex >= words.length) {
        timer.cancel();
        // Mark streaming done
        _updateMessage(msgId, fullText, isStreaming: false);
        return;
      }
      displayed = wordIndex == 0 ? words[0] : '$displayed ${words[wordIndex]}';
      wordIndex++;
      _updateMessage(msgId, displayed, isStreaming: true);
    });
  }

  void _updateMessage(String id, String text, {required bool isStreaming}) {
    final updated = state.messages.map((m) {
      if (m.id == id) return m.copyWith(text: text, isStreaming: isStreaming);
      return m;
    }).toList();
    state = state.copyWith(messages: updated);
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
