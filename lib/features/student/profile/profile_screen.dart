import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../core/api/student_api.dart';
import '../../../core/models/achievement.dart';
import '../../auth/auth_provider.dart';

final _profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return StudentApi().getProfile();
});

final _achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  return StudentApi().getAchievements();
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final profileAsync = ref.watch(_profileProvider);
    final achievementsAsync = ref.watch(_achievementsProvider);

    if (user == null) return const LoadingOverlay();

    return Scaffold(
      backgroundColor: kBgMain,
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.go('/student/profile/edit'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  AlochiAvatar(name: user.fullName, size: 80),
                  const SizedBox(height: 12),
                  Text(user.fullName,
                      style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700)),
                  if (user.school != null)
                    Text(user.school!,
                        style: const TextStyle(color: kTextSecondary)),
                  if (user.grade != null)
                    Text("${user.grade}-sinf",
                        style:
                            const TextStyle(color: kTextMuted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            profileAsync.when(
              loading: () => const LoadingWidget(),
              error: (_, __) => const SizedBox.shrink(),
              data: (profile) {
                final xp = profile['xp'] ?? 0;
                final level = profile['level'] ?? 1;
                final xpToNext = profile['xp_to_next_level'] ?? 1000;
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Daraja $level',
                              style: const TextStyle(
                                  color: kTextPrimary,
                                  fontWeight: FontWeight.w700)),
                          Text('$xp XP',
                              style: const TextStyle(
                                  color: kOrange, fontWeight: FontWeight.w700)),
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
                          style:
                              const TextStyle(color: kTextMuted, fontSize: 12)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Stat(
                              'Testlar', '${profile['tests_completed'] ?? 0}'),
                          _Stat("O'rtacha",
                              '${(profile['avg_score'] ?? 0).toStringAsFixed(0)}%'),
                          _Stat('Seriya', '${profile['streak'] ?? 0}'),
                          _Stat('Reyting', '#${profile['global_rank'] ?? '-'}'),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            achievementsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (achievements) {
                if (achievements.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      childAspectRatio: 2,
                      children: achievements
                          .map((a) => _AchievementCard(a: a))
                          .toList(),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _ActionBtn(
              icon: Icons.person_add_rounded,
              label: 'Ota-onani ulash',
              color: kBlue,
              onTap: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: kBgCard,
                  title: const Text('Ota-onani ulash',
                      style: TextStyle(color: kTextPrimary)),
                  content: const Text(
                      "Ota-onangizdagi A'lochi ilovasiga kirish uchun ushbu kodni ulashing.",
                      style: TextStyle(color: kTextSecondary)),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Yopish'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _ActionBtn(
              icon: Icons.logout_rounded,
              label: 'Chiqish',
              color: kRed,
              onTap: () => ref.read(authProvider.notifier).logout(),
            ),
          ],
        ),
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

class _AchievementCard extends StatelessWidget {
  final Achievement a;
  const _AchievementCard({required this.a});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: a.isUnlocked ? kOrange.withValues(alpha: 0.4) : kBgBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded,
              color: a.isUnlocked ? kOrange : kTextMuted, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(a.name,
                    style: TextStyle(
                        color: a.isUnlocked ? kTextPrimary : kTextMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(a.description,
                    style: const TextStyle(color: kTextMuted, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBgBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: TextStyle(color: color)),
        trailing: const Icon(Icons.chevron_right_rounded, color: kTextMuted),
        onTap: onTap,
      ),
    );
  }
}
