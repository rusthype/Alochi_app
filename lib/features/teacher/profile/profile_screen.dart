import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
                  onTap: () => context.push('/teacher/profile/edit'),
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFE5E7EB)),
                _SettingsRow(
                  icon: Icons.lock_outline_rounded,
                  iconBg: AppColors.warning,
                  label: "Parolni o'zgartirish",
                  onTap: () => context.push('/teacher/profile/password'),
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

          // Account info section
          const _SectionHeader(title: "Hisob ma'lumotlari"),
          AlochiCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.person_outline,
                  label: "Foydalanuvchi nomi",
                  value: profile.username.isEmpty ? "-" : profile.username,
                ),
                const _Divider(),
                const _InfoRow(
                  icon: Icons.badge_outlined,
                  label: "Roli",
                  value: "Ustoz",
                ),
                const _Divider(),
                _InfoRow(
                  icon: Icons.school_outlined,
                  label: "Maktab",
                  value: schoolName ?? "-",
                ),
                const _Divider(),
                const _InfoRow(
                  icon: Icons.history,
                  label: "Oxirgi kirish",
                  value: "Bugun",
                ),
              ],
            ),
          ),

          // App info section
          const _SectionHeader(title: "Ilova haqida"),
          const AlochiCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.info_outline,
                  label: "Versiya",
                  value: "1.1.0",
                ),
                _Divider(),
                _InfoRow(
                  icon: Icons.update,
                  label: "Yangilanish",
                  value: "Avtomatik",
                ),
              ],
            ),
          ),

          // Help section
          const _SectionHeader(title: "Yordam"),
          AlochiCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _LinkRow(
                  icon: Icons.shield_outlined,
                  label: "Maxfiylik siyosati",
                  onTap: () => _launchUrl(
                      context, 'https://alochi.org/static/legal/privacy.html'),
                ),
                const _Divider(),
                _LinkRow(
                  icon: Icons.description_outlined,
                  label: "Xizmat shartlari",
                  onTap: () => _launchUrl(
                      context, 'https://alochi.org/static/legal/terms.html'),
                ),
                const _Divider(),
                _LinkRow(
                  icon: Icons.email_outlined,
                  label: "Bog'lanish",
                  onTap: () => _launchUrl(context, 'mailto:support@alochi.org'),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Manzilni ochib bo'lmadi: $urlString")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xatolik yuz berdi: $e")),
        );
      }
    }
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.l)),
        title: Text(
          'Tizimdan chiqish',
          style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
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

// ─── Private Widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s, AppSpacing.l, AppSpacing.s, AppSpacing.s),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.label.copyWith(
          color: AppColors.brandMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l, vertical: AppSpacing.m),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.brandMuted),
          const SizedBox(width: AppSpacing.m),
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: AppColors.brandMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LinkRow(
      {required this.icon, required this.label, required this.onTap});

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
            Icon(icon, size: 20, color: AppColors.brand),
            const SizedBox(width: AppSpacing.m),
            Expanded(child: Text(label, style: AppTextStyles.body)),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.brandMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: Container(
        height: 1,
        color: const Color(0xFFF3F4F6),
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
            if (showChevron)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.brandMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
