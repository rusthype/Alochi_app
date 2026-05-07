import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_button.dart';

const _kAiWelcomeSeenKey = 'ai_welcome_seen_v1';

Future<bool> aiWelcomeSeen() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAiWelcomeSeenKey) ?? false;
  } catch (_) {
    return false;
  }
}

Future<void> markAiWelcomeSeen() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAiWelcomeSeenKey, true);
  } catch (_) {}
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AiWelcomeScreen extends StatelessWidget {
  const AiWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'AI Yordamchi',
          style: AppTextStyles.titleM.copyWith(color: AppColors.accent),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.ink, size: 20),
          onPressed: () => context.go('/teacher/dashboard'),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              _AiHeroSection(),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                "Nima qila olaman?",
                style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: AppSpacing.m),
              const _FeatureCard(
                icon: Icons.assignment_outlined,
                title: 'Vazifa yarating',
                subtitle:
                    "O'quvchilar uchun har xil darajadagi uy vazifalarini tez yozing",
              ),
              const SizedBox(height: AppSpacing.s),
              const _FeatureCard(
                icon: Icons.bar_chart_rounded,
                title: "O'quvchi tahlili",
                subtitle:
                    "Guruhingiz o'quvchilari haqida savollar bering va tavsiyalar oling",
              ),
              const SizedBox(height: AppSpacing.s),
              const _FeatureCard(
                icon: Icons.lightbulb_outline_rounded,
                title: 'Maslahat oling',
                subtitle:
                    'Dars rejalari, o\'qitish usullari va boshqa pedagogik savollarga javob oling',
              ),
              const SizedBox(height: AppSpacing.xxl),
              AlochiButton.primary(
                label: 'Boshlash',
                icon: Icons.smart_toy_outlined,
                onPressed: () async {
                  await markAiWelcomeSeen();
                  if (context.mounted) {
                    context.push('/teacher/ai/chat');
                  }
                },
              ),
              const SizedBox(height: AppSpacing.l),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero section ─────────────────────────────────────────────────────────────

class _AiHeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        Text(
          'AI Yordamchi',
          style: AppTextStyles.displayM.copyWith(
            color: AppColors.accent,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          'Sizning shaxsiy pedagogik yordamchingiz',
          style: AppTextStyles.body.copyWith(color: AppColors.brandMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Feature card ─────────────────────────────────────────────────────────────

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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(AppRadii.m),
            ),
            child: Icon(icon, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style:
                      AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
