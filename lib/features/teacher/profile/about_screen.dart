import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AlochiAppBar(title: "Ilova haqida"),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: AppColors.brand,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              const Text(
                "A'lochi Ustoz",
                style: AppTextStyles.displayM,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Versiya 1.1.0',
                style: AppTextStyles.body.copyWith(color: AppColors.brandMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              AlochiCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Bu ilova nima?", style: AppTextStyles.titleM),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        "A'lochi Ustoz — O'zbekiston maktablari ustozlari uchun raqamli kabinet. Davomat, baholar, vazifalar va AI yordamchi — bir joyda.",
                        style: AppTextStyles.body.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              AlochiCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Yaratuvchi", style: AppTextStyles.titleM),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        "A'lochi platformasi tomonidan yaratilgan.\nO'zbekiston, Toshkent.",
                        style: AppTextStyles.body.copyWith(color: AppColors.brandMuted),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      Text("alochi.org", style: AppTextStyles.body.copyWith(color: AppColors.brand)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Text(
                  "© 2026 A'lochi. Barcha huquqlar himoyalangan.",
                  style: AppTextStyles.caption.copyWith(color: AppColors.brandMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
