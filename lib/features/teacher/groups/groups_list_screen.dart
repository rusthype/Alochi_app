import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_pill.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../shared/widgets/alochi_search_bar.dart';
import '../../../core/models/group_model.dart';
import 'groups_provider.dart';

class GroupsListScreen extends ConsumerStatefulWidget {
  const GroupsListScreen({super.key});

  @override
  ConsumerState<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends ConsumerState<GroupsListScreen> {
  String _searchQuery = '';
  String _filter = 'Hammasi';

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsListProvider);

    return Scaffold(
      appBar: AlochiAppBar(
        titleWidget: Text(
          'Guruhlar',
          style: AppTextStyles.displayM.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        showBackButton: false,
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded,
                color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {}, // Handled by inline search bar below
          ),
        ],
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const AlochiEmptyState(
              icon: Icons.groups_outlined,
              title: "Guruhlar yo'q",
              subtitle: "Direktor sizga guruh tayinlaydi",
            );
          }

          final filteredGroups = groups.where((g) {
            // Filter logic
            bool matchesFilter = true;
            if (_filter == 'Bugun') {
              matchesFilter = g.nextLessonAt != null;
            } else if (_filter == 'Boshlang\'ich') {
              final code = g.code.toLowerCase();
              matchesFilter = code.contains('1-') ||
                  code.contains('2-') ||
                  code.contains('3-') ||
                  code.contains('4-');
            }

            if (!matchesFilter) return false;

            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery.toLowerCase();
            return g.subjectName.toLowerCase().contains(query) ||
                g.code.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.l,
                  AppSpacing.m,
                  AppSpacing.l,
                  AppSpacing.s,
                ),
                child: Column(
                  children: [
                    AlochiSearchBar(
                      hintText: 'Guruh nomi yoki fan...',
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'Hammasi',
                          'Bugun',
                          'Boshlang\'ich',
                        ].map((f) {
                          final isSelected = _filter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.s),
                            child: ChoiceChip(
                              label: Text(
                                  f == 'Hammasi' ? '$f (${groups.length})' : f),
                              selected: isSelected,
                              onSelected: (v) {
                                if (v) setState(() => _filter = f);
                              },
                              backgroundColor: Colors.white,
                              selectedColor: const Color(0xFF111827),
                              labelStyle: AppTextStyles.label.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadii.round),
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF111827)
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                              showCheckmark: false,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredGroups.isEmpty
                    ? const AlochiEmptyState(
                        icon: Icons.search_off_rounded,
                        title: "Hech narsa topilmadi",
                        subtitle: "Boshqa so'z bilan qidirib ko'ring",
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.refresh(groupsListProvider.future),
                        color: AppColors.brand,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.l,
                            vertical: AppSpacing.m,
                          ),
                          itemCount: filteredGroups.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.m),
                          itemBuilder: (context, index) =>
                              _GroupCard(group: filteredGroups[index]),
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const _GroupsLoadingSkeleton(),
        error: (err, _) => AlochiEmptyState(
          icon: Icons.wifi_off_rounded,
          iconColor: AppColors.warning,
          title: 'Guruhlarni yuklab bo\'lmadi',
          subtitle: err.toString(),
          actionLabel: "Qayta urinish",
          onAction: () => ref.refresh(groupsListProvider),
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GroupModel group;

  const _GroupCard({required this.group});

  Color _attendanceColor(double pct) {
    if (pct >= 90) return const Color(0xFF0F9A6E);
    if (pct >= 75) return const Color(0xFF1F6F65);
    return const Color(0xFFD97706);
  }

  @override
  Widget build(BuildContext context) {
    final attColor = _attendanceColor(group.attendancePct);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.push('/teacher/groups/${group.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEFEFEF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AlochiPill(
                      label: group.code, variant: AlochiPillVariant.brand),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.subjectName,
                          style: AppTextStyles.bodyS.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${group.studentsCount} o'quvchi"
                          "${group.nextLessonAt != null ? ' · ${group.nextLessonAt}' : ''}",
                          style: AppTextStyles.caption
                              .copyWith(color: const Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFD1D5DB)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Davomat',
                                style: AppTextStyles.caption
                                    .copyWith(color: const Color(0xFF6B7280))),
                            Text(
                              '${group.attendancePct.toStringAsFixed(0)}%',
                              style: AppTextStyles.caption.copyWith(
                                  color: attColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _ProgressBar(
                            value: group.attendancePct / 100, color: attColor),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("O'rtacha",
                          style: AppTextStyles.caption
                              .copyWith(color: const Color(0xFF6B7280))),
                      Text(
                        group.avgGrade.toStringAsFixed(1),
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final Color color;

  const _ProgressBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Container(
          height: 6,
          width: width,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(AppRadii.round),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0, 1),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadii.round),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GroupsLoadingSkeleton extends StatelessWidget {
  const _GroupsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.m,
      ),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.m),
      itemBuilder: (_, __) => _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Shimmer(width: 56, height: 22),
              SizedBox(width: 10),
              _Shimmer(width: 120, height: 14),
            ],
          ),
          Spacer(),
          _Shimmer(width: double.infinity, height: 6),
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double width;
  final double height;

  const _Shimmer({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
