import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/colors.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../shared/widgets/alochi_skeleton.dart';
import '../../../shared/widgets/alochi_button.dart';
import '../../../core/api/parent_api.dart';

final _childDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  return ParentApi().getChildDetail(id);
});

class ChildDetailScreen extends ConsumerWidget {
  final String childId;
  const ChildDetailScreen({super.key, required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_childDetailProvider(childId));
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: const AlochiAppBar(
        title: 'Bola tafsilotlari',
        backgroundColor: AppColors.darkBg,
      ),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              AlochiSkeleton(height: 200),
              SizedBox(height: 16),
              AlochiSkeleton(height: 200),
            ],
          ),
        ),
        error: (e, _) => AlochiEmptyState(
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.danger,
          title: 'Yuklab bo\'lmadi',
          subtitle: e.toString(),
          actionLabel: "Qayta urinish",
          onAction: () => ref.invalidate(_childDetailProvider(childId)),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(_childDetailProvider(childId).future),
          color: AppColors.accent,
          backgroundColor: AppColors.darkSurface,
          child: _ChildDetail(data: data),
        ),
      ),
    );
  }
}

class _ChildDetail extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ChildDetail({required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['full_name'] as String? ??
        '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
    final xp = data['xp'] ?? 0;
    final level = data['level'] ?? 1;
    final xpToNext = data['xp_to_next_level'] ?? 1000;
    final streak = data['streak'] ?? 0;
    final avgScore = data['avg_score'] ?? 0;
    final testsCompleted = data['tests_completed'] ?? 0;
    final rank = data['rank'];
    final school = data['school'] as String?;
    final grade = data['grade'];

    final weeklyActivity =
        ((data['weekly_activity'] ?? []) as List).cast<Map<String, dynamic>>();
    final recentTests =
        ((data['recent_tests'] ?? []) as List).cast<Map<String, dynamic>>();
    final achievements =
        ((data['achievements'] ?? []) as List).cast<Map<String, dynamic>>();

    // Placeholder for 14-day attendance
    final attendanceData =
        List.generate(14, (i) => i % 5 != 0); // true = present, false = absent

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                AlochiAvatar(name: name, size: 80),
                const SizedBox(height: 12),
                Text(name,
                    style: const TextStyle(
                        color: AppColors.darkInk,
                        fontSize: 24,
                        fontWeight: FontWeight.w700)),
                if (school != null)
                  Text(school,
                      style: const TextStyle(color: AppColors.darkMuted)),
                if (grade != null)
                  Text('$grade-sinf',
                      style: const TextStyle(
                          color: AppColors.darkMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Chat button
          AlochiButton(
            label: 'Ustoz bilan muloqot',
            icon: Icons.chat_bubble_rounded,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Ustoz bilan chat ochilmoqda...")),
              );
            },
          ),
          const SizedBox(height: 16),

          // XP card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Daraja $level',
                        style: const TextStyle(
                            color: AppColors.darkInk,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    Text('$xp XP',
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: xpToNext > 0
                        ? ((xp % xpToNext) / xpToNext).clamp(0.0, 1.0)
                        : 0.0,
                    backgroundColor: AppColors.darkBorder,
                    color: AppColors.accent,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Keyingi darajaga: ${xpToNext - (xp % xpToNext)} XP',
                    style: const TextStyle(
                        color: AppColors.darkMuted, fontSize: 12)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat('Testlar', '$testsCompleted'),
                    _Stat(
                        "O'rtacha", '${(avgScore as num).toStringAsFixed(0)}%'),
                    _Stat('Seriya', '$streak'),
                    _Stat('Reyting', '#${rank ?? '-'}'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('14 kunlik davomat',
              style: TextStyle(
                  color: AppColors.darkInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(14, (i) {
                final isPresent = attendanceData[i];
                return Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isPresent
                            ? AppColors.success.withValues(alpha: 0.2)
                            : AppColors.danger.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isPresent
                                ? AppColors.success
                                : AppColors.danger,
                            width: 1),
                      ),
                      child: Icon(
                        isPresent ? Icons.check_rounded : Icons.close_rounded,
                        color: isPresent ? AppColors.success : AppColors.danger,
                        size: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${i + 1}',
                        style: const TextStyle(
                            color: AppColors.darkMuted, fontSize: 10)),
                  ],
                );
              }),
            ),
          ),

          // Weekly activity chart
          if (weeklyActivity.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Haftalik faollik',
                style: TextStyle(
                    color: AppColors.darkInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              height: 160,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = [
                            'Du',
                            'Se',
                            'Ch',
                            'Pa',
                            'Ju',
                            'Sh',
                            'Ya'
                          ];
                          final idx = value.toInt();
                          if (idx < 0 || idx >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(days[idx],
                              style: const TextStyle(
                                  color: AppColors.darkMuted, fontSize: 11));
                        },
                      ),
                    ),
                  ),
                  barGroups: weeklyActivity
                      .asMap()
                      .entries
                      .map((e) => BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: (e.value['xp'] as num?)?.toDouble() ?? 0,
                                color: AppColors.accent,
                                width: 20,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                              ),
                            ],
                          ))
                      .toList(),
                ),
              ),
            ),
          ],

          // Recent tests
          if (recentTests.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text("So'nggi natijalar",
                style: TextStyle(
                    color: AppColors.darkInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...recentTests.take(5).map((t) {
              final score = t['score'] as int? ?? 0;
              final color = score >= 90
                  ? AppColors.success
                  : score >= 60
                      ? AppColors.warning
                      : AppColors.danger;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t['test_title'] as String? ?? 'Test',
                              style: const TextStyle(
                                  color: AppColors.darkInk,
                                  fontWeight: FontWeight.w600)),
                          Text(t['completed_at'] as String? ?? '',
                              style: const TextStyle(
                                  color: AppColors.darkMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$score%',
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Achievements
          if (achievements.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Yutuqlar',
                style: TextStyle(
                    color: AppColors.darkInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: achievements.map((a) {
                final unlocked = a['is_unlocked'] as bool? ?? false;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: unlocked
                            ? AppColors.accent.withValues(alpha: 0.4)
                            : AppColors.darkBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events_rounded,
                          color:
                              unlocked ? AppColors.accent : AppColors.darkMuted,
                          size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(a['name'] as String? ?? '',
                            style: TextStyle(
                                color: unlocked
                                    ? AppColors.darkInk
                                    : AppColors.darkMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: AppColors.darkInk,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        Text(label,
            style: const TextStyle(color: AppColors.darkMuted, fontSize: 11)),
      ],
    );
  }
}
