import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_skeleton.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../core/models/attendance_model.dart';
import 'attendance_provider.dart';

class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  final String groupId;

  const AttendanceHistoryScreen({super.key, required this.groupId});

  @override
  ConsumerState<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends ConsumerState<AttendanceHistoryScreen> {
  AttendancePeriod _period = AttendancePeriod.week;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(attendanceHistoryProvider((
      classId: widget.groupId,
      period: _period.name,
    )));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AlochiAppBar(title: 'Davomat tarixi'),
      body: Column(
        children: [
          _PeriodSelector(
            selected: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          Expanded(
            child: historyAsync.when(
              data: (data) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(attendanceHistoryProvider);
                  await ref.read(attendanceHistoryProvider((
                    classId: widget.groupId,
                    period: _period.name,
                  )).future);
                },
                color: AppColors.brand,
                child: _HistoryBody(data: data),
              ),
              loading: () => const _HistoryLoadingSkeleton(),
              error: (err, _) => AlochiEmptyState(
                icon: Icons.error_outline_rounded,
                iconColor: AppColors.danger,
                title: 'Yuklab bo\'lmadi',
                subtitle: 'Internetni tekshirib qayta urinib ko\'ring',
                actionLabel: 'Yangilash',
                onAction: () => ref.invalidate(attendanceHistoryProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final AttendancePeriod selected;
  final ValueChanged<AttendancePeriod> onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: AttendancePeriod.values.map((p) {
            final isSelected = selected == p;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_label(p)),
                selected: isSelected,
                onSelected: (v) {
                  if (v) onChanged(p);
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
    );
  }

  String _label(AttendancePeriod p) {
    switch (p) {
      case AttendancePeriod.week:
        return 'Hafta';
      case AttendancePeriod.month:
        return 'Oy';
      case AttendancePeriod.quarter:
        return 'Chorak';
    }
  }
}

class _HistoryBody extends StatelessWidget {
  final AttendanceHistoryModel data;

  const _HistoryBody({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(14),
      children: [
        _SummaryCard(
          percent: data.summaryPercent,
          deltaPct: data.deltaPct,
          trend: data.trend,
        ),
        const SizedBox(height: 14),
        _AttendanceChartCard(daily: data.daily),
        const SizedBox(height: 24),
        if (data.lowAttendanceStudents.isNotEmpty)
          _LowAttendanceSection(students: data.lowAttendanceStudents),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double percent;
  final double deltaPct;
  final String trend;

  const _SummaryCard({
    required this.percent,
    required this.deltaPct,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final isGood = percent >= 90;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${percent.toStringAsFixed(0)}%',
                      style: AppTextStyles.displayL.copyWith(
                        fontWeight: FontWeight.w700,
                        color:
                            isGood ? const Color(0xFF0F9A6E) : AppColors.brand,
                      ),
                    ),
                    Text(
                      'Haftalik davomat',
                      style: AppTextStyles.caption
                          .copyWith(color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              if (deltaPct != 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5EE),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.north_rounded,
                          size: 12, color: Color(0xFF0F9A6E)),
                      const SizedBox(width: 2),
                      Text(
                        '${deltaPct.toStringAsFixed(1)}%',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF0F9A6E),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              _LegendDot(color: Color(0xFF0F9A6E), label: 'Keldi'),
              SizedBox(width: 12),
              _LegendDot(color: Color(0xFFD97706), label: 'Kech'),
              SizedBox(width: 12),
              _LegendDot(color: Color(0xFFDC2626), label: "Yo'q"),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
                AppTextStyles.caption.copyWith(color: const Color(0xFF6B7280))),
      ],
    );
  }
}

class _AttendanceChartCard extends StatelessWidget {
  final List<DayAggregateModel> daily;

  const _AttendanceChartCard({required this.daily});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KUNLIK DAVOMAT',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9CA3AF),
                letterSpacing: 0.5,
              )),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: daily.map((d) => _BarItem(data: d)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final DayAggregateModel data;

  const _BarItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.total;
    if (total == 0) return const SizedBox(width: 14); // Holiday

    final presentH = (data.present / total) * 100;
    final lateH = (data.late / total) * 100;
    final absentH = (data.absent / total) * 100;

    return Column(
      children: [
        Expanded(
          child: Container(
            width: 14,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (absentH > 0)
                  Container(
                      height: absentH * 1.4, color: const Color(0xFFDC2626)),
                if (lateH > 0)
                  Container(
                      height: lateH * 1.4, color: const Color(0xFFD97706)),
                if (presentH > 0)
                  Container(
                    height: presentH * 1.4,
                    color: const Color(0xFF0F9A6E),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          data.date.split('-').last,
          style: AppTextStyles.caption
              .copyWith(color: const Color(0xFF9CA3AF)),
        ),
      ],
    );
  }
}

class _LowAttendanceSection extends StatelessWidget {
  final List<LowAttendanceStudentModel> students;

  const _LowAttendanceSection({required this.students});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCEBEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEBEB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.priority_high_rounded,
                      size: 16, color: Color(0xFFDC2626)),
                ),
                const SizedBox(width: 12),
                Text(
                  'Past davomatli o\'quvchilar',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          ...students.map((s) => _LowAttendanceRow(student: s)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LowAttendanceRow extends StatelessWidget {
  final LowAttendanceStudentModel student;

  const _LowAttendanceRow({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF4F5F7))),
      ),
      child: Row(
        children: [
          AlochiAvatar(name: student.name, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: AppTextStyles.titleM,
                ),
                Text(
                  "${student.missedLessons} kun qoldirgan",
                  style: AppTextStyles.caption
                      .copyWith(color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Text(
            '${student.attendancePct.toStringAsFixed(0)}%',
            style: AppTextStyles.body.copyWith(
              color: const Color(0xFFDC2626),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryLoadingSkeleton extends StatelessWidget {
  const _HistoryLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.l),
      children: const [
        AlochiSkeletonCard(height: 100),
        SizedBox(height: AppSpacing.xl),
        AlochiSkeletonCard(height: 200),
        SizedBox(height: AppSpacing.xl),
        AlochiSkeletonCard(height: 60),
        AlochiSkeletonCard(height: 60),
      ],
    );
  }
}
