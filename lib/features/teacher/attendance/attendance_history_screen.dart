import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_card.dart';
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
              data: (data) => _HistoryBody(data: data),
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        child: Row(
          children: AttendancePeriod.values.map((p) {
            final isSelected = selected == p;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s),
              child: ChoiceChip(
                label: Text(_label(p)),
                selected: isSelected,
                onSelected: (v) {
                  if (v) onChanged(p);
                },
                backgroundColor: Colors.white,
                selectedColor: AppColors.brandSoft,
                labelStyle: AppTextStyles.label.copyWith(
                  color: isSelected ? AppColors.brand : AppColors.ink,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.round),
                  side: BorderSide(
                    color: isSelected ? AppColors.brand : const Color(0xFFE5E7EB),
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
      padding: const EdgeInsets.all(AppSpacing.l),
      children: [
        _SummaryCard(
          percent: data.summaryPercent,
          deltaPct: data.deltaPct,
          trend: data.trend,
        ),
        const SizedBox(height: AppSpacing.xl),
        _AttendanceChart(daily: data.daily),
        const SizedBox(height: AppSpacing.xl),
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
    final isUp = trend == 'up';
    final isDown = trend == 'down';

    return AlochiCard(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: AppTextStyles.displayL.copyWith(
                    color: percent >= 90
                        ? const Color(0xFF0F9A6E)
                        : percent >= 75
                            ? AppColors.brand
                            : AppColors.warning,
                  ),
                ),
                Text(
                  'O\'rtacha davomat',
                  style: AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted),
                ),
              ],
            ),
          ),
          if (deltaPct != 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isUp
                    ? const Color(0xFFE1F5EE)
                    : isDown
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(AppRadii.round),
              ),
              child: Row(
                children: [
                  Icon(
                    isUp
                        ? Icons.trending_up_rounded
                        : isDown
                            ? Icons.trending_down_rounded
                            : Icons.trending_flat_rounded,
                    size: 14,
                    color: isUp
                        ? const Color(0xFF0F9A6E)
                        : isDown
                            ? AppColors.danger
                            : AppColors.brandMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${deltaPct.toStringAsFixed(1)}%',
                    style: AppTextStyles.caption.copyWith(
                      color: isUp
                          ? const Color(0xFF0F9A6E)
                          : isDown
                              ? AppColors.danger
                              : AppColors.brandMuted,
                      fontWeight: FontWeight.w600,
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

class _AttendanceChart extends StatelessWidget {
  final List<DayAggregateModel> daily;

  const _AttendanceChart({required this.daily});

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) return const SizedBox.shrink();

    // Take last 7 days for the chart
    final displayDays = daily.length > 7 ? daily.sublist(daily.length - 7) : daily;

    final bars = displayDays.asMap().entries.map((entry) {
      final data = entry.value;
      final total = data.total;
      final rate = total > 0 ? (data.present + data.late) / total * 100 : 0.0;

      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: rate,

            color: rate >= 75
                ? AppColors.brand
                : rate >= 50
                    ? AppColors.warning
                    : AppColors.danger,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.xs)),
          ),
        ],
      );
    }).toList();

    return AlochiCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kunlik davomat (%)', style: AppTextStyles.titleM),
            const SizedBox(height: AppSpacing.l),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  barGroups: bars,
                  maxY: 100,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),

                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,

                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= displayDays.length) {
                            return const SizedBox.shrink();
                          }
                          final dateStr = displayDays[idx].date;
                          // Extract day from YYYY-MM-DD
                          final parts = dateStr.split('-');
                          final day = parts.length > 2 ? parts[2] : '';
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              day,
                              style: AppTextStyles.caption.copyWith(color: AppColors.brandMuted),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LowAttendanceSection extends StatelessWidget {
  final List<LowAttendanceStudentModel> students;

  const _LowAttendanceSection({required this.students});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Past davomatli o\'quvchilar', style: AppTextStyles.titleM),
        const SizedBox(height: AppSpacing.m),
        ...students.map((s) => _LowAttendanceRow(student: s)),
      ],
    );
  }
}

class _LowAttendanceRow extends StatelessWidget {
  final LowAttendanceStudentModel student;

  const _LowAttendanceRow({required this.student});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: AlochiCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 10),
        child: Row(
          children: [
            AlochiAvatar(name: student.name, size: 32),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text(
                student.name,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(AppRadii.xs),
              ),
              child: Text(
                '${student.attendancePct.toStringAsFixed(0)}%',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
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
