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

const _kFirstLoginKey = 'first_login_complete';

final firstLoginCompletedProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final val = await AppStorage.readKey(_kFirstLoginKey);
  return val == 'true';
});

Future<void> markOnboardingComplete() async {
  await AppStorage.writeKey(_kFirstLoginKey, 'true');
}

class WelcomeIntroScreen extends ConsumerWidget {
  const WelcomeIntroScreen({super.key});

  Future<void> _skip(BuildContext context, WidgetRef ref) async {
    await markOnboardingComplete();
    await ref.read(authProvider.notifier).clearOnboardingFlag();
    if (context.mounted) context.go('/teacher/dashboard');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: AppSpacing.s,
              right: AppSpacing.l,
              child: TextButton(
                onPressed: () => _skip(context, ref),
                child: Text(
                  "O'tkazib yuborish",
                  style:
                      AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.l),
                  const OnboardingEntrance(
                    child:
                        OnboardingPageIndicator(activeIndex: 0, totalPages: 3),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Brand mark
                  OnboardingEntrance(
                    delay: const Duration(milliseconds: 80),
                    child: Row(
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
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  const Expanded(child: _AnimatedTreeIllustration()),
                  const SizedBox(height: AppSpacing.l),

                  OnboardingEntrance(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      'Xush kelibsiz, Ustoz!',
                      style:
                          AppTextStyles.displayM.copyWith(color: AppColors.ink),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  OnboardingEntrance(
                    delay: const Duration(milliseconds: 250),
                    child: Text(
                      "A'lochi platformasi sizning ish faoliyatingizni soddalashtiradi",
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.brandMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  const _AnimatedFeatureBullets(),
                  const SizedBox(height: AppSpacing.xl),

                  OnboardingEntrance(
                    delay: const Duration(milliseconds: 450),
                    child: AlochiButton.primary(
                      label: 'Davom etish',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () =>
                          context.go('/teacher/onboarding/features'),
                    ),
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

// ─── Animated tree illustration ───────────────────────────────────────────────

class _AnimatedTreeIllustration extends StatefulWidget {
  const _AnimatedTreeIllustration();

  @override
  State<_AnimatedTreeIllustration> createState() =>
      _AnimatedTreeIllustrationState();
}

class _AnimatedTreeIllustrationState extends State<_AnimatedTreeIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Center(
          child: Container(
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
          ),
        ),
      ),
    );
  }
}

// ─── Animated feature bullets ─────────────────────────────────────────────────

class _AnimatedFeatureBullets extends StatelessWidget {
  const _AnimatedFeatureBullets();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.checklist_rounded, 'Davomat va baholarni bir joyda'),
      (
        Icons.chat_bubble_outline_rounded,
        "O'quvchilar bilan to'g'ridan-to'g'ri aloqa"
      ),
      (Icons.auto_awesome_rounded, 'AI yordami har qadamda'),
    ];
    return Column(
      children: items.indexed.map((entry) {
        final (i, item) = entry;
        return OnboardingStaggerItem(
          index: i + 3,
          child: Padding(
            padding: EdgeInsets.only(
                bottom: i < items.length - 1 ? AppSpacing.m : 0),
            child: _BulletRow(icon: item.$1, text: item.$2),
          ),
        );
      }).toList(),
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
