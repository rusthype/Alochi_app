import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../shared/widgets/alochi_card.dart';
import '../../../features/auth/auth_provider.dart';
import '../../../core/api/teacher_api.dart';
import 'profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(teacherProfileProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          'Profil',
          style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
        ),
        automaticallyImplyLeading: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: profileAsync.when(
        data: (profile) => _ProfileContent(
          profile: profile,
          schoolName: authState.user?.school,
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
        error: (err, _) {
          // Fall back to user data from auth state
          final user = authState.user;
          if (user != null) {
            final fallback = TeacherProfileModel(
              id: user.id,
              name: user.fullName,
              username: user.username,
              phone: '',
            );
            return _ProfileContent(
              profile: fallback,
              schoolName: user.school,
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.danger, size: 40),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    "Profilni yuklashda xato",
                    style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    err.toString(),
                    style:
                        AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  TextButton(
                    onPressed: () => ref.invalidate(teacherProfileProvider),
                    child: Text(
                      'Qayta urinish',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.brand),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Profile content ──────────────────────────────────────────────────────────

class _ProfileContent extends ConsumerWidget {
  final TeacherProfileModel profile;
  final String? schoolName;

  const _ProfileContent({
    required this.profile,
    this.schoolName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User info card
          AlochiCard(
            child: Column(
              children: [
                AlochiAvatar(name: profile.name, size: 64),
                const SizedBox(height: AppSpacing.m),
                Text(
                  profile.name.isEmpty ? 'Ustoz' : profile.name,
                  style: AppTextStyles.titleL.copyWith(color: AppColors.ink),
                  textAlign: TextAlign.center,
                ),
                if (profile.username.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@${profile.username}',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.brandMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (schoolName != null && schoolName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.school_rounded,
                          size: 14, color: AppColors.brandMuted),
                      const SizedBox(width: 4),
                      Text(
                        schoolName!,
                        style: AppTextStyles.bodyS
                            .copyWith(color: AppColors.brandMuted),
                      ),
                    ],
                  ),
                ],
                if (profile.phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone_outlined,
                          size: 14, color: AppColors.brandMuted),
                      const SizedBox(width: 4),
                      Text(
                        profile.phone,
                        style: AppTextStyles.bodyS
                            .copyWith(color: AppColors.brandMuted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          // Settings list
          AlochiCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.send_rounded,
                  iconBg: const Color(0xFF0088CC),
                  label: 'Telegram ota-onalar',
                  onTap: () => context.push('/teacher/profile/telegram'),
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFE5E7EB)),
                _SettingsRow(
                  icon: Icons.edit_outlined,
                  iconBg: AppColors.brand,
                  label: 'Profilni tahrirlash',
                  trailing: _ComingSoonBadge(),
                  onTap: () {
                    // Day 6 placeholder
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Tez orada',
                          style: AppTextStyles.bodyS
                              .copyWith(color: Colors.white),
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: AppColors.brandMuted,
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFE5E7EB)),
                _SettingsRow(
                  icon: Icons.lock_outline_rounded,
                  iconBg: AppColors.warning,
                  label: "Parolni o'zgartirish",
                  trailing: _ComingSoonBadge(),
                  onTap: () {
                    // Day 6 placeholder
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Tez orada',
                          style: AppTextStyles.bodyS
                              .copyWith(color: Colors.white),
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: AppColors.brandMuted,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),

          // Logout card
          AlochiCard(
            padding: EdgeInsets.zero,
            child: _SettingsRow(
              icon: Icons.logout_rounded,
              iconBg: AppColors.danger,
              label: 'Chiqish',
              labelColor: AppColors.danger,
              showChevron: false,
              onTap: () => _showLogoutDialog(context, ref),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.l)),
        title: Text(
          'Chiqish',
          style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
        ),
        content: Text(
          "Ilovadan chiqishni xohlaysizmi?",
          style: AppTextStyles.body.copyWith(color: AppColors.brandMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Bekor',
              style: AppTextStyles.body.copyWith(color: AppColors.brandMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/teacher/auth/login');
              }
            },
            child: Text(
              'Chiqish',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings row ─────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final Color? labelColor;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconBg,
    required this.label,
    this.labelColor,
    this.trailing,
    this.showChevron = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.l),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l, vertical: AppSpacing.m),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadii.s),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body
                    .copyWith(color: labelColor ?? AppColors.ink),
              ),
            ),
            if (trailing != null) trailing!,
            if (showChevron)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.brandMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Coming soon badge ────────────────────────────────────────────────────────

class _ComingSoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.s),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(AppRadii.round),
      ),
      child: Text(
        'Tez orada',
        style: AppTextStyles.caption.copyWith(color: AppColors.brandMuted),
      ),
    );
  }
}
