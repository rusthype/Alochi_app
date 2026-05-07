import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_button.dart';
import '../../../core/storage/storage.dart';
import 'onboarding_widgets.dart';

/// Key written to secure storage after the user completes or skips onboarding.
const _kFirstLoginKey = 'first_login_complete';

/// Provider that checks whether the user has already seen the onboarding.
final firstLoginCompletedProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final val = await AppStorage.readKey(_kFirstLoginKey);
  return val == 'true';
});

/// Writes the first_login_complete flag so onboarding is skipped on next login.
Future<void> markOnboardingComplete() async {
  await AppStorage.writeKey(_kFirstLoginKey, 'true');
}

class WelcomeIntroScreen extends ConsumerWidget {
  const WelcomeIntroScreen({super.key});

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
                  const OnboardingPageIndicator(activeIndex: 0, totalPages: 3),
                  const SizedBox(height: AppSpacing.xl),

                  // Brand mark
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(AppRadii.m),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'A',
                          style: AppTextStyles.titleL.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Text(
                        "A'lochi Ustoz",
                        style: AppTextStyles.titleL.copyWith(
                          color: AppColors.brand,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Tree illustration placeholder
                  Expanded(
                    child: Center(
                      child: _TreeIllustration(),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.l),

                  // Heading
                  Text(
                    'Xush kelibsiz, Ustoz!',
                    style: AppTextStyles.displayM.copyWith(
                      color: AppColors.ink,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // Subtitle
                  Text(
                    "A'lochi platformasi sizning ish faoliyatingizni soddalashtiradi",
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.brandMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Feature bullets
                  const _FeatureBullets(),
                  const SizedBox(height: AppSpacing.xl),

                  // CTA
                  AlochiButton.primary(
                    label: 'Davom etish',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => context.go('/teacher/onboarding/features'),
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

// ─── Tree illustration ────────────────────────────────────────────────────────

class _TreeIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // SVG asset rendered as a simple placeholder using Material icon
    // Full SVG rendering requires flutter_svg which may not be in pubspec.
    // Using branded container with tree icon as a safe fallback.
    return const _TreePlaceholder();
  }
}

class _TreePlaceholder extends StatelessWidget {
  const _TreePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: const BoxDecoration(
        color: AppColors.brandSoft,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.park_rounded,
        size: 96,
        color: AppColors.brand,
      ),
    );
  }
}

// ─── Feature bullets ──────────────────────────────────────────────────────────

class _FeatureBullets extends StatelessWidget {
  const _FeatureBullets();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _BulletRow(
          icon: Icons.checklist_rounded,
          text: 'Davomat va baholarni bir joyda',
        ),
        SizedBox(height: AppSpacing.m),
        _BulletRow(
          icon: Icons.chat_bubble_outline_rounded,
          text: "O'quvchilar bilan to'g'ridan-to'g'ri aloqa",
        ),
        SizedBox(height: AppSpacing.m),
        _BulletRow(
          icon: Icons.auto_awesome_rounded,
          text: 'AI yordami har qadamda',
        ),
      ],
    );
  }
}

class _BulletRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BulletRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(AppRadii.s),
          ),
          child: Icon(icon, color: AppColors.brand, size: 20),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(color: AppColors.ink),
          ),
        ),
      ],
    );
  }
}
