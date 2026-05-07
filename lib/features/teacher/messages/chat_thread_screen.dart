import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../core/models/message_model.dart';
import '../students/students_provider.dart';
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

  Future<void> _sendMessage([String? text]) async {
    final messageText = text ?? _controller.text.trim();
    if (messageText.isEmpty) return;
    try {
      await ref
          .read(chatThreadProvider(widget.conversationId).notifier)
          .sendMessage(messageText);
      if (!mounted) return;
      if (text == null) _controller.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xabar yuborilmadi: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
      resizeToAvoidBottomInset: true,
      appBar: threadAsync.when(
        data: (state) => _ChatAppBar(
          conversation: state.detail?.conversation,
        ),
        loading: () => AppBar(title: const Text('Xabar')),
        error: (_, __) => AppBar(title: const Text('Xabar')),
      ),
      body: threadAsync.when(
        data: (state) {
          if (state.messages.isNotEmpty) _scrollToBottom();
          final studentId = state.detail?.conversation.studentId;

          return Column(
            children: [
              if (studentId != null) _ChildContextCard(studentId: studentId),
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
              
              _AiSuggestionsRow(onSelected: _sendMessage),
              
              _ChatComposer(
                controller: _controller,
                isSending: state.isSending,
                onSend: () => _sendMessage(),
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
          onAction: () => ref.read(chatThreadProvider(widget.conversationId).notifier).refresh(),
        ),
      ),
    );
  }
}

// ─── Child Context Card ───────────────────────────────────────────────────────

class _ChildContextCard extends ConsumerWidget {
  final String studentId;

  const _ChildContextCard({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentProfileProvider(studentId));
    final theme = Theme.of(context);

    return studentAsync.when(
      data: (student) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(bottom: BorderSide(color: theme.dividerColor)),
        ),
        child: Row(
          children: [
            _StatItem(
              label: 'Davomat',
              value: '${(student.attendancePct ?? 0).toStringAsFixed(0)}%',
              color: (student.attendancePct ?? 100) < 75 ? AppColors.danger : const Color(0xFF0F9A6E),
            ),
            const SizedBox(width: AppSpacing.l),
            _StatItem(
              label: 'O\'rtacha',
              value: (student.avgGrade ?? 0).toStringAsFixed(1),
              color: (student.avgGrade ?? 5) < 3.5 ? AppColors.danger : AppColors.brand,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => context.push('/teacher/students/$studentId'),
              icon: const Icon(Icons.person_outline_rounded, size: 16),
              label: const Text('Profil', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: AppColors.brandMuted),
            ),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 1),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.brandMuted, fontSize: 10)),
        Text(value, style: AppTextStyles.label.copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ─── AI Suggestions ───────────────────────────────────────────────────────────

class _AiSuggestionsRow extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const _AiSuggestionsRow({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = [
      'Darsda juda faol bo\'ldi',
      'Uy vazifasini vaqtida topshirdi',
      'Iltimos, darsga kech qolmasin',
    ];

    return Container(
      height: 44,
      color: theme.cardColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(suggestions[index]),
              labelStyle: AppTextStyles.caption.copyWith(color: AppColors.brand, fontSize: 11),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.round)),
              onPressed: () => onSelected(suggestions[index]),
            ),
          );
        },
      ),
    );
  }
}

// ─── Rest of UI components ───

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ConversationModel? conversation;
  const _ChatAppBar({this.conversation});
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = conversation?.participantName ?? '';
    return AppBar(
      backgroundColor: theme.cardColor, elevation: 0, surfaceTintColor: theme.cardColor,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          AlochiAvatar(name: name, size: 36),
          const SizedBox(width: AppSpacing.s),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
            children: [
              Text(name.isEmpty ? 'Xabar' : name, style: AppTextStyles.titleM.copyWith(color: theme.colorScheme.onSurface, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (conversation?.classCode != null) Text(conversation!.classCode!, style: AppTextStyles.caption.copyWith(color: AppColors.brandMuted)),
            ],
          )),
        ],
      ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  final List<MessageModel> messages;
  final ScrollController scrollController;
  const _MessagesList({required this.messages, required this.scrollController});
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.m),
      itemCount: messages.length,
      itemBuilder: (context, index) => _MessageBubble(message: messages[index]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  const _MessageBubble({required this.message});
  @override
  Widget build(BuildContext context) {
    final isOut = message.isFromTeacher;
    final theme = Theme.of(context);
    return Align(
      alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOut ? AppColors.brand : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: isOut ? null : Border.all(color: theme.dividerColor),
        ),
        child: Text(message.text, style: TextStyle(color: isOut ? Colors.white : theme.colorScheme.onSurface)),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  const _ChatComposer({required this.controller, required this.isSending, required this.onSend});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.m,
        right: AppSpacing.m,
        top: AppSpacing.m,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.m,
      ),
      decoration: BoxDecoration(color: theme.cardColor, border: Border(top: BorderSide(color: theme.dividerColor))),
      child: Row(
        children: [
          Expanded(child: TextField(controller: controller, style: TextStyle(color: theme.colorScheme.onSurface), decoration: const InputDecoration(hintText: 'Xabar...'))),
          IconButton(icon: const Icon(Icons.send_rounded, color: AppColors.brand), onPressed: isSending ? null : onSend),
        ],
      ),
    );
  }
}

class _EmptyThreadState extends StatelessWidget {
  const _EmptyThreadState();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Xabarlar yo\'q', style: TextStyle(color: AppColors.brandMuted)));
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(color: AppColors.danger.withValues(alpha: 0.1), padding: const EdgeInsets.all(8), child: Text(message, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)));
  }
}
