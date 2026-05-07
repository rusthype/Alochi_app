import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Profil',
          style: AppTextStyles.titleM
              .copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Theme.of(context).dividerColor),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(teacherProfileProvider.future),
        color: AppColors.brand,
        child: profileAsync.when(
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
                      style:
                          AppTextStyles.titleM.copyWith(color: AppColors.ink),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      err.toString(),
                      style: AppTextStyles.bodyS
                          .copyWith(color: AppColors.brandMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.l),
                    TextButton(
                      onPressed: () => ref.invalidate(teacherProfileProvider),
                      child: Text(
                        'Qayta urinish',
                        style:
                            AppTextStyles.body.copyWith(color: AppColors.brand),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User info card
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.brand,
                  child: Text(
                    profile.name.isNotEmpty
                        ? profile.name[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  profile.name.isEmpty ? 'Ustoz' : profile.name,
                  style: AppTextStyles.displayM.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                if (profile.username.isNotEmpty)
                  Text(
                    '@${profile.username}',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.brand,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (profile.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.phone,
                    style: AppTextStyles.bodyS.copyWith(
                      color: const Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Settings list
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.send_rounded,
                  iconBg: const Color(0xFF26A5E4),
                  label: 'Telegram ota-onalar',
                  onTap: () => context.push('/teacher/profile/telegram'),
                ),
                Divider(
                    height: 1,
                    indent: 64,
                    color: Theme.of(context).dividerColor),
                _SettingsRow(
                  icon: Icons.edit_outlined,
                  iconBg: const Color(0xFF1F6F65),
                  label: 'Profilni tahrirlash',
                  onTap: () => context.push('/teacher/profile/edit'),
                ),
                Divider(
                    height: 1,
                    indent: 64,
                    color: Theme.of(context).dividerColor),
                _SettingsRow(
                  icon: Icons.lock_outline_rounded,
                  iconBg: const Color(0xFFD97706),
                  label: "Parolni o'zgartirish",
                  onTap: () => context.push('/teacher/profile/password'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Help section
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: _SettingsRow(
              icon: Icons.info_outline_rounded,
              iconBg: const Color(0xFF0EA5E9),
              label: 'Ilova haqida',
              onTap: () => context.push('/teacher/about'),
            ),
          ),
          const SizedBox(height: 12),

          // Logout card
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: _SettingsRow(
              icon: Icons.logout_rounded,
              iconBg: const Color(0xFFDC2626),
              label: 'Tizimdan chiqish',
              labelColor: const Color(0xFFDC2626),
              showChevron: false,
              onTap: () => _showLogoutDialog(context, ref),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.l)),
        title: Text(
          'Tizimdan chiqish',
          style: AppTextStyles.titleM
              .copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          "Haqiqatdan ham tizimdan chiqmoqchimisiz?",
          style: AppTextStyles.body.copyWith(color: AppColors.brandMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Bekor qilish',
              style: AppTextStyles.body.copyWith(color: AppColors.brandMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Chiqish',
              style: AppTextStyles.body.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        context.go('/teacher/auth/login');
      }
    }
  }
}

// ─── Settings row ─────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final Color? labelColor;
  final bool showChevron;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconBg,
    required this.label,
    this.labelColor,
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                    color:
                        labelColor ?? Theme.of(context).colorScheme.onSurface),
              ),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.brandMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
