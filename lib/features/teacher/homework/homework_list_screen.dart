import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_card.dart';
import '../../../shared/widgets/alochi_pill.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../core/api/teacher_api.dart';
import 'homework_provider.dart';

class HomeworkListScreen extends ConsumerStatefulWidget {
  const HomeworkListScreen({super.key});

  @override
  ConsumerState<HomeworkListScreen> createState() => _HomeworkListScreenState();
}

class _HomeworkListScreenState extends ConsumerState<HomeworkListScreen> {
  String _filter = 'Hammasi';

  @override
  Widget build(BuildContext context) {
    final hwAsync = ref.watch(homeworkListProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AlochiAppBar(title: 'Vazifalar'),
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
        data: (data) => _HomeworkListBody(data: data, filter: _filter, onFilterChanged: (f) => setState(() => _filter = f)),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
        error: (err, _) => AlochiEmptyState(
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.danger,
          title: 'Yuklab bo\'lmadi',
          subtitle: 'Qayta urinib ko\'ring',
          actionLabel: "Yangilash",
          onAction: () => ref.invalidate(homeworkListProvider),
        ),
      ),
    );
  }
}

class _HomeworkListBody extends ConsumerWidget {
  final HomeworkListData data;
  final String filter;
  final ValueChanged<String> onFilterChanged;

  const _HomeworkListBody({
    required this.data,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAssignments = data.assignments.where((hw) {
      if (filter == 'Faol') return hw.isActive;
      if (filter == 'O\'tgan') return !hw.isActive;
      return true;
    }).toList();

    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: () async {
        ref.invalidate(homeworkListProvider);
        await ref.read(homeworkListProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          _StatsRow(stats: data.stats),
          const SizedBox(height: AppSpacing.l),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'Hammasi',
                'Faol',
                'O\'tgan',
              ].map((f) {
                final isSelected = filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (v) {
                      if (v) onFilterChanged(f);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.brandSoft,
                    labelStyle: AppTextStyles.label.copyWith(
                      color: isSelected ? AppColors.brand : AppColors.ink,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.round),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.brand
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          if (filteredAssignments.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxl),
              child: AlochiEmptyState(
                icon: Icons.assignment_outlined,
                title: filter == 'Hammasi'
                    ? "Vazifalar yaratilmagan"
                    : "Bu bo'limda vazifalar yo'q",
                subtitle: filter == 'Hammasi'
                    ? "Birinchi vazifani yaratish uchun + tugmasini bosing"
                    : "Boshqa filterni tanlang",
              ),
            )
          else
            ...filteredAssignments.map(
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
            value: stats.submitted,
            label: 'Topshirdi',
            color: AppColors.brand,
          ),
          _VerticalDivider(),
          _StatTile(
            value: stats.onTime,
            label: 'O\'z vaqtida',
            color: const Color(0xFF0F9A6E),
          ),
          _VerticalDivider(),
          _StatTile(
            value: stats.pending,
            label: 'Kutilmoqda',
            color: const Color(0xFFD97706),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isZero = value == 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isZero ? '—' : value.toString(),
          style: AppTextStyles.displayM.copyWith(
            color: isZero ? AppColors.brandMuted : color,
          ),
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
      onTap: () {
        // TODO V1.1.1: implement homework detail when backend /homework/{id}/ is ready
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vazifa tafsiloti tez orada (V1.1.1)'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(
                AppSpacing.l, 0, AppSpacing.l, AppSpacing.m),
            backgroundColor: AppColors.brand,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.m),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
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
                  label: hw.subject.isNotEmpty
                      ? '${hw.groupName} · ${hw.subject}'
                      : (hw.groupName.isNotEmpty ? hw.groupName : 'Guruh'),
                ),
                const Spacer(),
                if (hw.deadline.isNotEmpty)
                  _MetaChip(
                    icon: Icons.schedule_outlined,
                    label: _formatDate(hw.deadline),
                    color:
                        hw.isActive ? AppColors.brandMuted : AppColors.danger,
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
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.brand),
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
