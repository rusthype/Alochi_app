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
import '../../../shared/widgets/alochi_card.dart';
import '../../../core/models/group_model.dart';
import '../../../core/models/student_model.dart';
import '../../../core/api/teacher_api.dart';
import '../grades/grades_provider.dart';
import '../dashboard/dashboard_provider.dart';
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
          centerTitle: true,
          titleWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${group.code} · ${group.subjectName}',
                style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
              ),
              Text(
                "${group.studentsCount} o'quvchi",
                style:
                    AppTextStyles.caption.copyWith(color: const Color(0xFF6B7280)),
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
            unselectedLabelColor: const Color(0xFF6B7280),
            indicatorColor: AppColors.brand,
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle:
                AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
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
                            onPressed: () => ref
                                .refresh(groupStudentsProvider(widget.groupId)),
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
                _GradesJournalBody(groupId: widget.groupId),
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

  @override
  Widget build(BuildContext context) {
    final avgGradeStr =
        group.avgGrade > 0 ? group.avgGrade.toStringAsFixed(1) : '--';

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Expanded(
            child: _StatTile(
              label: "DAVOMAT",
              value: "28/32", // Mockup specific or calculated
              valueColor: AppColors.ink,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              label: "O'RTACHA",
              value: avgGradeStr,
              valueColor: AppColors.brand,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: _StatTile(
              label: 'BAJARISH',
              value: '87%', // Mockup specific placeholder
              valueColor: Color(0xFF0F9A6E),
            ),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.displayM.copyWith(
              color: valueColor,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
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

    return GestureDetector(
      onTap: () => context.push('/teacher/students/${student.id}'),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
        child: Row(
          children: [
            AlochiAvatar(name: student.fullName, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: AppTextStyles.titleM.copyWith(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _buildSubtitle(attPct, avgGrade),
                    style: AppTextStyles.caption.copyWith(
                      color: isLowAtt
                          ? const Color(0xFFD97706)
                          : const Color(0xFF6B7280),
                      fontSize: 11,
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
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.brandInk),
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

class _GradesJournalBody extends ConsumerWidget {
  final String groupId;
  const _GradesJournalBody({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalAsync = ref.watch(gradesJournalProvider(groupId));

    return journalAsync.when(
      data: (journal) {
        if (journal.students.isEmpty) {
          return const AlochiEmptyState(
            icon: Icons.star_outline,
            title: 'Baholar yo\'q',
            subtitle: 'Hali hech qanday baho qo\'yilmagan',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.l),
          itemCount: journal.students.length,
          itemBuilder: (context, index) {
            final student = journal.students[index];
            return _StudentGradeRow(
              student: student,
              groupId: groupId,
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      ),
      error: (e, _) => AlochiEmptyState(
        icon: Icons.error_outline,
        title: 'Yuklab bo\'lmadi',
        subtitle: 'Qayta urinib ko\'ring',
        actionLabel: 'Yangilash',
        onAction: () => ref.invalidate(gradesJournalProvider(groupId)),
      ),
    );
  }
}

class _StudentGradeRow extends ConsumerStatefulWidget {
  final GradeStudentRow student;
  final String groupId;

  const _StudentGradeRow({
    required this.student,
    required this.groupId,
  });

  @override
  ConsumerState<_StudentGradeRow> createState() => _StudentGradeRowState();
}

class _StudentGradeRowState extends ConsumerState<_StudentGradeRow> {
  int? _selectedGrade;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final todayGrade = widget.student.gradesByDate[todayKey];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: AlochiCard(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.brandSoft,
              child: Text(
                widget.student.name.isNotEmpty
                    ? widget.student.name[0].toUpperCase()
                    : '?',
                style: AppTextStyles.label.copyWith(color: AppColors.brand),
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            // Name + average
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.student.name, style: AppTextStyles.label),
                  Text(
                    'O\'rtacha: ${widget.student.average.toStringAsFixed(1)}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.brandMuted),
                  ),
                ],
              ),
            ),
            // Grade buttons: 2, 3, 4, 5
            Row(
              children: [2, 3, 4, 5].map((grade) {
                final isSelected = _selectedGrade == grade ||
                    (todayGrade == grade && _selectedGrade == null);
                return GestureDetector(
                  onTap: _saving ? null : () => _setGrade(grade, todayKey),
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? _gradeColor(grade) : AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(AppRadii.s),
                    ),
                    child: Center(
                      child: Text(
                        '$grade',
                        style: AppTextStyles.label.copyWith(
                          color: isSelected ? Colors.white : AppColors.brandMuted,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _gradeColor(int grade) {
    if (grade == 5) return AppColors.success;
    if (grade == 4) return AppColors.brand;
    if (grade == 3) return AppColors.warning;
    return AppColors.danger;
  }

  Future<void> _setGrade(int grade, String date) async {
    setState(() {
      _selectedGrade = grade;
      _saving = true;
    });
    try {
      final api = ref.read(teacherApiProvider);
      await api.setGrade(
        studentId: widget.student.id,
        grade: grade,
        date: date,
        groupId: widget.groupId,
      );
      ref.invalidate(gradesJournalProvider(widget.groupId));
    } catch (e) {
      if (mounted) {
        setState(() => _selectedGrade = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saqlashda xato'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                      height: 14, width: 140, color: const Color(0xFFF3F4F6)),
                  const SizedBox(height: 6),
                  Container(
                      height: 11, width: 100, color: const Color(0xFFF3F4F6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
