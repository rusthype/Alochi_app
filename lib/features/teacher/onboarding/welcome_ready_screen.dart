import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../shared/widgets/alochi_button.dart';
import '../../../shared/widgets/alochi_card.dart';
import '../../auth/auth_provider.dart';
import 'onboarding_widgets.dart';
import 'welcome_intro_screen.dart';

class WelcomeReadyScreen extends ConsumerStatefulWidget {
  const WelcomeReadyScreen({super.key});

  @override
  ConsumerState<WelcomeReadyScreen> createState() => _WelcomeReadyScreenState();
}

class _WelcomeReadyScreenState extends ConsumerState<WelcomeReadyScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confetti;
  late AnimationController _iconCtrl;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _iconCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _iconCtrl.forward();
        _confetti.play();
      }
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await markOnboardingComplete();
    await ref.read(authProvider.notifier).clearOnboardingFlag();
    if (mounted) context.go('/teacher/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Confetti
            ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              colors: const [
                AppColors.brand,
                AppColors.accent,
                AppColors.success,
                AppColors.info,
              ],
              shouldLoop: false,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.l),
                  const OnboardingEntrance(
                    child:
                        OnboardingPageIndicator(activeIndex: 2, totalPages: 3),
                  ),
                  const Spacer(),

                  // Animated checkmark
                  ScaleTransition(
                    scale: _iconScale,
                    child: Center(
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
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  OnboardingEntrance(
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      'Tayyorsiz!',
                      style:
                          AppTextStyles.displayL.copyWith(color: AppColors.ink),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  OnboardingEntrance(
                    delay: const Duration(milliseconds: 380),
                    child: Text(
                      "A'lochi Ustoz panelidan foydalanishni boshlang",
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.brandMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  OnboardingEntrance(
                    delay: const Duration(milliseconds: 460),
                    child: AlochiCard(
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
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.ink),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  OnboardingEntrance(
                    delay: const Duration(milliseconds: 540),
                    child: AlochiButton.primary(
                      label: 'Boshlash',
                      onPressed: _finish,
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
