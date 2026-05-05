import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/alochi_avatar.dart';
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
      backgroundColor: kBgMain,
      appBar: AppBar(title: const Text('Bola tafsilotlari')),
      body: async.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(
            child: Text('Xatolik: $e', style: const TextStyle(color: kRed))),
        data: (data) => _ChildDetail(data: data),
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

    return SingleChildScrollView(
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
                        color: kTextPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700)),
                if (school != null)
                  Text(school, style: const TextStyle(color: kTextSecondary)),
                if (grade != null)
                  Text('$grade-sinf',
                      style: const TextStyle(color: kTextMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // XP card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBgBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Daraja $level',
                        style: const TextStyle(
                            color: kTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    Text('$xp XP',
                        style: const TextStyle(
                            color: kOrange,
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
                    backgroundColor: kBgBorder,
                    color: kOrange,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Keyingi darajaga: ${xpToNext - (xp % xpToNext)} XP',
                    style: const TextStyle(color: kTextMuted, fontSize: 12)),
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

          // Weekly activity chart
          if (weeklyActivity.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Haftalik faollik',
                style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              height: 160,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBgBorder),
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
                                  color: kTextMuted, fontSize: 11));
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
                                color: kOrange,
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
                    color: kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...recentTests.take(5).map((t) {
              final score = t['score'] as int? ?? 0;
              final color = scoreColor(score);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: kBgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBgBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t['test_title'] as String? ?? 'Test',
                              style: const TextStyle(
                                  color: kTextPrimary,
                                  fontWeight: FontWeight.w600)),
                          Text(t['completed_at'] as String? ?? '',
                              style: const TextStyle(
                                  color: kTextMuted, fontSize: 12)),
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
                    color: kTextPrimary,
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
                    color: kBgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: unlocked
                            ? kOrange.withValues(alpha: 0.4)
                            : kBgBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events_rounded,
                          color: unlocked ? kOrange : kTextMuted, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(a['name'] as String? ?? '',
                            style: TextStyle(
                                color: unlocked ? kTextPrimary : kTextMuted,
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
                color: kTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        Text(label, style: const TextStyle(color: kTextMuted, fontSize: 11)),
      ],
    );
  }
}
