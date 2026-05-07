import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
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
import '../../../shared/widgets/alochi_skeleton.dart';
import '../../../core/models/group_model.dart';
import '../../../core/models/student_model.dart';
import '../../../core/models/group_analytics.dart';
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
                style: AppTextStyles.caption.copyWith(color: AppColors.gray),
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
            unselectedLabelColor: AppColors.gray,
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
                _AttendanceTab(groupId: widget.groupId),
                _GradesJournalBody(groupId: widget.groupId),
                _AnalyticsTab(groupId: widget.groupId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsTab extends ConsumerWidget {
  final String groupId;

  const _AnalyticsTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(groupAnalyticsProvider(groupId));

    return analyticsAsync.when(
      data: (analytics) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          children: [
            _SummaryStatsGrid(analytics: analytics),
            const SizedBox(height: AppSpacing.l),
            _AttendanceBarChart(
              title: 'DAVOMAT TRENDI (4 HAFTA)',
              points: analytics.attendanceTrend,
            ),
            const SizedBox(height: AppSpacing.l),
            _GradeLineChart(
              title: 'O\'RTACHA BAHO TRENDI (4 HAFTA)',
              points: analytics.gradeTrend,
            ),
            const SizedBox(height: AppSpacing.l),
            _RankingsSection(
              topStudents: analytics.topStudents,
              lowAttendanceStudents: analytics.lowAttendanceStudents,
            ),
          ],
        ),
      ),
      loading: () => const _AnalyticsLoadingSkeleton(),
      error: (err, _) => Center(
        child: AlochiEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Yuklab bo\'lmadi',
          subtitle: err.toString(),
          actionLabel: 'Qayta urinish',
          onAction: () => ref.refresh(groupAnalyticsProvider(groupId)),
        ),
      ),
    );
  }
}

class _SummaryStatsGrid extends StatelessWidget {
  final GroupAnalyticsModel analytics;

  const _SummaryStatsGrid({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final latestGrade =
        analytics.gradeTrend.isNotEmpty ? analytics.gradeTrend.last.value : 0.0;
    final gradeColor = latestGrade >= 4.5
        ? AppColors.success
        : (latestGrade >= 4.0 ? AppColors.brand : AppColors.warning);

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Bugungi o\'rtacha',
            value: latestGrade > 0 ? latestGrade.toStringAsFixed(1) : '--',
            valueColor: gradeColor,
            subtitle: 'Baholar o\'rtachasi',
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: _MetricCard(
            label: 'Davomat',
            value: analytics.attendanceTrend.isNotEmpty
                ? '${analytics.attendanceTrend.last.value.toInt()}%'
                : '--',
            valueColor: AppColors.ink,
            subtitle: 'Oxirgi hafta',
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String subtitle;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.caption.copyWith(color: AppColors.gray)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.displayM.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle,
              style: AppTextStyles.caption.copyWith(color: AppColors.gray2)),
        ],
      ),
    );
  }
}

class _AttendanceBarChart extends StatelessWidget {
  final String title;
  final List<ChartPointModel> points;

  const _AttendanceBarChart({required this.title, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray2,
                  letterSpacing: 0.5,
                ),
              ),
              _TrendBadge(points: points),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.gray2),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          points[index].label.split('-').last,
                          style: const TextStyle(
                              fontSize: 9, color: AppColors.gray2),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                barGroups: points.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value,
                        color: e.value.value < 75
                            ? AppColors.warning
                            : AppColors.success,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeLineChart extends StatelessWidget {
  final String title;
  final List<ChartPointModel> points;

  const _GradeLineChart({required this.title, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.gray2,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.gray2),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          points[index].label.split('-').last,
                          style: const TextStyle(
                              fontSize: 9, color: AppColors.gray2),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (points.length - 1).toDouble(),
                minY: 2,
                maxY: 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: points.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.value);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.brand,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: AppColors.brand,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.brand.withValues(alpha: 0.1),
                    ),
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

class _TrendBadge extends StatelessWidget {
  final List<ChartPointModel> points;

  const _TrendBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();
    final latest = points.last.value;
    final previous = points[points.length - 2].value;
    final isUp = latest >= previous;
    final color = isUp ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '${(latest - previous).abs().toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingsSection extends StatelessWidget {
  final List<TopStudentModel> topStudents;
  final List<LowAttendanceStudentModel> lowAttendanceStudents;

  const _RankingsSection({
    required this.topStudents,
    required this.lowAttendanceStudents,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (topStudents.isNotEmpty) ...[
          _RankingCard(
            title: 'ENG FAOL 3 O\'QUVCHI',
            icon: Icons.emoji_events_rounded,
            iconColor: AppColors.warning,
            items: topStudents
                .take(3)
                .map((s) => _RankingItem(
                      name: s.name,
                      value: '${s.xp} XP',
                      subValue: '${s.level}-daraja',
                      level: s.level,
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.l),
        ],
        if (lowAttendanceStudents.isNotEmpty)
          _RankingCard(
            title: 'DIQQAT TALAB (PAST DAVOMAT)',
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.danger,
            items: lowAttendanceStudents
                .map((s) => _RankingItem(
                      name: s.name,
                      value: '${s.attendancePct.toStringAsFixed(0)}%',
                      subValue: '${s.missedLessons} kun qoldirgan',
                      valueColor: AppColors.danger,
                      showAction: true,
                      onAction: () {
                        // messages compose screen logic would go here
                      },
                    ))
                .toList(),
          ),
      ],
    );
  }
}

class _RankingCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<_RankingItem> items;

  const _RankingCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray2,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          ...items,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RankingItem extends StatelessWidget {
  final String name;
  final String value;
  final String subValue;
  final Color? valueColor;
  final int? level;
  final bool showAction;
  final VoidCallback? onAction;

  const _RankingItem({
    required this.name,
    required this.value,
    required this.subValue,
    this.valueColor,
    this.level,
    this.showAction = false,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          AlochiAvatar(name: name, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.titleM.copyWith(
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  subValue,
                  style: AppTextStyles.caption.copyWith(color: AppColors.gray2),
                ),
              ],
            ),
          ),
          if (showAction)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.brand.withValues(alpha: 0.1),
                foregroundColor: AppColors.brand,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Yozish',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            )
          else
            Text(
              value,
              style: AppTextStyles.titleM.copyWith(
                color: valueColor ?? AppColors.brand,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _AnalyticsLoadingSkeleton extends StatelessWidget {
  const _AnalyticsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.l),
      children: const [
        AlochiSkeleton(
            height: 100, borderRadius: BorderRadius.all(Radius.circular(16))),
        SizedBox(height: AppSpacing.l),
        AlochiSkeleton(
            height: 180, borderRadius: BorderRadius.all(Radius.circular(16))),
        SizedBox(height: AppSpacing.l),
        AlochiSkeleton(
            height: 180, borderRadius: BorderRadius.all(Radius.circular(16))),
        SizedBox(height: AppSpacing.l),
        AlochiSkeleton(
            height: 240, borderRadius: BorderRadius.all(Radius.circular(16))),
      ],
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
              value: "28/32",
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
              value: '87%',
              valueColor: AppColors.success,
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
        color: AppColors.lineSoft,
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
              color: AppColors.gray,
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
                    color: AppColors.lineSoft,
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
                      color: isLowAtt ? AppColors.warning : AppColors.gray,
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

class _AttendanceTab extends ConsumerWidget {
  final String groupId;

  const _AttendanceTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupName =
        ref.watch(groupDetailProvider(groupId)).valueOrNull?.code ?? '';
    final now = DateTime.now();
    final today =
        // ignore: prefer_interpolation_to_compose_strings
        now.year.toString() +
            '-' +
            now.month.toString().padLeft(2, '0') +
            '-' +
            now.day.toString().padLeft(2, '0');

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
              context.push(
                '/teacher/lesson/$groupId/attendance',
                extra: {
                  'classId': groupId,
                  'date': today,
                  'groupName': groupName,
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

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
      loading: () => const _GradesJournalLoadingSkeleton(),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          AlochiAvatar(name: widget.student.name, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.student.name,
                  style: AppTextStyles.titleM.copyWith(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'O\'rtacha: ${widget.student.average.toStringAsFixed(1)}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
          Row(
            children: [2, 3, 4, 5].map((grade) {
              final isSelected = _selectedGrade == grade ||
                  (todayGrade == grade && _selectedGrade == null);
              return GestureDetector(
                onTap: _saving ? null : () => _setGrade(grade, todayKey),
                child: Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? _gradeColor(grade) : AppColors.lineSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$grade',
                      style: AppTextStyles.label.copyWith(
                        color: isSelected ? Colors.white : AppColors.gray2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
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
      // Also refresh stats row and student list
      ref.invalidate(groupDetailProvider(widget.groupId));
      ref.invalidate(groupStudentsProvider(widget.groupId));
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

class _GradesJournalLoadingSkeleton extends StatelessWidget {
  const _GradesJournalLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.l),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s),
        child: AlochiSkeleton(
          height: 58,
          width: double.infinity,
          borderRadius: BorderRadius.circular(12),
        ),
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
          const Divider(height: 1, color: AppColors.lineSoft),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.lineSoft,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 140, color: AppColors.lineSoft),
                  const SizedBox(height: 6),
                  Container(height: 11, width: 100, color: AppColors.lineSoft),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
