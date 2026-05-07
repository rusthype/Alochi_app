import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../shared/widgets/alochi_button.dart';
import '../../../shared/widgets/alochi_card.dart';
import '../../auth/auth_provider.dart';
import 'onboarding_widgets.dart';
import 'welcome_intro_screen.dart';

class WelcomeFeaturesScreen extends ConsumerWidget {
  const WelcomeFeaturesScreen({super.key});

  Future<void> _skip(BuildContext context, WidgetRef ref) async {
    await markOnboardingComplete();
    await ref.read(authProvider.notifier).clearOnboardingFlag();
    if (context.mounted) {
      context.go('/teacher/dashboard');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Skip button top-right
            Positioned(
              top: AppSpacing.s,
              right: AppSpacing.l,
              child: TextButton(
                onPressed: () => _skip(context, ref),
                child: Text(
                  "O'tkazib yuborish",
                  style: AppTextStyles.bodyS.copyWith(
                    color: AppColors.brandMuted,
                  ),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.l),
                  const OnboardingPageIndicator(activeIndex: 1, totalPages: 3),
                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    'Asosiy imkoniyatlar',
                    style: AppTextStyles.displayM.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    "A'lochi Ustoz bilan ishingiz tezroq va samaraliroq",
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.brandMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  const Expanded(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _FeatureCard(
                            icon: Icons.dashboard_outlined,
                            title: 'Dars boshqaruvi',
                            subtitle:
                                'Davomat, baholar, vazifalar — hammasi bir joyda',
                          ),
                          SizedBox(height: AppSpacing.m),
                          _FeatureCard(
                            icon: Icons.group_outlined,
                            title: "O'quvchi profillari",
                            subtitle:
                                "Har bir o'quvchi natijalari va chuqur statistikasi",
                          ),
                          SizedBox(height: AppSpacing.m),
                          _FeatureCard(
                            icon: Icons.psychology_outlined,
                            title: 'AI yordamchi',
                            subtitle:
                                'Test va savollar yarating bir tugma orqali',
                          ),
                          SizedBox(height: AppSpacing.m),
                          _FeatureCard(
                            icon: Icons.send_outlined,
                            title: 'Telegram aloqa',
                            subtitle:
                                'Ota-onalar bilan tezda bog\'lanish imkoni',
                          ),
                          SizedBox(height: AppSpacing.l),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.l),

                  // CTA
                  AlochiButton.primary(
                    label: 'Davom etish',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => context.go('/teacher/onboarding/ready'),
                  ),
                  const SizedBox(height: AppSpacing.l),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AlochiCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.brandSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.brand, size: 24),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleM.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.brandMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
