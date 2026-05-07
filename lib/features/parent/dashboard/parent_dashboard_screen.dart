import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../shared/widgets/alochi_skeleton.dart';
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
      backgroundColor: AppColors.darkBg,
      appBar: AlochiAppBar(
        showBackButton: false,
        backgroundColor: AppColors.darkBg,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ota-ona paneli',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkInk)),
            if (user != null)
              Text(user.fullName,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.darkMuted)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded,
                color: AppColors.darkMuted),
            onPressed: () => context.go('/parent/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_childrenProvider.future),
        color: AppColors.accent,
        backgroundColor: AppColors.darkSurface,
        child: childrenAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                AlochiSkeleton(height: 120),
                SizedBox(height: 16),
                AlochiSkeleton(height: 120),
                SizedBox(height: 16),
                AlochiSkeleton(height: 120),
              ],
            ),
          ),
          error: (e, _) => AlochiEmptyState(
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.danger,
            title: 'Yuklab bo\'lmadi',
            subtitle: e.toString(),
            actionLabel: 'Qayta urinish',
            onAction: () => ref.invalidate(_childrenProvider),
          ),
          data: (children) {
            if (children.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: const AlochiEmptyState(
                    icon: Icons.child_care_rounded,
                    title: "Bolalar bog'lanmagan",
                    subtitle:
                        'Farzandingizning ilovasidan sizga invite kodi yuboring',
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              // header + children + spacing + summary footer
              itemCount: 2 + children.length + 1,
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text('Farzandlarim',
                        style: TextStyle(
                            color: AppColors.darkInk,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                  );
                }
                if (i <= children.length) {
                  final child = children[i - 1];
                  return _ChildCard(
                    child: child,
                    onTap: () => context.go('/parent/children/${child['id']}'),
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
    final attendance = child['attendance_rate'] ?? 95; // Placeholder/Safe default
    final school = child['school'] as String?;
    final grade = child['grade'];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          children: [
            Row(
              children: [
                AlochiAvatar(name: name, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: AppColors.darkInk,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      if (school != null)
                        Text(school,
                            style: const TextStyle(
                                color: AppColors.darkMuted, fontSize: 12)),
                      if (grade != null)
                        Text('$grade-sinf',
                            style: const TextStyle(
                                color: AppColors.darkMuted, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded,
                      color: AppColors.brand, size: 22),
                  onPressed: () {
                    // Chat to teacher logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Ustoz bilan chat ochilmoqda...")),
                    );
                  },
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded,
                            color: AppColors.accent, size: 14),
                        Text('$xp XP',
                            style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ],
                    ),
                    Text('Daraja $level',
                        style:
                            const TextStyle(color: AppColors.darkMuted, fontSize: 11)),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: AppColors.darkMuted),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.darkBorder, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Mini(
                    icon: Icons.local_fire_department_rounded,
                    value: '$streak',
                    label: 'Seriya',
                    color: AppColors.accent),
                _Mini(
                    icon: Icons.bar_chart_rounded,
                    value: '${(avgScore as num).toStringAsFixed(0)}%',
                    label: "O'rtacha",
                    color: AppColors.info),
                _Mini(
                    icon: Icons.calendar_today_rounded,
                    value: '$attendance%',
                    label: 'Davomat',
                    color: AppColors.success),
                _Mini(
                    icon: Icons.emoji_events_rounded,
                    value: '#${child['rank'] ?? '-'}',
                    label: 'Reyting',
                    color: AppColors.warning),
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
                color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        Text(label, style: const TextStyle(color: AppColors.darkMuted, fontSize: 10)),
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
    final totalXp =
        children.fold<int>(0, (sum, c) => sum + (c['xp'] as int? ?? 0));
    final avgScore = children.isEmpty
        ? 0
        : children.fold<double>(0,
                (sum, c) => sum + ((c['avg_score'] as num?)?.toDouble() ?? 0)) /
            children.length;
    final totalStreak =
        children.fold<int>(0, (s, c) => s + (c['streak'] as int? ?? 0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Umumiy natijalar',
              style: TextStyle(
                  color: AppColors.darkInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SumStat(label: 'Jami XP', value: '$totalXp', color: AppColors.accent),
              _SumStat(
                  label: "O'rtacha ball",
                  value: '${avgScore.toStringAsFixed(0)}%',
                  color: AppColors.info),
              _SumStat(
                  label: 'Jami seriya', value: '$totalStreak', color: AppColors.success),
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
                color: color, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.darkMuted, fontSize: 11)),
      ],
    );
  }
}
