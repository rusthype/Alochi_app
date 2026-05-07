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
import '../../../core/models/lesson_detail_model.dart';
import '../../../core/models/student_model.dart';
import '../../../core/models/attendance_model.dart';
import '../attendance/attendance_provider.dart';
import '../homework/homework_provider.dart';
import '../dashboard/dashboard_provider.dart';
import '../grades/grades_provider.dart';
import '../groups/groups_provider.dart';
import 'lesson_provider.dart';

// Topic grade per student (2-5) — saved to grades/set endpoint
final topicGradeProvider =
    StateProvider.autoDispose.family<Map<String, int>, String>((ref, id) => {});

final homeworkCheckProvider =
    StateProvider.autoDispose.family<Set<String>, String>((ref, id) => {});

final activityRatingProvider =
    StateProvider.autoDispose.family<Map<String, int>, String>((ref, id) => {});

class LessonWorkflowScreen extends ConsumerWidget {
  /// groupId is used as the primary key — no /lessons/:id/ needed.
  final String lessonId;

  /// Pre-built extra data passed from LessonDetailScreen.
  final Map<String, dynamic>? extra;

  const LessonWorkflowScreen({
    super.key,
    required this.lessonId,
    this.extra,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If extra has groupId, use lessonFromGroupProvider (no 404 risk).
    // Otherwise fall back to lessonDetailProvider which tries /lessons/:id/
    // then composes from attendance on failure.
    final groupId = extra?['groupId']?.toString() ?? lessonId;
    final lessonAsync = ref.watch(lessonFromGroupProvider(groupId));

    final workflowState = ref.watch(lessonWorkflowProvider(groupId));
    final notifier = ref.read(lessonWorkflowProvider(groupId).notifier);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: lessonAsync.when(
        data: (lesson) => _buildAppBar(lesson),
        loading: () => _buildAppBarFromExtra(),
        error: (_, __) => _buildAppBarFromExtra(),
      ),
      body: lessonAsync.when(
        data: (lesson) => _LessonWorkflowBody(
          lesson: lesson,
          groupId: groupId,
          workflowState: workflowState,
          notifier: notifier,
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
        error: (err, _) {
          // Even on error, try to build from extra data
          final fallback = _buildFallbackLesson(groupId);
          return _LessonWorkflowBody(
            lesson: fallback,
            groupId: groupId,
            workflowState: workflowState,
            notifier: notifier,
          );
        },
      ),
    );
  }

  AlochiAppBar _buildAppBar(LessonDetailModel lesson) {
    final name = lesson.groupCode.isNotEmpty
        ? lesson.groupCode
        : extra?['groupName']?.toString() ?? '';
    final subject = lesson.subjectName.isNotEmpty
        ? lesson.subjectName
        : extra?['subject']?.toString() ?? 'Dars';
    final time = lesson.startTime.isNotEmpty
        ? '${lesson.startTime} - ${lesson.endTime}'
        : extra?['startTime']?.toString() ?? '';

    return AlochiAppBar(
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$name · $subject',
            style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
          ),
          if (time.isNotEmpty)
            Text(time,
                style:
                    AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted)),
        ],
      ),
      actions: [
        if (lesson.isActive || extra?['isNow'] == true)
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
    );
  }

  AlochiAppBar _buildAppBarFromExtra() {
    final name = extra?['groupName']?.toString() ?? '';
    final subject = extra?['subject']?.toString() ?? 'Dars';
    final time = extra?['startTime']?.toString() ?? '';
    return AlochiAppBar(
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name.isNotEmpty ? '$name · $subject' : subject,
            style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
          ),
          if (time.isNotEmpty)
            Text(time,
                style:
                    AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted)),
        ],
      ),
    );
  }

  LessonDetailModel _buildFallbackLesson(String groupId) {
    return LessonDetailModel(
      id: lessonId,
      groupId: groupId,
      groupCode: extra?['groupName']?.toString() ?? '',
      subjectName: extra?['subject']?.toString() ?? '',
      startTime: extra?['startTime']?.toString() ?? '',
      endTime: extra?['endTime']?.toString() ?? '',
      date: DateTime.now().toIso8601String().split('T').first,
      isActive: extra?['isNow'] == true,
      studentCount: 0,
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _LessonWorkflowBody extends StatelessWidget {
  final LessonDetailModel lesson;
  final String groupId;
  final LessonWorkflowState workflowState;
  final LessonWorkflowNotifier notifier;

  const _LessonWorkflowBody({
    required this.lesson,
    required this.groupId,
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
            groupId: groupId,
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
            groupId: groupId,
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
            groupId: groupId,
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
            groupId: groupId,
            notifier: notifier,
          ),
        ],
      ),
    );
  }
}

// ─── Stepper ──────────────────────────────────────────────────────────────────

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
                      _label(step),
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

  String _label(WorkflowStep step) {
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

// ─── Step card ────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final WorkflowStep step;
  final String title;
  final String subtitle;
  final IconData icon;
  final LessonWorkflowState workflowState;
  final LessonDetailModel lesson;
  final String groupId;
  final LessonWorkflowNotifier notifier;

  const _StepCard({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.workflowState,
    required this.lesson,
    required this.groupId,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = workflowState.isCompleted(step);
    final isActive = workflowState.currentStep == step;
    final isLocked = workflowState.isLocked(step);

    final Color borderColor;
    final Color bgColor;
    final Color iconColor;
    final Color iconBg;

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
                    Text(subtitle,
                        style: AppTextStyles.bodyS
                            .copyWith(color: AppColors.brandMuted)),
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
            _Step1Content(lesson: lesson, groupId: groupId, notifier: notifier),
          ],
          if (isActive && step == WorkflowStep.homework) ...[
            const SizedBox(height: AppSpacing.l),
            _Step2HomeworkCheck(
                lesson: lesson, groupId: groupId, notifier: notifier),
          ],
          if (isActive && step == WorkflowStep.grading) ...[
            const SizedBox(height: AppSpacing.l),
            _Step3ActivityContent(
                lesson: lesson, groupId: groupId, notifier: notifier),
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

// ─── Step 1 — Davomat ─────────────────────────────────────────────────────────

class _Step1Content extends ConsumerWidget {
  final LessonDetailModel lesson;
  final String groupId;
  final LessonWorkflowNotifier notifier;

  const _Step1Content({
    required this.lesson,
    required this.groupId,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = _today();
    final key = (classId: groupId, date: today);
    final stateAsync = ref.watch(attendanceMarkingProvider(key));

    return stateAsync.when(
      data: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.markedCount > 0)
            _AttendanceSummary(state: state)
          else
            Text("Davomat hali olinmagan",
                style: AppTextStyles.bodyS.copyWith(color: AppColors.gray)),
          const SizedBox(height: AppSpacing.m),
          Row(
            children: [
              Expanded(
                child: AlochiButton.primary(
                  label: state.markedCount > 0 ? "Tahrirlash" : "Davomat olish",
                  icon: Icons.how_to_reg_rounded,
                  onPressed: () => context.push(
                    '/teacher/lesson/${lesson.id}/attendance',
                    extra: {'classId': groupId, 'date': today},
                  ),
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
          '/teacher/lesson/${lesson.id}/attendance',
          extra: {'classId': groupId, 'date': today},
        ),
      ),
    );
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}

class _AttendanceSummary extends StatelessWidget {
  final AttendanceMarkingState state;
  const _AttendanceSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _Chip(
            count: state.presentCount,
            label: 'Keldi',
            color: const Color(0xFF0F9A6E)),
        _Chip(
            count: state.lateCount,
            label: 'Kech',
            color: const Color(0xFFD97706)),
        _Chip(count: state.absentCount, label: "Yo'q", color: AppColors.danger),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _Chip({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.round),
      ),
      child: Text('$count $label',
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Step 2 — Vazifa tekshirish ───────────────────────────────────────────────

class _Step2HomeworkCheck extends ConsumerWidget {
  final LessonDetailModel lesson;
  final String groupId;
  final LessonWorkflowNotifier notifier;

  const _Step2HomeworkCheck({
    required this.lesson,
    required this.groupId,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checked = ref.watch(homeworkCheckProvider(groupId));
    final checkNotifier = ref.read(homeworkCheckProvider(groupId).notifier);
    final today = _today();
    final key = (classId: groupId, date: today);
    final attAsync = ref.watch(attendanceMarkingProvider(key));

    return attAsync.when(
      data: (state) {
        final attending = state.students.where((s) {
          final st = state.statuses[s.id];
          return st == AttendanceStatus.present || st == AttendanceStatus.late;
        }).toList();

        return Column(
          children: [
            if (attending.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                child: Text("Darsda hech kim yo'q",
                    style: AppTextStyles.bodyS.copyWith(color: AppColors.gray)),
              )
            else
              ...attending.map((s) {
                final isChecked = checked.contains(s.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s),
                  child: Row(
                    children: [
                      AlochiAvatar(name: s.fullName, size: 32),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Text(s.fullName,
                            style: AppTextStyles.bodyS
                                .copyWith(color: AppColors.ink)),
                      ),
                      Checkbox(
                        value: isChecked,
                        activeColor: AppColors.brand,
                        onChanged: (v) {
                          final c = Set<String>.from(checked);
                          if (v == true) {
                            c.add(s.id);
                          } else {
                            c.remove(s.id);
                          }
                          checkNotifier.state = c;
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

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}

// ─── Step 3 — Baholash (mavzu baho + aktivlik) ───────────────────────────────

class _Step3ActivityContent extends ConsumerStatefulWidget {
  final LessonDetailModel lesson;
  final String groupId;
  final LessonWorkflowNotifier notifier;

  const _Step3ActivityContent({
    required this.lesson,
    required this.groupId,
    required this.notifier,
  });

  @override
  ConsumerState<_Step3ActivityContent> createState() =>
      _Step3ActivityContentState();
}

class _Step3ActivityContentState extends ConsumerState<_Step3ActivityContent> {
  bool _isSaving = false;

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveAndNext(List<StudentModel> students) async {
    final grades = ref.read(topicGradeProvider(widget.groupId));
    if (grades.isEmpty) {
      widget.notifier.completeStep(WorkflowStep.grading);
      return;
    }
    setState(() => _isSaving = true);
    final api = ref.read(teacherApiProvider);
    final today = _today();
    final subject = widget.lesson.subjectName.isNotEmpty
        ? widget.lesson.subjectName
        : 'Matematika';

    for (final s in students) {
      final g = grades[s.id] ?? 0;
      if (g == 0) continue;
      try {
        await api.setGrade(
          studentId: s.id,
          grade: g,
          date: today,
          groupId: widget.groupId,
          subject: subject,
        );
      } catch (e) {
        debugPrint('setGrade error for \${s.id}: \$e');
      }
    }
    if (mounted) {
      setState(() => _isSaving = false);
      // Refresh journal so GroupDetail shows new grades
      ref.invalidate(gradesJournalProvider(widget.groupId));
      ref.invalidate(groupDetailProvider(widget.groupId));
      widget.notifier.completeStep(WorkflowStep.grading);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grades = ref.watch(topicGradeProvider(widget.groupId));
    final gradeNotifier = ref.read(topicGradeProvider(widget.groupId).notifier);
    final ratings = ref.watch(activityRatingProvider(widget.groupId));
    final ratingNotifier =
        ref.read(activityRatingProvider(widget.groupId).notifier);

    final today = _today();
    final attAsync = ref.watch(
        attendanceMarkingProvider((classId: widget.groupId, date: today)));

    final students = attAsync.valueOrNull?.students.where((s) {
          final st = attAsync.valueOrNull?.statuses[s.id];
          return st == AttendanceStatus.present || st == AttendanceStatus.late;
        }).toList() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section: Mavzu bahosi (topic grade)
        Row(children: [
          const Icon(Icons.grade_rounded, size: 16, color: AppColors.brand),
          const SizedBox(width: 6),
          Text(
            'Mavzu bahosi (2-5)',
            style: AppTextStyles.label
                .copyWith(color: AppColors.brand, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Text(
            widget.lesson.subjectName.isNotEmpty
                ? widget.lesson.subjectName
                : '',
            style: AppTextStyles.caption.copyWith(color: AppColors.gray),
          ),
        ]),
        const SizedBox(height: AppSpacing.s),
        if (students.isEmpty)
          Text("Darsda o'quvchilar yo'q",
              style: AppTextStyles.bodyS.copyWith(color: AppColors.gray))
        else
          ...students.map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Row(
                children: [
                  AlochiAvatar(name: s.fullName, size: 32),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(s.fullName,
                        style:
                            AppTextStyles.bodyS.copyWith(color: AppColors.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  // Grade buttons 2-3-4-5
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [2, 3, 4, 5].map((g) {
                      final isSelected = grades[s.id] == g;
                      final color = _gradeColor(g);
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: GestureDetector(
                          onTap: () {
                            final c = Map<String, int>.from(grades);
                            c[s.id] = isSelected ? 0 : g;
                            gradeNotifier.state = c;
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? color : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$g',
                              style: AppTextStyles.label.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: AppSpacing.l),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        const SizedBox(height: AppSpacing.m),

        // Section: Aktivlik (activity rating)
        Row(children: [
          const Icon(Icons.bolt_rounded, size: 16, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            'Dars aktivligi',
            style: AppTextStyles.label
                .copyWith(color: AppColors.accent, fontWeight: FontWeight.w600),
          ),
        ]),
        const SizedBox(height: AppSpacing.s),
        ...students.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Row(
                children: [
                  AlochiAvatar(name: s.fullName, size: 32),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(s.fullName,
                        style:
                            AppTextStyles.bodyS.copyWith(color: AppColors.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  _RatingButtons(
                    value: ratings[s.id] ?? 0,
                    onChanged: (r) {
                      final c = Map<String, int>.from(ratings);
                      c[s.id] = r;
                      ratingNotifier.state = c;
                    },
                  ),
                ],
              ),
            )),

        const SizedBox(height: AppSpacing.l),
        Row(
          children: [
            Expanded(
              child: AlochiButton.secondary(
                label: 'Orqaga',
                onPressed: _isSaving
                    ? null
                    : () => widget.notifier.backStep(WorkflowStep.grading),
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: AlochiButton.primary(
                label: "Saqlash ›",
                isLoading: _isSaving,
                onPressed: _isSaving ? null : () => _saveAndNext(students),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _gradeColor(int g) {
    switch (g) {
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

class _RatingButtons extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _RatingButtons({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _RBtn(
          val: 1,
          label: 'Zaif',
          color: AppColors.danger,
          active: value == 1,
          onTap: () => onChanged(1)),
      const SizedBox(width: 4),
      _RBtn(
          val: 2,
          label: "O'rta",
          color: const Color(0xFFD97706),
          active: value == 2,
          onTap: () => onChanged(2)),
      const SizedBox(width: 4),
      _RBtn(
          val: 3,
          label: 'Yaxshi',
          color: const Color(0xFF0F9A6E),
          active: value == 3,
          onTap: () => onChanged(3)),
    ]);
  }
}

class _RBtn extends StatelessWidget {
  final int val;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;
  const _RBtn(
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
        child: Text(label,
            style: AppTextStyles.caption.copyWith(
                color: active ? Colors.white : const Color(0xFF6B7280),
                fontSize: 10,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─── Step 4 — Yakunlash ───────────────────────────────────────────────────────

class _Step4FinishContent extends ConsumerStatefulWidget {
  final LessonDetailModel lesson;
  final LessonWorkflowNotifier notifier;

  const _Step4FinishContent({required this.lesson, required this.notifier});

  @override
  ConsumerState<_Step4FinishContent> createState() => _Step4State();
}

class _Step4State extends ConsumerState<_Step4FinishContent> {
  final _title = TextEditingController();
  int? _days;
  bool _isFinishing = false;

  static const _opts = [
    (label: 'Bugun', days: 0),
    (label: 'Erta', days: 1),
    (label: '3 kun', days: 3),
    (label: '1 hafta', days: 7),
  ];

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createStatus = ref.watch(homeworkCreateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Yangi uy vazifasi (ixtiyoriy)',
            style: AppTextStyles.label.copyWith(
                color: AppColors.brandMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.s),
        TextField(
          controller: _title,
          style: AppTextStyles.body.copyWith(color: AppColors.ink),
          decoration: InputDecoration(
            hintText: 'Mavzu...',
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.brandMuted),
            filled: true,
            fillColor: Theme.of(context).cardColor,
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
          children: _opts.map((o) {
            final sel = _days == o.days;
            return ChoiceChip(
              label: Text(o.label),
              selected: sel,
              onSelected: (v) => setState(() => _days = v ? o.days : null),
              selectedColor: AppColors.brandSoft,
              labelStyle: AppTextStyles.label
                  .copyWith(color: sel ? AppColors.brand : AppColors.ink),
            );
          }).toList(),
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
    if (_title.text.trim().isNotEmpty) {
      final d = _days ?? 7;
      final deadline = DateTime.now().add(Duration(days: d));
      final due =
          '${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}';
      await ref.read(homeworkCreateProvider.notifier).create(
            groupId: widget.lesson.groupId,
            title: _title.text.trim(),
            description: '',
            dueDate: due,
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
