import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/teacher_api.dart';
import '../dashboard/dashboard_provider.dart';
import 'profile_provider.dart';

class ProfileEditState {
  final bool isLoading;
  final String? error;
  final bool saved;

  const ProfileEditState({
    this.isLoading = false,
    this.error,
    this.saved = false,
  });

  ProfileEditState copyWith({
    bool? isLoading,
    String? error,
    bool? saved,
  }) {
    return ProfileEditState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      saved: saved ?? this.saved,
    );
  }
}

class ProfileEditNotifier extends StateNotifier<ProfileEditState> {
  final TeacherApi _api;
  final Ref _ref;

  ProfileEditNotifier(this._api, this._ref) : super(const ProfileEditState());

  Future<bool> save({required String name, String? phone}) async {
    state = state.copyWith(isLoading: true, error: null, saved: false);
    try {
      await _api.patchTeacherProfile(name: name, phone: phone);
      // Invalidate profile so it refreshes on pop back
      _ref.invalidate(teacherProfileProvider);
      state = state.copyWith(isLoading: false, saved: true);
      return true;
    } catch (e, st) {
      debugPrint('profileEditNotifier save error: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final profileEditProvider =
    StateNotifierProvider.autoDispose<ProfileEditNotifier, ProfileEditState>(
  (ref) => ProfileEditNotifier(ref.read(teacherApiProvider), ref),
);
