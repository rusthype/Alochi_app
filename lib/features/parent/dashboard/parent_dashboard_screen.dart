import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../../core/api/parent_api.dart';
import '../../auth/auth_provider.dart';

final _childrenProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ParentApi().getChildren();
});

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final childrenAsync = ref.watch(_childrenProvider);

    return Scaffold(
      backgroundColor: kBgMain,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ota-ona paneli',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            if (user != null)
              Text(user.fullName,
                  style: const TextStyle(
                      fontSize: 12, color: kTextMuted)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () => context.go('/parent/notifications'),
          ),
        ],
      ),
      body: childrenAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: kRed, size: 48),
              const SizedBox(height: 16),
              Text('Xatolik: $e',
                  style: const TextStyle(color: kTextMuted)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(_childrenProvider),
                child: const Text('Qayta urinish'),
              ),
            ],
          ),
        ),
        data: (children) {
          if (children.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.child_care_rounded,
                      size: 64, color: kTextMuted),
                  SizedBox(height: 16),
                  Text("Bolalar bog'lanmagan",
                      style: TextStyle(
                          color: kTextPrimary, fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                      'Farzandingizning ilovasidan sizga invite kodi yuboring',
                      style: TextStyle(
                          color: kTextSecondary, fontSize: 14),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            // header + children + spacing + summary footer
            itemCount: 2 + children.length + 1,
            itemBuilder: (ctx, i) {
              if (i == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text('Farzandlarim',
                      style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                );
              }
              if (i <= children.length) {
                final child = children[i - 1];
                return _ChildCard(
                  child: child,
                  onTap: () =>
                      context.go('/parent/children/${child['id']}'),
                );
              }
              // Footer: spacing + summary
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: _SummarySection(children: children),
              );
            },
          );
        },
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final Map<String, dynamic> child;
  final VoidCallback onTap;
  const _ChildCard({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = child['full_name'] as String? ??
        '${child['first_name'] ?? ''} ${child['last_name'] ?? ''}'.trim();
    final xp = child['xp'] ?? 0;
    final level = child['level'] ?? 1;
    final streak = child['streak'] ?? 0;
    final avgScore = child['avg_score'] ?? 0;
    final school = child['school'] as String?;
    final grade = child['grade'];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBgBorder),
        ),
        child: Column(
          children: [
            Row(
              children: [
                AvatarWidget(name: name, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: kTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      if (school != null)
                        Text(school,
                            style: const TextStyle(
                                color: kTextSecondary,
                                fontSize: 12)),
                      if (grade != null)
                        Text('$grade-sinf',
                            style: const TextStyle(
                                color: kTextMuted, fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded,
                            color: kOrange, size: 14),
                        Text('$xp XP',
                            style: const TextStyle(
                                color: kOrange,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ],
                    ),
                    Text('Daraja $level',
                        style: const TextStyle(
                            color: kTextMuted, fontSize: 11)),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    color: kTextMuted),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: kBgBorder, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Mini(
                    icon: Icons.local_fire_department_rounded,
                    value: '$streak',
                    label: 'Seriya',
                    color: kOrange),
                _Mini(
                    icon: Icons.bar_chart_rounded,
                    value:
                        '${(avgScore as num).toStringAsFixed(0)}%',
                    label: "O'rtacha",
                    color: kBlue),
                _Mini(
                    icon: Icons.emoji_events_rounded,
                    value: '#${child['rank'] ?? '-'}',
                    label: 'Reyting',
                    color: kYellow),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _Mini(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
        Text(label,
            style:
                const TextStyle(color: kTextMuted, fontSize: 10)),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  final List<Map<String, dynamic>> children;
  const _SummarySection({required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final totalXp = children
        .fold<int>(0, (sum, c) => sum + (c['xp'] as int? ?? 0));
    final avgScore = children.isEmpty
        ? 0
        : children.fold<double>(
                0,
                (sum, c) =>
                    sum + ((c['avg_score'] as num?)?.toDouble() ?? 0)) /
            children.length;
    final totalStreak = children
        .fold<int>(0, (s, c) => s + (c['streak'] as int? ?? 0));

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
          const Text('Umumiy natijalar',
              style: TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SumStat(
                  label: 'Jami XP',
                  value: '$totalXp',
                  color: kOrange),
              _SumStat(
                  label: "O'rtacha ball",
                  value: '${avgScore.toStringAsFixed(0)}%',
                  color: kBlue),
              _SumStat(
                  label: 'Jami seriya',
                  value: '$totalStreak',
                  color: kGreen),
            ],
          ),
        ],
      ),
    );
  }
}

class _SumStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SumStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label,
            style:
                const TextStyle(color: kTextMuted, fontSize: 11)),
      ],
    );
  }
}
