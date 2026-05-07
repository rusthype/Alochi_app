import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/teacher_api.dart';
import '../../../core/api/connectivity_provider.dart';
import '../../../core/storage/offline_sync.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/models/student_model.dart';
import '../dashboard/dashboard_provider.dart';

enum AttendancePeriod { week, month, quarter }

class AttendanceMarkingState {
  final String classId;
  final String date;
  final List<StudentModel> students;
  final Map<String, AttendanceStatus> statuses;
  final bool isSaving;
  final bool hasUnsavedChanges;
  final String? error;
  final bool savedSuccessfully;

  const AttendanceMarkingState({
    required this.classId,
    required this.date,
    required this.students,
    required this.statuses,
    this.isSaving = false,
    this.hasUnsavedChanges = false,
    this.error,
    this.savedSuccessfully = false,
  });

  int get presentCount =>
      statuses.values.where((s) => s == AttendanceStatus.present).length;
  int get lateCount =>
      statuses.values.where((s) => s == AttendanceStatus.late).length;
  int get absentCount =>
      statuses.values.where((s) => s == AttendanceStatus.absent).length;
  int get markedCount => presentCount + lateCount + absentCount;
  int get unmarkedCount => students.length - markedCount;
  bool get canSave => hasUnsavedChanges && unmarkedCount == 0;

  AttendanceMarkingState copyWith({
    List<StudentModel>? students,
    Map<String, AttendanceStatus>? statuses,
    bool? isSaving,
    bool? hasUnsavedChanges,
    String? error,
    bool? savedSuccessfully,
  }) {
    return AttendanceMarkingState(
      classId: classId,
      date: date,
      students: students ?? this.students,
      statuses: statuses ?? this.statuses,
      isSaving: isSaving ?? this.isSaving,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      error: error,
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
    );
  }
}

typedef AttendanceKey = ({String classId, String date});

class AttendanceMarkingNotifier
    extends StateNotifier<AsyncValue<AttendanceMarkingState>> {
  final TeacherApi _api;
  final String classId;
  final String date;
  final Ref ref;

  AttendanceMarkingNotifier({
    required TeacherApi api,
    required this.classId,
    required this.date,
    required this.ref,
  })  : _api = api,
        super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final students = await _api.getGroupStudents(classId);
      final existing = await _api.getAttendance(classId: classId, date: date);
      final initialStatuses = <String, AttendanceStatus>{};
      for (final s in students) {
        initialStatuses[s.id] = existing[s.id] ?? AttendanceStatus.unmarked;
      }
      state = AsyncValue.data(AttendanceMarkingState(
        classId: classId,
        date: date,
        students: students,
        statuses: initialStatuses,
      ));
    } catch (e, st) {
      debugPrint('AttendanceMarkingNotifier._load error: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }

  void setStatus(String studentId, AttendanceStatus status) {
    final current = state.valueOrNull;
    if (current == null) return;
    final newStatuses = Map<String, AttendanceStatus>.from(current.statuses);
    newStatuses[studentId] = status;
    state = AsyncValue.data(current.copyWith(
      statuses: newStatuses,
      hasUnsavedChanges: true,
    ));
  }

  void markAllPresent() {
    final current = state.valueOrNull;
    if (current == null) return;
    final newStatuses = <String, AttendanceStatus>{};
    for (final s in current.students) {
      newStatuses[s.id] = AttendanceStatus.present;
    }
    state = AsyncValue.data(current.copyWith(
      statuses: newStatuses,
      hasUnsavedChanges: true,
    ));
  }

  Future<void> save() async {
    final current = state.valueOrNull;
    if (current == null || !current.canSave) return;
    
    final isOnline = ref.read(isOnlineProvider);
    state = AsyncValue.data(current.copyWith(isSaving: true, error: null));
    
    try {
      if (isOnline) {
        await _api.markAttendance(
          classId: classId,
          date: date,
          statuses: current.statuses,
        );
      } else {
        // Offline sinxronizatsiya uchun payload tayyorlash
        final statusStrings = current.statuses.map(
          (key, value) => MapEntry(key, AttendanceRecordModel.statusToString(value)),
        );
        
        await OfflineSyncService.enqueue(
          type: 'attendance',
          endpoint: '/teacher/attendance/mark/',
          payload: {
            'class_id': classId,
            'date': date,
            'statuses': statusStrings,
          },
        );
        
        // Simulyatsiya uchun biroz kutamiz
        await Future.delayed(const Duration(milliseconds: 500));
      }

      state = AsyncValue.data(current.copyWith(
        isSaving: false,
        hasUnsavedChanges: false,
        savedSuccessfully: true,
      ));
    } catch (e, st) {
      debugPrint('AttendanceMarkingNotifier.save error: $e\n$st');
      state = AsyncValue.data(current.copyWith(
        isSaving: false,
        error: e.toString(),
      ));
    }
  }
}

final attendanceMarkingProvider = StateNotifierProvider.autoDispose.family<
    AttendanceMarkingNotifier,
    AsyncValue<AttendanceMarkingState>,
    AttendanceKey>((ref, key) {
  final api = ref.read(teacherApiProvider);
  return AttendanceMarkingNotifier(
    api: api,
    classId: key.classId,
    date: key.date,
    ref: ref,
  );
});

final attendanceHistoryProvider = FutureProvider.autoDispose
    .family<AttendanceHistoryModel, ({String classId, String period})>(
        (ref, args) async {
  final api = ref.read(teacherApiProvider);
  return api.getAttendanceHistory(classId: args.classId, period: args.period);
});
