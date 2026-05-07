import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../shared/widgets/alochi_skeleton.dart';
import 'birthday_provider.dart';

class BirthdaysScreen extends ConsumerWidget {
  const BirthdaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birthdaysAsync = ref.watch(birthdayStudentsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AlochiAppBar(title: "Tug'ilgan kunlar"),
      body: birthdaysAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return const AlochiEmptyState(
              icon: Icons.cake_outlined,
              title: "Yaqin kunlarda tug'ilgan kun yo'q",
              subtitle: "Keyingi 7 kunda hech kim tug'ilmaydi",
            );
          }
          final today = list.where((s) => s.isToday).toList();
          final upcoming = list.where((s) => !s.isToday).toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.l),
            children: [
              if (today.isNotEmpty) ...[
                const _SectionHeader(
                    title: 'BUGUN',
                    icon: Icons.cake_rounded,
                    color: AppColors.accent),
                const SizedBox(height: AppSpacing.s),
                ...today.map((s) => _BirthdayCard(student: s)),
                const SizedBox(height: AppSpacing.l),
              ],
              if (upcoming.isNotEmpty) ...[
                const _SectionHeader(
                    title: 'YAQIN 7 KUN',
                    icon: Icons.calendar_today_outlined,
                    color: AppColors.brand),
                const SizedBox(height: AppSpacing.s),
                ...upcoming.map((s) => _BirthdayCard(student: s)),
              ],
            ],
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.l),
          itemCount: 5,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s),
            child: AlochiSkeleton(
              height: 72,
              borderRadius: BorderRadius.circular(AppRadii.l),
            ),
          ),
        ),
        error: (e, _) => AlochiEmptyState(
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.danger,
          title: 'Yuklab bo\'lmadi',
          subtitle: e.toString(),
          actionLabel: 'Qayta',
          onAction: () => ref.invalidate(birthdayStudentsProvider),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader(
      {required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(title,
            style: AppTextStyles.caption.copyWith(
                color: color, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ],
    );
  }
}

class _BirthdayCard extends ConsumerWidget {
  final BirthdayStudentModel student;

  const _BirthdayCard({required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: student.isToday
            ? AppColors.accentSoft
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(
          color: student.isToday
              ? AppColors.accent.withValues(alpha: 0.35)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AlochiAvatar(name: student.name, size: 44),
              if (student.isToday)
                const Positioned(
                  right: -4,
                  top: -4,
                  child: Text('🎂', style: TextStyle(fontSize: 16)),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name,
                    style: AppTextStyles.titleM.copyWith(
                        color: AppColors.ink, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(student.groupName,
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.gray)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: student.isToday ? AppColors.accent : AppColors.brandSoft,
              borderRadius: BorderRadius.circular(AppRadii.round),
            ),
            child: Text(
              birthdayDaysLabel(student.birthday),
              style: AppTextStyles.caption.copyWith(
                  color: student.isToday ? Colors.white : AppColors.brand,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
