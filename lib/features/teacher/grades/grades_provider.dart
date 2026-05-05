import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/teacher_api.dart';
import '../dashboard/dashboard_provider.dart';

final gradesJournalProvider =
    FutureProvider.autoDispose.family<GradesJournalData, String>((ref, groupId) async {
  final api = ref.read(teacherApiProvider);
  return api.getGrades(groupId: groupId);
});

// ─── Pending grade edits state ───────────────────────────────────────────────

class GradeEditState {
  /// Map of studentId → pending grade (2–5, or 0 = not set)
  final Map<String, int> pending;
  final bool isSaving;
  final bool savedSuccessfully;
  final String? error;

  const GradeEditState({
    required this.pending,
    this.isSaving = false,
    this.savedSuccessfully = false,
    this.error,
  });

  GradeEditState copyWith({
    Map<String, int>? pending,
    bool? isSaving,
    bool? savedSuccessfully,
    String? error,
  }) {
    return GradeEditState(
      pending: pending ?? this.pending,
      isSaving: isSaving ?? this.isSaving,
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
      error: error,
    );
  }

  bool get hasChanges => pending.values.any((g) => g > 0);
}

typedef GradeEditKey = ({String groupId, String subject, String date});

class GradeEditNotifier extends StateNotifier<GradeEditState> {
  final TeacherApi _api;
  final String groupId;
  final String subject;
  final String date;

  GradeEditNotifier({
    required TeacherApi api,
    required this.groupId,
    required this.subject,
    required this.date,
  })  : _api = api,
        super(const GradeEditState(pending: {}));

  void setGrade(String studentId, int grade) {
    final updated = Map<String, int>.from(state.pending);
    if (grade == 0) {
      updated.remove(studentId);
    } else {
      updated[studentId] = grade;
    }
    state = state.copyWith(pending: updated, savedSuccessfully: false, error: null);
  }

  Future<void> saveAll() async {
    if (!state.hasChanges || state.isSaving) return;
    state = state.copyWith(isSaving: true, error: null);
    try {
      final futures = state.pending.entries
          .where((e) => e.value > 0)
          .map((e) => _api.setGrade(
                studentId: e.key,
                subject: subject,
                grade: e.value,
                date: date,
              ))
          .toList();
      await Future.wait(futures);
      state = state.copyWith(
        isSaving: false,
        savedSuccessfully: true,
        pending: {},
      );
    } catch (e, st) {
      debugPrint('GradeEditNotifier.saveAll error: $e\n$st');
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }
}

final gradeEditProvider = StateNotifierProvider.autoDispose.family<GradeEditNotifier,
    GradeEditState, GradeEditKey>((ref, key) {
  final api = ref.read(teacherApiProvider);
  return GradeEditNotifier(
    api: api,
    groupId: key.groupId,
    subject: key.subject,
    date: key.date,
  );
});
