import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../core/api/student_api.dart';

final _journeyProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = StudentApi();
  final journey = await api.getJourney();
  final profile = await api.getProfile();
  return {
    'journey': journey,
    'profile': profile,
  };
});

class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_journeyProvider);
    return Scaffold(
      backgroundColor: kBgMain,
      appBar: AppBar(title: const Text('Sayohat')),
      body: async.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(
            child: Text('Xatolik: $e', style: const TextStyle(color: kRed))),
        data: (data) {
          final journey = data['journey'] as Map<String, dynamic>;
          final profile = data['profile'] as Map<String, dynamic>;
          final nodes = ((journey['nodes'] ?? journey['stages'] ?? []) as List)
              .cast<Map<String, dynamic>>();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _JourneyStats(profile: profile),
                ),
              ),
              if (nodes.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_rounded, size: 64, color: kTextMuted),
                        SizedBox(height: 16),
                        Text('Sayohat tez orada',
                            style: TextStyle(color: kTextSecondary)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _Node(
                        node: nodes[i],
                        index: i,
                        isLast: i == nodes.length - 1,
                      ),
                      childCount: nodes.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _JourneyStats extends StatelessWidget {
  final Map<String, dynamic> profile;
  const _JourneyStats({required this.profile});

  @override
  Widget build(BuildContext context) {
    final streak = profile['day_streak'] ?? profile['streak'] ?? 0;
    final xp = profile['total_xp'] ?? profile['xp'] ?? 0;
    final bestSubject = profile['best_subject'] ?? 'Matematika';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBgBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.local_fire_department_rounded,
            value: '$streak kun',
            label: 'Seriya',
            color: kRed,
          ),
          _StatItem(
            icon: Icons.bolt_rounded,
            value: '$xp',
            label: 'Jami XP',
            color: kOrange,
          ),
          _StatItem(
            icon: Icons.star_rounded,
            value: bestSubject,
            label: 'Eng yaxshi fan',
            color: kGreen,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        Text(label, style: const TextStyle(color: kTextMuted, fontSize: 11)),
      ],
    );
  }
}

class _Node extends StatelessWidget {
  final Map<String, dynamic> node;
  final int index;
  final bool isLast;
  const _Node({required this.node, required this.index, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final status = node['status'] as String? ?? 'locked';
    final isCompleted = status == 'completed';
    final isCurrent = status == 'current' || status == 'available';
    final isLocked = status == 'locked';

    final Color nodeColor;
    final IconData nodeIcon;
    if (isCompleted) {
      nodeColor = kGreen;
      nodeIcon = Icons.check_rounded;
    } else if (isCurrent) {
      nodeColor = kOrange;
      nodeIcon = Icons.play_arrow_rounded;
    } else {
      nodeColor = kTextMuted;
      nodeIcon = Icons.lock_rounded;
    }

    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: nodeColor.withValues(alpha: isLocked ? 0.1 : 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: nodeColor.withValues(alpha: isLocked ? 0.3 : 1),
                      width: isCurrent ? 3 : 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(nodeIcon, color: nodeColor, size: 20),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted ? kGreen : kBgBorder,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: isLocked
                  ? () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Bu bosqichni ochish uchun oldingi bosqichni yakunlang'),
                          backgroundColor: kBgCard,
                        ),
                      )
                  : () {
                      final testId = node['test_id']?.toString();
                      if (testId != null) {
                        context.go('/student/tests/$testId/play');
                      }
                    },
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kBgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isCurrent ? kOrange.withValues(alpha: 0.5) : kBgBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              node['title'] as String? ??
                                  'Bosqich ${index + 1}',
                              style: TextStyle(
                                  color: isLocked ? kTextMuted : kTextPrimary,
                                  fontWeight: FontWeight.w600)),
                          if (node['description'] != null)
                            Text(node['description'] as String,
                                style: const TextStyle(
                                    color: kTextMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (node['xp_reward'] != null)
                      Row(
                        children: [
                          const Icon(Icons.bolt_rounded,
                              color: kOrange, size: 14),
                          Text('${node['xp_reward']} XP',
                              style: const TextStyle(
                                  color: kOrange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
