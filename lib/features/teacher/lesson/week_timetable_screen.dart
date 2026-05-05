import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/lesson_model.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_card.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../shared/widgets/alochi_skeleton.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import 'lesson_list_provider.dart';

class WeekTimetableScreen extends ConsumerWidget {
  const WeekTimetableScreen({super.key});

  static const _dayNames = {
    'monday': 'Dushanba',
    'tuesday': 'Seshanba',
    'wednesday': 'Chorshanba',
    'thursday': 'Payshanba',
    'friday': 'Juma',
    'saturday': 'Shanba',
  };

  static const _dayOrder = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekAsync = ref.watch(weekLessonsProvider);
    // Today's day name in English
    final todayDays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    final todayKey = todayDays[DateTime.now().weekday - 1];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AlochiAppBar(title: 'Dars jadvali'),
      body: weekAsync.when(
        data: (week) {
          // Filter only days that have lessons
          final activeDays =
              _dayOrder.where((d) => week[d]?.isNotEmpty == true).toList();

          if (activeDays.isEmpty) {
            return const AlochiEmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'Dars jadvali yo\'q',
              subtitle: 'Admin hali jadval kiritmagmagan',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.l),
            itemCount: activeDays.length,
            itemBuilder: (context, index) {
              final dayKey = activeDays[index];
              final lessons = week[dayKey] ?? [];
              final isToday = dayKey == todayKey;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day header
                  Container(
                    margin: EdgeInsets.only(
                      top: index == 0 ? 0 : AppSpacing.l,
                      bottom: AppSpacing.s,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.brand : AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(AppRadii.m),
                    ),
                    child: Text(
                      isToday
                          ? '\${_dayNames[dayKey]} (Bugun)'
                          : _dayNames[dayKey] ?? dayKey,
                      style: AppTextStyles.label.copyWith(
                        color: isToday ? Colors.white : AppColors.brand,
                      ),
                    ),
                  ),
                  // Lessons list
                  ...lessons.map((lesson) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s),
                        child:
                            _TimetableLessonCard(lesson: lesson, isToday: isToday),
                      )),
                ],
              );
            },
          );
        },
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.l),
          children: const [
            AlochiSkeletonCard(height: 40),
            AlochiSkeletonCard(height: 80),
            AlochiSkeletonCard(height: 80),
            SizedBox(height: AppSpacing.m),
            AlochiSkeletonCard(height: 40),
            AlochiSkeletonCard(height: 80),
          ],
        ),
        error: (e, _) => AlochiEmptyState(
          icon: Icons.error_outline,
          title: 'Yuklab bo\'lmadi',
          subtitle: 'Qayta urinib ko\'ring',
          actionLabel: 'Yangilash',
          onAction: () => ref.invalidate(weekLessonsProvider),
        ),
      ),
    );
  }
}

class _TimetableLessonCard extends StatelessWidget {
  final LessonModel lesson;
  final bool isToday;
  const _TimetableLessonCard({required this.lesson, required this.isToday});

  @override
  Widget build(BuildContext context) {
    return AlochiCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Row(
          children: [
            // Time
            SizedBox(
              width: 50,
              child: Column(
                children: [
                  Text(
                    lesson.startTime,
                    style: AppTextStyles.label.copyWith(
                      color: lesson.isNow ? AppColors.brand : AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    lesson.endTime,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.brandMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Container(
                width: 2,
                height: 40,
                color: isToday ? AppColors.brand : AppColors.brandSoft),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesson.subject, style: AppTextStyles.label),
                  Text(
                    '\${lesson.groupName} · \${lesson.studentsCount} o\'quvchi',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.brandMuted),
                  ),
                  if (lesson.room.isNotEmpty)
                    Text(
                      lesson.room,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.brandMuted),
                    ),
                ],
              ),
            ),
            if (lesson.isNow)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
                child: Text('Hozir',
                    style:
                        AppTextStyles.caption.copyWith(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
