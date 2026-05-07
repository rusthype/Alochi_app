import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../shared/widgets/alochi_card.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.brand,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "A'lochi",
                  style:
                      AppTextStyles.displayL.copyWith(color: AppColors.brand),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ta\'lim platformasiga xush kelibsiz!',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                const Text(
                  'Rolingizni tanlang:',
                  style: AppTextStyles.titleL,
                ),
                const SizedBox(height: 32),

                // Role buttons
                _RoleCard(
                  title: 'Ustoz',
                  subtitle: 'Guruhlarni boshqarish va baholash',
                  icon: Icons.school_rounded,
                  color: AppColors.brand,
                  onTap: () => context.push('/teacher/auth/login'),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  title: 'Ota-ona',
                  subtitle: 'Farzandingiz natijalarini kuzating',
                  icon: Icons.family_restroom_rounded,
                  color: AppColors.accent,
                  onTap: () => context.push('/teacher/auth/login?role=parent'),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  title: 'O\'quvchi',
                  subtitle: 'Bilimingizni oshiring va XP yig\'ing',
                  icon: Icons.person_rounded,
                  color: AppColors.info,
                  onTap: () => context.push('/teacher/auth/login?role=student'),
                ),

                const Spacer(),
                const Text(
                  '© 2026 A\'lochi',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AlochiCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyS.copyWith(color: AppColors.gray),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.gray2),
          ],
        ),
      ),
    );
  }
}
