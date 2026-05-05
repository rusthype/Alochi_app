import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_card.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import 'telegram_provider.dart';

class TelegramParentsScreen extends ConsumerWidget {
  const TelegramParentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(telegramGroupsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.ink, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/teacher/profile');
            }
          },
        ),
        title: Text(
          "Telegram ota-onalar",
          style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const _ComingSoonState();
          }
          return _GroupsList(groups: groups);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
        error: (err, _) {
          // 404 or any error → gracefully show coming-soon
          final isNotFound = err.toString().contains('topilmadi') ||
              err.toString().contains('404') ||
              err.toString().contains('Not found');
          if (isNotFound) {
            return const _ComingSoonState();
          }
          return _ErrorState(
            message: err.toString(),
            onRetry: () => ref.invalidate(telegramGroupsProvider),
          );
        },
      ),
    );
  }
}

// ─── Coming-soon state ────────────────────────────────────────────────────────

class _ComingSoonState extends StatelessWidget {
  const _ComingSoonState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        children: [
          const _ExplainerBanner(),
          const SizedBox(height: AppSpacing.l),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(AppRadii.xxl),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFF0088CC),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Text(
                    'Telegram statuslari',
                    style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    "Telegram statuslari tez orada qo'shiladi",
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.brandMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    'Backend ishlab chiqilmoqda',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.warning),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Explainer banner ─────────────────────────────────────────────────────────

class _ExplainerBanner extends StatelessWidget {
  const _ExplainerBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(AppRadii.m),
        border: Border.all(color: const Color(0xFFBFD4FB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFF0088CC), size: 18),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              "Ota-onalar Telegram botiga o'zlari ulanadi. Sizning Telegram akkauntingiz kerak emas.",
              style: AppTextStyles.bodyS.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Groups list ─────────────────────────────────────────────────────────────

class _GroupsList extends ConsumerWidget {
  final List<TelegramGroupStatusData> groups;

  const _GroupsList({required this.groups});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.l),
      children: [
        const _ExplainerBanner(),
        const SizedBox(height: AppSpacing.l),
        ...groups.map((group) => _GroupCard(
              group: group,
              onTap: () =>
                  context.push('/teacher/telegram/groups/${group.groupId}/unlinked'),
            )),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  final TelegramGroupStatusData group;
  final VoidCallback onTap;

  const _GroupCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final percent = group.linkedPercent;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: GestureDetector(
        onTap: onTap,
        child: AlochiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.groupName,
                          style:
                              AppTextStyles.titleM.copyWith(color: AppColors.ink),
                        ),
                        if (group.subject.isNotEmpty)
                          Text(
                            group.subject,
                            style: AppTextStyles.bodyS
                                .copyWith(color: AppColors.brandMuted),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.brandMuted),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              Row(
                children: [
                  Text(
                    '${group.linkedCount}/${group.totalParents} ota-ona ulangan',
                    style:
                        AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted),
                  ),
                  const Spacer(),
                  Text(
                    '${(percent * 100).round()}%',
                    style: AppTextStyles.label.copyWith(
                      color: percent >= 0.75
                          ? AppColors.success
                          : percent >= 0.5
                              ? AppColors.warning
                              : AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.round),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percent >= 0.75
                        ? AppColors.success
                        : percent >= 0.5
                            ? AppColors.warning
                            : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Error state ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AlochiEmptyState(
      title: "Ma'lumotlarni yuklashda xato",
      subtitle: message,
      ctaLabel: "Qayta urinish",
      onCtaPressed: onRetry,
    );
  }
}
