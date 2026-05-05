import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_button.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../core/models/lesson_detail_model.dart';
import 'lesson_provider.dart';

class LessonWorkflowScreen extends ConsumerWidget {
  final String lessonId;

  const LessonWorkflowScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(lessonDetailProvider(lessonId));
    final workflowState = ref.watch(lessonWorkflowProvider(lessonId));
    final notifier = ref.read(lessonWorkflowProvider(lessonId).notifier);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: lessonAsync.when(
        data: (lesson) => AlochiAppBar(
          titleWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${lesson.groupCode} · ${lesson.subjectName}',
                style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
              ),
              Text(
                '${lesson.startTime} - ${lesson.endTime}',
                style: AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted),
              ),
            ],
          ),
          actions: [
            if (lesson.isActive)
              Container(
                margin: const EdgeInsets.only(right: AppSpacing.m),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(AppRadii.round),
                ),
                child: Text(
                  'JONLI',
                  style: AppTextStyles.label.copyWith(
                      color: AppColors.brand, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        loading: () => AlochiAppBar(title: 'Dars'),
        error: (_, __) => AlochiAppBar(title: 'Dars'),
      ),
      body: lessonAsync.when(
        data: (lesson) => _LessonWorkflowBody(
          lesson: lesson,
          lessonId: lessonId,
          workflowState: workflowState,
          notifier: notifier,
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
        error: (err, _) => AlochiEmptyState(
          title: "Dars topilmadi",
          subtitle: err.toString(),
        ),
      ),
    );
  }
}

class _LessonWorkflowBody extends StatelessWidget {
  final LessonDetailModel lesson;
  final String lessonId;
  final LessonWorkflowState workflowState;
  final LessonWorkflowNotifier notifier;

  const _LessonWorkflowBody({
    required this.lesson,
    required this.lessonId,
    required this.workflowState,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WorkflowStepper(workflowState: workflowState),
          const SizedBox(height: AppSpacing.l),
          _StepCard(
            step: WorkflowStep.attendance,
            title: 'Davomat belgilash',
            subtitle: "O'quvchilar davomatini belgilang",
            icon: Icons.how_to_reg_rounded,
            workflowState: workflowState,
            lesson: lesson,
            lessonId: lessonId,
            notifier: notifier,
          ),
          const SizedBox(height: AppSpacing.m),
          _StepCard(
            step: WorkflowStep.homework,
            title: 'Vazifa tekshirish',
            subtitle: "Oldingi vazifani tekshiring",
            icon: Icons.assignment_turned_in_rounded,
            workflowState: workflowState,
            lesson: lesson,
            lessonId: lessonId,
            notifier: notifier,
          ),
          const SizedBox(height: AppSpacing.m),
          _StepCard(
            step: WorkflowStep.grading,
            title: 'Baholash',
            subtitle: "Aktivlikni baholang",
            icon: Icons.star_rounded,
            workflowState: workflowState,
            lesson: lesson,
            lessonId: lessonId,
            notifier: notifier,
          ),
          const SizedBox(height: AppSpacing.m),
          _StepCard(
            step: WorkflowStep.finish,
            title: 'Darsni yakunlash',
            subtitle: "Yangi uy vazifasi bering",
            icon: Icons.flag_rounded,
            workflowState: workflowState,
            lesson: lesson,
            lessonId: lessonId,
            notifier: notifier,
          ),
        ],
      ),
    );
  }
}

class _WorkflowStepper extends StatelessWidget {
  final LessonWorkflowState workflowState;

  const _WorkflowStepper({required this.workflowState});

  @override
  Widget build(BuildContext context) {
    const steps = WorkflowStep.values;
    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = workflowState.isCompleted(step);
        final isActive = workflowState.currentStep == step;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.success
                            : isActive
                                ? AppColors.brand
                                : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stepLabel(step),
                      style: AppTextStyles.caption.copyWith(
                        color: isActive
                            ? AppColors.brand
                            : isCompleted
                                ? AppColors.success
                                : AppColors.brandMuted,
                        fontWeight: isActive || isCompleted
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1) const SizedBox(width: 2),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _stepLabel(WorkflowStep step) {
    switch (step) {
      case WorkflowStep.attendance:
        return 'Davomat';
      case WorkflowStep.homework:
        return 'Vazifa';
      case WorkflowStep.grading:
        return 'Baholash';
      case WorkflowStep.finish:
        return 'Yakun';
    }
  }
}

class _StepCard extends StatelessWidget {
  final WorkflowStep step;
  final String title;
  final String subtitle;
  final IconData icon;
  final LessonWorkflowState workflowState;
  final LessonDetailModel lesson;
  final String lessonId;
  final LessonWorkflowNotifier notifier;

  const _StepCard({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.workflowState,
    required this.lesson,
    required this.lessonId,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = workflowState.isCompleted(step);
    final isActive = workflowState.currentStep == step;
    final isLocked = workflowState.isLocked(step);

    Color borderColor;
    Color bgColor;
    Color iconColor;
    Color iconBg;

    if (isCompleted) {
      borderColor = const Color(0xFFE1F5EE);
      bgColor = const Color(0xFFF8FFFD);
      iconColor = AppColors.success;
      iconBg = const Color(0xFFE1F5EE);
    } else if (isActive) {
      borderColor = AppColors.brandLight;
      bgColor = Colors.white;
      iconColor = AppColors.brand;
      iconBg = AppColors.brandSoft;
    } else {
      borderColor = const Color(0xFFE5E7EB);
      bgColor = const Color(0xFFFAFAFA);
      iconColor = const Color(0xFFD1D5DB);
      iconBg = const Color(0xFFF3F4F6);
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadii.s),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleM.copyWith(
                        color: isLocked
                            ? const Color(0xFF9CA3AF)
                            : AppColors.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyS.copyWith(
                          color: AppColors.brandMuted),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 22)
              else if (isLocked)
                const Icon(Icons.lock_rounded,
                    color: Color(0xFFD1D5DB), size: 18),
            ],
          ),
          if (isActive && step == WorkflowStep.attendance) ...[
            const SizedBox(height: AppSpacing.l),
            _Step1Content(lesson: lesson, lessonId: lessonId, notifier: notifier),
          ],
          if (isActive && step != WorkflowStep.attendance) ...[
            const SizedBox(height: AppSpacing.l),
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(AppRadii.s),
              ),
              child: Text(
                'Bu qadam Day 3 da to\'ldiriladi',
                style: AppTextStyles.bodyS.copyWith(color: AppColors.brandInk),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Step1Content extends StatelessWidget {
  final LessonDetailModel lesson;
  final String lessonId;
  final LessonWorkflowNotifier notifier;

  const _Step1Content({
    required this.lesson,
    required this.lessonId,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final today = _todayString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _InfoChip(
              icon: Icons.people_outline_rounded,
              label: "${lesson.studentCount} o'quvchi",
            ),
            const SizedBox(width: AppSpacing.s),
            _InfoChip(
              icon: Icons.schedule_rounded,
              label: '${lesson.startTime} - ${lesson.endTime}',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        AlochiButton.primary(
          label: "Davomatga o'tish",
          icon: Icons.how_to_reg_rounded,
          onPressed: () {
            context.push(
              '/teacher/lesson/$lessonId/attendance',
              extra: {
                'classId': lesson.groupId,
                'date': today,
              },
            );
          },
        ),
        const SizedBox(height: AppSpacing.s),
        AlochiButton.secondary(
          label: "Davomatni o'tkazdim",
          onPressed: () => notifier.completeStep(WorkflowStep.attendance),
        ),
      ],
    );
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(AppRadii.round),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.brandMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.brandMuted),
          ),
        ],
      ),
    );
  }
}
