import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../core/models/message_model.dart';
import 'messages_provider.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatThreadScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final threadAsync = ref.watch(chatThreadProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      appBar: threadAsync.when(
        data: (state) => _ChatAppBar(
          conversation: state.detail?.conversation,
        ),
        loading: () => AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text('Xabar',
              style: AppTextStyles.titleM.copyWith(color: AppColors.ink)),
        ),
        error: (_, __) => AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text('Xabar',
              style: AppTextStyles.titleM.copyWith(color: AppColors.ink)),
        ),
      ),
      body: threadAsync.when(
        data: (state) {
          // Auto-scroll when messages update
          if (state.messages.isNotEmpty) _scrollToBottom();
          return Column(
            children: [
              Expanded(
                child: state.messages.isEmpty
                    ? const _EmptyThreadState()
                    : _MessagesList(
                        messages: state.messages,
                        scrollController: _scrollController,
                      ),
              ),
              if (state.errorMessage != null)
                _ErrorBanner(message: state.errorMessage!),
              _ChatComposer(
                controller: _controller,
                isSending: state.isSending,
                onSend: () async {
                  final text = _controller.text.trim();
                  if (text.isEmpty) return;
                  _controller.clear();
                  await ref
                      .read(chatThreadProvider(widget.conversationId).notifier)
                      .sendMessage(text);
                  _scrollToBottom();
                },
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
        error: (err, _) => AlochiEmptyState(
          title: "Xabarlarni yuklashda xato",
          subtitle: err.toString(),
          ctaLabel: "Qayta urinish",
          onCtaPressed: () => ref
              .read(chatThreadProvider(widget.conversationId).notifier)
              .refresh(),
        ),
      ),
    );
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ConversationModel? conversation;

  const _ChatAppBar({this.conversation});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final name = conversation?.participantName ?? '';
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.ink, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          AlochiAvatar(name: name, size: 36),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name.isEmpty ? 'Xabar' : name,
                  style: AppTextStyles.titleM
                      .copyWith(color: AppColors.ink, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (conversation?.classCode != null &&
                    conversation!.classCode!.isNotEmpty)
                  Text(
                    conversation!.classCode!,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.brandMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon:
              const Icon(Icons.more_vert_rounded, color: AppColors.brandMuted),
          onPressed: () {},
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE5E7EB)),
      ),
    );
  }
}

// ─── Messages list ────────────────────────────────────────────────────────────

class _MessagesList extends StatelessWidget {
  final List<MessageModel> messages;
  final ScrollController scrollController;

  const _MessagesList({
    required this.messages,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m, vertical: AppSpacing.m),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final prevMsg = index > 0 ? messages[index - 1] : null;
        final showDateSep = prevMsg == null ||
            _isDifferentDay(prevMsg.timestamp, msg.timestamp);
        return Column(
          children: [
            if (showDateSep) _DateSeparator(timestamp: msg.timestamp),
            _MessageBubble(message: msg),
          ],
        );
      },
    );
  }

  bool _isDifferentDay(String a, String b) {
    try {
      final da = DateTime.parse(a).toLocal();
      final db = DateTime.parse(b).toLocal();
      return da.day != db.day || da.month != db.month || da.year != db.year;
    } catch (_) {
      return false;
    }
  }
}

class _DateSeparator extends StatelessWidget {
  final String timestamp;

  const _DateSeparator({required this.timestamp});

  String _label() {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return 'Bugun';
      }
      final yesterday = now.subtract(const Duration(days: 1));
      if (dt.day == yesterday.day &&
          dt.month == yesterday.month &&
          dt.year == yesterday.year) {
        return 'Kecha';
      }
      return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _label();
    if (label.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Text(
              label,
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.brandMuted),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;

  const _MessageBubble({required this.message});

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOut = message.isFromTeacher;
    final time = _formatTime(message.timestamp);

    return Align(
      alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 2,
          bottom: 2,
          left: isOut ? 60 : 0,
          right: isOut ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: isOut ? AppColors.brand : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isOut ? 18 : 6),
            bottomRight: Radius.circular(isOut ? 6 : 18),
          ),
          border: isOut ? null : Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: isOut
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment:
              isOut ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: AppTextStyles.body.copyWith(
                color: isOut ? Colors.white : AppColors.ink,
              ),
            ),
            if (time.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: AppTextStyles.caption.copyWith(
                        color: isOut
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppColors.brandMuted,
                        fontSize: 10,
                      ),
                    ),
                    if (isOut) ...[
                      const SizedBox(width: 3),
                      Icon(
                        message.isRead
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 12,
                        color: message.isRead
                            ? AppColors.info
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyThreadState extends StatelessWidget {
  const _EmptyThreadState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 48, color: AppColors.brandMuted.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.m),
          Text(
            'Hali xabarlar yo\'q',
            style: AppTextStyles.body.copyWith(color: AppColors.brandMuted),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Birinchi xabarni yuboring',
            style: AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted),
          ),
        ],
      ),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m, vertical: AppSpacing.s),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m, vertical: AppSpacing.s),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(AppRadii.s),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 16),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(color: AppColors.danger),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Composer ─────────────────────────────────────────────────────────────────

class _ChatComposer extends StatefulWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _ChatComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  State<_ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<_ChatComposer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.m,
        right: AppSpacing.m,
        top: AppSpacing.s,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.s,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: widget.controller,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: AppTextStyles.body.copyWith(color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Xabar yozing...',
                  hintStyle:
                      AppTextStyles.body.copyWith(color: AppColors.brandMuted),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.round),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.round),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.round),
                    borderSide: const BorderSide(
                        color: AppColors.brandLight, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          GestureDetector(
            onTap: (_hasText && !widget.isSending) ? widget.onSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _hasText ? AppColors.brand : const Color(0xFFE5E7EB),
                shape: BoxShape.circle,
              ),
              child: widget.isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: _hasText ? Colors.white : AppColors.brandMuted,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
