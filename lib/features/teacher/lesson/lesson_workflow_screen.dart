import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../shared/widgets/alochi_button.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../core/models/lesson_detail_model.dart';
import '../../../core/models/student_model.dart';
import '../../../core/models/attendance_model.dart';
import '../attendance/attendance_provider.dart';
import '../homework/homework_provider.dart';
import 'lesson_provider.dart';

// Local provider for homework check (did they do it?)
final homeworkCheckProvider = StateProvider.autoDispose
    .family<Set<String>, String>((ref, lessonId) => {});

// Local provider for activity rating (1=Zaif, 2=O'rta, 3=Yaxshi)
final activityRatingProvider = StateProvider.autoDispose
    .family<Map<String, int>, String>((ref, lessonId) => {});

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
                style:
                    AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted),
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
        loading: () => const AlochiAppBar(title: 'Dars'),
        error: (_, __) => const AlochiAppBar(title: 'Dars'),
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
            subtitle: "O'quvchilar kelganini tekshiring",
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
            title: 'Aktivlikni baholash',
            subtitle: "Darsdagi qatnashuvni belgilang",
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
                            ? const Color(0xFF0F9A6E)
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
                                ? const Color(0xFF0F9A6E)
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
      iconColor = const Color(0xFF0F9A6E);
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
                        color:
                            isLocked ? const Color(0xFF9CA3AF) : AppColors.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyS
                          .copyWith(color: AppColors.brandMuted),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF0F9A6E), size: 22)
              else if (isLocked)
                const Icon(Icons.lock_rounded,
                    color: Color(0xFFD1D5DB), size: 18),
            ],
          ),
          if (isActive && step == WorkflowStep.attendance) ...[
            const SizedBox(height: AppSpacing.l),
            _Step1Content(
                lesson: lesson, lessonId: lessonId, notifier: notifier),
          ],
          if (isActive && step == WorkflowStep.homework) ...[
            const SizedBox(height: AppSpacing.l),
            _Step2HomeworkCheck(
                lesson: lesson, lessonId: lessonId, notifier: notifier),
          ],
          if (isActive && step == WorkflowStep.grading) ...[
            const SizedBox(height: AppSpacing.l),
            _Step3ActivityContent(
                lesson: lesson, lessonId: lessonId, notifier: notifier),
          ],
          if (isActive && step == WorkflowStep.finish) ...[
            const SizedBox(height: AppSpacing.l),
            _Step4FinishContent(lesson: lesson, notifier: notifier),
          ],
        ],
      ),
    );
  }
}

// ─── Step 1 — Davomat ────────────────────────────────────────────────────────

class _Step1Content extends ConsumerWidget {
  final LessonDetailModel lesson;
  final String lessonId;
  final LessonWorkflowNotifier notifier;

  const _Step1Content({
    required this.lesson,
    required this.lessonId,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = _todayString();
    final key = (classId: lesson.groupId, date: today);
    final stateAsync = ref.watch(attendanceMarkingProvider(key));

    return stateAsync.when(
      data: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.markedCount > 0)
            _AttendanceSummaryChips(state: state)
          else
            const Text('Davomat hali olinmagan', style: AppTextStyles.bodyS),
          const SizedBox(height: AppSpacing.m),
          Row(
            children: [
              Expanded(
                child: AlochiButton.primary(
                  label: state.markedCount > 0 ? "Tahrirlash" : "Davomat olish",
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
              ),
              if (state.markedCount > 0) ...[
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: AlochiButton.secondary(
                    label: "Keyingi",
                    onPressed: () =>
                        notifier.completeStep(WorkflowStep.attendance),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brand)),
      error: (_, __) => AlochiButton.primary(
        label: "Davomatga o'tish",
        onPressed: () => context.push(
          '/teacher/lesson/$lessonId/attendance',
          extra: {'classId': lesson.groupId, 'date': today},
        ),
      ),
    );
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

class _AttendanceSummaryChips extends StatelessWidget {
  final AttendanceMarkingState state;

  const _AttendanceSummaryChips({required this.state});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _AttChip(
            count: state.presentCount,
            label: 'Keldi',
            color: const Color(0xFF0F9A6E)),
        _AttChip(
            count: state.lateCount,
            label: 'Kech',
            color: const Color(0xFFD97706)),
        _AttChip(
            count: state.absentCount, label: "Yo'q", color: AppColors.danger),
      ],
    );
  }
}

class _AttChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _AttChip(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.round),
      ),
      child: Text(
        '$count $label',
        style: AppTextStyles.caption
            .copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Step 2 — Vazifa tekshirish ──────────────────────────────────────────────

class _Step2HomeworkCheck extends ConsumerWidget {
  final LessonDetailModel lesson;
  final String lessonId;
  final LessonWorkflowNotifier notifier;

  const _Step2HomeworkCheck({
    required this.lesson,
    required this.lessonId,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkedStudents = ref.watch(homeworkCheckProvider(lessonId));
    final checkNotifier = ref.read(homeworkCheckProvider(lessonId).notifier);

    // Get students from attendance provider
    final today = _todayString();
    final key = (classId: lesson.groupId, date: today);
    final attAsync = ref.watch(attendanceMarkingProvider(key));

    return attAsync.when(
      data: (state) {
        final students = state.students;
        if (students.isEmpty) {
          return const Text("O'quvchilar yo'q");
        }

        // Filter: only present/late students should be checked for homework in person
        final attendingStudents = students.where((s) {
          final status = state.statuses[s.id];
          return status == AttendanceStatus.present ||
              status == AttendanceStatus.late;
        }).toList();

        return Column(
          children: [
            ...attendingStudents.map((s) {
              final isChecked = checkedStudents.contains(s.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s),
                child: Row(
                  children: [
                    AlochiAvatar(name: s.fullName, size: 32),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Text(
                        s.fullName,
                        style:
                            AppTextStyles.bodyS.copyWith(color: AppColors.ink),
                      ),
                    ),
                    Checkbox(
                      value: isChecked,
                      activeColor: AppColors.brand,
                      onChanged: (v) {
                        final current = Set<String>.from(checkedStudents);
                        if (v == true) {
                          current.add(s.id);
                        } else {
                          current.remove(s.id);
                        }
                        checkNotifier.state = current;
                      },
                    ),
                  ],
                ),
              );
            }),
            if (attendingStudents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
                child: Text('Bugun darsda hech kim yo\'q',
                    style: AppTextStyles.bodyS),
              ),
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                Expanded(
                  child: AlochiButton.secondary(
                    label: 'Orqaga',
                    onPressed: () => notifier.backStep(WorkflowStep.homework),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: AlochiButton.primary(
                    label: 'Tasdiqlash',
                    onPressed: () =>
                        notifier.completeStep(WorkflowStep.homework),
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brand)),
      error: (_, __) => AlochiButton.primary(
        label: "O'tkazib yuborish",
        onPressed: () => notifier.completeStep(WorkflowStep.homework),
      ),
    );
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

// ─── Step 3 — Aktivlikni baholash ───────────────────────────────────────────

class _Step3ActivityContent extends ConsumerWidget {
  final LessonDetailModel lesson;
  final String lessonId;
  final LessonWorkflowNotifier notifier;

  const _Step3ActivityContent({
    required this.lesson,
    required this.lessonId,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratings = ref.watch(activityRatingProvider(lessonId));
    final ratingNotifier = ref.read(activityRatingProvider(lessonId).notifier);

    // Get students from attendance
    final today = _todayString();
    final attKey = (classId: lesson.groupId, date: today);
    final attAsync = ref.watch(attendanceMarkingProvider(attKey));

    final students = attAsync.valueOrNull?.students.where((s) {
          final status = attAsync.valueOrNull?.statuses[s.id];
          return status == AttendanceStatus.present ||
              status == AttendanceStatus.late;
        }).toList() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (students.isEmpty)
          const Text("Darsda o'quvchilar yo'q")
        else
          Column(
            children: students
                .map((s) => _ActivityRatingRow(
                      student: s,
                      rating: ratings[s.id] ?? 0,
                      onChanged: (r) {
                        final current = Map<String, int>.from(ratings);
                        current[s.id] = r;
                        ratingNotifier.state = current;
                      },
                    ))
                .toList(),
          ),
        const SizedBox(height: AppSpacing.m),
        Row(
          children: [
            Expanded(
              child: AlochiButton.secondary(
                label: 'Orqaga',
                onPressed: () => notifier.backStep(WorkflowStep.grading),
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: AlochiButton.primary(
                label: "Keyingisi ›",
                onPressed: () => notifier.completeStep(WorkflowStep.grading),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

class _ActivityRatingRow extends StatelessWidget {
  final StudentModel student;
  final int rating;
  final ValueChanged<int> onChanged;

  const _ActivityRatingRow({
    required this.student,
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        children: [
          AlochiAvatar(name: student.fullName, size: 32),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Text(
              student.fullName,
              style: AppTextStyles.bodyS.copyWith(color: AppColors.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _RatingSegmented(value: rating, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _RatingSegmented extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _RatingSegmented({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RateBtn(
            val: 1,
            label: 'Zaif',
            color: AppColors.danger,
            active: value == 1,
            onTap: () => onChanged(1)),
        const SizedBox(width: 4),
        _RateBtn(
            val: 2,
            label: 'O\'rta',
            color: const Color(0xFFD97706),
            active: value == 2,
            onTap: () => onChanged(2)),
        const SizedBox(width: 4),
        _RateBtn(
            val: 3,
            label: 'Yaxshi',
            color: const Color(0xFF0F9A6E),
            active: value == 3,
            onTap: () => onChanged(3)),
      ],
    );
  }
}

class _RateBtn extends StatelessWidget {
  final int val;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _RateBtn(
      {required this.val,
      required this.label,
      required this.color,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? color : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: active ? Colors.white : const Color(0xFF6B7280),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Step 4 — Yakunlash ──────────────────────────────────────────────────────

class _Step4FinishContent extends ConsumerStatefulWidget {
  final LessonDetailModel lesson;
  final LessonWorkflowNotifier notifier;

  const _Step4FinishContent({
    required this.lesson,
    required this.notifier,
  });

  @override
  ConsumerState<_Step4FinishContent> createState() => _Step4ContentState();
}

class _Step4ContentState extends ConsumerState<_Step4FinishContent> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  int? _deadlineDays;
  bool _telegramPoll = true;
  bool _isFinishing = false;

  static const _deadlineOptions = [
    (label: 'Bugun', days: 0),
    (label: 'Erta', days: 1),
    (label: '3 kun', days: 3),
    (label: '1 hafta', days: 7),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createStatus = ref.watch(homeworkCreateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yangi uy vazifasi (ixtiyoriy)',
          style: AppTextStyles.label.copyWith(
            color: AppColors.brandMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        TextField(
          controller: _titleController,
          style: AppTextStyles.body.copyWith(color: AppColors.ink),
          decoration: InputDecoration(
            hintText: 'Mavzu...',
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.brandMuted),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.m),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.m),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Wrap(
          spacing: 8,
          children: _deadlineOptions.map((opt) {
            final isSelected = _deadlineDays == opt.days;
            return ChoiceChip(
              label: Text(opt.label),
              selected: isSelected,
              onSelected: (v) =>
                  setState(() => _deadlineDays = v ? opt.days : null),
              selectedColor: AppColors.brandSoft,
              labelStyle: AppTextStyles.label.copyWith(
                color: isSelected ? AppColors.brand : AppColors.ink,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.m),
        Row(
          children: [
            const Icon(Icons.telegram_rounded,
                color: Color(0xFF0088CC), size: 20),
            const SizedBox(width: 8),
            const Expanded(
                child:
                    Text('Telegram so\'rovnoma', style: AppTextStyles.bodyS)),
            Switch.adaptive(
              value: _telegramPoll,
              onChanged: (v) => setState(() => _telegramPoll = v),
              activeTrackColor: AppColors.brand,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.l),
        AlochiButton.primary(
          label: 'Darsni yakunlash',
          icon: Icons.flag_rounded,
          isLoading: _isFinishing || createStatus.isLoading,
          onPressed: (_isFinishing || createStatus.isLoading) ? null : _finish,
        ),
      ],
    );
  }

  Future<void> _finish() async {
    setState(() => _isFinishing = true);

    // Create homework if title is provided
    if (_titleController.text.trim().isNotEmpty) {
      final days = _deadlineDays ?? 7;
      final deadline = DateTime.now().add(Duration(days: days));
      final dueDateStr =
          '${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}';

      await ref.read(homeworkCreateProvider.notifier).create(
            groupId: widget.lesson.groupId,
            title: _titleController.text.trim(),
            description: _descController.text.trim(),
            dueDate: dueDateStr,
          );
    }

    widget.notifier.completeStep(WorkflowStep.finish);

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dars yakunlandi'),
          backgroundColor: Color(0xFF0F9A6E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
