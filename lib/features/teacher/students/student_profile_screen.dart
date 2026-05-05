import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../shared/widgets/alochi_pill.dart';
import '../../../shared/widgets/alochi_grade_badge.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../core/models/student_model.dart';
import 'student_provider.dart';

class StudentProfileScreen extends ConsumerWidget {
  final String studentId;

  const StudentProfileScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentProfileProvider(studentId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AlochiAppBar(
        title: '',
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, color: AppColors.ink),
            onPressed: () {},
          ),
        ],
      ),
      body: studentAsync.when(
        data: (student) => _StudentProfileBody(student: student),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
        error: (err, _) => AlochiEmptyState(
          title: "Ma'lumot topilmadi",
          subtitle: err.toString(),
        ),
      ),
    );
  }
}

class _StudentProfileBody extends StatelessWidget {
  final StudentModel student;

  const _StudentProfileBody({required this.student});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroSection(student: student),
          const SizedBox(height: AppSpacing.l),
          _ThreeStatTiles(student: student),
          const SizedBox(height: AppSpacing.l),
          if (student.parents.isNotEmpty) ...[
            _ParentContactCard(parents: student.parents),
            const SizedBox(height: AppSpacing.l),
          ],
          if (student.recentAttendance.isNotEmpty) ...[
            _AttendanceCalendar(days: student.recentAttendance),
            const SizedBox(height: AppSpacing.l),
          ],
          if (student.recentGrades.isNotEmpty) ...[
            _RecentGradesList(grades: student.recentGrades),
            const SizedBox(height: AppSpacing.l),
          ],
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final StudentModel student;

  const _HeroSection({required this.student});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AlochiAvatar(name: student.fullName, size: 64),
        const SizedBox(width: AppSpacing.l),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.fullName,
                style: AppTextStyles.displayM
                    .copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              if (student.needsAttention)
                const AlochiPill(
                    label: 'Diqqat talab', variant: AlochiPillVariant.warning),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThreeStatTiles extends StatelessWidget {
  final StudentModel student;

  const _ThreeStatTiles({required this.student});

  @override
  Widget build(BuildContext context) {
    final att = student.attendancePct;
    final avg = student.avgGrade;

    Color attColor = AppColors.success;
    if (att != null && att < 75) attColor = AppColors.warning;
    if (att != null && att < 60) attColor = AppColors.danger;

    Color avgColor = AppColors.success;
    if (avg != null && avg < 3.5) avgColor = AppColors.warning;
    if (avg != null && avg < 2.5) avgColor = AppColors.danger;

    return Row(
      children: [
        _StatTile(
          icon: Icons.calendar_today_rounded,
          label: 'Davomat',
          value: att != null ? '${att.toStringAsFixed(0)}%' : '-',
          valueColor: attColor,
        ),
        const SizedBox(width: AppSpacing.m),
        _StatTile(
          icon: Icons.grade_rounded,
          label: "O'rtacha",
          value: avg != null ? avg.toStringAsFixed(1) : '-',
          valueColor: avgColor,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.l),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon, color: valueColor, size: 20),
            const SizedBox(width: AppSpacing.s),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.titleM.copyWith(color: valueColor),
                ),
                Text(
                  label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.brandMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentContactCard extends StatelessWidget {
  final List<ParentModel> parents;

  const _ParentContactCard({required this.parents});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Ota-ona kontakti",
              style: AppTextStyles.titleM.copyWith(color: AppColors.ink)),
          const SizedBox(height: AppSpacing.m),
          ...parents.map((p) => _ParentRow(parent: p)),
        ],
      ),
    );
  }
}

class _ParentRow extends StatelessWidget {
  final ParentModel parent;

  const _ParentRow({required this.parent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        children: [
          Icon(
            parent.relation == 'father'
                ? Icons.person_rounded
                : Icons.person_outline_rounded,
            color: AppColors.brandMuted,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              parent.name,
              style: AppTextStyles.body.copyWith(color: AppColors.ink),
            ),
          ),
          Icon(
            Icons.send_rounded,
            size: 18,
            color: parent.telegramLinked
                ? const Color(0xFF26A5E4)
                : const Color(0xFF9CA3AF),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCalendar extends StatelessWidget {
  final List<AttendanceDayModel> days;

  const _AttendanceCalendar({required this.days});

  Color _tileColor(String status) {
    switch (status) {
      case 'present':
        return const Color(0xFFE1F5EE);
      case 'late':
        return const Color(0xFFFAEEDA);
      case 'absent':
        return const Color(0xFFFCEBEB);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("So'nggi davomat",
              style: AppTextStyles.titleM.copyWith(color: AppColors.ink)),
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: days.map((day) {
              final date = DateTime.tryParse(day.date);
              final isToday = date != null &&
                  date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _tileColor(day.status),
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                  border: isToday
                      ? Border.all(color: AppColors.brand, width: 2)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  date != null ? date.day.toString() : '',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: day.status == 'no_lesson'
                        ? AppColors.brandMuted
                        : AppColors.ink,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            children: [
              _Legend(color: const Color(0xFFE1F5EE), label: 'Keldi'),
              const SizedBox(width: AppSpacing.l),
              _Legend(color: const Color(0xFFFAEEDA), label: 'Kech'),
              const SizedBox(width: AppSpacing.l),
              _Legend(color: const Color(0xFFFCEBEB), label: "Yo'q"),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.caption.copyWith(color: AppColors.brandMuted)),
      ],
    );
  }
}

class _RecentGradesList extends StatelessWidget {
  final List<RecentGradeModel> grades;

  const _RecentGradesList({required this.grades});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("So'nggi baholar",
              style: AppTextStyles.titleM.copyWith(color: AppColors.ink)),
          const SizedBox(height: AppSpacing.m),
          ...grades.map(
            (g) => Padding(
              padding:
                  const EdgeInsets.only(bottom: AppSpacing.s),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.topicTitle,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          g.date,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.brandMuted),
                        ),
                      ],
                    ),
                  ),
                  AlochiGradeBadge(value: g.value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
