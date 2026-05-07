import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/lesson_model.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_button.dart';
import '../../../shared/widgets/alochi_card.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../shared/widgets/alochi_skeleton.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import 'lesson_provider.dart';

class LessonDetailScreen extends ConsumerWidget {
  final String lessonId;
  final LessonModel? lesson;

  const LessonDetailScreen({
    required this.lessonId,
    this.lesson,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If lesson is passed, use it. Otherwise, fetch it.
    // For now, let's try to fetch if not provided to ensure we have groupId etc.
    final lessonAsync = ref.watch(lessonDetailProvider(lessonId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: lessonAsync.when(
        data: (l) => AlochiAppBar(
          titleWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.subjectName, style: AppTextStyles.titleL),
              Text(l.groupCode, style: AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted)),
            ],
          ),
        ),
        loading: () => AlochiAppBar(
          titleWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lesson?.subject ?? 'Dars', style: AppTextStyles.titleL),
              if (lesson?.groupName != null)
                Text(lesson!.groupName, style: AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted)),
            ],
          ),
        ),
        error: (_, __) => const AlochiAppBar(title: 'Dars'),
      ),
      body: lessonAsync.when(
        data: (lessonDetail) => _LessonDetailBody(lesson: lessonDetail),
        loading: () => lesson != null
            ? _LessonDetailBodyFromModel(lesson: lesson!)
            : const _LessonDetailLoadingSkeleton(),
        error: (err, __) => AlochiEmptyState(
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.danger,
          title: 'Yuklab bo\'lmadi',
          subtitle: 'Qayta urinib ko\'ring',
          actionLabel: 'Yangilash',
          onAction: () => ref.invalidate(lessonDetailProvider(lessonId)),
        ),
      ),
    );
  }
}

class _LessonDetailBody extends StatelessWidget {
  final dynamic lesson; // Can be LessonDetailModel or LessonModel (with groupId)

  const _LessonDetailBody({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final String subject = lesson is LessonModel ? lesson.subject : lesson.subjectName;
    final String groupName = lesson is LessonModel ? lesson.groupName : lesson.groupCode;
    final String startTime = lesson is LessonModel ? lesson.startTime : lesson.startTime;
    final String endTime = lesson is LessonModel ? lesson.endTime : lesson.endTime;
    final String room = lesson is LessonModel ? lesson.room : '';
    final int studentCount = lesson is LessonModel ? lesson.studentsCount : lesson.studentCount;
    final String groupId = lesson is LessonModel ? (lesson.groupId ?? '') : lesson.groupId;
    final bool isNow = lesson is LessonModel ? lesson.isNow : lesson.isActive;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Lesson info card
          AlochiCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.access_time,
                    label: 'Vaqt',
                    value: '$startTime — $endTime',
                  ),
                  const Divider(height: AppSpacing.l),
                  _InfoRow(
                    icon: Icons.group_outlined,
                    label: 'Guruh',
                    value: '$groupName · $studentCount o\'quvchi',
                  ),
                  if (room.isNotEmpty) ...[
                    const Divider(height: AppSpacing.l),
                    _InfoRow(
                      icon: Icons.room_outlined,
                      label: 'Xona',
                      value: room,
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (isNow) ...[
            const SizedBox(height: AppSpacing.s),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.s,
              ),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(AppRadii.m),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.circle, size: 8, color: Colors.white),
                  const SizedBox(width: AppSpacing.s),
                  Text(
                    'Dars hozir ketmoqda',
                    style: AppTextStyles.label.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),
          const Text('Amallar', style: AppTextStyles.titleM),
          const SizedBox(height: AppSpacing.m),

          // Action buttons
          AlochiButton.primary(
            label: 'Davomat olish',
            icon: Icons.how_to_reg_outlined,
            onPressed: () => context.push(
              '/teacher/lesson/${lesson.id}/attendance',
              extra: {
                'classId': groupId,
                'date': DateTime.now().toIso8601String().split('T').first,
              },
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          AlochiButton.secondary(
            label: 'Baho qo\'yish',
            icon: Icons.star_outline,
            onPressed: () => context.push(
              '/teacher/groups/$groupId/grades',
              extra: {
                'subject': subject,
                'groupName': groupName,
              },
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          AlochiButton.secondary(
            label: 'Vazifa berish',
            icon: Icons.assignment_outlined,
            onPressed: () => context.push('/teacher/homework/create'),
          ),
          const SizedBox(height: AppSpacing.m),
          AlochiButton.secondary(
            label: 'Darsni boshlash',
            icon: Icons.play_arrow_outlined,
            onPressed: () => context.push('/teacher/lesson/${lesson.id}'),
          ),
        ],
      ),
    );
  }
}

class _LessonDetailBodyFromModel extends StatelessWidget {
  final LessonModel lesson;
  const _LessonDetailBodyFromModel({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return _LessonDetailBody(lesson: lesson);
  }
}

class _LessonDetailLoadingSkeleton extends StatelessWidget {
  const _LessonDetailLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.l),
      children: const [
        AlochiSkeletonCard(height: 100),
        SizedBox(height: AppSpacing.xl),
        AlochiSkeleton(height: 20, width: 80),
        SizedBox(height: AppSpacing.m),
        AlochiSkeletonCard(height: 48),
        SizedBox(height: AppSpacing.m),
        AlochiSkeletonCard(height: 48),
        SizedBox(height: AppSpacing.m),
        AlochiSkeletonCard(height: 48),
        SizedBox(height: AppSpacing.m),
        AlochiSkeletonCard(height: 48),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.brand),
        const SizedBox(width: AppSpacing.m),
        Text(label, style: AppTextStyles.body.copyWith(color: AppColors.brandMuted)),
        const Spacer(),
        Expanded(
          child: Text(
            value, 
            style: AppTextStyles.label,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
