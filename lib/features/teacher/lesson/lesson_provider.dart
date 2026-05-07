import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/teacher_api.dart';
import '../../../core/models/lesson_detail_model.dart';
import '../dashboard/dashboard_provider.dart';
import '../../../core/utils/date_utils.dart';

/// Primary provider — tries /lessons/:id/ first.
/// On 404, composes from attendance + group data (no crash).
final lessonDetailProvider = FutureProvider.autoDispose
    .family<LessonDetailModel, String>((ref, lessonId) async {
  final api = ref.read(teacherApiProvider);
  try {
    return await api.getLessonDetail(lessonId);
  } catch (_) {
    // /teacher/lessons/:id/ not available in backend yet.
    // lessonId IS the group's lesson_id, which equals groupId in practice.
    // Fall back to composing from attendance endpoint.
    return _composeFromAttendance(api, lessonId);
  }
});

/// Composes LessonDetailModel from attendance + groups endpoints.
/// Takes groupId — works even when /lessons/ endpoint is missing.
final lessonFromGroupProvider = FutureProvider.autoDispose
    .family<LessonDetailModel, String>((ref, groupId) async {
  final api = ref.read(teacherApiProvider);
  return _composeFromAttendance(api, groupId);
});

Future<LessonDetailModel> _composeFromAttendance(
    TeacherApi api, String groupId) async {
  // GET /teacher/panel/groups/:id/attendance/
  // Returns {lesson_id, group: {id, name, subject}, date, students: [...]}
  final data = await api.getGroupAttendanceRaw(groupId);

  final group = data['group'] as Map<String, dynamic>? ?? {};
  final lessonId = data['lesson_id']?.toString() ?? groupId;
  final students = data['students'] as List? ?? [];
  final dateStr = data['date']?.toString() ?? todayIsoString();

  return LessonDetailModel(
    id: lessonId,
    groupId: groupId,
    groupCode: group['name']?.toString() ?? '',
    subjectName: group['subject']?.toString() ?? '',
    startTime: '',
    endTime: '',
    date: dateStr,
    isActive: true,
    studentCount: students.length,
  );
}

// ─── Workflow state ───────────────────────────────────────────────────────────

enum WorkflowStep { attendance, homework, grading, finish }

class LessonWorkflowState {
  final WorkflowStep currentStep;
  final Set<WorkflowStep> completedSteps;

  const LessonWorkflowState({
    this.currentStep = WorkflowStep.attendance,
    this.completedSteps = const {},
  });

  bool isCompleted(WorkflowStep step) => completedSteps.contains(step);

  bool isLocked(WorkflowStep step) {
    const order = WorkflowStep.values;
    final stepIdx = order.indexOf(step);
    if (stepIdx == 0) return false;
    final prev = order[stepIdx - 1];
    return !completedSteps.contains(prev);
  }

  LessonWorkflowState completeStep(WorkflowStep step) {
    final newCompleted = Set<WorkflowStep>.from(completedSteps)..add(step);
    const order = WorkflowStep.values;
    final nextIdx = order.indexOf(step) + 1;
    final nextStep = nextIdx < order.length ? order[nextIdx] : step;
    return LessonWorkflowState(
      currentStep: nextStep,
      completedSteps: newCompleted,
    );
  }
}

class LessonWorkflowNotifier extends StateNotifier<LessonWorkflowState> {
  LessonWorkflowNotifier() : super(const LessonWorkflowState());

  void completeStep(WorkflowStep step) {
    state = state.completeStep(step);
  }

  void backStep(WorkflowStep step) {
    const order = WorkflowStep.values;
    final idx = order.indexOf(step);
    if (idx <= 0) return;
    final prev = order[idx - 1];
    final newCompleted = Set<WorkflowStep>.from(state.completedSteps)
      ..remove(step);
    state = LessonWorkflowState(
      currentStep: prev,
      completedSteps: newCompleted,
    );
  }
}

final lessonWorkflowProvider = StateNotifierProvider.autoDispose
    .family<LessonWorkflowNotifier, LessonWorkflowState, String>(
        (ref, lessonId) => LessonWorkflowNotifier());
