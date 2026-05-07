import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user.dart';
import '../../core/api/auth_api.dart';
import '../../core/storage/storage.dart';
import '../../core/services/fcm_service.dart';
import '../teacher/dashboard/dashboard_provider.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  /// True when user is authenticated but has not yet seen onboarding.
  final bool needsOnboarding;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.needsOnboarding = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? needsOnboarding,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      needsOnboarding: needsOnboarding ?? this.needsOnboarding,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApi _api = AuthApi();
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    try {
      final token = await AppStorage.getAccessToken();
      if (token == null) {
        state = const AuthState();
        return;
      }

      // Load cached user for offline fallback
      UserModel? cachedUser;
      try {
        final cachedJson = await AppStorage.getUserData();
        if (cachedJson != null) {
          cachedUser = UserModel.fromJson(
              jsonDecode(cachedJson) as Map<String, dynamic>);
        }
      } catch (_) {}

      try {
        final user = await _api.me();
        // Persist user to cache
        await AppStorage.saveUserData(jsonEncode(user.toJson()));
        state = AuthState(user: user);
        if (user.role == 'teacher') _registerFCM();
      } catch (e) {
        final msg = e.toString();
        final isAuthError = msg.contains('Kirish huquqi') ||
            msg.contains('401') ||
            msg.contains('403') ||
            msg.contains('Ruxsat yo');
        if (isAuthError) {
          // Token expired or revoked — force login
          await AppStorage.clearAll();
          state = const AuthState();
        } else {
          // Network/server error — keep logged in with cached user
          debugPrint('_init: me() failed ($msg), using cached user');
          if (cachedUser != null) {
            state = AuthState(user: cachedUser);
          } else {
            state = const AuthState();
          }
        }
      }
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _api.login(username, password);
      // Check first-login flag for teacher role
      bool needsOnboarding = false;
      if (user.role == 'teacher') {
        final done = await AppStorage.readKey('first_login_complete');
        needsOnboarding = done != 'true';

        // Register FCM token
        _registerFCM();
      }
      // Mark first login complete immediately so onboarding is shown only once
      if (needsOnboarding) {
        await AppStorage.writeKey('first_login_complete', 'true');
      }
      // Cache user for offline fallback
      try {
        await AppStorage.saveUserData(jsonEncode(user.toJson()));
      } catch (_) {}
      state = AuthState(user: user, needsOnboarding: needsOnboarding);
    } catch (_) {
      state = state.copyWith(
          isLoading: false,
          error: 'Login amalga oshmadi. Ma\'lumotlarni tekshiring');
    }
  }

  Future<void> _registerFCM() async {
    try {
      final fcm = FCMService();
      await fcm.registerToken(_ref.read(teacherApiProvider));
    } catch (e) {
      // Silent fail
    }
  }

  /// Clear the needsOnboarding flag after user completes/skips onboarding.
  Future<void> clearOnboardingFlag() async {
    await AppStorage.writeKey('first_login_complete', 'true');
    state = state.copyWith(needsOnboarding: false);
  }

  Future<void> logout() async {
    // Unregister FCM token before logout if teacher
    if (state.user?.role == 'teacher') {
      try {
        final fcm = FCMService();
        await fcm.unregisterToken(_ref.read(teacherApiProvider));
      } catch (e) {
        // Silent fail
      }
    }

    await _api.logout();
    state = const AuthState();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref));
