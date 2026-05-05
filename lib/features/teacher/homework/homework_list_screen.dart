import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../core/models/homework_model.dart';
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
        padding: const EdgeInsets.all(14),
        children: [
          _StatsRow(stats: data.stats),
          const SizedBox(height: 20),
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
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (v) {
                      if (v) onFilterChanged(f);
                    },
                    backgroundColor: const Color(0xFFF4F5F7),
                    selectedColor: const Color(0xFF111827),
                    labelStyle: AppTextStyles.label.copyWith(
                      color: isSelected ? Colors.white : const Color(0xFF6B7280),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          if (filteredAssignments.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxl),
              child: const AlochiEmptyState(
                icon: Icons.assignment_outlined,
                title: "Vazifalar yo'q",
                subtitle: "Hali hech qanday vazifa yaratilmagan",
              ),
            )
          else
            ...filteredAssignments.map(
              (hw) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Row(
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
            color: AppColors.brand,
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
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString(),
            style: AppTextStyles.titleL.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFF9CA3AF),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 24, width: 1, color: const Color(0xFFE5E7EB));
  }
}

class _HomeworkCard extends StatelessWidget {
  final HomeworkModel hw;

  const _HomeworkCard({required this.hw});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hw.title,
                  style: AppTextStyles.titleM.copyWith(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              _Badge(isActive: hw.isActive),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${hw.groupName} · ${hw.subject}',
            style: AppTextStyles.caption.copyWith(color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(hw.deadline),
                    style: AppTextStyles.caption.copyWith(color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
              Text(
                '${hw.responseCount}/--',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
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

class _Badge extends StatelessWidget {
  final bool isActive;

  const _Badge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F2EF) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        isActive ? 'Aktiv' : 'O\'tgan',
        style: AppTextStyles.caption.copyWith(
          color: isActive ? AppColors.brand : const Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
