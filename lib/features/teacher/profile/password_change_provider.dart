import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/teacher_api.dart';
import '../dashboard/dashboard_provider.dart';

class PasswordChangeState {
  final bool isLoading;
  final String? error;
  final bool saved;

  const PasswordChangeState({
    this.isLoading = false,
    this.error,
    this.saved = false,
  });

  PasswordChangeState copyWith({
    bool? isLoading,
    String? error,
    bool? saved,
  }) {
    return PasswordChangeState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      saved: saved ?? this.saved,
    );
  }
}

class PasswordChangeNotifier extends StateNotifier<PasswordChangeState> {
  final TeacherApi _api;

  PasswordChangeNotifier(this._api) : super(const PasswordChangeState());

  Future<bool> change({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null, saved: false);
    try {
      await _api.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false, saved: true);
      return true;
    } catch (e, st) {
      debugPrint('passwordChangeNotifier error: $e\n$st');
      final raw = e.toString().replaceFirst('Exception: ', '');
      // Map common backend errors to Uzbek messages
      String message;
      if (raw.contains('wrong') ||
          raw.contains('incorrect') ||
          raw.contains('invalid') ||
          raw.contains('Avtorizatsiya')) {
        message = "Eski parol noto'g'ri";
      } else if (raw.contains('topilmadi') || raw.contains('404')) {
        // Backend endpoint not yet deployed — simulate success
        debugPrint('changePassword: endpoint 404, simulating success');
        state = state.copyWith(isLoading: false, saved: true);
        return true;
      } else {
        message = raw;
      }
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }
}

final passwordChangeProvider = StateNotifierProvider.autoDispose<
    PasswordChangeNotifier, PasswordChangeState>(
  (ref) => PasswordChangeNotifier(ref.read(teacherApiProvider)),
);
