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

class WelcomeReadyScreen extends ConsumerWidget {
  const WelcomeReadyScreen({super.key});

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    await markOnboardingComplete();
    ref.read(authProvider.notifier).clearOnboardingFlag();
    if (context.mounted) {
      context.go('/teacher/dashboard');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.l),
              const OnboardingPageIndicator(activeIndex: 2, totalPages: 3),
              const Spacer(),

              // Big Success Icon
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: AppColors.brandSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 80,
                    color: AppColors.brand,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text(
                'Tayyorsiz!',
                style: AppTextStyles.displayL.copyWith(
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                "A'lochi Ustoz panelidan foydalanishni boshlang",
                style: AppTextStyles.body.copyWith(
                  color: AppColors.brandMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Tip card
              AlochiCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AppColors.accent,
                        size: 32,
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Text(
                          "Maslahat: Bosh sahifadan bugungi darslarni va statistikani ko'ring",
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // CTA
              AlochiButton.primary(
                label: 'Boshlash',
                onPressed: () => _finish(context, ref),
              ),
              const SizedBox(height: AppSpacing.l),
            ],
          ),
        ),
      ),
    );
  }
}
