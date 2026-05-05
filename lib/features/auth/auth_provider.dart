import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user.dart';
import '../../core/api/auth_api.dart';
import '../../core/storage/storage.dart';

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

  AuthNotifier() : super(const AuthState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    try {
      final token = await AppStorage.getAccessToken();
      if (token != null) {
        final user = await _api.me();
        state = AuthState(user: user);
      } else {
        state = const AuthState();
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
      }
      state = AuthState(user: user, needsOnboarding: needsOnboarding);
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'Login failed. Check your credentials.');
    }
  }

  /// Clear the needsOnboarding flag after user completes/skips onboarding.
  void clearOnboardingFlag() {
    state = state.copyWith(needsOnboarding: false);
  }

  Future<void> logout() async {
    await _api.logout();
    state = const AuthState();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
