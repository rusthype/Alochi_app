import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../teacher/students/birthday_provider.dart';

/// Dashboard'da pastki qismda ko'rsatiladigan yengil banner.
/// Faqat bugungi va 7 kunlik tug'ilgan kunlar bo'lsa ko'rinadi.
class BirthdayDashboardBanner extends ConsumerWidget {
  const BirthdayDashboardBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(birthdayStudentsProvider);
    return async.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final todayCount = list.where((s) => s.isToday).length;
        final label = todayCount > 0
            ? "$todayCount nafar o'quvchining bugun tug'ilgan kuni!"
            : "${list.length} nafar o'quvchining yaqin 7 kunda tug'ilgan kuni";

        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l, vertical: AppSpacing.s),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/teacher/birthdays'),
              borderRadius: BorderRadius.circular(AppRadii.l),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadii.l),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Text('🎂', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTextStyles.bodyS.copyWith(
                          color: AppColors.accentInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: AppColors.accent.withValues(alpha: 0.7),
                        size: 18),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
