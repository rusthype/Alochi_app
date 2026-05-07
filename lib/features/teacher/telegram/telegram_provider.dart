import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/teacher_api.dart';
import '../dashboard/dashboard_provider.dart';

// Re-export types from teacher_api for use in screens
export '../../../core/api/teacher_api.dart'
    show TelegramGroupStatusData, UnlinkedParentData;

// ─── Telegram groups provider ─────────────────────────────────────────────────

final telegramGroupsProvider =
    FutureProvider.autoDispose<List<TelegramGroupStatusData>>((ref) async {
  final api = ref.read(teacherApiProvider);
  try {
    final data = await api.getTelegramGroupsStatus();
    return data;
  } catch (e, st) {
    debugPrint('telegramGroupsProvider error: $e\n$st');
    rethrow;
  }
});

// ─── Unlinked parents provider ────────────────────────────────────────────────

final unlinkedParentsProvider = FutureProvider.autoDispose
    .family<List<UnlinkedParentData>, String>((ref, groupId) async {
  final api = ref.read(teacherApiProvider);
  try {
    final data = await api.getUnlinkedParents(groupId);
    return data;
  } catch (e, st) {
    debugPrint('unlinkedParentsProvider error: $e\n$st');
    rethrow;
  }
});
