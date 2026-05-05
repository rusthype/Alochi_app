import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_card.dart';
import '../../../shared/widgets/alochi_pill.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../core/api/teacher_api.dart';
import 'homework_provider.dart';

class HomeworkListScreen extends ConsumerWidget {
  const HomeworkListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hwAsync = ref.watch(homeworkListProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AlochiAppBar(title: 'Vazifalar'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/teacher/homework/create'),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Yangi vazifa',
          style: AppTextStyles.label
              .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: hwAsync.when(
        data: (data) => _HomeworkListBody(data: data),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
        error: (err, _) => AlochiEmptyState(
          title: 'Yuklab bo\'lmadi',
          subtitle: err.toString(),
        ),
      ),
    );
  }
}

class _HomeworkListBody extends ConsumerWidget {
  final HomeworkListData data;

  const _HomeworkListBody({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (data.assignments.isEmpty) {
      return const AlochiEmptyState(
        title: 'Vazifa yaratmagansiz',
        subtitle: 'Yangi vazifa yaratish uchun + tugmasini bosing',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(homeworkListProvider.future),
      color: AppColors.brand,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          _StatsRow(stats: data.stats),
          const SizedBox(height: AppSpacing.l),
          ...data.assignments.map(
            (hw) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.m),
              child: _HomeworkCard(hw: hw),
            ),
          ),
          const SizedBox(height: 80), // FAB clearance
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final HomeworkStats stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return AlochiCard(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatTile(
            value: stats.submitted.toString(),
            label: 'Topshirdi',
            color: AppColors.brand,
          ),
          _VerticalDivider(),
          _StatTile(
            value: stats.onTime.toString(),
            label: 'O\'z vaqtida',
            color: const Color(0xFF0F9A6E),
          ),
          _VerticalDivider(),
          _StatTile(
            value: stats.pending.toString(),
            label: 'Kutilmoqda',
            color: const Color(0xFFD97706),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.displayM
              .copyWith(color: color, fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.brandMuted),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 32, width: 1, color: const Color(0xFFE5E7EB));
  }
}

class _HomeworkCard extends StatelessWidget {
  final HomeworkModel hw;

  const _HomeworkCard({required this.hw});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/teacher/homework/${hw.id}'),
      behavior: HitTestBehavior.opaque,
      child: AlochiCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    hw.title,
                    style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                AlochiPill(
                  label: hw.isActive ? 'Aktiv' : 'Tugagan',
                  variant: hw.isActive
                      ? AlochiPillVariant.success
                      : AlochiPillVariant.neutral,
                ),
              ],
            ),
            if (hw.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s),
              Text(
                hw.description,
                style:
                    AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                _MetaChip(
                  icon: Icons.group_outlined,
                  label: hw.groupName.isNotEmpty ? hw.groupName : 'Guruh',
                ),
                const SizedBox(width: AppSpacing.s),
                if (hw.subject.isNotEmpty)
                  _MetaChip(icon: Icons.book_outlined, label: hw.subject),
                const Spacer(),
                if (hw.deadline.isNotEmpty)
                  _MetaChip(
                    icon: Icons.schedule_outlined,
                    label: _formatDate(hw.deadline),
                    color: hw.isActive
                        ? AppColors.brandMuted
                        : AppColors.danger,
                  ),
              ],
            ),
            if (hw.responseCount > 0) ...[
              const SizedBox(height: AppSpacing.s),
              Row(
                children: [
                  const Icon(Icons.assignment_turned_in_outlined,
                      size: 14, color: AppColors.brand),
                  const SizedBox(width: 4),
                  Text(
                    '${hw.responseCount} ta javob',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.brand),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MetaChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.brandMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: c),
        ),
      ],
    );
  }
}
