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
import '../attendance/attendance_provider.dart';
import '../grades/grades_provider.dart';
import 'lesson_provider.dart';

// Local provider for homework check (did they do it?)
final homeworkCheckProvider = StateProvider.autoDispose.family<Set<String>, String>((ref, lessonId) => {});

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
            title: 'Baholash',
            subtitle: "Darsdagi aktivlikni baholang",
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
                    color: AppColors.success, size: 22)
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
            _Step3GradingContent(
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

    // Get students from attendance provider if possible
    final today = _todayString();
    final key = (classId: lesson.groupId, date: today);
    final attAsync = ref.watch(attendanceMarkingProvider(key));

    return attAsync.when(
      data: (state) {
        final students = state.students;
        if (students.isEmpty) {
          return const Text("O'quvchilar yo'q");
        }
        return Column(
          children: [
            ...students.map((s) {
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

// ─── Step 3 — Baholash ───────────────────────────────────────────────────────

class _Step3GradingContent extends ConsumerWidget {
  final LessonDetailModel lesson;
  final String lessonId;
  final LessonWorkflowNotifier notifier;

  const _Step3GradingContent({
    required this.lesson,
    required this.lessonId,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = _todayString();
    final key = (
      groupId: lesson.groupId,
      date: today,
    );
    final editState = ref.watch(gradeEditProvider(key));
    final gradeNotifier = ref.read(gradeEditProvider(key).notifier);

    // Get students from attendance
    final attKey = (classId: lesson.groupId, date: today);
    final attAsync = ref.watch(attendanceMarkingProvider(attKey));

    ref.listen<GradeEditState>(gradeEditProvider(key), (prev, next) {
      if (next.savedSuccessfully && !(prev?.savedSuccessfully ?? false)) {
        notifier.completeStep(WorkflowStep.grading);
      }
    });

    final students = attAsync.valueOrNull?.students ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (students.isEmpty)
          const Text("O'quvchilar topilmadi")
        else
          Column(
            children: students
                .map((s) => _InlineGradeRow(
                      student: s,
                      grade: editState.pending[s.id] ?? 0,
                      onGradeChanged: (g) => gradeNotifier.setGrade(s.id, g),
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
                label: editState.hasChanges ? 'Saqlash' : "O'tkazish",
                isLoading: editState.isSaving,
                onPressed: editState.isSaving
                    ? null
                    : () {
                        if (editState.hasChanges) {
                          gradeNotifier.saveAll();
                        } else {
                          notifier.completeStep(WorkflowStep.grading);
                        }
                      },
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

class _InlineGradeRow extends StatelessWidget {
  final StudentModel student;
  final int grade;
  final ValueChanged<int> onGradeChanged;

  const _InlineGradeRow({
    required this.student,
    required this.grade,
    required this.onGradeChanged,
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
          _MiniGradeSegmented(value: grade, onChanged: onGradeChanged),
        ],
      ),
    );
  }
}

class _MiniGradeSegmented extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _MiniGradeSegmented({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const grades = [2, 3, 4, 5];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: grades.map((g) {
        final isSelected = value == g;
        return GestureDetector(
          onTap: () => onChanged(isSelected ? 0 : g),
          child: Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(left: 3),
            decoration: BoxDecoration(
              color: isSelected ? _gradeColor(g) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            alignment: Alignment.center,
            child: Text(
              '$g',
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _gradeColor(int grade) {
    switch (grade) {
      case 5:
        return const Color(0xFF0F9A6E);
      case 4:
        return AppColors.brand;
      case 3:
        return const Color(0xFFD97706);
      case 2:
        return AppColors.danger;
      default:
        return AppColors.brandMuted;
    }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yangi uy vazifasi',
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
              onSelected: (v) => setState(() => _deadlineDays = v ? opt.days : null),
              selectedColor: AppColors.brandSoft,
              labelStyle: AppTextStyles.label.copyWith(
                color: isSelected ? AppColors.brand : AppColors.ink,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.l),
        AlochiButton.primary(
          label: 'Darsni yakunlash',
          icon: Icons.flag_rounded,
          isLoading: _isFinishing,
          onPressed: _isFinishing ? null : _finish,
        ),
      ],
    );
  }

  Future<void> _finish() async {
    setState(() => _isFinishing = true);
    await Future.delayed(const Duration(milliseconds: 400));
    widget.notifier.completeStep(WorkflowStep.finish);
    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dars yakunlandi'), backgroundColor: Color(0xFF0F9A6E)),
      );
    }
  }
}
