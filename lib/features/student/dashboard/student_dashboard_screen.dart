import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/score_cell.dart';
import '../../../core/api/student_api.dart';
import '../../auth/auth_provider.dart';

final _dashboardProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final api = StudentApi();
  final profile = await api.getProfile();
  // Fetch coins from separate endpoint
  try {
    final wallet = await api.getWallet();
    final coins = wallet['balance'] ?? wallet['coins'] ?? 0;
    return {...profile, 'coins': coins};
  } catch (_) {
    return profile;
  }
});

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(_dashboardProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: kBgMain,
      body: dashAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) =>
            Center(child: Text('Xatolik: $e', style: const TextStyle(color: kRed))),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(_dashboardProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(data: data, userName: user?.firstName ?? ''),
                const SizedBox(height: 20),
                _StatsRow(data: data),
                const SizedBox(height: 20),
                const _QuickActions(),
                const SizedBox(height: 20),
                _WeeklyChart(data: data),
                const SizedBox(height: 20),
                _RecentResults(data: data),
                if (data['daily_challenge'] != null) ...[
                  const SizedBox(height: 20),
                  _DailyChallengeCard(
                      data: data['daily_challenge'] as Map<String, dynamic>),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Map<String, dynamic> data;
  final String userName;
  const _Header({required this.data, required this.userName});

  @override
  Widget build(BuildContext context) {
    final xp = data['total_xp'] ?? data['xp'] ?? 0;
    final level = data['level'] ?? 1;
    final xpToNext = data['xp_to_next_level'] ?? 1000;
    final progress = xpToNext > 0 ? ((xp % xpToNext) / xpToNext).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Salom, $userName!',
                      style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700)),
                  Text('Daraja $level',
                      style: const TextStyle(
                          color: kTextSecondary, fontSize: 14)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kOrange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kOrange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, color: kOrange, size: 16),
                  const SizedBox(width: 4),
                  Text('$xp XP',
                      style: const TextStyle(
                          color: kOrange,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.toDouble(),
            backgroundColor: kBgBorder,
            color: kOrange,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
            'Keyingi darajaga: ${(xpToNext - (xp % xpToNext)).toInt()} XP',
            style: const TextStyle(color: kTextMuted, fontSize: 12)),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _StatsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        StatCard(
            icon: Icons.bolt_rounded,
            label: 'XP',
            value: '${data['total_xp'] ?? data['xp'] ?? 0}',
            color: kOrange),
        StatCard(
            icon: Icons.monetization_on_rounded,
            label: 'Tangalar',
            value: '${data['coins'] ?? 0}',
            color: kYellow),
        StatCard(
            icon: Icons.leaderboard_rounded,
            label: 'Reyting',
            value: '#${data['global_rank'] ?? '-'}',
            color: kGreen),
        StatCard(
            icon: Icons.local_fire_department_rounded,
            label: 'Seriya',
            value:
                '${data['consecutive_days_active'] ?? data['streak'] ?? data['day_streak'] ?? 0} kun',
            color: kRed),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    const actions = [
      (Icons.quiz_rounded, kOrange, 'Test', '/student/tests'),
      (Icons.leaderboard_rounded, kGreen, 'Reyting', '/student/leaderboard'),
      (Icons.storefront_rounded, kPurple, "Do'kon", '/student/shop'),
      (Icons.menu_book_rounded, kBlue, "So'zlar", '/student/vocabulary'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Tezkor o'tish",
            style: TextStyle(
                color: kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(
          children: actions
              .map((a) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => context.go(a.$4),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: kBgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBgBorder),
                          ),
                          child: Column(
                            children: [
                              Icon(a.$1, color: a.$2, size: 24),
                              const SizedBox(height: 6),
                              Text(a.$3,
                                  style: const TextStyle(
                                      color: kTextSecondary, fontSize: 11),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final Map<String, dynamic> data;
  const _WeeklyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final weeklyData =
        (data['weekly_activity'] as List?)?.cast<Map<String, dynamic>>() ??
            [];
    const days = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBgBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Haftalik faollik',
              style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                barGroups: List.generate(7, (i) {
                  final val = weeklyData.length > i
                      ? (weeklyData[i]['minutes'] as num?)?.toDouble() ?? 0
                      : 0.0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        color: kOrange,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
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
                      getTitlesWidget: (value, meta) => Text(
                        days[value.toInt()],
                        style: const TextStyle(
                            color: kTextMuted, fontSize: 11),
                      ),
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentResults extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RecentResults({required this.data});

  @override
  Widget build(BuildContext context) {
    final results =
        (data['recent_results'] as List?)?.take(5).toList() ?? [];
    if (results.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("So'nggi natijalar",
            style: TextStyle(
                color: kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBgBorder),
          ),
          child: Column(
            children: results.asMap().entries.map((e) {
              final r = e.value as Map<String, dynamic>;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                              r['test_title'] ?? r['title'] ?? 'Test',
                              style: const TextStyle(
                                  color: kTextPrimary, fontSize: 14),
                              overflow: TextOverflow.ellipsis),
                        ),
                        ScoreCell(score: r['score'] ?? 0),
                      ],
                    ),
                  ),
                  if (e.key < results.length - 1)
                    const Divider(height: 1, color: kBgBorder),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DailyChallengeCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/challenge'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            kOrange.withOpacity(0.3),
            kPurple.withOpacity(0.3)
          ]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kOrange.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kOrange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt_rounded, color: kOrange, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kunlik musobaqa',
                      style: TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  Text(
                      data['description'] as String? ??
                          'Bugungi musobaqada qatnashing',
                      style: const TextStyle(
                          color: kTextSecondary, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: kOrange, size: 16),
          ],
        ),
      ),
    );
  }
}
