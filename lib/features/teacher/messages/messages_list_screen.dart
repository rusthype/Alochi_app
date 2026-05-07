import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../core/models/message_model.dart';
import 'messages_provider.dart';

class MessagesListScreen extends ConsumerWidget {
  const MessagesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AlochiAppBar(
        title: 'Xabarlar',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.brand),
            tooltip: 'Yangi xabar',
            onPressed: () => context.push('/teacher/messages/compose'),
          ),
        ],
      ),
      body: conversationsAsync.when(
        data: (conversations) =>
            _ConversationsList(conversations: conversations),
        loading: () => const _ConversationsSkeleton(),
        error: (err, _) => AlochiEmptyState(
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.danger,
          title: "Xabarlarni yuklashda xato",
          subtitle: err.toString(),
          actionLabel: "Qayta urinish",
          onAction: () => ref.invalidate(conversationsProvider),
        ),
      ),
    );
  }
}

class _ConversationsList extends ConsumerWidget {
  final List<ConversationModel> conversations;

  const _ConversationsList({required this.conversations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (conversations.isEmpty) {
      return const AlochiEmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: "Hozircha xabarlar yo'q",
        subtitle: "Ota-onalar bilan suhbatlar bu yerda ko'rinadi",
      );
    }

    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: () async {
        ref.invalidate(conversationsProvider);
        await ref.read(conversationsProvider.future);
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: conversations.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          color: Color(0xFFF3F4F6),
          indent: 76,
        ),
        itemBuilder: (context, index) {
          return _ConversationRow(
            conversation: conversations[index],
            onTap: () => context.push(
              '/teacher/messages/${conversations[index].id}',
            ),
          );
        },
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const _ConversationRow({
    required this.conversation,
    required this.onTap,
  });

  String _lastMessagePrefix() {
    if (conversation.isFromMe) return 'Siz: ';
    if (conversation.participantRole == 'father') return 'Otasi: ';
    if (conversation.participantRole == 'mother') return 'Onasi: ';
    return '';
  }

  String _formatTime(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}s';
      return '${dt.day}.${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  bool _isRecent(String raw) {
    if (raw.isEmpty) return false;
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateTime.now().difference(dt).inHours < 3;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRecent = _isRecent(conversation.lastMessageTime);
    final timeColor = isRecent ? AppColors.accent : AppColors.brandMuted;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        child: Row(
          children: [
            // Avatar with optional unread dot
            Stack(
              children: [
                AlochiAvatar(name: conversation.participantName, size: 48),
                if (conversation.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFFFFFF),
                            blurRadius: 0,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.participantName,
                          style: AppTextStyles.titleM.copyWith(
                            fontSize: 14,
                            color: AppColors.ink,
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if ((conversation.classCode ?? '').isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: AppSpacing.s),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brandSoft,
                            borderRadius: BorderRadius.circular(AppRadii.xs),
                          ),
                          child: Text(
                            conversation.classCode ?? '',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const SizedBox(width: AppSpacing.s),
                      Text(
                        _formatTime(conversation.lastMessageTime),
                        style: AppTextStyles.caption.copyWith(color: timeColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_lastMessagePrefix()}${conversation.lastMessage}',
                          style: AppTextStyles.bodyS.copyWith(
                            color: conversation.unreadCount > 0
                                ? AppColors.ink
                                : AppColors.brandMuted,
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: AppSpacing.s),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brand,
                            borderRadius: BorderRadius.circular(AppRadii.round),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationsSkeleton extends StatelessWidget {
  const _ConversationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 76),
      itemBuilder: (_, __) => const _RowSkeleton(),
    );
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l, vertical: AppSpacing.m),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(AppRadii.round),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(4),
                    )),
                const SizedBox(height: 6),
                Container(
                    height: 12,
                    width: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(4),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
