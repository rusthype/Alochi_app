import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../shared/widgets/alochi_grade_badge.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../shared/widgets/alochi_button.dart';
import '../../../shared/widgets/alochi_search_bar.dart';
import '../../../core/models/group_model.dart';
import '../../../core/models/student_model.dart';
import 'groups_provider.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));
    final studentsAsync = ref.watch(groupStudentsProvider(widget.groupId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: groupAsync.when(
        data: (group) => AlochiAppBar(
          titleWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${group.code} · ${group.subjectName}',
                style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
              ),
              Text(
                "${group.studentsCount} o'quvchi",
                style: AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_horiz_rounded, color: AppColors.ink),
              onPressed: () {},
            ),
          ],
        ),
        loading: () => const AlochiAppBar(
          title: 'Guruh',
          actions: [],
        ),
        error: (_, __) => const AlochiAppBar(title: 'Guruh'),
      ),
      body: Column(
        children: [
          groupAsync.when(
            data: (group) => _GroupStatsRow(group: group),
            loading: () => const SizedBox(height: 4),
            error: (_, __) => const SizedBox.shrink(),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.brand,
            unselectedLabelColor: AppColors.brandMuted,
            indicatorColor: AppColors.brand,
            indicatorWeight: 2,
            labelStyle: AppTextStyles.label
                .copyWith(fontWeight: FontWeight.w600),
            unselectedLabelStyle: AppTextStyles.label,
            tabs: const [
              Tab(text: "O'quvchilar"),
              Tab(text: 'Davomat'),
              Tab(text: 'Baholar'),
              Tab(text: 'Tahlil'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                studentsAsync.when(
                  data: (students) => _StudentsTab(
                    students: students,
                    groupId: widget.groupId,
                  ),
                  loading: () => const _StudentsLoadingSkeleton(),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 40, color: AppColors.danger),
                          const SizedBox(height: AppSpacing.m),
                          Text(err.toString(),
                              style: AppTextStyles.bodyS
                                  .copyWith(color: AppColors.brandMuted),
                              textAlign: TextAlign.center),
                          const SizedBox(height: AppSpacing.m),
                          TextButton(
                            onPressed: () =>
                                ref.refresh(groupStudentsProvider(widget.groupId)),
                            child: Text('Qayta urinish',
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.brand)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Attendance tab
                _AttendanceTab(groupId: widget.groupId),
                // Grades tab
                groupAsync.when(
                  data: (group) => _GradesTab(
                    groupId: widget.groupId,
                    subject: group.subjectName,
                    groupName: group.code,
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.brand),
                  ),
                  error: (_, __) => _GradesTab(
                    groupId: widget.groupId,
                    subject: '',
                    groupName: '',
                  ),
                ),
                // Analytics tab — placeholder (V1.2)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Text(
                      'Tahlil V1.2 da qo\'shiladi',
                      style: AppTextStyles.bodyS
                          .copyWith(color: AppColors.brandMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupStatsRow extends StatelessWidget {
  final GroupModel group;

  const _GroupStatsRow({required this.group});

  Color _attendanceColor(double pct) {
    if (pct >= 90) return const Color(0xFF0F9A6E);
    if (pct >= 75) return AppColors.brand;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l, vertical: AppSpacing.m),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatTile(
            label: "Keldi",
            value: group.studentsCount.toString(),
            valueColor: AppColors.ink,
          ),
          _StatDivider(),
          _StatTile(
            label: "O'rtacha",
            value: group.avgGrade.toStringAsFixed(1),
            valueColor: AppColors.brand,
          ),
          _StatDivider(),
          _StatTile(
            label: 'Davomat',
            value: '${group.attendancePct.toStringAsFixed(0)}%',
            valueColor: _attendanceColor(group.attendancePct),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.displayM.copyWith(color: valueColor),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.brandMuted),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 1,
      color: const Color(0xFFE5E7EB),
    );
  }
}

class _StudentsTab extends StatefulWidget {
  final List<StudentModel> students;
  final String groupId;

  const _StudentsTab({required this.students, required this.groupId});

  @override
  State<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<_StudentsTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    if (widget.students.isEmpty) {
      return const AlochiEmptyState(
        title: "O'quvchilar yo'q",
        subtitle: "Bu guruhda hali o'quvchi biriktirilmagan",
      );
    }

    final filteredStudents = widget.students.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.fullName.toLowerCase().contains(_searchQuery.toLowerCase());
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
          child: AlochiSearchBar(
            hintText: 'Talaba ismi...',
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        Expanded(
          child: filteredStudents.isEmpty
              ? const AlochiEmptyState(
                  icon: Icons.search_off_rounded,
                  title: "Hech narsa topilmadi",
                  subtitle: "Boshqa ism bilan qidirib ko'ring",
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.l,
                    vertical: AppSpacing.m,
                  ),
                  itemCount: filteredStudents.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: Color(0xFFF3F4F6),
                  ),
                  itemBuilder: (context, index) => _StudentRow(
                    student: filteredStudents[index],
                    groupId: widget.groupId,
                  ),
                ),
        ),
      ],
    );
  }
}

class _StudentRow extends StatelessWidget {
  final StudentModel student;
  final String groupId;

  const _StudentRow({required this.student, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final attPct = student.attendancePct;
    final avgGrade = student.avgGrade;
    final isLowAtt = attPct != null && attPct < 75;
    final isLowGrade = avgGrade != null && avgGrade < 3.5;

    return GestureDetector(
      onTap: () => context.push('/teacher/students/${student.id}'),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
        child: Row(
          children: [
            AlochiAvatar(name: student.fullName, size: 38),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _buildSubtitle(attPct, avgGrade),
                    style: AppTextStyles.bodyS.copyWith(
                      color: (isLowAtt || isLowGrade)
                          ? AppColors.warning
                          : AppColors.brandMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (student.lastGrade != null) ...[
              const SizedBox(width: AppSpacing.m),
              AlochiGradeBadge(value: student.lastGrade!),
            ],
          ],
        ),
      ),
    );
  }

  String _buildSubtitle(double? att, double? avg) {
    final parts = <String>[];
    if (att != null) parts.add('Davomat ${att.toStringAsFixed(0)}%');
    if (avg != null) parts.add("O'rt. ${avg.toStringAsFixed(1)}");
    return parts.join(' · ');
  }
}

// ─── Attendance Tab ──────────────────────────────────────────────────────────

class _AttendanceTab extends StatelessWidget {
  final String groupId;

  const _AttendanceTab({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(AppRadii.l),
            ),
            child: Row(
              children: [
                const Icon(Icons.how_to_reg_outlined,
                    color: AppColors.brand, size: 20),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text(
                    'Guruh davomati va tarixi',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.brandInk),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          AlochiButton.secondary(
            label: 'Davomat tarixi',
            icon: Icons.history_rounded,
            onPressed: () =>
                context.push('/teacher/groups/$groupId/attendance-history'),
          ),
          const SizedBox(height: AppSpacing.m),
          AlochiButton.primary(
            label: 'Bugungi davomatni belgilash',
            icon: Icons.how_to_reg_rounded,
            onPressed: () {
              final today = _todayString();
              context.push(
                '/teacher/lesson/$groupId/attendance',
                extra: {'classId': groupId, 'date': today},
              );
            },
          ),
        ],
      ),
    );
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

// ─── Grades Tab ───────────────────────────────────────────────────────────────

class _GradesTab extends StatelessWidget {
  final String groupId;
  final String subject;
  final String groupName;

  const _GradesTab({
    required this.groupId,
    required this.subject,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(AppRadii.l),
            ),
            child: Row(
              children: [
                const Icon(Icons.grade_outlined,
                    color: AppColors.brand, size: 20),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text(
                    'Guruh baholari jurnali',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.brandInk),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          AlochiButton.primary(
            label: 'Baho qo\'yish',
            icon: Icons.edit_rounded,
            onPressed: () => context.push(
              '/teacher/groups/$groupId/grades',
              extra: {
                'subject': subject,
                'groupName': groupName,
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentsLoadingSkeleton extends StatelessWidget {
  const _StudentsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.l),
      itemCount: 6,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 14,
                      width: 140,
                      color: const Color(0xFFF3F4F6)),
                  const SizedBox(height: 6),
                  Container(
                      height: 11,
                      width: 100,
                      color: const Color(0xFFF3F4F6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
