import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
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
  String _selectedPeriod = 'month';

  @override
  Widget build(BuildContext context) {
    final key = (classId: widget.groupId, period: _selectedPeriod);
    final historyAsync = ref.watch(attendanceHistoryProvider(key));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AlochiAppBar(title: 'Davomat tarixi'),
      body: Column(
        children: [
          _PeriodChips(
            selected: _selectedPeriod,
            onSelected: (p) => setState(() => _selectedPeriod = p),
          ),
          Expanded(
            child: historyAsync.when(
              data: (history) => _HistoryBody(
                history: history,
                groupId: widget.groupId,
                period: _selectedPeriod,
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              ),
              error: (err, _) => AlochiEmptyState(
                title: "Ma'lumot topilmadi",
                subtitle: err.toString(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _PeriodChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('week', 'Hafta'),
      ('month', 'Oy'),
      ('quarter', 'Chorak'),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l, vertical: AppSpacing.s),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt.$1 == selected;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s),
            child: GestureDetector(
              onTap: () => onSelected(opt.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.l, vertical: AppSpacing.s),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brandSoft : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(AppRadii.round),
                ),
                child: Text(
                  opt.$2,
                  style: AppTextStyles.label.copyWith(
                    color: isSelected ? AppColors.brand : AppColors.brandMuted,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HistoryBody extends ConsumerWidget {
  final AttendanceHistoryModel history;
  final String groupId;
  final String period;

  const _HistoryBody({
    required this.history,
    required this.groupId,
    required this.period,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: () async {
        final key = (classId: groupId, period: period);
        ref.invalidate(attendanceHistoryProvider(key));
        await ref.read(attendanceHistoryProvider(key).future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryCard(history: history),
            const SizedBox(height: AppSpacing.l),
            if (history.lowAttendanceStudents.isNotEmpty) ...[
              _LowAttendanceCard(students: history.lowAttendanceStudents),
              const SizedBox(height: AppSpacing.l),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final AttendanceHistoryModel history;

  const _SummaryCard({required this.history});

  Color _pctColor(double pct) {
    if (pct >= 90) return const Color(0xFF0F9A6E);
    if (pct >= 75) return AppColors.brand;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final color = _pctColor(history.summaryPercent);
    final trendIcon = history.trend == 'up'
        ? Icons.trending_up_rounded
        : history.trend == 'down'
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;
    final trendColor = history.trend == 'up'
        ? const Color(0xFF0F9A6E)
        : history.trend == 'down'
            ? AppColors.danger
            : AppColors.brandMuted;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${history.summaryPercent.toStringAsFixed(1)}%',
                    style: AppTextStyles.displayM.copyWith(
                        color: color, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Umumiy davomat',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.brandMuted),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(trendIcon, color: trendColor, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${history.deltaPct.abs().toStringAsFixed(1)}%',
                    style: AppTextStyles.label.copyWith(color: trendColor),
                  ),
                ],
              ),
            ],
          ),
          if (history.daily.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.l),
            _MiniBarChart(days: history.daily),
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                _Legend(color: const Color(0xFF0F9A6E), label: 'Keldi'),
                const SizedBox(width: AppSpacing.l),
                _Legend(color: const Color(0xFFD97706), label: 'Kech'),
                const SizedBox(width: AppSpacing.l),
                _Legend(color: AppColors.danger, label: "Yo'q"),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  final List<DayAggregateModel> days;

  const _MiniBarChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((day) {
          if (!day.isLessonDay || day.total == 0) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
              ),
            );
          }
          final date = DateTime.tryParse(day.date);
          final isToday = date != null &&
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;

          final presentH = (day.present / day.total * 50).clamp(0.0, 50.0);
          final lateH = (day.late / day.total * 50).clamp(0.0, 50.0);
          final absentH = (day.absent / day.total * 50).clamp(0.0, 50.0);

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isToday)
                  Text(
                    'Bugun',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.brand,
                        fontSize: 8),
                    overflow: TextOverflow.visible,
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (absentH > 0)
                      Container(
                        height: absentH,
                        color: AppColors.danger,
                      ),
                    if (lateH > 0)
                      Container(
                        height: lateH,
                        color: const Color(0xFFD97706),
                      ),
                    if (presentH > 0)
                      Container(
                        height: presentH,
                        color: const Color(0xFF0F9A6E),
                      ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LowAttendanceCard extends StatelessWidget {
  final List<LowAttendanceStudentModel> students;

  const _LowAttendanceCard({required this.students});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: const Color(0xFFFCEBEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCEBEB),
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: AppColors.danger, size: 16),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Past davomatli o\'quvchilar',
                style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          ...students.take(5).map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(s.name,
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.ink)),
                      ),
                      Text(
                        '${s.attendancePct.toStringAsFixed(0)}%',
                        style: AppTextStyles.body.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
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
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.brandMuted)),
      ],
    );
  }
}
