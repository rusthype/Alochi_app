import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../../core/api/student_api.dart';
import '../../../core/models/leaderboard.dart';
import '../../auth/auth_provider.dart';

final _scopeProvider = StateProvider<String>((ref) => 'global');

final _leaderboardProvider =
    FutureProvider<List<LeaderboardEntry>>((ref) async {
  final scope = ref.watch(_scopeProvider);
  return StudentApi().getLeaderboard(scope: scope);
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(_scopeProvider);
    final async = ref.watch(_leaderboardProvider);
    final currentUser = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: kBgMain,
      appBar: AppBar(title: const Text('Reyting')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBgBorder),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _ScopeTab(
                      label: 'Global',
                      value: 'global',
                      current: scope),
                  _ScopeTab(
                      label: 'Shahar',
                      value: 'city',
                      current: scope),
                  _ScopeTab(
                      label: 'Maktab',
                      value: 'school',
                      current: scope),
                ],
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(
                  child: Text('Xatolik: $e',
                      style: const TextStyle(color: kRed))),
              data: (entries) {
                if (entries.isEmpty) {
                  return const EmptyState(
                      message: "Ma'lumot topilmadi",
                      icon: Icons.leaderboard_outlined);
                }
                final top3 = entries.take(3).toList();
                final rest = entries.skip(3).toList();
                final currentUserId = currentUser?.id;
                final currentEntry = entries
                    .where((e) =>
                        e.isCurrentUser ||
                        (currentUserId != null &&
                            e.userId == currentUserId))
                    .firstOrNull;
                final isInTop = currentEntry != null &&
                    currentEntry.rank <= 10;

                return ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (top3.length >= 2) _Podium(entries: top3),
                    const SizedBox(height: 16),
                    ...rest.map((e) => _RankRow(
                          entry: e,
                          isCurrentUser: e.isCurrentUser ||
                              (currentUserId != null &&
                                  e.userId == currentUserId),
                        )),
                    if (currentEntry != null && !isInTop) ...[
                      const SizedBox(height: 8),
                      const Divider(color: kBgBorder),
                      _RankRow(
                          entry: currentEntry,
                          isCurrentUser: true),
                    ],
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeTab extends ConsumerWidget {
  final String label;
  final String value;
  final String current;
  const _ScopeTab(
      {required this.label,
      required this.value,
      required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            ref.read(_scopeProvider.notifier).state = value,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? kOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  isSelected ? Colors.white : kTextSecondary,
              fontWeight: isSelected
                  ? FontWeight.w700
                  : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  const _Podium({required this.entries});

  @override
  Widget build(BuildContext context) {
    final ordered = entries.length >= 3
        ? [entries[1], entries[0], entries[2]]
        : entries;
    const heights = [100.0, 130.0, 80.0];
    const colors = [
      Color(0xFFC0C0C0),
      Color(0xFFFFD700),
      Color(0xFFCD7F32)
    ];
    const sizes = [40.0, 52.0, 36.0];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBgBorder),
      ),
      child: Column(
        children: [
          const Text('Top 3',
              style:
                  TextStyle(color: kTextSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              ordered.length > 3 ? 3 : ordered.length,
              (i) => _PodiumSlot(
                entry: ordered[i],
                color: i < colors.length
                    ? colors[i]
                    : kTextMuted,
                height: i < heights.length ? heights[i] : 80,
                avatarSize: i < sizes.length ? sizes[i] : 36,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntry entry;
  final Color color;
  final double height;
  final double avatarSize;
  const _PodiumSlot(
      {required this.entry,
      required this.color,
      required this.height,
      required this.avatarSize});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AvatarWidget(
            name: entry.name, size: avatarSize, color: color),
        const SizedBox(height: 8),
        Text(entry.name.split(' ').first,
            style: const TextStyle(
                color: kTextPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis),
        Text('${entry.xp} XP',
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text('#${entry.rank}',
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;
  const _RankRow(
      {required this.entry, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? kOrange.withValues(alpha: 0.1)
            : kBgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? kOrange.withValues(alpha: 0.5)
              : kBgBorder,
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('#${entry.rank}',
                style: TextStyle(
                    color: isCurrentUser ? kOrange : kTextMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
          AvatarWidget(name: entry.name, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    style: TextStyle(
                        color: kTextPrimary,
                        fontWeight: isCurrentUser
                            ? FontWeight.w700
                            : FontWeight.normal)),
                if (entry.school != null)
                  Text(entry.school!,
                      style: const TextStyle(
                          color: kTextMuted, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text('${entry.xp} XP',
              style: TextStyle(
                  color: isCurrentUser
                      ? kOrange
                      : kTextSecondary,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
