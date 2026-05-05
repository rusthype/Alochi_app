import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../shared/widgets/alochi_button.dart';
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
            _AttendanceLineChart(days: student.recentAttendance),
            const SizedBox(height: AppSpacing.l),
          ],
          if (student.recentGrades.isNotEmpty) ...[
            _RecentGradesList(grades: student.recentGrades),
            const SizedBox(height: AppSpacing.l),
          ],
          _HomeworkSummaryCard(student: student),
          const SizedBox(height: AppSpacing.xxl),
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
                style: AppTextStyles.displayM.copyWith(
                    color: AppColors.ink, fontWeight: FontWeight.w700),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  parent.name,
                  style: AppTextStyles.body.copyWith(color: AppColors.ink),
                ),
                Text(
                  parent.relation == 'father' ? 'Otasi' : 'Onasi',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.brandMuted),
                ),
              ],
            ),
          ),
          // Phone button
          if (parent.phone != null && parent.phone!.isNotEmpty)
            GestureDetector(
              onTap: () {
                // tel:// intent — no url_launcher dep, just show intent
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Telefon: ${parent.phone}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(AppRadii.s),
                ),
                child: const Icon(Icons.phone_outlined,
                    size: 16, color: AppColors.brandMuted),
              ),
            ),
          const SizedBox(width: AppSpacing.s),
          // Message/Telegram button
          GestureDetector(
            onTap: () => context.push('/teacher/messages'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: parent.telegramLinked
                    ? const Color(0xFFE3F2FD)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(AppRadii.s),
              ),
              child: Icon(
                Icons.chat_outlined,
                size: 16,
                color: parent.telegramLinked
                    ? const Color(0xFF26A5E4)
                    : const Color(0xFF9CA3AF),
              ),
            ),
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

// ─── Attendance line chart (fl_chart) ────────────────────────────────────────

class _AttendanceLineChart extends StatelessWidget {
  final List<AttendanceDayModel> days;

  const _AttendanceLineChart({required this.days});

  @override
  Widget build(BuildContext context) {
    // Build rolling present-rate per day (1 = present, 0.5 = late, 0 = absent)
    final spots = <FlSpot>[];
    for (int i = 0; i < days.length; i++) {
      double val;
      switch (days[i].status) {
        case 'present':
          val = 1.0;
          break;
        case 'late':
          val = 0.5;
          break;
        case 'absent':
          val = 0.0;
          break;
        default:
          continue;
      }
      spots.add(FlSpot(i.toDouble(), val));
    }

    if (spots.isEmpty) return const SizedBox.shrink();

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
          Text("Davomat grafigi",
              style: AppTextStyles.titleM.copyWith(color: AppColors.ink)),
          const SizedBox(height: AppSpacing.m),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.brand,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.brand.withValues(alpha: 0.08),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Homework summary ─────────────────────────────────────────────────────────

class _HomeworkSummaryCard extends StatelessWidget {
  final StudentModel student;

  const _HomeworkSummaryCard({required this.student});

  @override
  Widget build(BuildContext context) {
    // Derive summary from recent grades as a proxy (grades ≈ submitted homework)
    final gradedCount = student.recentGrades.length;
    final att = student.attendancePct;
    final avg = student.avgGrade;

    if (gradedCount == 0 && att == null && avg == null) {
      return const SizedBox.shrink();
    }

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
          Row(
            children: [
              const Icon(Icons.assignment_outlined,
                  size: 18, color: AppColors.brand),
              const SizedBox(width: AppSpacing.s),
              Text("Vazifalar holati",
                  style: AppTextStyles.titleM.copyWith(color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          if (gradedCount > 0)
            _SummaryRow(
              label: "Baholangan",
              value: "$gradedCount ta",
              valueColor: AppColors.success,
            ),
          if (att != null)
            _SummaryRow(
              label: "Davomat",
              value: "${att.toStringAsFixed(0)}%",
              valueColor: att >= 75 ? AppColors.success : AppColors.warning,
            ),
          if (avg != null)
            _SummaryRow(
              label: "O'rtacha baho",
              value: avg.toStringAsFixed(1),
              valueColor: avg >= 3.5 ? AppColors.success : AppColors.warning,
            ),
          const SizedBox(height: AppSpacing.m),
          AlochiButton.secondary(
            label: "Xabar yuborish",
            icon: Icons.chat_outlined,
            onPressed: () => context.push('/teacher/messages'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.body.copyWith(color: AppColors.brandMuted)),
          Text(value,
              style: AppTextStyles.body
                  .copyWith(color: valueColor, fontWeight: FontWeight.w600)),
        ],
      ),
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
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.topicTitle,
                          style:
                              AppTextStyles.body.copyWith(color: AppColors.ink),
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
