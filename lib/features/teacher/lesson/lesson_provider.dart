import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/lesson_detail_model.dart';
import '../dashboard/dashboard_provider.dart';

final lessonDetailProvider =
    FutureProvider.family<LessonDetailModel, String>((ref, lessonId) async {
  final api = ref.read(teacherApiProvider);
  return api.getLessonDetail(lessonId);
});

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
    final order = WorkflowStep.values;
    final stepIdx = order.indexOf(step);
    if (stepIdx == 0) return false;
    final prev = order[stepIdx - 1];
    return !completedSteps.contains(prev);
  }

  LessonWorkflowState completeStep(WorkflowStep step) {
    final newCompleted = Set<WorkflowStep>.from(completedSteps)..add(step);
    final order = WorkflowStep.values;
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
}

final lessonWorkflowProvider = StateNotifierProvider.family<
    LessonWorkflowNotifier,
    LessonWorkflowState,
    String>((ref, lessonId) => LessonWorkflowNotifier());
