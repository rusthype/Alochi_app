import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../shared/widgets/alochi_avatar.dart';
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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Reyting'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _ScopeTab(label: 'Global', value: 'global', current: scope),
                  _ScopeTab(label: 'Shahar', value: 'city', current: scope),
                  _ScopeTab(label: 'Maktab', value: 'school', current: scope),
                ],
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(
                child: Text('Xatolik: $e',
                    style: const TextStyle(color: AppColors.danger)),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return const AlochiEmptyState(title: "Ma'lumot topilmadi");
                }
                final top3 = entries.take(3).toList();
                final rest = entries.skip(3).toList();
                final currentUserId = currentUser?.id;
                final currentEntry = entries
                    .where((e) =>
                        e.isCurrentUser ||
                        (currentUserId != null && e.userId == currentUserId))
                    .firstOrNull;

                // Build flat item list for ListView.builder
                final hasPodium = top3.isNotEmpty;
                final stickyEntry =
                    (currentEntry != null && currentEntry.rank > 3)
                        ? currentEntry
                        : null;
                
                final int podiumCount = hasPodium ? 1 : 0;
                final int stickyCount =
                    stickyEntry != null ? 3 : 0; // divider + row + space
                final itemCount = podiumCount + 1 + rest.length + stickyCount;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  itemCount: itemCount,
                  itemBuilder: (ctx, i) {
                    if (hasPodium && i == 0) {
                      return _Podium(
                        entries: top3,
                        currentUserId: currentUserId,
                      );
                    }
                    final afterPodium = i - podiumCount;
                    if (afterPodium == 0) {
                      return const SizedBox(height: 16);
                    }
                    final restIdx = afterPodium - 1;
                    if (restIdx < rest.length) {
                      final e = rest[restIdx];
                      return _RankRow(
                        entry: e,
                        isCurrentUser: e.isCurrentUser ||
                            (currentUserId != null &&
                                e.userId == currentUserId),
                      );
                    }
                    if (stickyEntry != null) {
                      final stickyOffset = afterPodium - 1 - rest.length;
                      if (stickyOffset == 0) {
                        return const SizedBox(height: 8);
                      }
                      if (stickyOffset == 1) {
                        return const Divider(color: AppColors.line);
                      }
                      if (stickyOffset == 2) {
                        return _RankRow(
                          entry: stickyEntry,
                          isCurrentUser: true,
                        );
                      }
                    }
                    return const SizedBox(height: 32);
                  },
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
      {required this.label, required this.value, required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(_scopeProvider.notifier).state = value,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(
              color: isSelected ? Colors.white : AppColors.gray,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String? currentUserId;
  const _Podium({required this.entries, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    // Order for visual display: [2nd, 1st, 3rd]
    List<LeaderboardEntry?> ordered = [null, null, null];
    if (entries.isNotEmpty) ordered[1] = entries[0];
    if (entries.length > 1) ordered[0] = entries[1];
    if (entries.length > 2) ordered[2] = entries[2];

    const colors = [
      Color(0xFFC0C0C0), // Silver
      Color(0xFFFFD700), // Gold
      Color(0xFFCD7F32), // Bronze
    ];
    const heights = [110.0, 140.0, 90.0];
    const avatarSizes = [44.0, 56.0, 40.0];

    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 16, left: 8, right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (i) {
          final entry = ordered[i];
          if (entry == null) return const Expanded(child: SizedBox());
          return Expanded(
            child: _PodiumSlot(
              entry: entry,
              color: colors[i],
              height: heights[i],
              avatarSize: avatarSizes[i],
              isCurrentUser: entry.isCurrentUser ||
                  (currentUserId != null && entry.userId == currentUserId),
            ),
          );
        }),
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntry entry;
  final Color color;
  final double height;
  final double avatarSize;
  final bool isCurrentUser;

  const _PodiumSlot({
    required this.entry,
    required this.color,
    required this.height,
    required this.avatarSize,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrentUser ? AppColors.brand : color,
                    width: isCurrentUser ? 3 : 2,
                  ),
                ),
                child: AlochiAvatar(name: entry.name, size: avatarSize),
              ),
              Positioned(
                bottom: -4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#${entry.rank}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            entry.name.split(' ').first,
            style: AppTextStyles.label.copyWith(
              color: AppColors.ink,
              fontWeight: isCurrentUser ? FontWeight.w800 : FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${entry.xp} XP',
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: height),
            builder: (context, h, _) {
              return Container(
                width: 60,
                height: h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: 0.3),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Icon(
                      Icons.emoji_events,
                      color: color.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;
  const _RankRow({required this.entry, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.brand.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? AppColors.brand.withValues(alpha: 0.3) : AppColors.line,
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${entry.rank}',
              style: AppTextStyles.label.copyWith(
                color: isCurrentUser ? AppColors.brand : AppColors.gray2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          AlochiAvatar(name: entry.name, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.ink,
                    fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (entry.school != null)
                  Text(
                    entry.school!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.gray),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '${entry.xp} XP',
            style: AppTextStyles.bodyS.copyWith(
              color: isCurrentUser ? AppColors.brand : AppColors.gray,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
